 //SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC721{
    function transferFrom(address from, address to, uint256 tokenID) external;
}


contract Market{
  
    struct Listing{
        address owner;       // who owns the listed artifact
        uint256 buyoutPrice; // price of the artifact in wei
    }

    address public admin;  // The admin can reset the token contract after each new round
    address public pendingAdmin; // the pending admin in case admin transfers ownership
    uint256 public endDate;
    mapping(uint256 => Listing) public listings; // all listings 
    
    IERC721 private DFTokens; 
        
    constructor(address tokensAddress, uint256 _minutes){
        admin = msg.sender; // admin can upgrade to new rounds
        DFTokens = IERC721(tokensAddress);  
        endDate = block.timestamp + (_minutes * 60);
    }

    modifier onlyAdmin(){
        require(msg.sender == admin, "Only the admin can access this funciton");
        _;
    }


    // sendValue from openZeppelin Address library https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function list(uint256 tokenID, uint256 price) external  {
        
        listings[tokenID] = Listing({
            owner: msg.sender,
            buyoutPrice: price
        });

        DFTokens.transferFrom(msg.sender, address(this), tokenID);        
    }

    // buying function. User input is the price they pay
    function buy(uint256 tokenID) external payable  {
        //Retains the original values in memory
        Listing memory oldListing = listings[tokenID];
        
        //As the token is bought, the listing is closed
        listings[tokenID]= Listing({
            owner: address(0),
            buyoutPrice: 0
        });
        require (msg.value == oldListing.buyoutPrice, "wrong value");
        DFTokens.transferFrom(address(this), msg.sender, tokenID);
        sendValue(payable(oldListing.owner), oldListing.buyoutPrice);
    }
    
    
    // Unlist a token you listed
    // Useful if you want your tokens back
    function unlist (uint256 id) external {
        address holder = listings[id].owner;
        require(msg.sender == holder, "Only the owner can unlist");
        
        listings[id]= Listing({
            owner: address(0),
            buyoutPrice: 0
        });
        
        DFTokens.transferFrom(address(this), holder, id);
    }


    // ADMIN 
    // Change the tokens address between rounds
    function newRound(uint256 _minutes, address tokens) external onlyAdmin(){
        require(block.timestamp>endDate,"too early");
        endDate = block.timestamp + (_minutes * 60);
        DFTokens = IERC721(tokens);
    }

    function giveOwnership(address newOwner) external onlyAdmin() {
        pendingAdmin = newOwner;
    }

    function acceptOwnership() external{
        require(msg.sender == pendingAdmin, "you are not the pending admin");
        admin = pendingAdmin;
    }

}
