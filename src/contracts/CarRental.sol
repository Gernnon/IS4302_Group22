pragma solidity ^0.5.0;
import "./CarPool.sol";
import "./UserPool.sol";

contract CarRental {
    CarPool carsContract;
    UserPool usersContract;
    uint256 public commissionFee;
    uint256 totalCommission = 0;
    address _owner = msg.sender;

    enum offerState {IN_PROCESS, ACCEPTED}
    struct Offer {
        uint256 carId;
        address renter;
        uint256 rate;
        uint256 duration;
        offerState status;
    }

    uint public totalListingsCounter = 0;
    mapping(uint256 => Offer[]) public allOffers;
    mapping(uint256 => uint256) public allListings;
    mapping(uint256 => uint256) public countOffers;

    constructor(CarPool carAddress, UserPool userAddress, uint256 fee) public {
        carsContract = carAddress;
        usersContract = userAddress;
        commissionFee = fee;
    }

    // modifier to ensure user is owner of car
    modifier isOwner(uint256 _carId) {
        require(msg.sender == carsContract.getOwner(_carId), "You are not the owner of this car!");
        _;
    }

    // modifier to ensure user is registered
    modifier isRegistered(address _renter) {
        require(usersContract.checkRegistered(_renter) == true, "You are not a registered user!");
        _;
    }

    // modifier to ensure car is listed
    modifier isListed(uint256 _carId) {
        require(carsContract.checkRentalStatus(_carId) == 1, "Car is not listed!");
        _;
    }

    // modifier to ensure car is rented
    modifier isRented(uint256 _carId) {
        require(carsContract.checkRentalStatus(_carId) == 2, "Car is not rented!");
        _;
    }

    // modifier to ensure user calling is the renter
    modifier isRenter(uint256 _carId) {
        require(carsContract.getRenter(_carId) == msg.sender, "You are not the renter!");
        _;
    }

    // modifier to ensure balance is enough to rent car
    modifier sufficientBalance(uint256 _rate, uint256 _duration) {
        uint256 _balance = usersContract.getBalance(msg.sender);
        require(_balance >= (_rate * _duration), "You have insufficient tokens!");
        _;
    }

    // modifier to ensure administrator can call the function
    modifier administratorOnly {
        require(_owner == msg.sender);
        _;
    }

    // list a car for rental
    function list(uint256 _carId) public isOwner(_carId) {
        carsContract.listCar(_carId);
        totalListingsCounter = totalListingsCounter + 1;
        allListings[totalListingsCounter] = _carId;
    }

    // delist a car
    function delist(uint256 _carId) public isOwner(_carId) {
        carsContract.delistCar(_carId);
        uint index;
        for(uint i=0; i<totalListingsCounter; i++) {
            if(allListings[i] == _carId) {
                index = i;
                break;
            }
        }
        delete allListings[index];
        totalListingsCounter = totalListingsCounter - 1;

        // delete all offers as well
        for(uint i=0; i<allOffers[_carId].length; i++) {
            allOffers[_carId].length--;
            countOffers[_carId]--;
        }
    }

    // make offer for listed car
    function makeOffer(uint256 _carId, uint256 _rate, uint256 _duration) public isListed(_carId) isRegistered(msg.sender) sufficientBalance(_rate, _duration) {
        string memory renterLType = usersContract.getLicenseType(msg.sender);
        string memory carLType = carsContract.checkLicenseType(_carId);
        require(keccak256(abi.encodePacked(renterLType)) == keccak256(abi.encodePacked(carLType)), "You do not have the required license to rent this vehicle!");
        Offer memory myOffer = Offer({
            carId: _carId,
            renter: msg.sender,
            rate: _rate,
            duration: _duration,
            status: offerState.IN_PROCESS
        });

        allOffers[_carId].push(myOffer);
        countOffers[_carId]++;
    }

    // owner can accept rental offers
    function acceptOffer(uint256 _carId, address _renter) public isOwner(_carId) isListed(_carId) {
        uint index;
        for(uint i=0; i<allOffers[_carId].length; i++) {
            if(allOffers[_carId][i].renter == _renter) {
                index = i;
                break;
            }
        }
        Offer memory myOffer = allOffers[_carId][index];
        allOffers[_carId][index].status = offerState.ACCEPTED;
        carsContract.rentCar(_carId, _renter, myOffer.rate, myOffer.duration);
    }

    // owner can reject rental offers
    function rejectOffer(uint256 _carId, address _renter) public isOwner(_carId) isListed(_carId) {
        uint index;
        for(uint i=0; i<allOffers[_carId].length; i++) {
            if(allOffers[_carId][i].renter == _renter) {
                index = i;
                break;
            }
        }
        //Remove offer
        allOffers[_carId][index] = allOffers[_carId][(allOffers[_carId].length-1)];
        allOffers[_carId].length--;
        countOffers[_carId]--;
    }

    // renter can cancel offer
    function cancelOffer(uint _carId) isRented(_carId) public {
        require(carsContract.checkRentalStatus(_carId) != 3, "This car has already been collected for use!");
        address _renter = carsContract.getRenter(_carId);
        uint index;
        for(uint i=0; i<allOffers[_carId].length; i++) {
            if(allOffers[_carId][i].renter == _renter) {
                index = i;
                break;
            }
        }
        //Remove offer
        allOffers[_carId][index] = allOffers[_carId][(allOffers[_carId].length-1)];
        allOffers[_carId].length--;
        countOffers[_carId]--;

        //If buyer is cancelling an offer that has already been accepted by a seller.
        carsContract.cancelRental(_carId);
    }

    // renter starts trip
    function startTrip(uint256 _carId) isRenter(_carId) public {
        carsContract.startRental(_carId);
        //Remove all offers on the car
        for(uint i=0; i<allOffers[_carId].length; i++) {
            allOffers[_carId].length--;
        }
        countOffers[_carId] = 0;
    }

    // owner ends trip
    function endTrip(uint256 _carId) isOwner(_carId) public {
        carsContract.endRental(_carId);
        // transfer funds
        address _renter = carsContract.getRenter(_carId);
        uint256 _rate = carsContract.getRate(_carId);
        uint256 _duration = carsContract.getDuration(_carId);
        uint256 _amt = (_rate*_duration)-commissionFee;
        carsContract.transferCT(_renter, msg.sender, _amt);
        carsContract.transferCT(_renter, address(this), commissionFee);
        totalCommission = totalCommission + commissionFee;
    }

    // withdraw commission fee for administrator
    function withdraw() public administratorOnly {
        carsContract.transferCT(address(this), _owner, totalCommission);
    }

    // function to show listed car details
    function getCarDetails(uint256 _carId) public view returns(string memory, uint8, string memory, string memory) {
        string memory _description = carsContract.getCarDescription(_carId);
        uint8 _capacity = carsContract.getCarCapacity(_carId);
        string memory _licenseType = carsContract.getCarLicenseType(_carId);
        string memory _location = carsContract.getCarLocation(_carId);
        return (_description, _capacity, _licenseType, _location);
    }
}