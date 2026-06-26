// //SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import {Test} from "forge-std/Test.sol";
// import {CrossContractAttack} from "../src/CrossContract/CrossContractAttack.sol";
// import {VulnerableVault} from "../src/CrossContract/VulnerableVault.sol";
// import {VulnerableToken} from "../src/CrossContract/VulnerableToken.sol";

// contract CrossContractAttackTest is Test {
//     VulnerableToken public token;
//     VulnerableVault public vault;
//     CrossContractAttack public attacker;

//     address victim = makeAddr("victim");

//     function setUp() public {
//         token = new VulnerableToken();
//         vault = new VulnerableVault(token);
//         token.setVault(address(vault));
//         attacker = new CrossContractAttack(vault, token);

//         vm.deal(victim, 10 ether);
//         vm.prank(victim);
//         vault.deposit{value: 10 ether}();
//     }

//     function testCrossContractAttack() public {
//         uint256 initialVaultBalance = address(vault).balance;

//         vm.deal(address(attacker), 1 ether);
//         vm.prank(address(attacker));
//         attacker.attack{value: 1 ether}();

//         uint256 finalVaultBalance = address(vault).balance;
//         uint256 finalAttackerBalance = address(attacker).balance;

//         assertEq(finalVaultBalance, initialVaultBalance - 10 ether, "Vault balance should be reduced by 10 ether");
//         assertGt(finalAttackerBalance, 10 ether, "Attacker balance should increase by 10 ether");
//     }
// }