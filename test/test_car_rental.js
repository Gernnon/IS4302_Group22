const _deploy_contracts = require("../migrations/2_deploy_contracts");
const truffleAssert = require('truffle-assertions');
var assert = require('assert');

var ERC20 = artifacts.require("../contracts/ERC20");
var CarToken = artifacts.require("../src/contracts/CarToken.sol");
var CarPool = artifacts.require("../src/contracts/CarPool.sol");
var UserPool = artifacts.require("../src/contracts/UserPool.sol");
var CarRental = artifacts.require("../src/contracts/CarRental.sol");

contract('CarRentalTest', function(accounts) {
    before(async () => {
        Erc20Inst = await ERC20.deployed();
        CarTokenInst = await CarToken.deployed();
        CarPoolInst = await CarPool.deployed();
        UserPoolInst = await UserPool.deployed();
        CarRentalInst = await CarRental.deployed();

        administrator = accounts[0]; // the first address in Ganache accounts[] will be owner of CarRental
        owner1Address = accounts[1]; 
        owner2Address = accounts[2];
        renter1Address = accounts[3];
        renter2Address = accounts[4];
    
        testCaseAddress = accounts[9]; // address for this test case, only for testing
    
        owner1 = 1;
        owner2 = 2;
        car1 = 1;
        car2 = 2;
        renter1 = 3;
        renter2 = 4;
        offer1 = 1;
        offer2 = 2;
    
        carRentalAddress = CarRentalInst.address; // CarRental Contract's address
    
        // car state
        CarState = {
            READY:0, 
            REPAIR:1, 
            REMOVED:2
        };
    
        RentalStatus = {
            NONE:0, 
            LISTED:1,
            RENTED:2, 
            COLLECTED:3,
            RETURNED:4
        };

        OfferState = {
            IN_PROCESS:0, 
            ACCEPTED:1
        }
    
        // duration and rate
        duration = 10;
        price = 20;
        rate = 1;
        commissionFee = 10; // stay same with 2_deploy_contracts.js

        // car state
        Car1Details = {
            description:"Car1 Description",
            capacity:5,
            licenseType:"Class3",
            plateNum:"Car1 PlatNum",
            location:"Car1 Loc",
            condition:"Car1 Condition"
        }

        Car2Details = {
            description:"Car2 Description",
            capacity:7,
            licenseType:"Class3",
            plateNum:"Car2 PlatNum",
            location:"Car2 Loc",
            condition:"Car2 Condition"
        }
    });

    it("[Test 1] Register a user", async()=>{
        // name, NRIC, licenceType, coordinates
        makeOwner1 = await UserPoolInst.registerUser("Owner1", "G0000001O", "Class3", "[10.0,20.0]", {from:owner1Address});
        assert.notStrictEqual(
            makeOwner1,
            undefined,
            "Failed to register owner1"
        );
        
        makeOwner2 = await UserPoolInst.registerUser("Owner2", "G0000002O", "Class3", "[10.0,20.0]", {from:owner2Address});
        assert.notStrictEqual(
            makeOwner2,
            undefined,
            "Failed to register owner2"
        );

        makeRenter1 = await UserPoolInst.registerUser("Renter1", "G0000001R", "Class3", "[10.0,20.0]", {from:renter1Address});
        assert.notStrictEqual(
            makeRenter1,
            undefined,
            "Failed to register renter1"
        );

        makeRenter2 = await UserPoolInst.registerUser("Renter2", "G0000002R", "Class3", "[10.0,20.0]", {from:renter2Address});
        assert.notStrictEqual(
            makeRenter2,
            undefined,
            "Failed to register renter2"
        );
    });

    it("[Test 2] User can update location", async()=>{
        await UserPoolInst.userLocUpdate("[11.0, 22.0]", renter1, {from:renter1Address});
        let renter1Loc = await UserPoolInst.getLocation(renter1Address, {from:renter1Address});
        assert.equal(
            renter1Loc,
            "[11.0, 22.0]",
            "Failed to update user's location"
        );
    });

    it("[Test 3] Owner can add/remove a car", async()=>{
        // 1. owner add a car
        // description, capacity, plateNum, licenseType, coordinates, condition
        let makeCar1 = await CarPoolInst.addCar(Car1Details.description, Car1Details.capacity, Car1Details.plateNum,
            Car1Details.licenseType, Car1Details.location, Car1Details.condition, {from: owner1Address});
        
        assert.notStrictEqual(
            makeCar1,
            undefined,
            "Owner1 failed to add a car"
        );
        // test car state
        let carState = await CarPoolInst.getCarState(car1, {from: owner1Address});
        assert.equal(
            carState,
            CarState.READY,
            `Car added with state ${carState} instead of READY(1)`
        );
        
        // owner remove a car
        await CarPoolInst.removeCar(car1, {from: owner1Address});
        carState = await CarPoolInst.getCarState(car1, {from: owner1Address});
        assert.equal(
            carState,
            CarState.REMOVED,
            "Owner1 failed to remove a car"
        );

        let makeCar2 = await CarPoolInst.addCar(Car2Details.description, Car2Details.capacity, Car2Details.plateNum,
            Car2Details.licenseType, Car2Details.location, Car2Details.condition, {from: owner2Address});
    });

    it("[Test 4] Owner can edit car's information", async()=>{
        // uint256 _carId, string memory _coords, bool _insured, address _owner
        await CarPoolInst.editCar(car2, "[12.0, 23.0]", true, owner2Address, {from:owner2Address});
        let carLoc = await CarPoolInst.getCarLocation(car2, {from:testCaseAddress});
        assert.equal(
            carLoc,
            "[12.0, 23.0]",
            `Owner failed to edit car's information. ${carLoc}`
        );
    });

    it("[Test 5] Owner can change car state to REPAIR/READY", async()=>{
        // car damaged, set car to repair
        await CarPoolInst.updateStatus(car2, "REPAIR", {from: owner2Address});
        // test car state
        let carState = await CarPoolInst.getCarState(car2, {from: owner2Address});
        assert.equal(
            carState,
            CarState.REPAIR,
            `Owner2 failed to set car state to REPAIR(1), but ${carState}`
        );

        // car repaired, set car to ready
        await CarPoolInst.updateStatus(car2, "READY", {from: owner2Address});
        // test car state
        carState = await CarPoolInst.getCarState(car2, {from: owner2Address});
        assert.equal(
            carState,
            CarState.READY,
            `Owner2 failed to set car state to READY(0), but ${carState}`
        );
    });

    it("[Test 6] Owner can list/delist a car", async()=>{
        // 1. Only owner can list a car
        await CarRentalInst.list(car2, {from:owner2Address});
        let rentalStatus = await CarPoolInst.checkRentalStatus(car2);
        assert.equal(
            rentalStatus,
            RentalStatus.LISTED,
            `Owner2 failed to list car. Car should have state LISTED(1), but ${rentalStatus}`
        );

        // 2. Owner can delist a car
        await CarRentalInst.delist(car2, {from:owner2Address});
        rentalStatus = await CarPoolInst.checkRentalStatus(car2);
        assert.equal(
            rentalStatus,
            RentalStatus.NONE,
            `Owner2 failed to delist car. Car should have state NONE(0), but ${rentalStatus}`
        );

        await CarRentalInst.list(car2, {from:owner2Address});
    });

    it("[Test 7] Renter can top up balance", async()=>{
        await CarTokenInst.getCredit({from: renter1Address, value: 1e18});
        let balance1 = await CarTokenInst.checkCredit({from: renter1Address});
        assert.equal(
            balance1,
            100000,
            "Renter1 failed to top up"
        );

        await CarTokenInst.getCredit({from: renter2Address, value: 1e18});
        let balance2 = await CarTokenInst.checkCredit({from: renter2Address});
        assert.equal(
            balance2,
            100000,
            "Renter2 failed to top up"
        );
    });

    it("[Test 8] Renter can check details of a car", async()=>{
        let carDetails = await CarRentalInst.getCarDetails(car2,{from: renter1Address});
        assert.notStrictEqual(
            carDetails,
            undefined,
            `Renter1 checked a listed car but get none info.`
        );
    });

    it("[Test 9] Renter can make offers to a listed car", async()=>{
        await CarRentalInst.makeOffer(car2, rate, duration, {from: renter1Address});
        let offerDetails1 = await CarRentalInst.getOfferDetails(car2, 0);
        assert.equal(
            offerDetails1[4], // offerDetails1.status
            OfferState.IN_PROCESS,
            `Renter1 failed to make offer to car2`
        );

        await CarRentalInst.makeOffer(car2, rate, duration, {from: renter2Address});
        let offerDetails2 = await CarRentalInst.getOfferDetails(car2, 1);
        assert.equal(
            offerDetails2[4], // offerDetails2.status
            OfferState.IN_PROCESS,
            `Renter2 failed to make offer to car2`
        );
    });

    it("[Test 10] Owner can accept an offer", async()=>{
        await CarRentalInst.acceptOffer(car2, renter2Address, {from: owner2Address});
        // test offer state
        let offerDetails2 = await CarRentalInst.getOfferDetails(car2, 1);
        assert.equal(
            offerDetails2[4], // offerDetails2.status
            OfferState.ACCEPTED,
            `Owner2 failed accept an offer, OfferStatus: ${offerDetails2[4]}`
        );
        // test rental status
        let rentalStatus = await CarPoolInst.checkRentalStatus(car2, {from: owner2Address});
        assert.equal(
            rentalStatus,
            RentalStatus.RENTED,
            `Owner2 failed to accept an offer, RentalStatus: ${rentalStatus}`
        );
    });

    it("[Test 11] Renter can cancel offers", async()=>{
        await CarRentalInst.cancelOffer(car2, {from: renter2Address});
        let rentalStatus = await CarPoolInst.checkRentalStatus(car2, {from: renter2Address});
        assert.equal(
            rentalStatus, // check offerDetails.status
            RentalStatus.LISTED,
            `Renter2 failed to cancelled offer, RentalStatus: ${rentalStatus}`
        );
    });

    it("[Test 12] Owner can reject an offer", async()=>{
        // renter2 makes an offer
        await CarRentalInst.makeOffer(car2, rate, duration, {from: renter2Address});
        // owner2 rejects the offer
        await CarRentalInst.rejectOffer(car2, renter2Address, {from: owner2Address});
        // test car state
        let rentalStatus = await CarPoolInst.checkRentalStatus(car2, {from: owner2Address});
        assert.equal(
            rentalStatus,
            RentalStatus.LISTED,
            `Owner2 failed to reject offer, RentalStatus: ${rentalStatus}`
        );
    });

    it("[Test 13] Renter can start a trip", async()=>{
        // renter2 makes an offer
        await CarRentalInst.makeOffer(car2, rate, duration, {from: renter2Address});
        // owner2 accepts the offer
        await CarRentalInst.acceptOffer(car2, renter2Address, {from: owner2Address});
        // renterw start a trip
        await CarRentalInst.startTrip(car2, {from: renter2Address});
        let rentalStatus = await CarPoolInst.checkRentalStatus(car2, {from: renter2Address});
        assert.equal(
            rentalStatus,
            RentalStatus.COLLECTED,
            `Renter2 failed to start a trip, RentalStatus: ${rentalStatus}`
        );
    });

    it("[Test 14] Only owner can end a trip", async()=>{
        // renter try to end a trip himself
        await truffleAssert.reverts(
            CarRentalInst.endTrip(car2, {from: renter2Address}),
            null,
            `Only owner can end a trip`
        )
        
        // owner can end a trip
        await CarRentalInst.endTrip(car2, {from: owner2Address});
        let rentalStatus = await CarPoolInst.checkRentalStatus(car2, {from: owner2Address});
        assert.equal(
            rentalStatus,
            RentalStatus.LISTED,
            `Owner2 failed to end a trip, RentalStatus: ${rentalStatus}`
        );
    });

    it("[Test 15] Contract can transfer tokens to all stackholders", async()=>{
        // check renter's balance 
        let renter2Balance = await CarTokenInst.checkCredit({from: renter2Address});
        assert.equal(
            renter2Balance,
            100000 - duration*rate - commissionFee,
            `Renter2's balance changed incorrectly, should be ${100000 - duration*rate - commissionFee}, but ${renter2Balance}`
        );
        
        // check owner's balance
        let owner2Balance = await CarTokenInst.checkCredit({from: owner2Address});
        assert.equal(
            owner2Balance,
            duration*rate,
            `Owner2's balance changed incorrectly, should be ${duration*rate}, but ${owner2Balance}`
        );
        // check CarRental contract's balance
        let carRentalBalance = await CarTokenInst.checkCredit({from: CarRentalInst.address});
        assert.equal(
            carRentalBalance,
            commissionFee,
            `CarRentalContract's balance changed incorrectly, should be ${commissionFee}, but ${carRentalBalance}`
        );
    }); 
    
    it("[Test 16] Administrator can withdraw commissionFee", async()=>{
        await CarRentalInst.withdraw();
        // check CarRentalContract's balance
        let carRentalBalance = await CarTokenInst.checkCredit({from: carRentalAddress});
        assert.equal(
            carRentalBalance,
            0,
            `Failed to withdraw commission fee from CarRentalContract`
        );
        
        // check administrator's balance
        let adminBalance = await CarTokenInst.checkCredit({from: administrator});
        assert.equal(
            adminBalance,
            commissionFee,
            `Failed to transfer commission fee to administrator's account`
        );
    });
});