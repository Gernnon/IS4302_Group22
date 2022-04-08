const CarToken = artifacts.require("CarToken");
const CarPool = artifacts.require("CarPool");
const UserPool = artifacts.require("UserPool");
const CarRental = artifacts.require("CarRental");

module.exports = function(deployer) {
  deployer
  .deploy(CarToken)
  .then(
    function() {
      return deployer.deploy(CarPool, CarToken.address)
    }
  )
  .then(
    function() {
      return deployer.deploy(UserPool, CarToken.address)
    }
  )
  .then(
    function() {
      return deployer.deploy(CarRental, CarPool.address, UserPool.address, 10)
    }
  );
};
