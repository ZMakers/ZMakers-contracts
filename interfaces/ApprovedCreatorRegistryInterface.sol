pragma solidity ^0.4.22;


/**
 * Interface to the digital media store external contract that is 
 * responsible for storing the common digital media and collection data.
 * This allows for new token contracts to be deployed and continue to reference
 * the digital media and collection data.
 */
contract ApprovedCreatorRegistryInterface {

    function getVersion() public pure returns (uint);
    function typeOfContract() public pure returns (string);
    function isOperatorApprovedForCustodialAccount(
        address _operator,
        address _custodialAddress) public view returns (bool);

}
