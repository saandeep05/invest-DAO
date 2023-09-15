// SPDX-License-Identifier: MIT
pragma solidity <= 0.8.1;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NftContract is ERC721Enumerable, Ownable {
    struct OwnNftToken {
        uint256 tokenId;
        uint256 cost;
        string metadata;
    }

    mapping(uint256 => OwnNftToken) private tokens;

    constructor() ERC721("Yet Another Token", "YAT") {}

    function mint(string memory metadata) external onlyOwner {
        tokens[totalSupply()] = OwnNftToken({tokenId:totalSupply(), cost: 0.1 ether, metadata: metadata});
        _safeMint(msg.sender, totalSupply());
    }
}