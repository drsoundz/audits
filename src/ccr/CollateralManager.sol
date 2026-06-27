// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CollateralManager{
    mapping(address => uint256) public collaterals;
    address public owner;
    address public lendingPool;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function setLendingPool(address _lendingPool) external onlyOwner {
        lendingPool = _lendingPool;
    }

    function depositCollateral() external payable {
        require(msg.value > 0, "zero deposit");
        collaterals[msg.sender] += msg.value;
    }

    function withdrawCollateral(uint256 amount) external {
        require(collaterals[msg.sender] >= amount, "insufficient collateral");

        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "ETH transfer failed");

        collaterals[msg.sender] -= amount;
    }

    function getCollateral(address user) public view returns(uint256){
        return collaterals[user];
    }
}