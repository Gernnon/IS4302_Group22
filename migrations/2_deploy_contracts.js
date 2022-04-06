const UserPool = artifacts.require("UserPool");
const CarPool = artifacts.require("CarPool");
const CarRental = artifacts.require("CarRental");

const commissionFee = 1;

module.exports = (deployer, network, accounts) => {
    deployer.deploy(UserPool).then(function() {
      return deployer.deploy(CarPool).then(function(){
          return deployer.deploy(CarRental, CarPool.address, UserPool.address, commissionFee); // stay same with test_car_rental
      });
    });
  };