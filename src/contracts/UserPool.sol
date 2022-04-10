pragma solidity ^0.5.0;
import "./CarToken.sol";

contract UserPool {

    CarToken ctContract;

    constructor (CarToken ctAddress) public {
        ctContract = ctAddress;
    }

    struct User{
        address userAddress;
        string name;
        string licenseNum;
        string licenseType;
        string coords;
        uint256 balance;
    }

    uint public totalUsersCounter = 0;
    mapping(uint256 => User) public allUsers;

    event UserRegistered(uint256 totalUsersCounter, string _name, string _licenseNum, string _licenseType);

    modifier licenseNumValid(string memory _licenceNum) {
        _licenceNum = _licenceNum;
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

    function registerUser(string memory _name, string memory _licenseNum, string memory _licenseType, string memory _coords) public licenseNumValid(_licenseNum) returns (uint256) {
        totalUsersCounter = totalUsersCounter + 1;
        
        User memory myUser = User({
            userAddress: msg.sender,
            name: _name,
            licenseNum: _licenseNum,
            licenseType: _licenseType,
            coords: _coords,
            balance: 0
        });

        allUsers[totalUsersCounter] = myUser;
        emit UserRegistered(totalUsersCounter, _name, _licenseNum, _licenseType);
        return totalUsersCounter;
    }

    function userLocUpdate(string memory _coords, uint256 _userId) public {
        allUsers[_userId].coords = _coords;
    }

    function getLicenseNum(address _renter) public view returns(string memory) {
        uint index;
        for(uint i=1; i<=totalUsersCounter; i++) {
            if(allUsers[i].userAddress == _renter) {
                index = i;
                break;
            }
        }
        return allUsers[index].licenseNum;
    }

    function getLicenseType(address _renter) public view returns(string memory) {
        uint index;
        for(uint i=1; i<=totalUsersCounter; i++) {
            if(allUsers[i].userAddress == _renter) {
                index = i;
                break;
            }
        }
        return allUsers[index].licenseType;
    }

    function getLocation(address _renter) public view returns(string memory) {
        uint index;
        for(uint i=1; i<=totalUsersCounter; i++) {
            if(allUsers[i].userAddress == _renter) {
                index = i;
                break;
            }
        }
        return (allUsers[index].coords);
    }

    function updateBalance(address _renter) public {
        uint256 newbal = ctContract.checkBal(_renter);
        uint index;
        for(uint i=1; i<=totalUsersCounter; i++) {
            if(allUsers[i].userAddress == _renter) {
                index = i;
                break;
            }
        }
        allUsers[index].balance = newbal;
    }

    function getBalance(address _renter) public view returns(uint256) {
        return ctContract.checkBal(_renter);
    }

    function checkRegistered(address _renter) public view returns(bool) {
        bool registered = false;
        for(uint i=1; i<=totalUsersCounter; i++) {
            if(allUsers[i].userAddress == _renter) {
                registered = true;
                break;
            }
        }
        return registered;
    }
 
}