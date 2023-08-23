// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


contract MyToken is ERC20, Ownable, ERC20Permit, IERC721Receiver {

    IERC721 public collection;
    uint256 public oneTokenValue = 0.01 ether;
    uint256 public remainingPercentage = 100;
    mapping(address=> uint256) public stakeHoldersAndTheirPercentages; // address -> selling percentage 
    mapping (address=>uint256) public stockHoldersOfProperty ;// address -> tokenId; 
    mapping (uint256=>bool) public listed;
    mapping(uint256=>uint256) public TotalAmountOfTokensForNft; // tokenId -> total supply
    bool public canRedeem = false;
    mapping(address => uint256) public shareholderShareSellingPrice; // address of shareholder->price
    uint256 public sharers;
    mapping(uint256=>mapping(uint256=>address)) PropertySharers; // sharers -> tokenId -> address

    constructor(address _collection) ERC20("MyToken", "MTK") ERC20Permit("MyToken") {
        collection = IERC721(_collection);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function listProperty(uint256 _tokenId, uint256 _valueToken) external payable {
        require(collection.ownerOf(_tokenId)== msg.sender,"You are not the owner of this Property");
        require(msg.value >= oneTokenValue*_valueToken,"Value on the token is not correct");
        require(!listed[_tokenId],"Already Listed");
        _mint(msg.sender, _valueToken);
        TotalAmountOfTokensForNft[_tokenId] = _valueToken;
        approve(address(this), _valueToken);
        listed[_tokenId] = true;
        oneTokenValue = 0.02 ether;
    }

    function buyShare(uint256 _tokenId, uint256 _share) external payable {
        require(remainingPercentage >= _share,"You cannot by this much share as the remaining share is less");
        uint256 NumberOfTokensToBuy = (TotalAmountOfTokensForNft[_tokenId] * _share )/100;
        uint256 totalPrice = NumberOfTokensToBuy * oneTokenValue;
        require(msg.value >= totalPrice);
        ERC20(address(this)).transferFrom(collection.ownerOf(_tokenId), msg.sender, NumberOfTokensToBuy);
        (bool sent,) = collection.ownerOf(_tokenId).call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        remainingPercentage -= _share;
        stakeHoldersAndTheirPercentages[msg.sender] = _share;
        stockHoldersOfProperty[msg.sender] = _tokenId;
        sharers+=1;
        PropertySharers[sharers][_tokenId] = msg.sender;
        approve(address(this) , NumberOfTokensToBuy);


    }

    function sellShare(uint256 _tokenId,uint256 _share, uint256 _price) external payable  {
        require(stakeHoldersAndTheirPercentages[msg.sender]==_share,"You don't have this much share");
        require(stockHoldersOfProperty[msg.sender]==_tokenId,"you didn't buy share in this Property");
        shareholderShareSellingPrice[msg.sender] = _price;

    }

    function buyShareFromShareholder(uint256 _tokenId,uint256 _sharers) external payable {
        require(msg.value>=shareholderShareSellingPrice[PropertySharers[_sharers][_tokenId]],"Insufficient balance");
        uint256 TokensToSend = (TotalAmountOfTokensForNft[_tokenId] * stakeHoldersAndTheirPercentages[PropertySharers[_sharers][_tokenId]] )/100;
        ERC20(address(this)).transferFrom(PropertySharers[_sharers][_tokenId],msg.sender,TokensToSend);
        (bool sent,) = payable(PropertySharers[_sharers][_tokenId]).call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        stockHoldersOfProperty[msg.sender]==_tokenId;
        stockHoldersOfProperty[PropertySharers[_sharers][_tokenId]]=0;
        stakeHoldersAndTheirPercentages[msg.sender] = stakeHoldersAndTheirPercentages[PropertySharers[_sharers][_tokenId]];
        stakeHoldersAndTheirPercentages[PropertySharers[_sharers][_tokenId]]= 0;
        PropertySharers[_sharers][_tokenId] = msg.sender;

    }
}