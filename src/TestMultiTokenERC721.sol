// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import "./MultiTokenERC721.sol";

contract TestMultiTokenERC721 is MultiTokenERC721 {
  function mint(
    address token,
    address account,
    uint256 tokenId
  ) external {
    _mint(token, account, tokenId);
  }

  function burn(address token, uint256 tokenId) external {
    _burn(token, tokenId);
  }
}
