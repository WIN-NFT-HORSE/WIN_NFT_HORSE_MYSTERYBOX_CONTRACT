pragma solidity ^0.5.5;

/**
 * @title TRC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from TRC721 asset contracts.
 */
contract ITRC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The TRC721 smart contract calls this function on the recipient
     * after a {ITRC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onTRC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the TRC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onTRC721Received(address,address,uint256,bytes)"))`
     */
    function onTRC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}
