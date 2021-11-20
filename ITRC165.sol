pragma solidity ^0.5.5;

/**
 * @dev Interface of the TRC165 standard.
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({TRC165Checker}).
 *
 * For an implementation, see {TRC165}.
 */
interface ITRC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
