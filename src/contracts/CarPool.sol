pragma solidity ^0.5.0;
import "./CarToken.sol";

contract CarPool {
    
    CarToken ctContract;

    constructor (CarToken ctAddress) public {
        ctContract = ctAddress;
    }
    
    enum carState {READY, REPAIR, REMOVED}
    enum rentalState {NONE, LISTED, RENTED, COLLECTED, RETURNED}

    struct Car {
        string description;
        uint8 capacity;
        string licenseType;
        string plateNum;
        bool insured;
        string coords;
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
        rentalState status;
    }

    uint256 public totalCarsCounter = 0; 
    mapping(uint256 => Car) public allCars;
    mapping(uint256 => Rental) public allRentals;
    mapping(address => uint256[]) owners;

    event AddedCar(uint256 _carId, string _description, uint8 _capacity, string _plateNum);

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

    // register/unregister a car
    function addCar(string memory _description, uint8 _capacity, string memory _plateNum, string memory _licenseType, string memory _coords, string memory _condition) public validPlateNum(_plateNum) returns(uint256) {
        require(bytes(_description).length > 0 && _capacity > 0 && _capacity <= 8 && bytes(_plateNum).length > 0, "Check vehicle information.");
        require(bytes(_condition).length > 0, "Check vehicle condition.");

        totalCarsCounter = totalCarsCounter + 1;
        
        Car memory myCar = Car({
            description: _description,
            capacity: _capacity,
            plateNum: _plateNum,
            licenseType: _licenseType,
            insured: true,
            coords: _coords,
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
            status: rentalState.NONE
        });
        
        allCars[totalCarsCounter] = myCar;
        allRentals[totalCarsCounter] = myRental;
        emit AddedCar(totalCarsCounter, _description, _capacity, _plateNum);
        return totalCarsCounter;
    }

    function removeCar(uint256 _carId) public ownerOnly(_carId) validCarId(_carId) {
        allCars[_carId].status = carState.REMOVED;
        allRentals[_carId].status = rentalState.NONE;
    }
    
    // edit car properties (location, insurance and owner). these 3 are commonly associated with transfer of car ownership
    function editCar(uint256 _carId, string memory _coords, bool _insured, address _owner) public ownerOnly(_carId) validCarId(_carId) {
        Car memory myCar = allCars[_carId];
        myCar.coords = _coords;
        myCar.insured = _insured;
        myCar.owner = _owner;

        allCars[_carId] = myCar;
    }

    // update car status
    function updateStatus(uint256 _carId, string memory _status) public ownerOnly(_carId) validCarId(_carId) {
        Car memory myCar = allCars[_carId];
        if (keccak256(abi.encodePacked(_status)) == keccak256(abi.encodePacked("READY"))) {
            myCar.status = carState.READY;
        } else if (keccak256(abi.encodePacked(_status)) == keccak256(abi.encodePacked("REPAIR"))) {
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

    // list car for rent
    function listCar(uint256 _carId) public validCarId(_carId) {
        allRentals[_carId].status = rentalState.LISTED;
    }

    // delist car for rent
    function delistCar(uint256 _carId) public validCarId(_carId) {
        allRentals[_carId].status = rentalState.NONE;
    }

    // rent the car (will be called from car rental contract)
    function rentCar(uint256 _carId, address _renter, uint256 _rate, uint256 _duration) public validCarId(_carId) {
        Rental memory myRental = Rental({
            carId: _carId,
            renter: _renter,
            duration: _duration,
            rate: _rate,
            total: _duration*_rate,
            status: rentalState.RENTED
        });
        allRentals[_carId] = myRental;
    }

    // cancel rental (will be called from car rental contract)
    function cancelRental(uint256 _carId) public validCarId(_carId) {
        Rental memory myRental = Rental({
            carId: totalCarsCounter,
            renter: msg.sender,
            duration: 0,
            rate: 0,
            total: 0,
            status: rentalState.LISTED
        });
        allRentals[_carId] = myRental;
    }

    // renter to start rental (will be called from car rental contract)
    function startRental(uint256 _carId) public validCarId(_carId) {
        allRentals[_carId].status = rentalState.COLLECTED;
    }

    // owner to end rental (will be called from car rental contract)
    function endRental(uint256 _carId) public validCarId(_carId) {
        allRentals[_carId].status = rentalState.LISTED;
    }

    // transfer CarToken as payment
    function transferCT(address _from, address _to, uint256 _amt) public {
        ctContract.transfer(_from, _to, _amt);
    }

    // get renter
    function getRenter(uint256 _carId) public view returns(address) {
        return allRentals[_carId].renter;
    }

    // get duration
    function getDuration(uint256 _carId) public view returns(uint256) {
        return allRentals[_carId].duration;
    }

    // get rate
    function getRate(uint256 _carId) public view returns(uint256) {
        return allRentals[_carId].rate;
    }

    // get owner
    function getOwner(uint256 _carId) public view returns(address) {
        return allCars[_carId].owner;
    }

    // get car info
    function getCarDescription(uint256 _carId) public view returns(string memory) {
        return allCars[_carId].description;
    }
    function getCarCapacity(uint256 _carId) public view returns(uint8) {
        return allCars[_carId].capacity;
    }
    function getCarLicenseType(uint256 _carId) public view returns(string memory) {
        return allCars[_carId].licenseType;
    }
    function getCarLocation(uint256 _carId) public view returns(string memory) {
        return allCars[_carId].coords;
    }
    function getCarState(uint256 _carId) public view returns(carState){
        return allCars[_carId].status;
    }

    // check rental status
    function checkRentalStatus(uint256 _carId) public view returns(uint8) {
        uint8 val = 0;
        if (allRentals[_carId].status == rentalState.LISTED) {
            val = 1;
        } else if (allRentals[_carId].status == rentalState.RENTED) {
            val = 2;
        } else if (allRentals[_carId].status == rentalState.COLLECTED) {
            val = 3;
        } else if (allRentals[_carId].status == rentalState.RETURNED) {
            val = 4;
        }
        return val;
    }

    // check license type
    function checkLicenseType(uint256 _carId) public view returns(string memory) {
        return allCars[_carId].licenseType;
    }

}