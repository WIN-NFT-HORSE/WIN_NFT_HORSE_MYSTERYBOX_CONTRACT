pragma solidity ^0.5.0;

import "./ITRC721.sol";
/**
 * @title TRC-721 Non-Fungible Token Standard, optional enumeration extension
 */
contract ITRC721Enumerable is ITRC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}
