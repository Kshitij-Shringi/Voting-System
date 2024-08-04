// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Election.sol";

contract ElectionTest is Test {
    Election election;
    address admin = address(1);
    address voter1 = address(2);
    address voter2 = address(3);
    address voter3 = address(4);

    function setUp() public {
        vm.startPrank(admin);
        election = new Election();
        vm.stopPrank();
    }

    function testAddCandidate() public {
        vm.startPrank(admin);
        election.addCandidate("Alice", "Proposal A");
        (uint256 id, string memory name, string memory proposal, uint256 voteCount) = election.getCandidate(1);
        assertEq(id, 1, "Candidate ID should be 1");
        assertEq(name, "Alice", "Candidate name should be Alice");
        assertEq(proposal, "Proposal A", "Candidate proposal should be Proposal A");
        assertEq(voteCount, 0, "Candidate vote count should be 0");
        vm.stopPrank();
    }

    function testAddVoter() public {
        vm.startPrank(admin);
        election.addVoter(voter1);
        (bool isRegistered, bool hasVoted, uint256 vote, address delegate) = election.getVoterDetails(voter1);
        assertTrue(isRegistered, "Voter should be registered");
        assertFalse(hasVoted, "Voter should not have voted yet");
        assertEq(vote, 0, "Voter's vote should be 0");
        assertEq(delegate, address(0), "Voter's delegate should be address(0)");
        vm.stopPrank();
    }

    function testStartElection() public {
        vm.startPrank(admin);
        election.startElection();
        assertTrue(election.electionStarted(), "Election should be started");
        vm.stopPrank();
    }

    function testEndElection() public {
        vm.startPrank(admin);
        election.startElection();
        election.endElection();
        assertTrue(election.electionEnded(), "Election should be ended");
        vm.stopPrank();
    }

    function testVote() public {
        vm.startPrank(admin);
        election.addVoter(voter1);
        election.addCandidate("Alice", "Proposal A");
        election.startElection();
        vm.stopPrank();

        vm.startPrank(voter1);
        election.vote(1);
        (uint256 id, string memory name, string memory proposal, uint256 voteCount) = election.getCandidate(1);
        assertEq(voteCount, 1, "Candidate should have 1 vote");
        vm.stopPrank();
    }

    function testDelegateVote() public {
        vm.startPrank(admin);
        election.addVoter(voter1);
        election.addVoter(voter2);
        election.addCandidate("Alice", "Proposal A");
        election.startElection();
        vm.stopPrank();

        vm.startPrank(voter1);
        election.delegate(voter2);
        (bool isRegistered, bool hasVoted, uint256 vote, address delegate) = election.getVoterDetails(voter1);
        assertTrue(hasVoted, "Voter should have voted");
        assertEq(delegate, voter2, "Voter's delegate should be voter2");
        vm.stopPrank();

        vm.startPrank(voter2);
        election.vote(1);
        (uint256 id, string memory name, string memory proposal, uint256 voteCount) = election.getCandidate(1);
        assertEq(voteCount, 1, "Candidate should have 1 vote");
        vm.stopPrank();
    }

    function testGetWinner() public {
        // Setup the election environment
        vm.startPrank(admin);
        election.addVoter(voter1);
        election.addVoter(voter2);
        election.addVoter(voter3);
        election.addCandidate("Alice", "Proposal A");
        election.addCandidate("Bob", "Proposal B");
        election.startElection();
        vm.stopPrank();

        // Cast votes
        vm.startPrank(voter1);
        election.vote(1);
        vm.stopPrank();

        vm.startPrank(voter2);
        election.vote(2);
        vm.stopPrank();

        vm.startPrank(voter3);
        election.vote(2);
        vm.stopPrank();

        // End the election
        vm.startPrank(admin);
        election.endElection();
        vm.stopPrank();

        // Check the winner
        (string memory name, uint256 id, uint256 voteCount) = election.getWinner();
        assertEq(name, "Bob", "Winner's name should be Bob");
        assertEq(id, 2, "Winner's ID should be 2");
        assertEq(voteCount, 2, "Winner should have 2 votes");
    }

    function testCannotAddCandidateAfterElectionStarted() public {
        vm.startPrank(admin);
        election.startElection();
        vm.expectRevert("Election has already started");
        election.addCandidate("Charlie", "Proposal C");
        vm.stopPrank();
    }

    function testCannotAddVoterAfterElectionStarted() public {
        vm.startPrank(admin);
        election.startElection();
        vm.expectRevert("Election has already started");
        election.addVoter(voter3);
        vm.stopPrank();
    }

    function testCannotVoteBeforeElectionStarted() public {
        vm.startPrank(admin);
        election.addVoter(voter1);
        election.addCandidate("Alice", "Proposal A");
        vm.stopPrank();

        vm.startPrank(voter1);
        vm.expectRevert("Election has not started yet");
        election.vote(1);
        vm.stopPrank();
    }

    function testCannotVoteAfterElectionEnded() public {
        vm.startPrank(admin);
        election.addVoter(voter1);
        election.addCandidate("Alice", "Proposal A");
        election.startElection();
        election.endElection();
        vm.stopPrank();

        vm.startPrank(voter1);
        vm.expectRevert("Election has already ended");
        election.vote(1);
        vm.stopPrank();
    }

    function testCannotDelegateVoteAfterElectionEnded() public {
        vm.startPrank(admin);
        election.addVoter(voter1);
        election.addVoter(voter2);
        election.addCandidate("Alice", "Proposal A");
        election.startElection();
        election.endElection();
        vm.stopPrank();

        vm.startPrank(voter1);
        vm.expectRevert("Election has already ended");
        election.delegate(voter2);
        vm.stopPrank();
    }
}
