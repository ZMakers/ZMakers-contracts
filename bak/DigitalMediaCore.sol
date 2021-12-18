pragma solidity 0.4.25;

import './DigitalMediaToken.sol';

/**
 * This is the main driver contract that is used to control and run the service. Funds 
 * are managed through this function, underlying contracts are also updated through 
 * this contract.
 *
 * This class also exposes a set of creation methods that are allowed to be created
 * by an approved token creator, on behalf of a particular address.  This is meant
 * to simply the creation flow for MakersToken users that aren't familiar with 
 * the blockchain.  The ERC721 tokens that are created are still fully compliant, 
 * although it is possible for a malicious token creator to mint unwanted tokens 
 * on behalf of a creator.  Worst case, the creator can burn those tokens.
 */
contract DigitalMediaCore is DigitalMediaToken {
    using SafeMath for uint32;

    // List of approved token creators (on behalf of the owner)
    mapping (address => bool) public approvedTokenCreators;

    // Mapping from owner to operator accounts.
    mapping (address => mapping (address => bool)) internal oboOperatorApprovals;

    // Mapping of all disabled OBO operators.
    mapping (address => bool) public disabledOboOperators;

    // OboApproveAll Event
    event OboApprovalForAll(
        address _owner, 
        address _operator, 
        bool _approved);

    // Fired when disbaling obo capability.
    event OboDisabledForAll(address _operator);

    constructor (
        string _tokenName, 
        string _tokenSymbol, 
        uint256 _tokenIdStartingCounter, 
        address _dmsAddress,
        address _crsAddress)
            public DigitalMediaToken(
                _tokenName, 
                _tokenSymbol,
                _tokenIdStartingCounter) {
        paused = true;
        setDigitalMediaStoreAddress(_dmsAddress);
        setCreatorRegistryStore(_crsAddress);
    }

    /**
     * Retrieves a Digital Media object.
     */
    function getDigitalMedia(uint256 _id) 
            external 
            view 
            returns (
            uint256 id,
            uint32 totalSupply,
            uint32 printIndex,
            uint256 collectionId,
            address creator,
            string metadataPath) {

        DigitalMedia memory digitalMedia = _getDigitalMedia(_id);
        require(digitalMedia.creator != address(0), "DigitalMedia not found.");
        id = _id;
        totalSupply = digitalMedia.totalSupply;
        printIndex = digitalMedia.printIndex;
        collectionId = digitalMedia.collectionId;
        creator = digitalMedia.creator;
        metadataPath = digitalMedia.metadataPath;
    }

    /**
     * Retrieves a collection.
     */
    function getCollection(uint256 _id) 
            external 
            view 
            returns (
            uint256 id,
            address creator,
            string metadataPath) {
        DigitalMediaCollection memory digitalMediaCollection = _getCollection(_id);
        require(digitalMediaCollection.creator != address(0), "Collection not found.");
        id = _id;
        creator = digitalMediaCollection.creator;
        metadataPath = digitalMediaCollection.metadataPath;
    }

    /**
     * Retrieves a Digital Media Release (i.e a token)
     */
    function getDigitalMediaRelease(uint256 _id) 
            external 
            view 
            returns (
            uint256 id,
            uint32 printEdition,
            uint256 digitalMediaId) {
        require(exists(_id));
        DigitalMediaRelease storage digitalMediaRelease = tokenIdToDigitalMediaRelease[_id];
        id = _id;
        printEdition = digitalMediaRelease.printEdition;
        digitalMediaId = digitalMediaRelease.digitalMediaId;
    }

    /**
     * Creates a new collection.
     *
     * No creations of any kind are allowed when the contract is paused.
     */
    function createCollection(string _metadataPath) 
            external 
            whenNotPaused {
        _createCollection(msg.sender, _metadataPath);
    }

    /**
     * Creates a new digital media object.
     */
    function createDigitalMedia(uint32 _totalSupply, uint256 _collectionId, string _metadataPath) 
            external 
            whenNotPaused {
        _createDigitalMedia(msg.sender, _totalSupply, _collectionId, _metadataPath);
    }

    /**
     * Creates a new digital media object and mints it's first digital media release token.
     *
     * No creations of any kind are allowed when the contract is paused.
     */
    function createDigitalMediaAndReleases(
                uint32 _totalSupply,
                uint256 _collectionId,
                string _metadataPath,
                uint32 _numReleases)
            external 
            whenNotPaused {
        uint256 digitalMediaId = _createDigitalMedia(msg.sender, _totalSupply, _collectionId, _metadataPath);
        _createDigitalMediaReleases(msg.sender, digitalMediaId, _numReleases);
    }

    /**
     * Creates a new collection, a new digital media object within it and mints a new
     * digital media release token.
     *
     * No creations of any kind are allowed when the contract is paused.
     */
    function createDigitalMediaAndReleasesInNewCollection(
                uint32 _totalSupply, 
                string _digitalMediaMetadataPath,
                string _collectionMetadataPath,
                uint32 _numReleases)
            external 
            whenNotPaused {
        uint256 collectionId = _createCollection(msg.sender, _collectionMetadataPath);
        uint256 digitalMediaId = _createDigitalMedia(msg.sender, _totalSupply, collectionId, _digitalMediaMetadataPath);
        _createDigitalMediaReleases(msg.sender, digitalMediaId, _numReleases);
    }

    /**
     * Creates a new digital media release (token) for a given digital media id.
     *
     * No creations of any kind are allowed when the contract is paused.
     */
    function createDigitalMediaReleases(uint256 _digitalMediaId, uint32 _numReleases) 
            external 
            whenNotPaused {
        _createDigitalMediaReleases(msg.sender, _digitalMediaId, _numReleases);
    }

    /**
     * Deletes a token / digital media release. Doesn't modify the current print index
     * and total to be printed. Although dangerous, the owner of a token should always 
     * be able to burn a token they own.
     *
     * Only the owner of the token or accounts approved by the owner can burn this token.
     */
    function burnToken(uint256 _tokenId) external {
        _burnToken(_tokenId, msg.sender);
    }

    /* Support ERC721 burn method */
    function burn(uint256 tokenId) public {
        _burnToken(tokenId, msg.sender);
    }

    /**
     * Ends the production run of a digital media.  Afterwards no more tokens
     * will be allowed to be printed for this digital media.  Used when a creator
     * makes a mistake and wishes to burn and recreate their digital media.
     * 
     * When a contract is paused we do not allow new tokens to be created, 
     * so stopping the production of a token doesn't have much purpose.
     */
    function burnDigitalMedia(uint256 _digitalMediaId) external whenNotPaused {
        _burnDigitalMedia(_digitalMediaId, msg.sender);
    }

    /**
     * Resets the approval rights for a given tokenId.
     */
    function resetApproval(uint256 _tokenId) external {
        clearApproval(msg.sender, _tokenId);
    }

    /**
     * Changes the creator for the current sender, in the event we 
     * need to be able to mint new tokens from an existing digital media 
     * print production. When changing creator, the old creator will
     * no longer be able to mint tokens.
     *
     * A creator may need to be changed:
     * 1. If we want to allow a creator to take control over their token minting (i.e go decentralized)
     * 2. If we want to re-issue private keys due to a compromise.  For this reason, we can call this function
     * when the contract is paused.
     * @param _creator the creator address
     * @param _newCreator the new creator address
     */
    function changeCreator(address _creator, address _newCreator) external {
        _changeCreator(msg.sender, _creator, _newCreator);
    }

    /**********************************************************************/
    /**Calls that are allowed to be called by approved creator addresses **/ 
    /**********************************************************************/
    
    /**
     * Add a new approved token creator.
     *
     * Only the owner of this contract can update approved Obo accounts.
     */
    function addApprovedTokenCreator(address _creatorAddress) external onlyOwner {
        require(disabledOboOperators[_creatorAddress] != true, "Address disabled.");
        approvedTokenCreators[_creatorAddress] = true;
    }

    /**
     * Removes an approved token creator.
     *
     * Only the owner of this contract can update approved Obo accounts.
     */
    function removeApprovedTokenCreator(address _creatorAddress) external onlyOwner {
        delete approvedTokenCreators[_creatorAddress];
    }

    /**
    * @dev Modifier to make the approved creation calls only callable by approved token creators
    */
    modifier isApprovedCreator() {
        require(
            (approvedTokenCreators[msg.sender] == true && 
             disabledOboOperators[msg.sender] != true), 
            "Unapproved OBO address.");
        _;
    }

    /**
     * Only the owner address can set a special obo approval list.
     * When issuing OBO management accounts, we should give approvals through
     * this method only so that we can very easily reset it's approval in
     * the event of a disaster scenario.
     *
     * Only the owner themselves is allowed to give OboApproveAll access.
     */
    function setOboApprovalForAll(address _to, bool _approved) public {
        require(_to != msg.sender, "Approval address is same as approver.");
        require(approvedTokenCreators[_to], "Unrecognized OBO address.");
        require(disabledOboOperators[_to] != true, "Approval address is disabled.");
        oboOperatorApprovals[msg.sender][_to] = _approved;
        emit OboApprovalForAll(msg.sender, _to, _approved);
    }

    /**
     * Only called in a disaster scenario if the account has been compromised.  
     * There's no turning back from this and the oboAddress will no longer be 
     * able to be given approval rights or perform obo functions.  
     * 
     * Only the owner of this contract is allowed to disable an Obo address.
     *
     */
    function disableOboAddress(address _oboAddress) public onlyOwner {
        require(approvedTokenCreators[_oboAddress], "Unrecognized OBO address.");
        disabledOboOperators[_oboAddress] = true;
        delete approvedTokenCreators[_oboAddress];
        emit OboDisabledForAll(_oboAddress);
    }

    /**
     * Override the isApprovalForAll to check for a special oboApproval list.  Reason for this
     * is that we can can easily remove obo operators if they every become compromised.
     */
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        if (disabledOboOperators[_operator] == true) {
            return false;
        } else if (isOperatorApprovedForCustodialAccount(_operator, _owner) == true) {
            return true;
        } else if (oboOperatorApprovals[_owner][_operator]) {
            return true;
        } else {
            return super.isApprovedForAll(_owner, _operator);
        }
    }

    /**
     * Creates a new digital media object and mints it's digital media release tokens.
     * Called on behalf of the _owner. Pass count to mint `n` number of tokens.
     *
     * Only approved creators are allowed to create Obo.
     *
     * No creations of any kind are allowed when the contract is paused.
     */
    function oboCreateDigitalMediaAndReleases(
                address _owner,
                uint32 _totalSupply, 
                uint256 _collectionId, 
                string _metadataPath,
                uint32 _numReleases)
            external 
            whenNotPaused
            isApprovedCreator {
        uint256 digitalMediaId = _createDigitalMedia(_owner, _totalSupply, _collectionId, _metadataPath);
        _createDigitalMediaReleases(_owner, digitalMediaId, _numReleases);
    }

    /**
     * Creates a new collection, a new digital media object within it and mints a new
     * digital media release token.
     * Called on behalf of the _owner.
     *
     * Only approved creators are allowed to create Obo.
     *
     * No creations of any kind are allowed when the contract is paused.
     */
    function oboCreateDigitalMediaAndReleasesInNewCollection(
                address _owner,
                uint32 _totalSupply, 
                string _digitalMediaMetadataPath,
                string _collectionMetadataPath,
                uint32 _numReleases)
            external 
            whenNotPaused
            isApprovedCreator {
        uint256 collectionId = _createCollection(_owner, _collectionMetadataPath);
        uint256 digitalMediaId = _createDigitalMedia(_owner, _totalSupply, collectionId, _digitalMediaMetadataPath);
        _createDigitalMediaReleases(_owner, digitalMediaId, _numReleases);
    }

    /**
     * Creates multiple digital media releases (tokens) for a given digital media id.
     * Called on behalf of the _owner.
     *
     * Only approved creators are allowed to create Obo.
     *
     * No creations of any kind are allowed when the contract is paused.
     */
    function oboCreateDigitalMediaReleases(
                address _owner,
                uint256 _digitalMediaId,
                uint32 _numReleases) 
            external 
            whenNotPaused
            isApprovedCreator {
        _createDigitalMediaReleases(_owner, _digitalMediaId, _numReleases);
    }
}