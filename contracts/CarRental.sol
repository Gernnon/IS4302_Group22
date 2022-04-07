pragma solidity ^0.8.0;
import "./CarPool.sol";
import "./UserPool.sol";

contract CarRental{
    CarPool carPoolContract;
    UserPool userPoolContract;
    uint256 public comissionFee;
    uint256 totalCommission = 0;
    address _owner = msg.sender;

    struct listInfo {
        uint256 duration;
        uint256 rate;
    }

    struct offerDetails {
        uint256 userId;
        uint256 duration;
        uint256 rate;
    }

    mapping(uint256 => offerDetails) offer; // car => offer
    mapping(uint256 => listInfo) listInfos; // car => (duration, rate)

    constructor(CarPool carAddress, UserPool userAddress, uint256 fee) public {
        carPoolContract = carAddress;
        userPoolContract = userAddress;
        comissionFee = fee;
    }

    // modifier to ensure user calling contract is valid
    modifier validUser(uint256 userId) {
        require(msg.sender == userPoolContract.getUserAddress(userId));
        _;
    }

    // modifier to ensure deposit is enough to rent car
    modifier sufficientBalance(uint256 carId, uint256 deposit) {
        uint256 price;
        uint256 duration;
        (price, duration) = checkListInfo(carId)
        require(deposit >= (price + comissionFee));
        _;
    }

    // modifier to ensure car is not currently rented
    modifier carNotRented(uint256 carId) {
        require((carPoolContract.getRentalState(carId) == CarPool.rentalState.NONE) || (carPoolContract.getRentalState(carId) == CarPool.rentalState.RETURNED));
        _;
    }

    // modifier to ensure administrator can call the function
    modifier administratorOnly {
        require(_owner = msg.sender);
        _;
    }

    // list a car for rental
    function list(uint256 carId, uint256 duration, uint256 rate) public {
        require(duration > 0);
        require(rate > 0);

        // new list info
        listInfo memory newListInfo = listInfo(duration, rate)

        listInfos[carId] = newListInfo;  
    }

    // unlist a car
    function unlist(uint256 carId) public {
        listInfo memory newListInfo = listInfo(0, 0);

        listInfos[carId] = newListInfo;
    }

    // check the information for a car on list
    function checkListInfo(uint256 carId) public view returns (uint256, uint256) {
        uint256 duration = listInfos[carId].duration;
        uint256 rate = listInfos[carId].rate;

        return (duration, rate);
    }

    // rent a car directly from listed cars
    function rent(uint256 carId) public validUser(userId) carNotRented(carId) {
        (duration, rate) = checkListInfo(carId);
        carPoolContract.rentCar(carId, msg.sender, duration, rate);

        uint256 price = duration * rate;
        uint256 total = price + commissionFee;
        totalCommission += commissionFee;

        // deduct from renter
        userPoolContract.deduct(total);

        // owner gets price amount
        address owner = carPoolContract.getOwner(carId); 
        userPoolContract.topupTo(owner, price);
    }

    // offer a price for rent
    function addOffer(uint256 userId, uint256 carId, uint256 duration, uint256 rate) public {
        offerDetails memory newOfferDetails = offerDetails(userId, duration, rate);

        offer[carId] = newOfferDetails;
    }

    // view offer of a renter
    function viewOffer(uint256 carId) public view returns(uint256, uint256, uint256) {
        uint256 userId = offer[carId].userId;
        uint256 duration = offer[carId].duration;
        uint256 rate = offer[carId].rate;

        return (userId, duration, rate);
    }

    // accept offer of a renter and rent the car
    function acceptOffer(uint256 carId) public {
        (userId, duration, rate) = viewoffer(carId);

        carPoolContract.rentCar(carId, userId, duration, rate);

        uint256 price = duration * rate;
        uint256 total = price + commissionFee;
        totalCommission += commissionFee;

        // owner gets price amount
        userPoolContract.topup(price);

        // deduct from renter
        address renter = userPoolContract.getUserAddress(userId);
        userPoolContract.deductFrom(renter, total);
    }

    // decline offer of a renter
    function declineOffer(uint256 carId) public {
        offerDetails memory resetOffer = offerDetails(0,0,0);
        offer[carId] = resetOffer;
    }

    // return a car
    function return(uint256 carId) public {
        carPoolContract.updateRent(carId, "RETURNED");
    }

    // withdraw commission fee for administrator
    function withdraw() public administratorOnly {
        tokenContract.transferCredit(_owner, totalCommission);
    }
}