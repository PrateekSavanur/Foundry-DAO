// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract TimeLock is TimelockController {
    // minDelay is how long you have to wait till executing
    // proposers is the list of addresses that can propose
    // Executors is the list of addresses that can execute

    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) TimelockController(minDelay, proposers, executors, msg.sender) {}
}
