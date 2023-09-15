// SPDX-License-Identifier: MIT
pragma solidity <= 0.8.1;
import "@openzeppelin/contracts/access/Ownable.sol";

contract ExternalMarketplace {
    mapping(uint256 => address) tokenOwner;
    uint256 nftPrice = 0.00001 ether;

    modifier onlyAvailable(uint256 _tokenId) {
        require(tokenOwner[_tokenId] == address(0), "Token not available");
        _;
    }

    function getPrice() external view returns (uint256) {
        return nftPrice;
    }

    function available(uint256 _tokenId) external  view returns (bool) {
        if(tokenOwner[_tokenId] == address(0)) return true;
        return false;
    }

    function purchase(uint256 _tokenId) external payable onlyAvailable(_tokenId) {
        require(msg.value == nftPrice, "Enter correct value");
        tokenOwner[_tokenId] = msg.sender;
    }
}