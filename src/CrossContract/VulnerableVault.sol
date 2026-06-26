// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import "./VulnerableToken.sol";

// contract VulnerableVault {
//     VulnerableToken public immutable token;

//     constructor(VulnerableToken _token) {
//         token = _token;
//     }


//     function deposit() external payable {
//         require(msg.value > 0, "zero deposit");
//         token.mint(msg.sender, msg.value);
//     }


//     function withdraw(uint256 amount) external {
//         uint256 bal = token.balanceOf(msg.sender);
//         require(bal >= amount, "insufficient token balance");

//         (bool ok, ) = msg.sender.call{value: amount}("");
//         require(ok, "ETH transfer failed");


//         token.transfer(msg.sender, address(0), amount); 
//     }

//     function vaultBalance() external view returns (uint256) {
//         return address(this).balance;
//     }
// }
