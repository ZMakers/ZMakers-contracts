pragma solidity ^0.4.25;

import './interfaces/DigitalMediaStoreInterface.sol';
import './libraries/SafeMath.sol';

contract DigitalMediaStore is DigitalMediaStoreInterface {
    using SafeMath for uint256;

    uint MediaStoreVersion;
    uint256 internal DigitalMediaId = 0;
    uint256 internal CollectionId = 0;

    struct DigitalMedia {
        uint256 id;
        address creator;
        uint32 printIndex;
        uint32 totalSupply;
        uint256 collectionId;
        string metadataPath;
    }
    
    struct Collection {
        uint256 id;
        address creator;
        string metadataPath;
    }
    
    mapping (uint256=>DigitalMedia) DigitalMedias; 
    mapping (uint256=>Collection) Collections; 

    function getDigitalMediaStoreVersion() public pure returns (uint) {
        uint _version = 2;
        return _version;
    }

    function getStartingDigitalMediaId() public view returns (uint256) {
        return MediaStoreVersion;
    }

    function registerTokenContractAddress() external{
        
    }

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
                string _metadataPath) external returns (uint) {
        Collection memory collection = Collections[_collectionId];
        require(collection.creator == _creator, 'Incorrect Creator, Fail to Create Digital Media!');
        DigitalMediaId = DigitalMediaId.add(1);
        DigitalMedia memory _digitalMedia = DigitalMedia({
            id: DigitalMediaId,
            creator: _creator,
            printIndex: _printIndex,
            totalSupply: _totalSupply,
            collectionId: _collectionId,
            metadataPath: _metadataPath
        });
        DigitalMedias[DigitalMediaId] = _digitalMedia;
        return DigitalMediaId;
    }

    /**
     * Increments the current print index of the digital media object
     * @param  _digitalMediaId uint256 the id of the digital media
     * @param  _increment uint32 the amount to increment by
     */
    function incrementDigitalMediaPrintIndex(
                uint256 _digitalMediaId, 
                uint32 _increment)  external {
        DigitalMedia storage _digitalMedia = DigitalMedias[_digitalMediaId];
        require(_digitalMedia.creator == msg.sender, 'Only creator can manipulate!');
        _digitalMedia.printIndex=uint32(uint256(_digitalMedia.printIndex).add(uint256(_increment)));
    }

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
                string metadataPath) {
        
        DigitalMedia memory dm = DigitalMedias[_digitalMediaId];
        id = _digitalMediaId;
        totalSupply = dm.totalSupply;
        printIndex = dm.printIndex;
        collectionId = dm.collectionId;
        creator = dm.creator;
        metadataPath = dm.metadataPath;
    }

    /**
     * Creates a new collection
     * @param  _creator address the address of the creator
     * @param  _metadataPath string the ipfs metadata path
     * @return the id of the new collection created
     */
    function createCollection(address _creator, string _metadataPath) external returns (uint) {
        CollectionId=CollectionId.add(1);
        Collection memory collection = Collection({
            id: CollectionId,
            creator: _creator,
            metadataPath: _metadataPath
        });
        Collections[CollectionId]=collection;
        return CollectionId;
    }

    /**
     * Retrieves a collection by id
     * @param  _collectionId uint256
     */
    function getCollection(uint256 _collectionId) external view
            returns(
                uint256 id,
                address creator,
                string metadataPath) {
        Collection memory collection = Collections[_collectionId];
        id=_collectionId;
        creator=collection.creator;
        require(creator != address(0),"Incorrect creator! Collection Not Found!");
        metadataPath=collection.metadataPath;
    }

}