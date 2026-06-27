// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./CollateralManager.sol";

/**
 * @title LendingPool
 * @notice Lends ETH to users who have sufficient collateral recorded in
 *         CollateralManager.  The pool enforces a 150 % collateral ratio:
 *         to borrow X ETH you must hold 1.5 × X ETH in collateral.
*/
contract LendingPool {
    // ── Constants ──────────────────────────────────────────────────────────
    /// @dev Borrower must hold 150 % of loan value in collateral.
    uint256 public constant COLLATERAL_RATIO = 150; // percent

    // ── State ──────────────────────────────────────────────────────────────
    CollateralManager public immutable collateralManager;

    mapping(address => uint256) public loans;       // outstanding borrows
    mapping(address => bool)    public hasBorrowed; // one borrow per user

    uint256 public totalLoaned;

    // ── Events ─────────────────────────────────────────────────────────────
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);

    // ── Constructor ────────────────────────────────────────────────────────
    constructor(address _collateralManager) payable {
        collateralManager = CollateralManager(payable(_collateralManager));
    }

    // ── Core ───────────────────────────────────────────────────────────────
    /**
     * @notice Borrow ETH against collateral held in CollateralManager.
     *
     * VULNERABILITY: collateralManager.getCollateral() is called here.
     * If this call arrives during CollateralManager.withdrawCollateral()'s
     * execution window (before collateral[] is decremented), the returned
     * value is stale and the loan is wrongly approved.
     */
    function borrow(uint256 amount) external {
        require(amount > 0, "Zero borrow");
        require(!hasBorrowed[msg.sender], "Already have a loan");
        require(address(this).balance >= amount, "Pool insufficient liquidity");

        uint256 userCollateral = collateralManager.getCollateral(msg.sender);

        // 150 % collateral ratio check
        require(
            userCollateral * 100 >= amount * COLLATERAL_RATIO,
            "Insufficient collateral"
        );

        hasBorrowed[msg.sender] = true;
        loans[msg.sender]  += amount;
        totalLoaned        += amount;

        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "Loan transfer failed");

        emit Borrowed(msg.sender, amount);
    }

    /// @notice Repay outstanding loan (full repayment only for simplicity).
    function repay() external payable {
        uint256 owed = loans[msg.sender];
        require(msg.value >= owed, "Underpayment");

        hasBorrowed[msg.sender] = false;
        loans[msg.sender]  = 0;
        totalLoaned       -= owed;

        // Refund overpayment
        if (msg.value > owed) {
            (bool ok, ) = msg.sender.call{value: msg.value - owed}("");
            require(ok, "Refund failed");
        }

        emit Repaid(msg.sender, owed);
    }

    function poolBalance() external view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}
}
