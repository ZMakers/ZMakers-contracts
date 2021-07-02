pragma solidity 0.4.25;


import './MediaStoreVersionControl.sol';
import './interfaces/ApprovedCreatorRegistryInterface.sol';

/**
 * Manager that interfaces with the underlying digital media store contract.
 */
contract DigitalMediaManager is MediaStoreVersionControl {

    struct DigitalMedia {
        uint256 id;
        uint32 totalSupply;
        uint32 printIndex;
        uint256 collectionId;
        address creator;
        string metadataPath;
    }

    struct DigitalMediaCollection {
        uint256 id;
        address creator;
        string metadataPath;
    }

    ApprovedCreatorRegistryInterface public creatorRegistryStore;

    // Set the creator registry address upon construction. Immutable.
    function setCreatorRegistryStore(address _crsAddress) internal {
        ApprovedCreatorRegistryInterface candidateCreatorRegistryStore = ApprovedCreatorRegistryInterface(_crsAddress);
        require(candidateCreatorRegistryStore.getVersion() == 1);
        // Simple check to make sure we are adding the registry contract indeed
        // https://fravoll.github.io/solidity-patterns/string_equality_comparison.html
        require(keccak256(candidateCreatorRegistryStore.typeOfContract()) == keccak256("approvedCreatorRegistry"));
        creatorRegistryStore = candidateCreatorRegistryStore;
    }

    /**
     * Validates that the Registered store is initialized.
     */
    modifier registryInitialized() {
        require(creatorRegistryStore != address(0));
        _;
    }

    /**
     * Retrieves a collection object by id.
     */
    function _getCollection(uint256 _id) 
            internal 
            view 
            managersInitialized 
            returns(DigitalMediaCollection) {
        uint256 id;
        address creator;
        string memory metadataPath;
        (id, creator, metadataPath) = currentDigitalMediaStore.getCollection(_id);
        DigitalMediaCollection memory collection = DigitalMediaCollection({
            id: id,
            creator: creator,
            metadataPath: metadataPath
        });
        return collection;
    }

    /**
     * Retrieves a digital media object by id.
     */
    function _getDigitalMedia(uint256 _id) 
            internal 
            view 
            managersInitialized 
            returns(DigitalMedia) {
        uint256 id;
        uint32 totalSupply;
        uint32 printIndex;
        uint256 collectionId;
        address creator;
        string memory metadataPath;
        DigitalMediaStoreInterface _digitalMediaStore = _getDigitalMediaStore(_id);
        (id, totalSupply, printIndex, collectionId, creator, metadataPath) = _digitalMediaStore.getDigitalMedia(_id);
        DigitalMedia memory digitalMedia = DigitalMedia({
            id: id,
            creator: creator,
            totalSupply: totalSupply,
            printIndex: printIndex,
            collectionId: collectionId,
            metadataPath: metadataPath
        });
        return digitalMedia;
    }

    /**
     * Increments the print index of a digital media object by some increment.
     */
    function _incrementDigitalMediaPrintIndex(DigitalMedia _dm, uint32 _increment) 
            internal 
            managersInitialized {
        DigitalMediaStoreInterface _digitalMediaStore = _getDigitalMediaStore(_dm.id);
        _digitalMediaStore.incrementDigitalMediaPrintIndex(_dm.id, _increment);
    }

    // Check if the token operator is approved for the owner address
    function isOperatorApprovedForCustodialAccount(
        address _operator, 
        address _owner) internal view registryInitialized returns(bool) {
        return creatorRegistryStore.isOperatorApprovedForCustodialAccount(
            _operator, _owner);
    }
}
