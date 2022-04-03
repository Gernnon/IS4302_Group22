pragma solidity ^0.8.0;
import "./CarPool.sol";
import "./UserPool.sol";

contract CarRental{
    CarPool carPoolContract;
    UserPool userPoolContract;
    uint256 public comissionFee;
    address _owner = msg.sender;

    struct listInfo {
        uint256 price;
        uint256 duration;
    }
    mapping(uint256 => listInfo) listInfos; // car => (price, duration)

    constructor(CarPool carAddress, UserPool userAddress) public {}

    // list/unlist a car by owner
    function list(uint256 carId, uint256 duration, uint256 price) public prevOwnerOnly(carId) {}
    function unlist(uint256 carId) public prevOwnerOnly(carId) {}
    // check the information for a car on list
    function checkListInfo(uint256 carId) public view returns (uint256, uint256) {}
    // rent a car and prepay deposit, and set the car's renter
    function rent(uint256 carId, uint256 deposit) public payable validUser {}
    // after renting a car, refund some of the deposit to the renter's balance
    function refund(uint256 carId) public renterOnly(carId){}
    // renter can unlock a car before use
    function unlock(uint256 carId) public renterOnly(carId) validCarId(carId) {}
    // renter can lock a car after use
    function lock(uint256 carId) public renterOnly(carId) validCarId(carId) {}
    // withdraw commission fee for administrator
    function withdraw() public administratorOnly {}
}