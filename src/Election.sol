// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Election System
/// @notice This contract implements a basic election system
/// @dev All function calls are currently implemented without side effects
contract Election {
    struct Candidate {
        uint256 id;
        string name;
        string proposal;
        uint256 voteCount;
    }

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 vote;
        address delegate;
    }

    address public owner;
    bool public electionStarted;
    bool public electionEnded;

    uint256 public candidatesCount;
    uint256 public votersCount;
    mapping(uint256 => Candidate) public candidates;
    mapping(address => Voter) public voters;

    /// @notice Event emitted when a new candidate is added
    /// @param candidateId The ID of the new candidate
    event CandidateAdded(uint256 candidateId);

    /// @notice Event emitted when a new voter is added
    /// @param voter The address of the new voter
    event VoterAdded(address voter);

    /// @notice Event emitted when the election starts
    event ElectionStarted();

    /// @notice Event emitted when the election ends
    event ElectionEnded();

    /// @notice Event emitted when a vote is cast
    /// @param voter The address of the voter
    /// @param candidateId The ID of the candidate voted for
    event VoteCast(address voter, uint256 candidateId);

    constructor() {
        owner = msg.sender;
        electionStarted = false;
        electionEnded = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier whenElectionNotStarted() {
        require(!electionStarted, "Election has already started");
        _;
    }

    modifier whenElectionStarted() {
        require(electionStarted, "Election has not started yet");
        require(!electionEnded, "Election has already ended");
        _;
    }

    modifier whenElectionEnded() {
        require(electionEnded, "Election has not ended yet");
        _;
    }

    /// @notice Adds a new candidate to the election
    /// @param _name The name of the candidate
    /// @param _proposal The proposal of the candidate
    function addCandidate(string memory _name, string memory _proposal) public onlyOwner whenElectionNotStarted {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, _proposal, 0);
        emit CandidateAdded(candidatesCount);
    }

    /// @notice Registers a new voter
    /// @param _voter The address of the voter
    function addVoter(address _voter) public onlyOwner whenElectionNotStarted {
        require(!voters[_voter].isRegistered, "Voter is already registered");
        voters[_voter] = Voter(true, false, 0, address(0));
        votersCount++;
        emit VoterAdded(_voter);
    }

    /// @notice Starts the election
    function startElection() public onlyOwner whenElectionNotStarted {
        electionStarted = true;
        emit ElectionStarted();
    }

    /// @notice Ends the election
    function endElection() public onlyOwner whenElectionStarted {
        electionEnded = true;
        emit ElectionEnded();
    }

    /// @notice Casts a vote for a candidate
    /// @param _candidateId The ID of the candidate to vote for
    function vote(uint256 _candidateId) public whenElectionStarted {
        require(voters[msg.sender].isRegistered, "You are not registered to vote");
        require(!voters[msg.sender].hasVoted, "You have already voted");
        require(_candidateId > 0 && _candidateId <= candidatesCount, "Invalid candidate ID");

        voters[msg.sender].hasVoted = true;
        voters[msg.sender].vote = _candidateId;
        candidates[_candidateId].voteCount++;

        emit VoteCast(msg.sender, _candidateId);
    }

    /// @notice Delegates voting right to another voter
    /// @param _to The address of the voter to delegate to
    function delegate(address _to) public whenElectionStarted {
        require(voters[msg.sender].isRegistered, "You are not registered to vote");
        require(!voters[msg.sender].hasVoted, "You have already voted");
        require(voters[_to].isRegistered, "Delegate is not registered to vote");
        require(msg.sender != _to, "Cannot delegate to yourself");

        voters[msg.sender].hasVoted = true;
        voters[msg.sender].delegate = _to;

        if (voters[_to].hasVoted) {
            candidates[voters[_to].vote].voteCount++;
        } else {
            voters[_to].vote = voters[msg.sender].vote;
        }
    }

    /// @notice Displays candidate details
    /// @param _candidateId The ID of the candidate
    /// @return id The ID of the candidate
    /// @return name The name of the candidate
    /// @return proposal The proposal of the candidate
    /// @return voteCount The number of votes the candidate has received
    function getCandidate(uint256 _candidateId)
        public
        view
        returns (uint256 id, string memory name, string memory proposal, uint256 voteCount)
    {
        require(_candidateId > 0 && _candidateId <= candidatesCount, "Invalid candidate ID");
        Candidate memory candidate = candidates[_candidateId];
        return (candidate.id, candidate.name, candidate.proposal, candidate.voteCount);
    }

    /// @notice Shows the winner of the election
    /// @return name The name of the winning candidate
    /// @return id The ID of the winning candidate
    /// @return voteCount The number of votes the winning candidate received
    function getWinner() public view whenElectionEnded returns (string memory name, uint256 id, uint256 voteCount) {
        uint256 winningVoteCount = 0;
        uint256 winningCandidateId = 0;

        for (uint256 i = 1; i <= candidatesCount; i++) {
            if (candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                winningCandidateId = i;
            }
        }

        Candidate memory winner = candidates[winningCandidateId];
        return (winner.name, winner.id, winner.voteCount);
    }

    /// @notice Shows the results of a specific candidate
    /// @param _candidateId The ID of the candidate
    /// @return id The ID of the candidate
    /// @return name The name of the candidate
    /// @return voteCount The number of votes the candidate received
    function getResults(uint256 _candidateId) public view returns (uint256 id, string memory name, uint256 voteCount) {
        require(_candidateId > 0 && _candidateId <= candidatesCount, "Invalid candidate ID");
        Candidate memory candidate = candidates[_candidateId];
        return (candidate.id, candidate.name, candidate.voteCount);
    }

    /// @notice Shows the details of a voter
    /// @param _voter The address of the voter
    /// @return isRegistered Whether the voter is registered
    /// @return hasVoted Whether the voter has voted
    /// @return vote The candidate ID the voter voted for
    /// @return delegate The address to whom the vote was delegated
    function getVoterDetails(address _voter)
        public
        view
        returns (bool isRegistered, bool hasVoted, uint256 vote, address delegate)
    {
        Voter memory voter = voters[_voter];
        return (voter.isRegistered, voter.hasVoted, voter.vote, voter.delegate);
    }
}
