// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
        uint numberOfProposalsRegistered;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    WorkflowStatus public workflowStatus;
    uint public winningProposalId;

    mapping(address => Voter) public voters;
    Proposal[] public proposals;
    address[] public whitelist; // Liste blanche des électeurs autorisés

    event VoterRegistered(address indexed voterAddress);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted(address indexed voter, uint proposalId);

    constructor() {
        workflowStatus = WorkflowStatus.RegisteringVoters;
    }

    modifier atStatus(WorkflowStatus _status) {
        require(workflowStatus == _status, "Invalid workflow status");
        _;
    }

    //Bonus: Fonction pour ajouter un électeur à la liste blanche
    function addToWhitelist(address _voter) external onlyOwner atStatus(WorkflowStatus.RegisteringVoters) {
        require(!voters[_voter].isRegistered, "Voter already registered");
        voters[_voter].isRegistered = true;
        whitelist.push(_voter);
        emit VoterRegistered(_voter);
    }

    //Bonus: Fonction pour limiter le nombre de propositions qu'un électeur peut enregistrer
    function registerProposal(string calldata _description) external atStatus(WorkflowStatus.ProposalsRegistrationStarted) {
        require(voters[msg.sender].isRegistered, "Voter is not registered");
        require(voters[msg.sender].numberOfProposalsRegistered < 3, "You can only register up to 3 proposals.");
        uint proposalId = proposals.length;
        proposals.push(Proposal(_description, 0));
        voters[msg.sender].numberOfProposalsRegistered++;
        emit ProposalRegistered(proposalId);
    }
    
   struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    WorkflowStatus public workflowStatus;
    uint public winningProposalId;

    mapping(address => Voter) public voters;
    Proposal[] public proposals;

    event VoterRegistered(address indexed voterAddress);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted(address indexed voter, uint proposalId);

    constructor() {
        workflowStatus = WorkflowStatus.RegisteringVoters;
    }

    modifier atStatus(WorkflowStatus _status) {
        require(workflowStatus == _status, "Invalid workflow status");
        _;
    }

    function startProposalsRegistration() external onlyOwner atStatus(WorkflowStatus.RegisteringVoters) {
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    function endProposalsRegistration() external onlyOwner atStatus(WorkflowStatus.ProposalsRegistrationStarted) {
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    function startVotingSession() external onlyOwner atStatus(WorkflowStatus.ProposalsRegistrationEnded) {
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    function endVotingSession() external onlyOwner atStatus(WorkflowStatus.VotingSessionStarted) {
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    function tallyVotes() external onlyOwner atStatus(WorkflowStatus.VotingSessionEnded) {
        workflowStatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);

        uint winningVoteCount = 0;
        uint winningProposalIndex = 0;

        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposalIndex = i;
            }
        }

        winningProposalId = winningProposalIndex;
    }

    function registerVoter(address _voter) external onlyOwner atStatus(WorkflowStatus.RegisteringVoters) {
        require(!voters[_voter].isRegistered, "Voter already registered");
        voters[_voter].isRegistered = true;
        emit VoterRegistered(_voter);
    }

    function registerProposal(string calldata _description) external atStatus(WorkflowStatus.ProposalsRegistrationStarted) {
        require(!voters[msg.sender].hasVoted, "Voter has already voted");
        uint proposalId = proposals.length;
        proposals.push(Proposal(_description, 0));
        emit ProposalRegistered(proposalId);
    }

    function vote(uint _proposalId) external atStatus(WorkflowStatus.VotingSessionStarted) {
        require(voters[msg.sender].isRegistered, "Voter is not registered");
        require(!voters[msg.sender].hasVoted, "Voter has already voted");
        require(_proposalId < proposals.length, "Invalid proposal ID");

        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalId;
        proposals[_proposalId].voteCount++;
        emit Voted(msg.sender, _proposalId);
    }

    function getWinner() external view returns (uint) {
        require(workflowStatus == WorkflowStatus.VotesTallied, "Voting is not yet complete");
        return winningProposalId;
    }
}
