// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IFakeNFTMarketplace {
    function purchase(uint256 _tokenId) external payable;

    function getPrice() external view returns (uint256);

    function available(uint256 _tokenId) external view returns (bool);
}

interface ICryptoDevsNFT {
    function balanceOf(address owner) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
}

contract CryptoDevsDAO is Ownable {
    enum Vote {
        YAY,
        NAY
    }

    struct Proposal {
        // The NFT to BUY from the secondary marketplace
        uint256 nftTokenId;
        // when does voting end
        uint256 deadline;
        uint256 yayVotes;
        uint256 nayVotes;
        bool executed;
        mapping(uint256 => bool) voters;
    }

    // Proposal ID => proposal
    mapping(uint256 => Proposal) public proposals;
    uint256 public numProposals;

    IFakeNFTMarketplace nftMarketplace;
    ICryptoDevsNFT cryptoDevsNFT;

    constructor(address _nftMarketplace, address _cryptodevsNft) payable {
        nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
        cryptoDevsNFT = ICryptoDevsNFT(_cryptodevsNft);
    }

    modifier nftHolderOnly() {
        require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "NOT_DAO_MEMBER");
        _;
    }

    modifier activeProposalOnly(uint256 proposalId) {
        require(
            proposals[proposalId].deadline > block.timestamp,
            "PROPOSAL_INACTIVE"
        );
        _;
    }

    modifier inactiveProposalOnly(uint256 proposalId) {
        require(
            proposals[proposalId].deadline <= block.timestamp,
            "PROPOSAL_STILL_ACTIVE"
        );
        require(proposals[proposalId].executed == false, "ALREADY_EXECUTED");
        _;
    }

    // create a proposal - memberOnly
    // _nftTokenId refers to the NFT you want to buy from the 'FakeNFTMarketplace'
    // returns ID of newly created proposal
    function createProposal(uint256 _nftTokenId)
        external
        nftHolderOnly
        returns (uint256)
    {
        require(nftMarketplace.available(_nftTokenId), "NFT_NOT_FOR_SALE");
        Proposal storage proposal = proposals[numProposals];
        proposal.nftTokenId = _nftTokenId;
        proposal.deadline = block.timestamp + 5 minutes;

        numProposals++;
        return numProposals - 1;
    }

    // vote on a proposal - memberOnly
    function voteOnProposal(uint256 proposalId, Vote vote)
        external
        nftHolderOnly
        activeProposalOnly(proposalId)
    {
        Proposal storage proposal = proposals[proposalId];
        uint256 voterNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
        uint256 numVotes;

        for (uint256 i = 0; i < voterNFTBalance; i++) {
            uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
            if (proposal.voters[tokenId] == false) {
                numVotes++;
                proposal.voters[tokenId] = true;
            }
        }

        require(numVotes > 0, "ALREADY_VOTED");

        if (vote == Vote.YAY) {
            proposal.yayVotes += numVotes;
        } else {
            proposal.nayVotes += numVotes;
        }
    }

    // execute the proposal - memberOnly
    function executeProposal(uint256 proposalId)
        external
        nftHolderOnly
        inactiveProposalOnly(proposalId)
    {
        Proposal storage proposal = proposals[proposalId];

        // Did the proposal pass?
        if (proposal.yayVotes > proposal.nayVotes) {
            uint256 nftPrice = nftMarketplace.getPrice();
            require(address(this).balance >= nftPrice, "NOT_ENOUGH_ETH");
            nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
        }
        proposal.executed = true;
    }

    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}

    fallback() external payable {}
}
