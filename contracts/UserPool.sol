pragma solidity ^0.8.0;

contract UserPool{
    struct location{fixed locationX; fixed locationY;}
    struct user{
        address userAddress;
        string name;
        string ID;
        string licenceNum;
        bool validated; // license is validated
        location loc; // user location
        uint256 balance;
    }
    mapping(uint256 => user) public users;
    function userRegister(string name, string ID, string licenceNum) public returns (uint256) {}
    // interface for a third-party authority account to provide user validation
    function validateUserInfo() public AuthorityOnly {} 
    // topup and withdraw
    function topup(uint256 erc20Amt) public payable returns(uint256) {} 
    function withdraw() public {}
    // get user location
    function getLocation() public view returns(fixed, fixed){}

    function getUserAddress(uint256 userId) public view returns(address) {
        return users[userId].userAddress;
    }
}