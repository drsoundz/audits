// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MalleableWithdraw {
    address public owner;
    mapping(bytes32 => bool) public usedSignatures;

    constructor(address _owner) payable {
        owner = _owner;
    }

    receive() external payable {}

    /// @notice VULNERABLE — replay protection keyed by signature bytes, not a nonce.
    function withdraw(address to, uint256 amount, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 sigHash = keccak256(abi.encodePacked(v, r, s));
        require(!usedSignatures[sigHash], "signature already used");

        bytes32 messageHash = keccak256(abi.encodePacked(to, amount));
        address signer = ecrecover(messageHash, v, r, s);
        require(signer == owner, "invalid signature");

        usedSignatures[sigHash] = true;
        (bool success, ) = to.call{value: amount}("");
        require(success, "transfer failed");
    }
}