pragma solidity 0.4.25;

import './Pausable.sol';
import './interfaces/DigitalMediaStoreInterface.sol';

/**
 * A special control class that is used to configure and manage a token contract's 
 * different digital media store versions.
 *
 * Older versions of token contracts had the ability to increment the digital media's
 * print edition in the media store, which was necessary in the early stages to provide
 * upgradeability and flexibility.
 *
 * New verions will get rid of this ability now that token contract logic
 * is more stable and we've built in burn capabilities.  
 *
 * In order to support the older tokens, we need to be able to look up the appropriate digital
 * media store associated with a given digital media id on the latest token contract.
 */
contract MediaStoreVersionControl is Pausable {

    // The single allowed creator for this digital media contract.
    DigitalMediaStoreInterface public v1DigitalMediaStore;

    // The current digitial media store, used for this tokens creation.
    DigitalMediaStoreInterface public currentDigitalMediaStore;
    uint256 public currentStartingDigitalMediaId;


    /**
     * Validates that the managers are initialized.
     */
    modifier managersInitialized() {
        require(v1DigitalMediaStore != address(0));
        require(currentDigitalMediaStore != address(0));
        _;
    }

    /**
     * Sets a digital media store address upon construction.  
     * Once set it's immutable, so that a token contract is always
     * tied to one digital media store.
     */
    function setDigitalMediaStoreAddress(address _dmsAddress)  
            internal {
        DigitalMediaStoreInterface candidateDigitalMediaStore = DigitalMediaStoreInterface(_dmsAddress);
        require(candidateDigitalMediaStore.getDigitalMediaStoreVersion() == 2, "Incorrect version.");
        currentDigitalMediaStore = candidateDigitalMediaStore;
        currentDigitalMediaStore.registerTokenContractAddress();
        currentStartingDigitalMediaId = currentDigitalMediaStore.getStartingDigitalMediaId();
    }

    /**
     * Publicly callable by the owner, but can only be set one time, so don't make 
     * a mistake when setting it.
     *
     * Will also check that the version on the other end of the contract is in fact correct.
     */
    function setV1DigitalMediaStoreAddress(address _dmsAddress) public onlyOwner {
        require(address(v1DigitalMediaStore) == 0, "V1 media store already set.");
        DigitalMediaStoreInterface candidateDigitalMediaStore = DigitalMediaStoreInterface(_dmsAddress);
        require(candidateDigitalMediaStore.getDigitalMediaStoreVersion() == 1, "Incorrect version.");
        v1DigitalMediaStore = candidateDigitalMediaStore;
        v1DigitalMediaStore.registerTokenContractAddress();
    }

    /**
     * Depending on the digital media id, determines whether to return the previous
     * version of the digital media manager.
     */
    function _getDigitalMediaStore(uint256 _digitalMediaId) 
            internal 
            view
            managersInitialized
            returns (DigitalMediaStoreInterface) {
        if (_digitalMediaId < currentStartingDigitalMediaId) {
            return v1DigitalMediaStore;
        } else {
            return currentDigitalMediaStore;
        }
    }  
}
