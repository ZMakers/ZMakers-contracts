pragma solidity ^0.4.25;

import './interfaces/ApprovedCreatorRegistryInterface.sol';

contract ApprovedCreatorRegistry is ApprovedCreatorRegistryInterface {

    mapping(address => address) operators;
    
    function getVersion() public pure returns (uint) {
        uint _version = 1;
        return _version;
    }
    
    function typeOfContract() public pure returns (string) {
        return "approvedCreatorRegistry";
    }
    
    function isOperatorApprovedForCustodialAccount(
        address _operator,
        address _custodialAddress) public view returns (bool) {
            require(_operator != address(0), "Invalid operator address, 0x0 address is not allowed!");
            require(_custodialAddress != address(0), "Invalid custodial address, 0x0 address is not allowed!");
            if(operators[_operator] != _custodialAddress) {
                return false;
            }
            return true;
    }

}
