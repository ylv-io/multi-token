// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { WrappedERC721 } from "../src/WrappedERC721.sol";
import { MultiTokenERC721 } from "../src/MultiTokenERC721.sol";
import { MockMultiTokenERC721 } from "./utils/mock/MockMultiTokenERC721.sol";

contract WrappedERC721Test is PRBTest, StdCheats {
  MockMultiTokenERC721 internal multiToken;
  WrappedERC721 internal token;

  /// @dev A function invoked before each test case is run.
  function setUp() public virtual {
    multiToken = new MockMultiTokenERC721();
    token = new WrappedERC721(multiToken, "NFT", "NFT");
    multiToken.addToken(address(token));
  }
}
