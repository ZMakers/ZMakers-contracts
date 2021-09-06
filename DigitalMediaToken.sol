pragma solidity 0.4.25;

import './DigitalMediaManager.sol';
import './ERC721Safe.sol';
import './HelperUtils.sol';
import './SingleCreatorControl.sol';

/**
 * The DigitalMediaToken contract.  Fully implements the ERC721 contract
 * from OpenZeppelin without any modifications to it.
 * 
 * This contract allows for the creation of:
 *  1. New Collections
 *  2. New DigitalMedia objects
 *  3. New DigitalMediaRelease objects
 * 
 * The primary piece of logic is to ensure that an ERC721 token can 
 * have a supply and print edition that is enforced by this contract.
 */
contract DigitalMediaToken is DigitalMediaManager, ERC721Safe, HelperUtils, SingleCreatorControl {

    event DigitalMediaReleaseCreateEvent(
        uint256 id, 
        address owner,
        uint32 printEdition,
        string tokenURI, 
        uint256 digitalMediaId);

    // Event fired when a new digital media is created
    event DigitalMediaCreateEvent(
        uint256 id, 
        address storeContractAddress,
        address creator, 
        uint32 totalSupply, 
        uint32 printIndex, 
        uint256 collectionId, 
        string metadataPath);

    // Event fired when a digital media's collection is 
    event DigitalMediaCollectionCreateEvent(
        uint256 id, 
        address storeContractAddress,
        address creator, 
        string metadataPath);

    // Event fired when a digital media is burned
    event DigitalMediaBurnEvent(
        uint256 id,
        address caller,
        address storeContractAddress);

    // Event fired when burning a token
    event DigitalMediaReleaseBurnEvent(
        uint256 tokenId, 
        address owner);

    event UpdateDigitalMediaPrintIndexEvent(
        uint256 digitalMediaId,
        uint32 printEdition);

    // Event fired when a creator assigns a new creator address.
    event ChangedCreator(
        address creator,
        address newCreator);

    struct DigitalMediaRelease {
        // The unique edition number of this digital media release
        uint32 printEdition;

        // Reference ID to the digital media metadata
        uint256 digitalMediaId;
    }

    // Maps internal ERC721 token ID to digital media release object.
    mapping (uint256 => DigitalMediaRelease) public tokenIdToDigitalMediaRelease;

    // Maps a creator address to a new creator address.  Useful if a creator
    // changes their address or the previous address gets compromised.
    mapping (address => address) public approvedCreators;

    // Token ID counter
    uint256 internal tokenIdCounter = 0;

    constructor (string _tokenName, string _tokenSymbol, uint256 _tokenIdStartingCounter) 
            public ERC721Token(_tokenName, _tokenSymbol) {
        tokenIdCounter = _tokenIdStartingCounter;
    }

    /**
     * Creates a new digital media object.
     * @param  _creator address  the creator of this digital media
     * @param  _totalSupply uint32 the total supply a creation could have
     * @param  _collectionId uint256 the collectionId that it belongs to
     * @param  _metadataPath string the path to the ipfs metadata
     * @return uint the new digital media id
     */
    function _createDigitalMedia(
          address _creator, uint32 _totalSupply, uint256 _collectionId, string _metadataPath) 
          internal 
          returns (uint) {

        require(_validateCollection(_collectionId, _creator), "Creator for collection not approved.");

        uint256 newDigitalMediaId = currentDigitalMediaStore.createDigitalMedia(
            _creator,
            0, 
            _totalSupply,
            _collectionId,
            _metadataPath);

        emit DigitalMediaCreateEvent(
            newDigitalMediaId,
            address(currentDigitalMediaStore),
            _creator,
            _totalSupply,
            0,
            _collectionId,
            _metadataPath);

        return newDigitalMediaId;
    }

    /**
     * Burns a token for a given tokenId and caller.
     * @param  _tokenId the id of the token to burn.
     * @param  _caller the address of the caller.
     */
    function _burnToken(uint256 _tokenId, address _caller) internal {
        address owner = ownerOf(_tokenId);
        require(_caller == owner || 
                getApproved(_tokenId) == _caller || 
                isApprovedForAll(owner, _caller),
                "Failed token burn.  Caller is not approved.");
        _burn(owner, _tokenId);
        delete tokenIdToDigitalMediaRelease[_tokenId];
        emit DigitalMediaReleaseBurnEvent(_tokenId, owner);
    }

    /**
     * Burns a digital media.  Once this function succeeds, this digital media
     * will no longer be able to mint any more tokens.  Existing tokens need to be 
     * burned individually though.
     * @param  _digitalMediaId the id of the digital media to burn
     * @param  _caller the address of the caller.
     */
    function _burnDigitalMedia(uint256 _digitalMediaId, address _caller) internal {
        DigitalMedia memory _digitalMedia = _getDigitalMedia(_digitalMediaId);
        require(_checkApprovedCreator(_digitalMedia.creator, _caller) || 
                isApprovedForAll(_digitalMedia.creator, _caller), 
                "Failed digital media burn.  Caller not approved.");

        uint32 increment = _digitalMedia.totalSupply - _digitalMedia.printIndex;
        _incrementDigitalMediaPrintIndex(_digitalMedia, increment);
        address _burnDigitalMediaStoreAddress = address(_getDigitalMediaStore(_digitalMedia.id));
        emit DigitalMediaBurnEvent(
          _digitalMediaId, _caller, _burnDigitalMediaStoreAddress);
    }

    /**
     * Creates a new collection
     * @param  _creator address the creator of this collection
     * @param  _metadataPath string the path to the collection ipfs metadata
     * @return uint the new collection id
     */
    function _createCollection(
          address _creator, string _metadataPath) 
          internal 
          returns (uint) {
        uint256 newCollectionId = currentDigitalMediaStore.createCollection(
            _creator,
            _metadataPath);

        emit DigitalMediaCollectionCreateEvent(
            newCollectionId,
            address(currentDigitalMediaStore),
            _creator,
            _metadataPath);

        return newCollectionId;
    }

    /**
     * Creates _count number of new digital media releases (i.e a token).  
     * Bumps up the print index by _count.
     * @param  _owner address the owner of the digital media object
     * @param  _digitalMediaId uint256 the digital media id
     */
    function _createDigitalMediaReleases(
        address _owner, uint256 _digitalMediaId, uint32 _count)
        internal {

        require(_count > 0, "Failed print edition.  Creation count must be > 0.");
        require(_count < 10000, "Cannot print more than 10K tokens at once");
        DigitalMedia memory _digitalMedia = _getDigitalMedia(_digitalMediaId);
        uint32 currentPrintIndex = _digitalMedia.printIndex;
        require(_checkApprovedCreator(_digitalMedia.creator, _owner), "Creator not approved.");
        require(isAllowedSingleCreator(_owner), "Creator must match single creator address.");
        require(_count + currentPrintIndex <= _digitalMedia.totalSupply, "Total supply exceeded.");
        
        string memory tokenURI = HelperUtils.strConcat("ipfs://ipfs/", _digitalMedia.metadataPath);

        for (uint32 i=0; i < _count; i++) {
            uint32 newPrintEdition = currentPrintIndex + 1 + i;
            DigitalMediaRelease memory _digitalMediaRelease = DigitalMediaRelease({
                printEdition: newPrintEdition,
                digitalMediaId: _digitalMediaId
            });

            uint256 newDigitalMediaReleaseId = _getNextTokenId();
            tokenIdToDigitalMediaRelease[ ] = _digitalMediaRelease;
        
            emit DigitalMediaReleaseCreateEvent(
                newDigitalMediaReleaseId,
                _owner,
                newPrintEdition,
                tokenURI,
                _digitalMediaId
            );

            // This will assign ownership and also emit the Transfer event as per ERC721
            _mint(_owner, newDigitalMediaReleaseId);
            _setTokenURI(newDigitalMediaReleaseId, tokenURI);
            tokenIdCounter = tokenIdCounter.add(1);

        }
        _incrementDigitalMediaPrintIndex(_digitalMedia, _count);
        emit UpdateDigitalMediaPrintIndexEvent(_digitalMediaId, currentPrintIndex + _count);
    }

    /**
     * Checks that a given caller is an approved creator and is allowed to mint or burn
     * tokens.  If the creator was changed it will check against the updated creator.
     * @param  _caller the calling address
     * @return bool allowed or not
     */
    function _checkApprovedCreator(address _creator, address _caller) 
            internal 
            view 
            returns (bool) {
        address approvedCreator = approvedCreators[_creator];
        if (approvedCreator != address(0)) {
            return approvedCreator == _caller;
        } else {
            return _creator == _caller;
        }
    }

    /**
     * Validates the an address is allowed to create a digital media on a
     * given collection.  Collections are tied to addresses.
     */
    function _validateCollection(uint256 _collectionId, address _address) 
            private 
            view 
            returns (bool) {
        if (_collectionId == 0 ) {
            return true;
        }

        DigitalMediaCollection memory collection = _getCollection(_collectionId);
        return _checkApprovedCreator(collection.creator, _address);
    }

    /**
    * Generates a new token id.
    */
    function _getNextTokenId() private view returns (uint256) {
        return tokenIdCounter.add(1); 
    }

    /**
     * Changes the creator that is approved to printing new tokens and creations.
     * Either the _caller must be the _creator or the _caller must be the existing
     * approvedCreator.
     * @param _caller the address of the caller
     * @param  _creator the address of the current creator
     * @param  _newCreator the address of the new approved creator
     */
    function _changeCreator(address _caller, address _creator, address _newCreator) internal {
        address approvedCreator = approvedCreators[_creator];
        require(_caller != address(0) && _creator != address(0), "Creator must be valid non 0x0 address.");
        require(_caller == _creator || _caller == approvedCreator, "Unauthorized caller.");
        if (approvedCreator == address(0)) {
            approvedCreators[_caller] = _newCreator;
        } else {
            require(_caller == approvedCreator, "Unauthorized caller.");
            approvedCreators[_creator] = _newCreator;
        }
        emit ChangedCreator(_creator, _newCreator);
    }

    /**
     * Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
     */
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

}
