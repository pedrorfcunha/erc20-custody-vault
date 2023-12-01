// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

error CustodyVault__NotTrustee();

contract CustodyVault {
    struct Deposit {
        uint256 batchId;
        uint256 depositId;
        address senderAddress;
        address receiverAddress;
        address token;
        uint256 amount;
        DepositStatus status;
    }

    enum DepositStatus {
        Pending,
        Transferred,
        Reverted
    }

    mapping(address => uint256) public balances;
    mapping(uint256 => Deposit) public deposits;
    uint256 public counter;
    mapping(address => bool) private allowedTokens;
    mapping(address => bool) private allowedSenders;
    mapping(address => bool) private trusteeAddress;

    modifier onlyTrustee() {
        if (!trusteeAddress[msg.sender]) revert CustodyVault__NotTrustee();
        _;
    }

    constructor() {
        trusteeAddress[msg.sender] = true;
    }

    function setTrusteeAddress(address _address) public onlyTrustee {
        trusteeAddress[_address] = true;
    }

    function removeTrusteeAddress(address _address) public onlyTrustee {
        trusteeAddress[_address] = false;
    }

    function setAllowedTokens(address _token) public onlyTrustee {
        allowedTokens[_token] = true;
    }

    function removeAllowedTokens(address _address) public onlyTrustee {
        allowedTokens[_address] = false;
    }

    function setAllowedSenders(address _address) public onlyTrustee {
        allowedSenders[_address] = true;
    }

    function removeAllowedSenders(address _address) public onlyTrustee {
        allowedSenders[_address] = false;
    }

    function deposit(
        address _token,
        uint256 _amount,
        address _receiverAddress,
        uint256 _batchId
    ) public {
        IERC20 token = IERC20(_token);
        // Validate if the ERC20 token matches the requirement/is registered
        require(isTokenAllowed(_token), "Token not allowed");

        // Validate if the sender has permission/is registered
        require(isAddressAllowed(msg.sender), "Address not registered");

        // Validate the sender's ERC20 token balance
        require(
            isBalanceEnought(_token, _amount),
            "Account with insufficient funds"
        );

        // Transfer the tokens from the sender to the contract
        token.transferFrom(msg.sender, address(this), _amount);
        balances[_token] += _amount;

        // Store the deposit details with the current counter value as depositId
        deposits[counter] = Deposit(
            _batchId,
            counter,
            msg.sender,
            _receiverAddress,
            _token,
            _amount,
            DepositStatus.Pending
        );

        // Increment the counter and use it as the depositId
        counter = counter + 1;
    }

    function approveTransfer(uint256 _depositId) public onlyTrustee {
        Deposit storage depositData = deposits[_depositId];

        // Ensure the deposit is valid and the status is Pending
        require(depositData.senderAddress != address(0), "Invalid deposit ID");
        require(
            depositData.status == DepositStatus.Pending,
            "Deposit already transferred"
        );

        // Transfer the deposited amount to the receiver address
        IERC20 token = IERC20(depositData.token);
        token.transfer(depositData.receiverAddress, depositData.amount);
        balances[depositData.token] -= depositData.amount;

        // Update the deposit status to Transferred
        depositData.status = DepositStatus.Transferred;
    }

    function revertTransfer(uint256 _depositId) public onlyTrustee {
        Deposit storage depositData = deposits[_depositId];

        // Ensure the deposit is valid and the status is Pending
        require(depositData.senderAddress != address(0), "Invalid deposit ID");
        require(
            depositData.status == DepositStatus.Pending,
            "Deposit already transferred or reverted"
        );

        // Transfer the deposited amount back to the sender address
        IERC20 token = IERC20(depositData.token);
        token.transfer(depositData.senderAddress, depositData.amount);
        balances[depositData.token] -= depositData.amount;

        // Update the deposit status to Transferred
        depositData.status = DepositStatus.Reverted;
    }

    function isTokenAllowed(address _token) public view returns (bool) {
        return allowedTokens[_token];
    }

    function isAddressAllowed(address _address) public view returns (bool) {
        return allowedSenders[_address];
    }

    function isTrustee(address _address) public view returns (bool) {
        return trusteeAddress[_address];
    }

    function isBalanceEnought(address _token, uint256 _amount)
        public
        view
        returns (bool)
    {
        IERC20 token = IERC20(_token);
        uint256 _balance = token.balanceOf(msg.sender);
        if (_balance >= _amount) {
            return true;
        }
        return false;
    }

    function getUserTokenBalance(address _token) public view returns (uint256) {
        IERC20 token = IERC20(_token);
        return token.balanceOf(msg.sender);
    }

    function getTransferStatus(uint256 _depositId)
        public
        view
        returns (string memory)
    {
        // Ensure the deposit is valid
        if (deposits[_depositId].senderAddress == address(0)) {
            return "Deposit invalid";
        }

        //Check the current status
        DepositStatus status = deposits[_depositId].status;
        if (status == DepositStatus.Pending) {
            return "Pending";
        } else if (status == DepositStatus.Transferred) {
            return "Transferred";
        } else if (status == DepositStatus.Reverted) {
            return "Reverted";
        }

        return "";
    }

    function getMaxBatchId() public view returns (uint256) {
        uint256 maxBatchId = 0;

        for (uint256 i = 0; i < counter; i++) {
            if (deposits[i].batchId > maxBatchId) {
                maxBatchId = deposits[i].batchId;
            }
        }

        return maxBatchId;
    }

    function getAllDeposits() public view returns (Deposit[] memory) {
        Deposit[] memory allDeposits = new Deposit[](counter);

        for (uint256 i = 0; i < counter; i++) {
            allDeposits[i] = deposits[i];
        }

        return allDeposits;
    }
}
