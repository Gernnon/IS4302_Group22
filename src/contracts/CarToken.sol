pragma solidity ^0.5.0;
import "./ERC20.sol";

contract CarToken {
    ERC20 erc20Contract;
    uint256 supplyLimit;
    uint256 currentSupply;
    address owner;

    constructor() public {
        ERC20 e = new ERC20();
        erc20Contract = e;
        owner = msg.sender;
        supplyLimit = 1000000000;
    }

    function getCredit() public payable {
        uint256 amt = msg.value / 10000000000000; //translates to 1 ETH : 100000 CT
        require(erc20Contract.totalSupply() + amt < supplyLimit, "Token supply is not enough!");
        // erc20Contract.transferFrom(owner, msg.sender, amt);
        erc20Contract.mint(msg.sender, amt);
    }

    function checkCredit() public view returns(uint256) {
        return erc20Contract.balanceOf(msg.sender);
    }

    // get wallet balance of specific user, to be called from inheriting contracts
    function checkBal(address user) public view returns(uint256) {
        return erc20Contract.balanceOf(user);
    }

    //call transferToken function of ERC20 token contract from external contract (this is a custom function i have put in ERC20.sol)
    function transfer(address sender, address receiver, uint256 amt) public {
        erc20Contract.transferTokens(sender, receiver, amt);
    }
}