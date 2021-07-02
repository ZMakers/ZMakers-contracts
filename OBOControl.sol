pragma solidity 0.4.25;

import './Pausable.sol';

contract OBOControl is Pausable {
	// List of approved on behalf of users.
    mapping (address => bool) public approvedOBOs;

	/**
     * Add a new approved on behalf of user address.
     */
    function addApprovedOBO(address _oboAddress) external onlyOwner {
        approvedOBOs[_oboAddress] = true;
    }

    /**
     * Removes an approved on bhealf of user address.
     */
    function removeApprovedOBO(address _oboAddress) external onlyOwner {
        delete approvedOBOs[_oboAddress];
    }

    /**
    * @dev Modifier to make the obo calls only callable by approved addressess
    */
    modifier isApprovedOBO() {
        require(approvedOBOs[msg.sender] == true);
        _;
    }
}
