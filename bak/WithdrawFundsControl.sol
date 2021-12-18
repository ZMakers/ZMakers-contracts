pragma solidity 0.4.25;

import './Pausable.sol';

contract WithdrawFundsControl is Pausable {

	// List of approved on withdraw addresses
    mapping (address => uint256) public approvedWithdrawAddresses;

    // Full day wait period before an approved withdraw address becomes active
    uint256 constant internal withdrawApprovalWaitPeriod = 60 * 60 * 24;

    event WithdrawAddressAdded(address withdrawAddress);
    event WithdrawAddressRemoved(address widthdrawAddress);

	/**
     * Add a new approved on behalf of user address.
     */
    function addApprovedWithdrawAddress(address _withdrawAddress) external onlyOwner {
        approvedWithdrawAddresses[_withdrawAddress] = now;
        emit WithdrawAddressAdded(_withdrawAddress);
    }

    /**
     * Removes an approved on bhealf of user address.
     */
    function removeApprovedWithdrawAddress(address _withdrawAddress) external onlyOwner {
        delete approvedWithdrawAddresses[_withdrawAddress];
        emit WithdrawAddressRemoved(_withdrawAddress);
    }

    /**
     * Checks that a given withdraw address ia approved and is past it's required
     * wait time.
     */
    function isApprovedWithdrawAddress(address _withdrawAddress) internal view returns (bool)  {
        uint256 approvalTime = approvedWithdrawAddresses[_withdrawAddress];
        require (approvalTime > 0);
        return now - approvalTime > withdrawApprovalWaitPeriod;
    }
}
