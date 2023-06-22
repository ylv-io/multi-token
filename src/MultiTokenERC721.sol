// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./WrappedERC721.sol";

contract MultiTokenERC721 is Ownable, IERC721Errors {
  // Mapping from token ID to owner address
  mapping(address => mapping(uint256 => address)) private _owners;

  // Mapping owner address to token count
  mapping(address => mapping(address => uint256)) private _balances;

  // Mapping from token ID to approved address
  mapping(address => mapping(uint256 => address)) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => mapping(address => bool))) private _operatorApprovals;

  // Mapping for approved tokens
  mapping(address => bool) private _tokens;

  event TokenAdded(address indexed token);

  modifier onlyToken(address token) {
    require(_tokens[token], "MultiToken: Not a valid token");
    _;
  }

  constructor() Ownable(msg.sender) {}

  function addToken(address token) public onlyOwner {
    _tokens[token] = true;
    emit TokenAdded(token);
  }

  function balanceOf(address token, address owner) public view virtual returns (uint256) {
    if (owner == address(0)) {
      revert ERC721InvalidOwner(address(0));
    }
    return _balances[token][owner];
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(address token, uint256 tokenId) public view virtual returns (address) {
    address owner = _ownerOf(token, tokenId);
    if (owner == address(0)) {
      revert ERC721NonexistentToken(tokenId);
    }
    return owner;
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(
    address token,
    address sender,
    address to,
    uint256 tokenId
  ) public virtual {
    address owner = ownerOf(token, tokenId);
    if (to == owner) {
      revert ERC721InvalidOperator(owner);
    }

    if (sender != owner && !isApprovedForAll(token, owner, sender)) {
      revert ERC721InvalidApprover(sender);
    }

    _approve(token, to, tokenId);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(address token, uint256 tokenId) public view virtual returns (address) {
    _requireMinted(token, tokenId);

    return _tokenApprovals[token][tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(
    address token,
    address sender,
    address operator,
    bool approved
  ) public virtual {
    _setApprovalForAll(token, sender, operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(
    address token,
    address owner,
    address operator
  ) public view virtual returns (bool) {
    return _operatorApprovals[token][owner][operator];
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address token,
    address sender,
    address from,
    address to,
    uint256 tokenId
  ) public virtual {
    if (!_isApprovedOrOwner(token, sender, tokenId)) {
      revert ERC721InsufficientApproval(sender, tokenId);
    }

    _transfer(token, from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address token,
    address sender,
    address from,
    address to,
    uint256 tokenId
  ) public virtual {
    safeTransferFrom(token, sender, from, to, tokenId, "");
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address token,
    address sender,
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public virtual {
    if (!_isApprovedOrOwner(token, sender, tokenId)) {
      revert ERC721InsufficientApproval(sender, tokenId);
    }
    _safeTransfer(token, sender, from, to, tokenId, data);
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
  function _safeTransfer(
    address token,
    address sender,
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) internal virtual {
    _transfer(token, from, to, tokenId);
    if (!_checkOnERC721Received(sender, from, to, tokenId, data)) {
      revert ERC721InvalidReceiver(to);
    }
  }

  /**
   * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
   */
  function _ownerOf(address token, uint256 tokenId) internal view virtual returns (address) {
    return _owners[token][tokenId];
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   * and stop existing when they are burned (`_burn`).
   */
  function _exists(address token, uint256 tokenId) internal view virtual returns (bool) {
    return _ownerOf(token, tokenId) != address(0);
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _isApprovedOrOwner(
    address token,
    address spender,
    uint256 tokenId
  ) internal view virtual returns (bool) {
    address owner = ownerOf(token, tokenId);
    return (spender == owner || isApprovedForAll(token, owner, spender) || getApproved(token, tokenId) == spender);
  }

  /**
   * @dev Safely mints `tokenId` and transfers it to `to`.
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(
    address token,
    address sender,
    address to,
    uint256 tokenId
  ) internal virtual {
    _safeMint(token, sender, to, tokenId, "");
  }

  /**
   * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
   * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
   */
  function _safeMint(
    address token,
    address sender,
    address to,
    uint256 tokenId,
    bytes memory data
  ) internal virtual {
    _mint(token, to, tokenId);
    if (!_checkOnERC721Received(sender, address(0), to, tokenId, data)) {
      revert ERC721InvalidReceiver(to);
    }
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
  function _mint(
    address token,
    address to,
    uint256 tokenId
  ) internal virtual {
    if (to == address(0)) {
      revert ERC721InvalidReceiver(address(0));
    }
    if (_exists(token, tokenId)) {
      revert ERC721InvalidSender(address(0));
    }

    _beforeTokenTransfer(address(0), to, tokenId, 1);

    // Check that tokenId was not minted by `_beforeTokenTransfer` hook
    if (_exists(token, tokenId)) {
      revert ERC721InvalidSender(address(0));
    }

    unchecked {
      // Will not overflow unless all 2**256 token ids are minted to the same owner.
      // Given that tokens are minted one by one, it is impossible in practice that
      // this ever happens. Might change if we allow batch minting.
      // The ERC fails to describe this case.
      _balances[token][to] += 1;
    }

    _owners[token][tokenId] = to;

    // Emit Transfer event on the token
    WrappedERC721(token).emitTransfer(address(0), to, tokenId);

    _afterTokenTransfer(address(0), to, tokenId, 1);
  }

  /**
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   * This is an internal function that does not check if the sender is authorized to operate on the token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function _burn(address token, uint256 tokenId) internal virtual {
    address owner = ownerOf(token, tokenId);

    // Clear approvals
    delete _tokenApprovals[token][tokenId];

    // Decrease balance with checked arithmetic, because an `ownerOf` override may
    // invalidate the assumption that `_balances[from] >= 1`.
    _balances[token][owner] -= 1;

    delete _owners[token][tokenId];

    // Emit Transfer event on the token
    WrappedERC721(token).emitTransfer(owner, address(0), tokenId);

    _afterTokenTransfer(owner, address(0), tokenId, 1);
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
  function _transfer(
    address token,
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {
    address owner = ownerOf(token, tokenId);
    if (owner != from) {
      revert ERC721IncorrectOwner(from, tokenId, owner);
    }
    if (to == address(0)) {
      revert ERC721InvalidReceiver(address(0));
    }

    _beforeTokenTransfer(from, to, tokenId, 1);

    // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
    owner = ownerOf(token, tokenId);
    if (owner != from) {
      revert ERC721IncorrectOwner(from, tokenId, owner);
    }

    // Clear approvals from the previous owner
    delete _tokenApprovals[token][tokenId];

    // Decrease balance with checked arithmetic, because an `ownerOf` override may
    // invalidate the assumption that `_balances[from] >= 1`.
    _balances[token][from] -= 1;

    unchecked {
      // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
      // all 2**256 token ids to be minted, which in practice is impossible.
      _balances[token][to] += 1;
    }

    _owners[token][tokenId] = to;

    // Emit Transfer event on the token
    WrappedERC721(token).emitTransfer(address(0), to, tokenId);

    _afterTokenTransfer(from, to, tokenId, 1);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits an {Approval} event.
   */
  function _approve(
    address token,
    address to,
    uint256 tokenId
  ) internal virtual {
    _tokenApprovals[token][tokenId] = to;
    // Emit Approval event on the token
    WrappedERC721(token).emitApproval(ownerOf(token, tokenId), to, tokenId);
  }

  /**
   * @dev Approve `operator` to operate on all of `owner` tokens
   *
   * Emits an {ApprovalForAll} event.
   */
  function _setApprovalForAll(
    address token,
    address owner,
    address operator,
    bool approved
  ) internal virtual {
    if (owner == operator) {
      revert ERC721InvalidOperator(owner);
    }
    _operatorApprovals[token][owner][operator] = approved;
    // Emit ApprovalForAll event on the token
    WrappedERC721(token).emitApprovalForAll(owner, operator, approved);
  }

  /**
   * @dev Reverts if the `tokenId` has not been minted yet.
   */
  function _requireMinted(address token, uint256 tokenId) internal view virtual {
    if (!_exists(token, tokenId)) {
      revert ERC721NonexistentToken(tokenId);
    }
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkOnERC721Received(
    address sender,
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) private returns (bool) {
    if (to.code.length > 0) {
      try IERC721Receiver(to).onERC721Received(sender, from, tokenId, data) returns (bytes4 retval) {
        return retval == IERC721Receiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert ERC721InvalidReceiver(to);
        } else {
          /// @solidity memory-safe-assembly
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
   * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
   * - When `from` is zero, the tokens will be minted for `to`.
   * - When `to` is zero, ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   * - `batchSize` is non-zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 firstTokenId,
    uint256 batchSize
  ) internal virtual {}

  /**
   * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
   * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
   * - When `from` is zero, the tokens were minted for `to`.
   * - When `to` is zero, ``from``'s tokens were burned.
   * - `from` and `to` are never both zero.
   * - `batchSize` is non-zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 firstTokenId,
    uint256 batchSize
  ) internal virtual {}
}
