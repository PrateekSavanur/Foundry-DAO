// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {GovernorContract} from "../src/governance_standard/GovernorContract.sol";
import {GovToken} from "../src/GovToken.sol";
import {TimeLock} from "../src/governance_standard/TimeLock.sol";
import {Company} from "../src/Company.sol";

contract MyGovernorTest is Test {
    GovToken token;
    TimeLock timelock;
    GovernorContract governor;
    Company company;

    uint256 public constant MIN_DELAY = 3600;
    uint256 public constant QUORUM_PERCENTAGE = 4;
    uint32 public constant VOTING_PERIOD = 50400;
    uint48 public constant VOTING_DELAY = 1;

    address[] proposers;
    address[] executors;

    bytes[] functionCalls;
    address[] addressesToCall;
    uint256[] values;

    address public constant VOTER = address(1);

    function setUp() public {
        token = new GovToken();

        // Transfer some tokens to VOTER for testing
        token.transfer(VOTER, 50000e18); // Transfer tokens to VOTER

        vm.prank(VOTER);
        token.delegate(VOTER); // Delegate tokens for voting

        timelock = new TimeLock(MIN_DELAY, proposers, executors);
        governor = new GovernorContract(
            token,
            timelock,
            VOTING_DELAY,
            VOTING_PERIOD,
            QUORUM_PERCENTAGE
        );

        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE();

        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0));
        timelock.revokeRole(adminRole, msg.sender);

        company = new Company();
        company.transferOwnership(address(timelock));
    }

    function testCantUpdateHeadlineWithoutGovernance() public {
        vm.expectRevert();
        company.updateHeadline("Hello World");
    }

    function testGovernanceUpdatesHeadline() public {
        string memory newHeadline = "This is new Tagline";
        string memory description = "Store new tagline in Company";
        bytes memory encodedFunctionCall = abi.encodeWithSignature(
            "updateHeadline(string)",
            newHeadline
        );
        addressesToCall.push(address(company));
        values.push(0);
        functionCalls.push(encodedFunctionCall);

        // 1. Propose to the DAO
        uint256 proposalId = governor.propose(
            addressesToCall,
            values,
            functionCalls,
            description
        );

        console.log(
            "Proposal State after creation:",
            uint256(governor.state(proposalId))
        ); // Should be 0 (Pending)

        // Advance time and block to start voting period
        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);

        // 2. Vote
        string memory reason = "I like a do da cha cha";
        // 0 = Against, 1 = For, 2 = Abstain for this example
        uint8 voteWay = 1;
        vm.prank(VOTER);
        governor.castVoteWithReason(proposalId, voteWay, reason);

        // Advance time and block to end voting period
        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);

        console.log(
            "Proposal State after voting period:",
            uint256(governor.state(proposalId))
        ); // Should be 4 (Succeeded)

        // Check if the proposal succeeded

        console.log(uint256(governor.state(proposalId)));
        require(
            uint256(governor.state(proposalId)) == 4,
            "Proposal did not succeed"
        );

        // 3. Queue
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(addressesToCall, values, functionCalls, descriptionHash);
        vm.roll(block.number + MIN_DELAY + 1);
        vm.warp(block.timestamp + MIN_DELAY + 1);

        // 4. Execute
        governor.execute(
            addressesToCall,
            values,
            functionCalls,
            descriptionHash
        );

        assert(
            keccak256(abi.encodePacked((company.getHeadline()))) ==
                keccak256(abi.encodePacked((newHeadline)))
        );
    }
}
