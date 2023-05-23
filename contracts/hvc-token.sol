// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

// Simple ERC20 contract for testing purposes

contract HVC is ERC20, AccessControl, ERC20Permit {
    constructor() ERC20("HVCToken", "HVC") ERC20Permit("HVCToken") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function getTokenAddress() public view returns (address) {
        return address(this);
    }
}
