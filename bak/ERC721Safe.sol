pragma solidity ^0.4.25;
import './ERC721Token.sol';

contract ERC721Safe is ERC721Token {
    bytes4 constant internal InterfaceSignature_ERC165 =
        bytes4(keccak256('supportsInterface(bytes4)'));

    bytes4 constant internal InterfaceSignature_ERC721 =
        bytes4(keccak256('name()')) ^
        bytes4(keccak256('symbol()')) ^
        bytes4(keccak256('totalSupply()')) ^
        bytes4(keccak256('balanceOf(address)')) ^
        bytes4(keccak256('ownerOf(uint256)')) ^
        bytes4(keccak256('approve(address,uint256)')) ^
        bytes4(keccak256('safeTransferFrom(address,address,uint256)'));
	
   function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}
