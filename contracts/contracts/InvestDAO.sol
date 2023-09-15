// SPDX-License-Identifier: MIT
pragma solidity <= 0.8.1;
import "@openzeppelin/contracts/access/Ownable.sol";

interface IExternalMarketplace {
    function purchase(uint256 _tokenId) external payable;
    function available(uint256 _tokenId) external view returns (bool);
    function getPrice() external  view returns (uint256); 
}

interface IOwnNftContract {
    function mint() external;
    function balanceOf(address _owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface IOwnMarketplace {
    function withdraw() external;
}

contract InvestDAO is Ownable {
    struct Proposal {
        uint256 tokenId;
        uint256 cost;
        uint256 deadline;
        uint256 yayVotes;
        uint256 nayVotes;
        bool executed;
        mapping(address => bool) voters;
    }

    mapping(uint256 => Proposal) public proposals;
    IOwnNftContract nftContract;
    IExternalMarketplace marketplace;
    IOwnMarketplace ownMarketplace;
    enum Vote {
        YAY, NAY
    }
    uint256 numProposals;

    constructor(address _nftContract, address _extMarketplace, address _ownMarketplace) {
        nftContract = IOwnNftContract(_nftContract);
        marketplace = IExternalMarketplace(_extMarketplace);
        ownMarketplace = IOwnMarketplace(_ownMarketplace);
    }

    modifier nftHolderOnly() {
        require(nftContract.balanceOf(msg.sender) > 0, "You do not hold our NFT to make a proposal");
        _;
    }

    modifier activeProposalsOnly(uint256 _proposalId) {
        require(proposals[_proposalId].deadline > block.timestamp, "This proposal is not live");
        _;
    }
    
    modifier inactiveProposalsOnly(uint256 _proposalId) {
        require(proposals[_proposalId].deadline < block.timestamp, "This proposal is still active");
        require(!proposals[_proposalId].executed, "This proposal has already been executed");
        _;
    }

    function createProposal(uint256 _tokenId) external nftHolderOnly {
        require(marketplace.available(_tokenId), "This token is not available");
        Proposal storage proposal = proposals[numProposals];
        proposal.tokenId = _tokenId;
        proposal.deadline = block.timestamp + 2 minutes;
        proposal.cost = marketplace.getPrice();
        numProposals++;
    }

    function vote(uint256 _proposalId, Vote _option) external nftHolderOnly activeProposalsOnly(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.voters[msg.sender], "You have already voted for this proposal");
        proposal.voters[msg.sender] = true;
        if(_option == Vote.YAY) proposal.yayVotes += nftContract.balanceOf(msg.sender);
        else proposal.nayVotes += nftContract.balanceOf(msg.sender);
    }

    function executeProposal(uint256 _proposalId) public nftHolderOnly inactiveProposalsOnly(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(marketplace.available(proposal.tokenId), "token not available to purchase");
        ownMarketplace.withdraw();
        require(address(this).balance > proposal.cost, "Not enough funds");
        if(proposal.yayVotes > proposal.nayVotes) {
            marketplace.purchase{value: proposal.cost}(proposal.tokenId);
        }
        proposal.executed = true;
    }

    function withdraw() external nftHolderOnly {
        (bool sent, ) = payable(msg.sender).call{value: (nftContract.balanceOf(msg.sender)/nftContract.totalSupply())*(address(this).balance)}("From returns");
        require(sent, "withdraw failed");
    }

    receive() external payable {}
    fallback() external payable {}
}