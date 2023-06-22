// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./MultiTokenERC721.sol";

contract WrappedERC721 is IERC721, IERC721Metadata, ERC165, IERC721Errors {
  using Strings for uint256;

  MultiTokenERC721 private immutable _multiToken;
  string private _name;
  string private _symbol;

  modifier onlyMultiToken() {
    require(msg.sender == address(_multiToken), "Sender is not a multitoken");
    _;
  }

  constructor(
    MultiTokenERC721 multiToken_,
    string memory name_,
    string memory symbol_
  ) {
    _multiToken = multiToken_;
    _name = name_;
    _symbol = symbol_;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721Metadata-name}.
   */
  function name() public view virtual returns (string memory) {
    return _name;
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
   */
  function symbol() public view virtual returns (string memory) {
    return _symbol;
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
    // checking that tokenId has an owner
    _multiToken.ownerOf(address(this), tokenId);

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string.concat(baseURI, tokenId.toString()) : "";
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view virtual returns (uint256) {
    return _multiToken.balanceOf(address(this), owner);
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view virtual returns (address) {
    return _multiToken.ownerOf(address(this), tokenId);
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual {
    _multiToken.approve(address(this), msg.sender, to, tokenId);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view virtual returns (address) {
    return _multiToken.getApproved(address(this), tokenId);
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public virtual {
    _multiToken.setApprovalForAll(address(this), msg.sender, operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
    return _multiToken.isApprovedForAll(address(this), owner, operator);
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual {
    _multiToken.transferFrom(address(this), msg.sender, from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual {
    _multiToken.safeTransferFrom(address(this), msg.sender, from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public virtual {
    _multiToken.safeTransferFrom(address(this), msg.sender, from, to, tokenId, data);
  }

  function emitTransfer(
    address from,
    address to,
    uint256 amount
  ) external onlyMultiToken {
    emit Transfer(from, to, amount);
  }

  function emitApprovalForAll(
    address owner,
    address operator,
    bool approved
  ) external onlyMultiToken {
    emit ApprovalForAll(owner, operator, approved);
  }

  function emitApproval(
    address owner,
    address spender,
    uint256 amount
  ) external onlyMultiToken {
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overridden in child contracts.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }
}
