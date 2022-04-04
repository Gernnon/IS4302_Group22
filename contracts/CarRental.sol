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
        uint256 price;
        uint256 duration;
    }
    mapping(uint256 => listInfo) listInfos; // car => (price, duration)

    constructor(CarPool carAddress, UserPool userAddress, uint256 fee) public {
        carPoolContract = carAddress;
        userPoolContract = userAddress;
        comissionFee = fee;
    }

    // modifier to ensure a function is callable only by its previous owner
    modifier prevOwnerOnly(uint256 carId) {
        require(msg.sender == carPoolContract.getPrevOwner(carId));
        _;
    }

    // modifier to ensure user calling contract is valid
    modifier validUser(uint256 userId) {
        require(msg.sender == userPoolContract.getUserAddress(userId));
        _;
    }

    // modifier to ensure deposit is enough to rent car
    modifier sufficientDeposit(uint256 carId, uint256 deposit) {
        uint256 price;
        uint256 duration;
        (price, duration) = checkListInfo(carId)
        require(deposit >= (price + comissionFee));
        _;
    }

    // modifier to ensure car is not currently rented
    modifier carNotRented(uint256 carId) {
        require(carPoolContract.getRenter(carId) != address(0));
        _;
    }

    // modifier to ensure carId is valid
    modifier validCarId(uint256 carId) {
        require(carPoolContract.isExists(carId));
        _;
    }

    // modifier to ensure administrator can call the function
    modifier administratorOnly {
        require(_owner = msg.sender);
        _;
    }

    // list a car for rental
    function list(uint256 carId, uint256 duration, uint256 price) public prevOwnerOnly(carId) {
        require(duration > 0);
        require(price > 0);

        // new list info
        listInfo memory newListInfo = listInfo(price, duration)

        listInfos[carId] = newListInfo;  
    }

    // unlist a car
    function unlist(uint256 carId) public prevOwnerOnly(carId) {
        listInfo memory newListInfo = listInfo(0, 0);

        listInfos[carId] = newListInfo;
    }

    // check the information for a car on list
    function checkListInfo(uint256 carId) public view returns (uint256, uint256) {
        uint256 price = listInfos[carId].price;
        uint256 duration = listInfos[carId].duration;

        return (price, duration);
    }

    // rent a car and prepay deposit, and set the car's renter
    function rent(uint256 userId, uint256 carId, uint256 deposit) public payable validUser(userId) sufficientDeposit(carId, deposit) carNotRented(carId) {
        carPoolContract.setToInuse(carId, msg.sender);
        
        //deposit eg. tokenContract.deposit(msg.sender, deposit)
    }

    // after renting a car, pay car owner rent price, refund some of the deposit to the renter's balance
    function transfer(uint256 carId) public renterOnly(carId) {
        //uint256 price;
        //uint256 duration;

        //(price, duration) = checkListInfo(carId);
        //uint256 deposit = tokenContract.getDeposit(msg.sender);
        //uint256 amt = deposit - price - comissionFee;
        //transfer to car owner eg. tokenContract.transferCredit(carPoolContract.getPrevOwner(carId), price);
        //refund excess to sender eg. tokenContract.transferCredit(msg.sender, amt);
        //totalCommission += commissionFee;
    }

    // Is locking and unlocking necessary?
    // renter can unlock a car before use
    function unlock(uint256 carId) public renterOnly(carId) validCarId(carId) {}
    // renter can lock a car after use
    function lock(uint256 carId) public renterOnly(carId) validCarId(carId) {}

    // withdraw commission fee for administrator
    function withdraw() public administratorOnly {
        //tokenContract.transferCredit(_owner, totalCommission);
    }
}