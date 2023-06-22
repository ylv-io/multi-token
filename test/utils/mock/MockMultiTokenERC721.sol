// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import { MultiTokenERC721 } from "../../../src/MultiTokenERC721.sol";

contract MockMultiTokenERC721 is MultiTokenERC721 {
  constructor() MultiTokenERC721() {}

  function safeMint(
    address token,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public {
    _safeMint(token, msg.sender, to, tokenId, data);
  }

  function safeMint(
    address token,
    address to,
    uint256 tokenId
  ) public {
    _safeMint(token, msg.sender, to, tokenId);
  }

  function mint(
    address token,
    address to,
    uint256 tokenId
  ) public {
    _mint(token, to, tokenId);
  }

  function burn(address token, uint256 tokenId) public {
    _burn(token, tokenId);
  }
}
