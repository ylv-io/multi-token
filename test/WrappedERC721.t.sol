// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import { WrappedERC721 } from "../src/WrappedERC721.sol";
import { MultiTokenERC721 } from "../src/MultiTokenERC721.sol";
import { MockMultiTokenERC721 } from "./utils/mock/MockMultiTokenERC721.sol";

contract WrappedERC721Test is PRBTest, StdCheats, IERC721Errors {
  MockMultiTokenERC721 internal multiToken;
  WrappedERC721 internal token;

  /// @dev A function invoked before each test case is run.
  function setUp() public virtual {
    multiToken = new MockMultiTokenERC721();
    token = new WrappedERC721(multiToken, "Non Fungible", "NFT");
    multiToken.addToken(address(token));
  }

  function invariantMetadata() public {
    assertEq(token.name(), "Non Fungible");
    assertEq(token.symbol(), "NFT");
  }

  function testMint() public {
    multiToken.mint(address(token), address(0xBEEF), 1337);

    assertEq(token.balanceOf(address(0xBEEF)), 1);
    assertEq(token.ownerOf(1337), address(0xBEEF));
  }

  function testBurn() public {
    multiToken.mint(address(token), address(0xBEEF), 1337);
    multiToken.burn(address(token), 1337);

    assertEq(token.balanceOf(address(0xBEEF)), 0);

    vm.expectRevert(abi.encodeWithSelector(ERC721NonexistentToken.selector, 1337));
    token.ownerOf(1337);
  }

  function testApprove() public {
    multiToken.mint(address(token), address(this), 1337);

    token.approve(address(0xBEEF), 1337);

    assertEq(token.getApproved(1337), address(0xBEEF));
  }

  function testApproveBurn() public {
    multiToken.mint(address(token), address(this), 1337);

    token.approve(address(0xBEEF), 1337);

    multiToken.burn(address(token), 1337);

    assertEq(token.balanceOf(address(this)), 0);
    vm.expectRevert(abi.encodeWithSelector(ERC721NonexistentToken.selector, 1337));
    assertEq(token.getApproved(1337), address(0));

    vm.expectRevert(abi.encodeWithSelector(ERC721NonexistentToken.selector, 1337));
    token.ownerOf(1337);
  }

  function testApproveAll() public {
    token.setApprovalForAll(address(0xBEEF), true);

    assertTrue(token.isApprovedForAll(address(this), address(0xBEEF)));
  }
}
