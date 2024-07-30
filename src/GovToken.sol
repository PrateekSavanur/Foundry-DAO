// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract GovToken is ERC20Permit, ERC20Votes {
    uint256 public s_maxSupply = 1000000000000000000000000; // 1 Million tokens

    constructor()
        ERC20("Governance Token", "GT")
        ERC20Permit("Governance Token")
    {
        _mint(msg.sender, s_maxSupply);
    }

    // Overrides
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    function nonces(
        address owner
    ) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
