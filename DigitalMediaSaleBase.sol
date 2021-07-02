pragma solidity 0.4.25;

import './ERC721Holder.sol';
import './Pausable.sol';
import './OBOControl.sol';
import './WithdrawFundsControl.sol';
import './libraries/SafeMath.sol';
import './ERC721Safe.sol';

/**
 * Base class that manages the underlying functions of a Digital Media Sale,
 * most importantly the escrow of digital tokens.
 *
 * Manages ensuring that only approved addresses interact with this contract.
 *
 */
contract DigitalMediaSaleBase is ERC721Holder, Pausable, OBOControl, WithdrawFundsControl {
    using SafeMath for uint256;

     // Mapping of token contract address to bool indicated approval.
    mapping (address => bool) public approvedTokenContracts;

    /**
     * Adds a new token contract address to be approved to be called.
     */
    function addApprovedTokenContract(address _tokenContractAddress) 
            public onlyOwner {
        approvedTokenContracts[_tokenContractAddress] = true;
    }

    /**
     * Remove an approved token contract address from the list of approved addresses.
     */
    function removeApprovedTokenContract(address _tokenContractAddress) 
            public onlyOwner {            
        delete approvedTokenContracts[_tokenContractAddress];
    }

    /**
     * Checks that a particular token contract address is a valid address.
     */
    function _isValidTokenContract(address _tokenContractAddress) 
            internal view returns (bool) {
        return approvedTokenContracts[_tokenContractAddress];
    }

    /**
     * Returns an ERC721 instance of a token contract address.  Throws otherwise.
     * Only valid and approved token contracts are allowed to be interacted with.
     */
    function _getTokenContract(address _tokenContractAddress) internal view returns (ERC721Safe) {
        require(_isValidTokenContract(_tokenContractAddress));
        return ERC721Safe(_tokenContractAddress);
    }

    /**
     * Checks with the ERC-721 token contract that the _claimant actually owns the token.
     */
    function _owns(address _claimant, uint256 _tokenId, address _tokenContractAddress) internal view returns (bool) {
        ERC721Safe tokenContract = _getTokenContract(_tokenContractAddress);
        return (tokenContract.ownerOf(_tokenId) == _claimant);
    }

    /**
     * Checks with the ERC-721 token contract the owner of the a token
     */
    function _ownerOf(uint256 _tokenId, address _tokenContractAddress) internal view returns (address) {
        ERC721Safe tokenContract = _getTokenContract(_tokenContractAddress);
        return tokenContract.ownerOf(_tokenId);
    }

    /**
     * Checks to ensure that the token owner has approved the escrow contract 
     */
    function _approvedForEscrow(address _seller, uint256 _tokenId, address _tokenContractAddress) internal view returns (bool) {
        ERC721Safe tokenContract = _getTokenContract(_tokenContractAddress);
        return (tokenContract.isApprovedForAll(_seller, this) || 
                tokenContract.getApproved(_tokenId) == address(this));
    }

    /**
     * Escrows an ERC-721 token from the seller to this contract.  Assumes that the escrow contract
     * is already approved to make the transfer, otherwise it will fail.
     */
    function _escrow(address _seller, uint256 _tokenId, address _tokenContractAddress) internal {
        // it will throw if transfer fails
        ERC721Safe tokenContract = _getTokenContract(_tokenContractAddress);
        tokenContract.safeTransferFrom(_seller, this, _tokenId);
    }

    /**
     * Transfer an ERC-721 token from escrow to the buyer.  This is to be called after a purchase is
     * completed.
     */
    function _transfer(address _receiver, uint256 _tokenId, address _tokenContractAddress) internal {
        // it will throw if transfer fails
        ERC721Safe tokenContract = _getTokenContract(_tokenContractAddress);
        tokenContract.safeTransferFrom(this, _receiver, _tokenId);
    }

    /**
     * Method to check whether this is an escrow contract
     */
    function isEscrowContract() public pure returns(bool) {
        return true;
    }

    /**
     * Withdraws all the funds to a specified non-zero address
     */
    function withdrawFunds(address _withdrawAddress) public onlyOwner {
        require(isApprovedWithdrawAddress(_withdrawAddress));
        _withdrawAddress.transfer(address(this).balance);
    }
}
