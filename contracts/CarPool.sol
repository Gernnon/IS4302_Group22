pragma solidity ^0.8.0;

contract CarPool {
    
    enum carState { inreview, available, inuse, damaged}
    struct location{fixed locationX; fixed locationY;}

    struct car {
        string brand;
        string model;
        uint8 capacity;
        string licenceNum;
        location loc;
        carState state;
        address owner;
        address prevOwner;
        address renter;
        string issue; // damage issues of the car
    }

    mapping(uint256 => car) public cars;
    mapping(address => uint256[]) owners;

    // interface for a third-party authority account to provide car validation
    function validateCarInfo() public authorityOnly {}
    // register/unregister a car
    function register(string brand, string model, uint8 capacity, string licenceNum) public payable returns(uint256){}
    function unregisterCar(uint256 carId) public ownerOnly(carId) validCarId(carId){}
    // transfer a car to CarRental
    function transfer(uint256 carId, address carRental) public ownerOnly(carId) validCarId(carId) {}
    // set a car to damaged and describe the issue
    function setToDamaged(uint256 carId, string issue) public ownerOnly validCarId(carId){}
    // owner(CarRental account) can set a car to inuse when a renter use a car
    function setToInuse(uint256 carId) public ownerOnly(carId) validCarId(carId){}
    // owner(CarRental account) can set a car to available when the renter finishs using the car
    function setToAvailable(uint256 carId) public ownerOnly(carId) validCarId(carId) {}
    // get car location
    function getLocation() public view returns(fixed, fixed){}
}
