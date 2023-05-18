// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

contract CustodyVault {
    struct Deposit {
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
    address[] private allowedTokens;
    address[] private allowedAddresses;

    function setAllowedTokens(address _token) public returns (address) {
        allowedTokens.push(_token);
        return _token;
    }

    function setAllowedAddresses(address _address) public returns (address) {
        allowedAddresses.push(_address);
        return _address;
    }

    function deposit(
        address _token,
        uint256 _amount,
        address _receiverAddress
    ) public {
        IERC20 token = IERC20(_token);

        // If necessaary, set the minimum amount to X token
        // uint256 _minAmount = 1 * (10 ** );

        // Here we validate if the amount sent is enough
        // require(_amount >= _minAmount, "Amount less than the minimum amount");

        // Validate if the ERC20 token matches the requirement/is registered
        require(isTokenAllowed(_token), "Token not allowed");

        // Validate if the sender has permission/is registered
        require(isAddressAllowed(msg.sender), "Address not registered");

        // Validate the sender's ERC20 token balance
        // uint256 _balance = token.balanceOf(msg.sender);
        // require(_balance >= _amount, "Account with insufficient funds");
        require(
            isBalanceEnought(_token, _amount),
            "Account with insufficient funds"
        );

        // Transfer the tokens from the sender to the contract
        token.transferFrom(msg.sender, address(this), _amount);
        balances[_token] += _amount;

        // Store the deposit details with the current counter value as depositId
        deposits[counter] = Deposit(
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

    function approveTransfer(uint256 _depositId) public {
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

    function revertTransfer(uint256 _depositId) public {
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
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            if (_token == allowedTokens[i]) {
                return true;
            }
        }
        return false;
    }

    function isAddressAllowed(address _address) public view returns (bool) {
        for (uint256 i = 0; i < allowedAddresses.length; i++) {
            if (_address == allowedAddresses[i]) {
                return true;
            }
        }
        return false;
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
}


// Missing:
// 1. Set access control (only a trustee may set allowedAddresses and allowedTokens)
// 2. Create a simple front-end to interact with the contract
// 3. Understand how creating events can improve/optimize the code
// 4. Understand how to improve the approval/permit requirement of the ERC20 token
