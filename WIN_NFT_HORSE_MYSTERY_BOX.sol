pragma solidity ^0.5.0;

import "./ITRC721Enumerable.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./TRC165.sol";
import "./IERC721Metadata.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./EnumerableSet.sol";
import "./EnumerableMap.sol";
import "./Strings.sol";
import "./ITRC721Receiver.sol";

contract ITpunks is ITRC721Enumerable {
    // function isMintedBeforeReveal(uint256 index) external view returns (bool);
}

/**
 * @title Tpunks contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract WIN_NFT_HORSE_MYSTERY_BOX is Context, Ownable, TRC165, ITpunks, IERC721Metadata {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Public variables

    // This is the provenance record of all artwork in existence
    // openssl dgst -sha256 punks-modify.png
    string public constant Tpunk_PROVENANCE = "ffa993388253d151e96ed2d68f9ed78b3f1ac2bc6e2c5cf5041d30897dd2943d";

    uint256 public MAX_NFT_SUPPLY = 0;

    // uint256 public startingIndexBlock;

    // uint256 public startingIndex;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _TRC721_RECEIVED = 0x5175f878;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping(address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from token ID to name
    mapping(uint256 => string) private _tokenName;

    // Mapping if certain name string has already been reserved
    mapping(string => bool) private _nameReserved;

    // Mapping from token ID to whether minted before reveal
    mapping(uint256 => bool) private _mintedBeforeReveal;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    uint256 private _price = 0;

    // for randomized
    uint256[10] private punks_index = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

    uint256[10] private punks_index_exists = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

    uint256 private punks_index_exists_length = 10;

    uint256 public punks_per_colum = 0;

    uint256 private nonce = 0;

    // for intvite
    struct userAirdrop {
        bool isExists;
        uint256 id;
        // mapping (uint256 => address) referral;
        uint256 referral_buy_index;
    }

    mapping(address => userAirdrop) public usersAirdrop;

    mapping(uint256 => address) public usersAirdropAddress;

    uint256 public airDrop_id = 1000;

    uint256 public airDrop_reward = 100;

    mapping(uint256 => address) public winners;

    function startAirDrop() public returns (uint256){

        require(!usersAirdrop[msg.sender].isExists, 'This account already started airdrop');

        userAirdrop memory ua = userAirdrop({
        isExists : true,
        id : airDrop_id,
        referral_buy_index : 0
        });

        usersAirdrop[msg.sender] = ua;

        usersAirdropAddress[airDrop_id] = msg.sender;

        airDrop_id++;

        return usersAirdrop[msg.sender].id;

    }


    // initialize
    bool private start_sale = true;


    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_TRC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *
     *     => 0x06fdde03 ^ 0x95d89b41 == 0x93254542
     */
    bytes4 private constant _INTERFACE_ID_TRC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_TRC721_ENUMERABLE = 0x780e9d63;

    // Events
    event NameChange (uint256 indexed maskIndex, string newName);

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name, string memory symbol, uint256 price, uint256 max_supply) public {
        _name = name;
        _symbol = symbol;
        _price = price;
        MAX_NFT_SUPPLY = max_supply;
        punks_per_colum = max_supply / 10;

        // register the supported interfaces to conform to TRC721 via TRC165
        _registerInterface(_INTERFACE_ID_TRC721);
        _registerInterface(_INTERFACE_ID_TRC721_METADATA);
        _registerInterface(_INTERFACE_ID_TRC721_ENUMERABLE);
    }

    function initializeOwners(address[] memory users, uint256 _column) onlyOwner public {
        require(!start_sale, 'You can not do it when sale is start');

        for (uint256 i = 0; i < users.length; i++) {

            uint256 p_index = ((punks_index[_column]) + ((_column * punks_per_colum)));

            _safeMint(users[i], p_index);

            punks_index[_column]++;
        }
    }

    function finishInitilizeOwners() onlyOwner public {
        start_sale = true;
    }

    function startInitilizeOwners() onlyOwner public {
        start_sale = false;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "TRC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        return _tokenOwners.get(tokenId, "TRC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view returns (uint256) {
        (uint256 tokenId,) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev Gets current Tpunk Price
     */
    function getNFTPrice() public view returns (uint256) {
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        return _price;
    }

    function setNFTPrice(uint256 value) public onlyOwner {
        _price = value;
    }

    function setMaxSupply(uint256 value) public onlyOwner {
        MAX_NFT_SUPPLY = value;
        punks_per_colum = value / 10;
    }

    /**
    * @dev Mints Tpunk
    */
    function mintNFT() public payable returns (uint256)  {
        require(start_sale, 'sale is not start');
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        require(totalSupply().add(1) <= MAX_NFT_SUPPLY, "Exceeds MAX_NFT_SUPPLY");
        require(getNFTPrice().mul(1) == msg.value, "Trx value sent is not correct");

        uint256 mintIndex = getNextPunkIndex();
        _safeMint(msg.sender, mintIndex);


        nonce = 0;

        (bool success,) = address(uint160(owner())).call.value(msg.value)("");
        require(success, "Address: unable to send value, recipient may have reverted");
        return mintIndex;
    }

    /**
   * @dev Mints Tpunk
   */
    function mintNFT_To(address to) public payable returns (uint256)  {
        require(start_sale, 'sale is not start');
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        require(totalSupply().add(1) <= MAX_NFT_SUPPLY, "Exceeds MAX_NFT_SUPPLY");
        require(getNFTPrice().mul(1) == msg.value, "Trx value sent is not correct");

        uint256 mintIndex = getNextPunkIndex();
        _safeMint(to, mintIndex);


        nonce = 0;

        (bool success,) = address(uint160(owner())).call.value(msg.value)("");
        require(success, "Address: unable to send value, recipient may have reverted");
        return mintIndex;
    }

    /**
    * @dev Mints Tpunk
    */
    function mintNFTAirDrop(uint256 numberOfNfts, uint256 _airDrop_id) public payable {
        require(start_sale, 'sale is not start');
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        require(numberOfNfts > 0, "numberOfNfts cannot be 0");
        require(numberOfNfts <= 20, "You may not buy more than 20 NFTs at once");
        require(totalSupply().add(numberOfNfts) <= MAX_NFT_SUPPLY, "Exceeds MAX_NFT_SUPPLY");
        require(getNFTPrice().mul(numberOfNfts) == msg.value, "Trx value sent is not correct");

        uint256 msgValue = msg.value;

        for (uint i = 0; i < numberOfNfts; i++) {
            uint256 mintIndex = getNextPunkIndex();
            _safeMint(msg.sender, mintIndex);
        }

        nonce = 0;

        if (usersAirdrop[usersAirdropAddress[_airDrop_id]].isExists) {

            if (usersAirdropAddress[_airDrop_id] != msg.sender) {

                usersAirdrop[usersAirdropAddress[_airDrop_id]].referral_buy_index = usersAirdrop[usersAirdropAddress[_airDrop_id]].referral_buy_index + numberOfNfts;

                address ads = usersAirdropAddress[_airDrop_id];
                address _fads = ads;

                for (uint256 i = 0; i < 5; i++) {

                    address wads = winners[i];

                    if (usersAirdrop[wads].isExists) {

                        if (wads == _fads) {
                            winners[i] = ads;
                            break;
                        } else if (usersAirdrop[ads].referral_buy_index > usersAirdrop[wads].referral_buy_index) {
                            winners[i] = ads;
                            ads = wads;
                        }

                    } else {
                        winners[i] = ads;
                        break;
                    }


                }

                uint256 amount = airDrop_reward * numberOfNfts;

                msgValue = msgValue - amount;

                (bool success,) = address(uint160(usersAirdropAddress[_airDrop_id])).call.value(amount)("");
                require(success, "Address: unable to send value, recipient may have reverted");
            }

        }

        (bool success,) = address(uint160(owner())).call.value(msgValue)("");
        require(success, "Address: unable to send value, recipient may have reverted");


    }

    /**
     * @dev Withdraw ether from this contract (Callable by owner)
    */
    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }


    function getNextPunkIndex() private returns (uint256){


        if (punks_index_exists_length > 1) {
            nonce++;
            for (uint256 i = 0; i < punks_index_exists_length; i++) {
                uint256 n = i + uint256(keccak256(abi.encodePacked(now + nonce))) % (punks_index_exists_length - i);
                uint256 temp = punks_index_exists[n];
                punks_index_exists[n] = punks_index_exists[i];
                punks_index_exists[i] = temp;
            }
        } else if (punks_index[punks_index_exists[0]] == punks_per_colum) {
            revert("we don't have any item !");
        }

        uint256 p_index = ((punks_index[punks_index_exists[0]]) + ((punks_index_exists[0] * punks_per_colum)));

        punks_index[punks_index_exists[0]]++;

        if (punks_index[punks_index_exists[0]] >= punks_per_colum) {
            punks_index_exists_length--;
            punks_index_exists[0] = punks_index_exists[punks_index_exists_length];
        }

        return p_index;

    }


    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "TRC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view returns (address) {

        require(_exists(tokenId), "TRC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public {
        require(operator != _msgSender(), "TRC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "TRC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "TRC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnTRC721Received(from, to, tokenId, _data), "TRC721: transfer to non TRC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "TRC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal {
        require(totalSupply() < MAX_NFT_SUPPLY);
        _safeMint(to, tokenId, "");

    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
        _mint(to, tokenId);
        require(totalSupply() < MAX_NFT_SUPPLY);
        require(_checkOnTRC721Received(address(0), to, tokenId, _data), "TRC721: transfer to non TRC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "TRC721: mint to the zero address");
        require(!_exists(tokenId), "TRC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "TRC721: transfer of token that is not own");
        require(to != address(0), "TRC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }


    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnTRC721Received(address from, address to, uint256 tokenId, bytes memory _data)
    internal returns (bool)
    {
        if (!to.isContract) {
            return true;
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(
                ITRC721Receiver(to).onTRC721Received.selector,
                _msgSender(),
                from,
                tokenId,
                _data
            ));
        if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("TRC721: transfer to non TRC721Receiver implementer");
            }
        } else {
            bytes4 retval = abi.decode(returndata, (bytes4));
            return (retval == _TRC721_RECEIVED);
        }
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal {}

}
