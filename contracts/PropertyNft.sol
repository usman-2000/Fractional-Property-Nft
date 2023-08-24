// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract PropertyNft is ERC721, Ownable,ERC721Enumerable {
    mapping(uint256=>bool) public  listNft;

    constructor() ERC721("PropertyNft", "P-NFT") {}

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
        listNft[tokenId] = true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (listNft[tokenId]) {
            require(false, "Transfer not allowed");
        }
        
    }
    function changeListing(bool _val, uint256 _tokenId) public   {
        listNft[_tokenId] = _val;
    }

    function supportsInterface(bytes4 interfaceId)public view override(ERC721, ERC721Enumerable)returns (bool){
        return super.supportsInterface(interfaceId);
    }
    
}