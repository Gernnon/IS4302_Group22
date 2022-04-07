//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


contract UserPool{
    uint public totalUsersCounter = 0;

    struct Location{fixed locationX; fixed locationY;}
    struct User{
        address userAddress;
        string name;
        string licenseNum; //license number is same as NRIC/ID number
        bool validated; // license is validated
        Location loc; // user location
        uint256 balance;
    }
    mapping(string => User) public allUsers; //licenseNum is used as it is unique
    mapping(address => string) public allIdentities; //maps user address to licenseNum

    event UserRegistered(uint totalUsersCounter, string _name, string _licenceNum);
    event TopUp(address to, uint256 amount);
    event Deduct(address from, uint256 amount);

    modifier userOnly(string _licenceNum) {
        require(msg.sender == allUsers[_licenceNum].owner, "You are not this account's user!");
        _;
    }

    modifier licenseNumValid(string _licenceNum) {
        _licenceNum = _licenceNum.toUpper();
        bytes memory b = bytes(_licenceNum);

        require(b.length == 9 &&
                (b[0] == 0x53 || b[0] == 0x54 || b[0] == 0x46 || b[0] == 0x47 || b[0] == 0x4D) && //check first char of NRIC
                (b[1] >= 0x30 && b[1] <= 0x39) && //numeric
                (b[2] >= 0x30 && b[2] <= 0x39) &&
                (b[3] >= 0x30 && b[3] <= 0x39) &&
                (b[4] >= 0x30 && b[4] <= 0x39) &&
                (b[5] >= 0x30 && b[5] <= 0x39) &&
                (b[6] >= 0x30 && b[6] <= 0x39) &&
                (b[7] >= 0x30 && b[7] <= 0x39) &&
                (b[8] >= 0x41 && b[8] <= 0x5A)    //alphabetical
                , "You have entered an invalid licence number!");
        _;
    }

    function userRegister(string memory _name, string memory _licenseNum, fixed _locationX, fixed _locationY) public licenseNumValid(_licenseNum) returns (uint256) {
        totalUsersCounter = totalUsersCounter + 1;

        Location memory myLocation = Location({
            locationX: _locationX,
            locationY: _locationY
        });
        
        User memory currUser = User({
            userAddress: msg.sender,
            name: _name,
            licenseNum: _licenseNum.toUpper(),
            validated: false,
            loc: myLocation,
            balance: 0
        });

        allUsers[_licenceNum] = currUser;
        emit UserRegistered(totalUsersCounter, _name, _licenceNum);
        return totalUsersCounter;
    }

    function userLocUpdate(fixed _locationX, fixed _locationY, string memory _licenseNum) public userOnly(_licenseNum) {
        Location memory myLocation = Location({
            locationX: _locationX,
            locationY: _locationY
        });

        allUsers[_licenceNum].loc = myLocation;
    }

    // interface for a third-party authority account to provide user validation
    function validateUserInfo(string _licenceNum) public AuthorityOnly {
        allUsers[_licenceNum].validated = true;
    } 

    // topup and withdraw
    function topup(uint256 erc20Amt) public payable returns(uint256) {
        require(erc20Amt >= 1E16, "At least 0.01ETH needed to top up!");
        allUser[allIdentities[msg.sender]].balance = allUser[allIdentities[msg.sender]].balance + erc20Amt;

        emit TopUp(msg.sender, erc20Amt);
    } 

    function deduct(uint256 erc20Amt) public {
        require(erc20Amt >= 1E16, "At least 0.01ETH required for deduction!");
        require(erc20Amt <= allUser[allIdentities[msg.sender]].balance, "Balance is not enough!");
        allUser[allIdentities[msg.sender]].balance = allUser[allIdentities[msg.sender]].balance - erc20Amt;

        emit Deduct(msg.sender, erc20Amt);
    }

    function topupTo(address user, uint256 amount) public {
        allUser[allIdentities[user]].balance = allUser[allIdentities[user].balance + amount;
    }

    function deductFrom(address user, uint256 amount) public {
        allUser[allIdentities[user]].balance = allUser[allIdentities[user].balance - amount;
    }

    function getUserAddress() public view returns(address) {
        return userAddress;
    }

    function getName() public view returns(String) {
        return name;
    }

    function getLicenseNum() public view returns(String) {
        return licenseNum;
    }

    function getLocation() public view returns(Location) {
        return loc;
    }

    function getBalance() public view returns(uint256) {
        return balance;
    }
}