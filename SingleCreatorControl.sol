pragma solidity 0.4.25;


/**
 * A special control class that's used to help enforce that a DigitalMedia contract
 * will service only a single creator's address.  This is used when deploying a 
 * custom token contract owned and managed by a single creator.
 */
contract SingleCreatorControl {

    // The single allowed creator for this digital media contract.
    address public singleCreatorAddress;

    // The single creator has changed.
    event SingleCreatorChanged(
        address indexed previousCreatorAddress, 
        address indexed newCreatorAddress);

    /**
     * Sets the single creator associated with this contract.  This function
     * can only ever be called once, and should ideally be called at the point
     * of constructing the smart contract.
     */
    function setSingleCreator(address _singleCreatorAddress) internal {
        require(singleCreatorAddress == address(0), "Single creator address already set.");
        singleCreatorAddress = _singleCreatorAddress;
    }

    /**
     * Checks whether a given creator address matches the single creator address.
     * Will always return true if a single creator address was never set.
     */
    function isAllowedSingleCreator(address _creatorAddress) internal view returns (bool) {
        require(_creatorAddress != address(0), "0x0 creator addresses are not allowed.");
        return singleCreatorAddress == address(0) || singleCreatorAddress == _creatorAddress;
    }

    /**
     * A publicly accessible function that allows the current single creator
     * assigned to this contract to change to another address.
     */
    function changeSingleCreator(address _newCreatorAddress) public {
        require(_newCreatorAddress != address(0));
        require(msg.sender == singleCreatorAddress, "Not approved to change single creator.");
        singleCreatorAddress = _newCreatorAddress;
        emit SingleCreatorChanged(singleCreatorAddress, _newCreatorAddress);
    }
}
