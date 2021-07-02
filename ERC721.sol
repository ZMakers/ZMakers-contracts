pragma solidity ^0.4.21;

import './interfaces/ERC721Basic.sol';
import './interfaces/ERC721Enumberable.sol';
import './interfaces/ERC721Metadata.sol';

contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}