// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;


// contract VulnerableToken {
//     mapping(address => uint256) public balanceOf;
//     uint256 public totalSupply;

//     address public vault;

//     modifier onlyVault() {
//         require(msg.sender == vault, "not vault");
//         _;
//     }

//     function setVault(address _vault) external {
//         require(vault == address(0), "already set");
//         vault = _vault;
//     }

//     function mint(address to, uint256 amount) external onlyVault {
//         balanceOf[to] += amount;
//         totalSupply += amount;
//     }

//     function burn(address from, uint256 amount) external onlyVault {
//         require(balanceOf[from] >= amount, "insufficient balance");
//         balanceOf[from] -= amount;
//         totalSupply -= amount;
//     }

//     function transfer(address from, address to, uint256 amount) external onlyVault {
//         require(balanceOf[from] >= amount, "insufficient balance");

//         // if (to.code.length > 0) {
//         //     ITokenReceiver(to).onTokenReceived(from, amount);  // <-- reentrancy hook
//         // }

//         balanceOf[from] -= amount;
//         balanceOf[to]   += amount;
//     }
// }

// // interface ITokenReceiver {
// //     function onTokenReceived(address from, uint256 amount) external;
// // }
