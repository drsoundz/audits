//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {CollateralManager} from "../src/ccr/CollateralManager.sol";
import {LendingPool} from "../src/ccr/LendingPool.sol";
import {PoolAttacker} from "../src/ccr/PoolAttacker.sol";

contract CrossContractAttackTest is Test {
    CollateralManager public collateralManager;
    LendingPool public lendingPool;
    PoolAttacker public attackPool;

    address public owner = makeAddr("owner");
    address public user = makeAddr("user");

    uint256 constant POOL_SEED = 10 ether;
    uint256 constant COLLATERAL = 2 ether;
    uint256 constant BORROW_AMOUNT = 1.3 ether;

    function setUp() public {
        vm.deal(owner, POOL_SEED);

        vm.startPrank(owner);
        collateralManager = new CollateralManager();
        lendingPool = new LendingPool{value: POOL_SEED}(address(collateralManager));
        collateralManager.setLendingPool(address(lendingPool));
        vm.stopPrank();

        vm.deal(owner, POOL_SEED);
        vm.deal(user, COLLATERAL);

        vm.prank(user);
        collateralManager.depositCollateral{value: COLLATERAL}();

        vm.prank(owner);
        attackPool = new PoolAttacker(payable(address(collateralManager)), payable(address(lendingPool)));

        vm.deal(owner, POOL_SEED);
    }

    function test_crossContractAttack() public {
        uint256 ownerBefore = owner.balance;
        uint256 poolBefore = address(lendingPool).balance;

        console.log("Owner before attack: ", ownerBefore / 1e18);
        console.log("Pool before attack: ", poolBefore / 1e18);
        console.log("attacker collateral", collateralManager.getCollateral(address(attackPool)) / 1e18);
        console.log("attacker loan before", lendingPool.loans(address(attackPool)) / 1e18);

        vm.prank(owner);
        attackPool.attack{value: COLLATERAL}(BORROW_AMOUNT);

        vm.prank(owner);
        attackPool.drain();


        uint256 ownerAfter = owner.balance;
        uint256 poolAfter = address(lendingPool).balance;

        console.log("Owner after attack: ", ownerAfter / 1e18);
        console.log("Pool after attack: ", poolAfter / 1e18);  
        console.log("attacker collateral", collateralManager.getCollateral(address(attackPool)) / 1e18);
        console.log("attacker loan after", lendingPool.loans(address(attackPool)) / 1e18);

        assertGt(ownerAfter, ownerBefore);
        assertEq(collateralManager.getCollateral(address(attackPool)), 0);

    }
}