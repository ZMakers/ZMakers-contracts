pragma solidity 0.4.25;


/**
 * Interface to the digital media store external contract that is 
 * responsible for storing the common digital media and collection data.
 * This allows for new token contracts to be deployed and continue to reference
 * the digital media and collection data.
 */
contract DigitalMediaStoreInterface {

    function getDigitalMediaStoreVersion() public pure returns (uint);

    function getStartingDigitalMediaId() public view returns (uint256);

    function registerTokenContractAddress() external;

    /**
     * Creates a new digital media object in storage
     * @param  _creator address the address of the creator
     * @param  _printIndex uint32 the current print index for the limited edition media
     * @param  _totalSupply uint32 the total allowable prints for this media
     * @param  _collectionId uint256 the collection id that this media belongs to
     * @param  _metadataPath string the ipfs metadata path
     * @return the id of the new digital media created
     */
    function createDigitalMedia(
                address _creator, 
                uint32 _printIndex, 
                uint32 _totalSupply, 
                uint256 _collectionId, 
                string _metadataPath) external returns (uint);

    /**
     * Increments the current print index of the digital media object
     * @param  _digitalMediaId uint256 the id of the digital media
     * @param  _increment uint32 the amount to increment by
     */
    function incrementDigitalMediaPrintIndex(
                uint256 _digitalMediaId, 
                uint32 _increment)  external;

    /**
     * Retrieves the digital media object by id
     * @param  _digitalMediaId uint256 the address of the creator
     */
    function getDigitalMedia(uint256 _digitalMediaId) external view returns(
                uint256 id,
                uint32 totalSupply,
                uint32 printIndex,
                uint256 collectionId,
                address creator,
                string metadataPath);

    /**
     * Creates a new collection
     * @param  _creator address the address of the creator
     * @param  _metadataPath string the ipfs metadata path
     * @return the id of the new collection created
     */
    function createCollection(address _creator, string _metadataPath) external returns (uint);

    /**
     * Retrieves a collection by id
     * @param  _collectionId uint256
     */
    function getCollection(uint256 _collectionId) external view
            returns(
                uint256 id,
                address creator,
                string metadataPath);
}

