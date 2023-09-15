// SPDX-License-Identifier: MIT
pragma solidity <= 0.8.1;
import "./NftContract.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Marketplace is Ownable {
    NftContract nftContract;
    mapping(uint256 => address) private tokenOwner;
    mapping(address => bool) private isApproved;

    modifier onlyAvailable(uint256 _tokenId) {
        require(available(_tokenId), "Token already owned");
        _;
    }

    modifier onlyValidToken(uint256 _tokenId) {
        require(_tokenId < nftContract.totalSupply(), "Invalid token Id");
        _;
    }

    modifier onlyApproved() {
        require(isApproved[msg.sender], "You are not approved for withdrawing funds");
        _;
    }

    constructor(address nftContractAddress) {
        nftContract = NftContract(nftContractAddress);
    }

    function purchase(uint256 _tokenId) external payable onlyValidToken(_tokenId) onlyAvailable(_tokenId) {
        require(msg.value == 0.00001 ether, "Enter correct value");
        nftContract.safeTransferFrom(nftContract.owner(), msg.sender, _tokenId);
        tokenOwner[_tokenId] = msg.sender;
    }

    function available(uint256 _tokenId) public view onlyValidToken(_tokenId) returns(bool) {
        if(tokenOwner[_tokenId] == address(0)) return true;
        return false;
    }

    function airDrop() public onlyOwner {
        for(uint256 i=0;i<nftContract.totalSupply();i++) {
            if(tokenOwner[i] == address(0)) continue;
            nftContract.safeTransferFrom(owner(), tokenOwner[i], i);
        }
    }

    function getPrice(uint256 _tokenId) public view onlyValidToken(_tokenId) returns (uint256) {
        return 0.1 ether;
    }

    function approve(address addr) public onlyOwner {
        isApproved[addr] = true;
    }

    function withdraw() external onlyApproved {
        uint256 amount = address(this).balance;
        (bool sent, ) = payable(msg.sender).call{value: amount}("Funds from marketplace");
        require(sent, "Withdraw failed");
    }
}
