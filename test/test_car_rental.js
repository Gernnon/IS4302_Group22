const _deploy_contracts = require("../migrations/2_deploy_contracts");
const truffleAssert = require('truffle-assertions');
var assert = require('assert');

var CarPool = artifacts.require("../contracts/CarPool.sol");
var UserPool = artifacts.require("../contracts/UserPool.sol");
var CarRental = artifacts.require("../contracts/CarRental.sol");

contract('CarRentalTest', function(accounts) {
    before(async () => {
        carPoolInst = await CarPool.deployed();
        userPoolInst = await UserPool.deployed();
        CarRentalInst = await CarRental.deployed();
    });

    let administrator = accounts[0]; // the first address in Ganache accounts[] will be owner of CarRental
    let owner1Address = accounts[1]; 
    let owner2Address = acccounts[2];
    let renter1Address = accounts[3];
    let renter2Address = accounts[4];

    let testCaseAddress = accounts[9]; // address for this test case, only for testing

    let owner1 = -1;
    let owner2 = -1;
    let car1 = -1;
    let car2 = -1;
    let renter1 = -1;
    let renter2 = -1;

    let carRentalAddress = CarRentalInst.address; // CarRental Contract's address

    // car state
    let CarState = {
        ADDED:0, 
        READY:1, 
        REPAIR:2, 
        REMOVED:3
    };

    let RentalState = {
        NONE:0, 
        RENTED:1, 
        RETURNED:2
    };

    // duration and rate
    let duration = 10;
    let price = 20;
    let rate = 1;
    let commissionFee = 1; // stay same with 2_deploy_contracts.js
    let carLoc = [1.0, 2.0];
    let userLoc = [1.0, 2.1];

    it("[Test 1] Register a user", async()=>{
        owner1 = await UserPoolInst.add("Owner1", "Owner1Id", "Owner1LicenceNum", {from:owner1Address});

        assert.notStrictEqual(
            owner1,
            -1,
            "Failed to register a user"
        );
        
        owner2 = await UserPoolInst.add("Owner2", "Owner2Id", "Owner2LicenceNum", {from:owner2Address});
        renter1 = await UserPoolInst.add("Renter1", "Renter1Id", "Renter1LicenceNum", {from:renter1Address});
        renter2 = await UserPoolInst.add("Renter2", "Renter2Id", "Renter2LicenceNum", {from:renter2Address});
        
    });

    it("[Test 2] Owner add/remove a car", async()=>{
        // 1. owner add a car
        car1 = await CarPoolInst.addCar("brand1", "model1", "vehType1", 5 /*capacity*/,
          "plateNum1", 103.413384/*lat*/, 1.910925/*lon*/, "condition1",{from:owner1Address});
        assert.notStrictEqual(
            car1,
            -1,
            "Failed to add a car"
        );
        // test car state
        let carState = await CarPoolInst.getCarState(car1, {from: owner1Address});
        assert.StrictEqual(
            carState,
            CarState.READY,
            `Car added with state ${carState} instead of READY(1)`
        );
        
        // owner remove a car
        await CarPoolInst.removeCar(car1, {from: owner1Address});
        carState = await CarPoolInst.getCarState(car1, {from: owner1Address});
        assert.StrictEqual(
            carState,
            CarState.REMOVED,
            "Failed to remove a car"
        );

        car2 = await CarPoolInst.addCar("brand2", "model2", "vehType2", 7 /*capacity*/,
        "plateNum2", 103.413384/*lat*/, 1.910925/*lon*/, "condition2", {from:owner2Address});
    });

    it("[Test 3] Owner changes car state to REPAIR/READY", async()=>{
        // car damaged, set car to repair
        await CarPoolInst.updateStatus(car2, "REPAIR", {from: owner2Address});
        // test car state
        let carState = await CarPoolInst.getCarState(car2, {from: owner2Address});
        assert.StrictEqual(
            carState,
            CarState.REPAIR,
            `Failed to set car state to REPAIR(3), but ${carState}`
        );

        // car repaired, set car to ready
        await CarPoolInst.updateStatus(car2, "READY", {from: owner2Address});
        // test car state
        carState = await CarPoolInst.getCarState(car2, {from: owner2Address});
        assert.StrictEqual(
            carState,
            CarState.READY,
            `Failed to set car state to READY(1), but ${carState}`
        );
    });

    it("[Test 4] Owner transfers car to CarRental", async()=>{
        await CarPoolInst.transfer(car2, CarRentalInst.address, {from:owner2Address});

        let newOwner = await CarPoolInst.getOwner(car2, {from: testCaseAddress});
        assert.strictEqual(
            newOwner,
            carRentalAddress,
            "Car not transferred ownership to CarRental"
        );
    });

    it("[Test 5] Owner lists/unlists a car", async()=>{
        // 1. Only owner can list a car
        await truffleAssert.passes(
            CarRentalInst.list(car2, duration, price, {from:owner2Address}),
            "Owner should be able to list a car"
        );

        // 2. Owner can unlist a car
        await truffleAssert.passes(
            CarRentalInst.unlist(car2, {from:owner1Address}),
            "Owner should be able to unlist a car"
        );

        await CarRentalInst.list(car2, duration, price, {from:owner2Address});
    });

    it("[Test 6] IPFS/GPS device updates car location", async()=>{
        // set location
        await CarPoolInst.setLocation(car1, carLoc[0], carLoc[1], {from: device1Address});
        // get location
        let carLocNew = await CarPoolInst.getLocation(car1, {from: carRentalAddress});
        assert.StrictEqual(
            Math.abs(carLoc[0]-carLocNew[0]) < 0.001 && Math.abs(carLoc[1]-carLocNew[1]) < 0.001,
            true,
            `Failed to set car location to ${carLoc}, but ${carLocNew}`
        );
    });

    it("[Test 7] User's frontend updates user location", async()=>{
        // set location
        await UserPoolInst.setLocation(user1, userLoc[0], userLoc[1], {from: user1Address});
        // get location
        let userLocNew = await UserPoolInst.getLocation(user1, {from: carRentalAddress});
        assert.StrictEqual(
            Math.abs(userLoc[0]-userLocNew[0]) < 0.001 && Math.abs(userLoc[1]-userLocNew[1]) < 0.001,
            true,
            `Failed to set user location to ${userLoc}, but ${userLocNew}`
        );
    });

    it("[Test 8] Renter check any available cars", async()=>{
        let listInfo = await CarRental.checkListInfo(car2,{from: renter1Address});
        assert.strictEqual(
            listInfo,
            [duration, price, location],
            "listInfo should be the same as owner's setting."
        );
    });

    it("[Test 9] Renter rent a car", async()=>{
        await CarRentalInst.rent(renter1, car1, 100, {from: renter1Address});
        // test car state
        let rentalState = await CarPoolInst.getRentalState(car1, {from: owner1Address});
        assert.StrictEqual(
            rentalState,
            RentalState.RENTED,
            `Failed to change rental state to RENTED(1), but ${rentalState}`
        );
    });

    it("[Test 10] Renter returns a car", async=>{
        await CarRentalInst.return(car1, {from: renter1Address});
        // test car state
        let rentalState = await CarPoolInst.getRentalState(car1, {from: owner1Address});
        assert.StrictEqual(
            rentalState,
            RentalState.RETURNED,
            `Failed to change rental state to RETURNED(2), but ${rentalState}`
        );
    });

    it("[Test 11] Renter refund his money", async()=>{
        let balanceBeforeReturn = await UserPoolInst.getBalance({from: renter1Address});
        await CarRentalInst.transfer({from: renter1Address});
        let balanceAfterReturn = await UserPoolInst.getBalance({from: renter1Address});
        // check renter's balance 
        assert.strictEqual(
            Math.abs(balanceAfterReturn-balanceBeforeReturn - (commissionFee+price)) < 0.0001,
            true,
            `Balance changed incorrectly, should be ${commissionFee+price}, but ${balanceAfterReturn-balanceBeforeReturn}`
        );
    });    
});