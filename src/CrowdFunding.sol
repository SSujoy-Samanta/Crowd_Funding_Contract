// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CrowdFunding {
    enum VotingStatus {
        Pending,
        OnGoing,
        Completed
    }

    address public immutable creator;
    uint256 public immutable fundingGoal;
    uint256 public fundsRaised;
    VotingStatus public votingStatus = VotingStatus.Pending;
    bool public fundingApproved;

    struct Backer {
        uint256 balance;
        bool hasVoted;
    }

    mapping(address => Backer) public backers;
    uint256 public yesVotes;
    uint256 public noVotes;

    event Funded(address indexed backer, uint256 amount);
    event Refunded(address indexed backer, uint256 amount);
    event Withdrawn(address indexed creator, uint256 amount);
    event Voted(address indexed voter, bool vote);
    event VotingStarted();
    event VotingEnded(bool success);

    modifier onlyOwner() {
        require(msg.sender == creator, "You are not the contract owner");
        _;
    }

    constructor(address _creator, uint256 _goalAmount) {
        require(_creator != address(0), "Invalid creator address");
        require(_goalAmount > 0, "Funding goal must be greater than zero");

        creator = _creator;
        fundingGoal = _goalAmount;
    }

    // Function to contribute ETH
    function creditFund() external payable {
        require(msg.value > 0, "Must send ETH");
        require(votingStatus == VotingStatus.Pending, "Voting already completed or it is ongoing");

        backers[msg.sender].balance += msg.value;
        fundsRaised += msg.value;

        // Start voting automatically when goal is reached
        if (fundsRaised >= fundingGoal && votingStatus == VotingStatus.Pending) {
            votingStatus = VotingStatus.OnGoing;
            emit VotingStarted();
        }

        emit Funded(msg.sender, msg.value);
    }

    // Backers can vote YES or NO on fund withdrawal
    function vote(bool _vote) external {
        require(votingStatus == VotingStatus.OnGoing, "Voting is not active");
        require(backers[msg.sender].balance > 0, "Only backers can vote");
        require(!backers[msg.sender].hasVoted, "Already voted");

        uint256 weight = backers[msg.sender].balance;
        backers[msg.sender].hasVoted = true;

        _vote ? yesVotes += weight : noVotes += weight;

        // Check if voting is complete
        if (yesVotes > fundsRaised / 2) {
            votingStatus = VotingStatus.Completed;
            fundingApproved = true;
            emit VotingEnded(true);
        } else if (noVotes >= fundsRaised / 2) {
            votingStatus = VotingStatus.Completed;
            fundingApproved = false;
            emit VotingEnded(false);
        }

        emit Voted(msg.sender, _vote);
    }

    // Creator can withdraw funds if funding goal is reached and majority voted YES
    function withdrawFunds() external onlyOwner {
        require(fundsRaised >= fundingGoal, "Funding goal not reached yet");
        require(votingStatus == VotingStatus.Completed, "Voting is not completed yet");
        require(fundingApproved, "Funding not approved");

        uint256 amount = address(this).balance;
        require(amount > 0, "No funds to withdraw");

        // Prevent reentrancy attack
        fundsRaised = 0;

        (bool success, ) = payable(creator).call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawn(creator, amount);
    }

    // Function to refund ETH to backer if funding is unsuccessful
    function claimRefund() external {
        require(votingStatus == VotingStatus.Completed, "Voting must be completed first");
        require(!fundingApproved, "Funding was successful, no refunds");
        require(backers[msg.sender].balance > 0, "No funds to refund");

        uint256 amount = backers[msg.sender].balance;

        // Prevent reentrancy attack: Reset before sending funds
        backers[msg.sender].balance = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");

        emit Refunded(msg.sender, amount);
    }
}
