//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract CarPool {
    
    enum carState {ADDED, READY, REPAIR, REMOVED}
    enum rentalState {NONE, RENTED, RETURNED}
    uint public totalCarsCounter = 0;

    struct Location{fixed lat; fixed long;}
    struct Car {
        string brand;
        string model;
        string vehType;
        uint8 capacity;
        string plateNum;
        bool insured;
        Location location;
        carState status;
        address owner;
        string condition; // damage issues of the car
    }
    struct Rental {
        uint256 carId;
        address renter;
        uint256 duration;
        uint256 rate;
        uint256 total;
        rentalState state;
    }
      
    mapping(uint256 => Car) public allCars;
    mapping(uint256 => Rental) public allRentals;
    mapping(address => uint256[]) owners;

    event AddedCar(uint256 _carId, string _brand, string _model, string _vehType, uint8 _capacity, string _plateNum);

    modifier ownerOnly(uint256 _carId) {
        require(msg.sender == allCars[_carId].owner, "You are not the owner of this car!");
        _;
    }

    modifier validCarId(uint256 _carId) {
        require(_carId <= totalCarsCounter, "You entered an invalid carId!");
        _;
    }

    modifier validPlateNum(string memory _plateNum) {
        bool unique = true;
        for (uint i=1; i<=totalCarsCounter; i++) {
            if (keccak256(abi.encodePacked(allCars[i].plateNum)) == keccak256(abi.encodePacked(_plateNum))) {
                unique = false;
                break;
            }
        }
        require(unique == true, "That plate number has already been registered!");
        _;
    }

    // any verification can be settled at the frontend. e.g. SingPass verification of vehicle details.
    // interface for a third-party authority account to provide car validation
    // function validateCarInfo() public authorityOnly {}

    // register/unregister a car
    function addCar(string memory _brand, string memory _model, string memory _vehType, uint8 _capacity, string memory _plateNum, fixed _lat, fixed _long, string memory _condition) public validPlateNum(_plateNum) returns(uint256) {
        require(bytes(_brand).length > 0 && bytes(_model).length > 0 && bytes(_vehType).length > 0 && _capacity > 0 && _capacity <= 8 && bytes(_plateNum).length > 0, "Check vehicle information.");
        require(bytes(_condition).length > 0, "Check vehicle condition.");

        totalCarsCounter = totalCarsCounter + 1;

        Location memory myLoc = Location({
            lat: _lat,
            long: _long
        });
        
        Car memory myCar = Car({
            brand: _brand,
            model: _model,
            vehType: _vehType,
            capacity: _capacity,
            plateNum: _plateNum,
            insured: true,
            location: myLoc,
            status: carState.READY,
            owner: msg.sender,
            condition: _condition
        });

        Rental memory myRental = Rental({
            carId: totalCarsCounter,
            renter: msg.sender,
            duration: 0,
            rate: 0,
            total: 0,
            state: rentalState.NONE
        });
        
        allCars[totalCarsCounter] = myCar;
        allRentals[totalCarsCounter] = myRental;
        emit AddedCar(totalCarsCounter, _brand, _model, _vehType, _capacity, _plateNum);
        return totalCarsCounter;
    }

    function removeCar(uint256 _carId) public ownerOnly(_carId) validCarId(_carId) {
        allCars[_carId].state = carState.REMOVED;
        allRentals[_carId].state = rentalState.NONE;
    }
    
    // edit car properties (location, insurance and owner). these 3 are commonly associated with transfer of car ownership
    function editCar(uint256 _carId, fixed _lat, fixed _long, bool _insured, address _owner) public ownerOnly(_carId) validCarId(_carId) {
        Car memory myCar = allCars[_carId];
        Location memory myLoc = Location({
            lat: _lat,
            long: _long
        });
        myCar.location = myLoc;
        myCar.insured = _insured;
        myCar.owner = _owner;

        allCars[_carId] = myCar;
    }

    // update car status
    function updateStatus(uint256 _carId, string memory _status) public ownerOnly(_carId) validCarId(_carId) {
        Car memory myCar = allCars[_carId];
        if (_status == "ADDED") {
            myCar.status = carState.ADDED;
        } else if (_status == "READY") {
            myCar.status = carState.READY;
        } else if (_status == "REPAIR") {
            myCar.status = carState.REPAIR;
        }

        allCars[_carId] = myCar;
    }

    // update car condition
    function updateCondition(uint256 _carId, string memory _condition) public ownerOnly(_carId) validCarId(_carId) {
        Car memory myCar = allCars[_carId];
        myCar.condition = _condition;

        allCars[_carId] = myCar;
    }

    // rent the car (will be called from car rental contract)
    function rentCar(uint256 _carId, address _renter, uint256 _duration, uint256 _rate) public validCarId(_carId) {
        Rental memory myRental = Rental({
            carId: _carId,
            renter: _renter,
            duration: _duration,
            rate: _rate,
            total: _duration*_rate,
            state: rentalState.RENTED
        });
        allRentals[_carId] = myRental;
    }

    // get car location
    function getLocation(uint256 _carId) public view returns(fixed, fixed) {
        Car memory myCar = allCars[_carId];
        Location memory myLocation = myCar.location;
        return (myLocation.lat, myLocation.long);
    }

    // get renter
    function getRenter(uint256 _carId) public view returns(address) {
        return allRentals[_carId].renter;
    }

}
