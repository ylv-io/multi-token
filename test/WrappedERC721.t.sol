// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import { WrappedERC721 } from "../src/WrappedERC721.sol";
import { MultiTokenERC721 } from "../src/MultiTokenERC721.sol";
import { MockMultiTokenERC721 } from "./utils/mock/MockMultiTokenERC721.sol";

contract ERC721Recipient is IERC721Receiver {
  address public operator;
  address public from;
  uint256 public id;
  bytes public data;

  function onERC721Received(
    address _operator,
    address _from,
    uint256 _id,
    bytes calldata _data
  ) public virtual override returns (bytes4) {
    operator = _operator;
    from = _from;
    id = _id;
    data = _data;

    return IERC721Receiver.onERC721Received.selector;
  }
}

contract RevertingERC721Recipient is IERC721Receiver {
  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) public virtual override returns (bytes4) {
    revert(string(abi.encodePacked(IERC721Receiver.onERC721Received.selector)));
  }
}

contract WrongReturnDataERC721Recipient is IERC721Receiver {
  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) public virtual override returns (bytes4) {
    return 0xCAFEBEEF;
  }
}

contract NonERC721Recipient {}

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

  function testTransferFrom() public {
    address from = address(0xABCD);

    multiToken.mint(address(token), from, 1337);

    vm.prank(from);
    token.approve(address(this), 1337);

    token.transferFrom(from, address(0xBEEF), 1337);

    assertEq(token.getApproved(1337), address(0));
    assertEq(token.ownerOf(1337), address(0xBEEF));
    assertEq(token.balanceOf(address(0xBEEF)), 1);
    assertEq(token.balanceOf(from), 0);
  }

  function testTransferFromSelf() public {
    multiToken.mint(address(token), address(this), 1337);

    token.transferFrom(address(this), address(0xBEEF), 1337);

    assertEq(token.getApproved(1337), address(0));
    assertEq(token.ownerOf(1337), address(0xBEEF));
    assertEq(token.balanceOf(address(0xBEEF)), 1);
    assertEq(token.balanceOf(address(this)), 0);
  }

  function testTransferFromApproveAll() public {
    address from = address(0xABCD);

    multiToken.mint(address(token), from, 1337);

    vm.prank(from);
    token.setApprovalForAll(address(this), true);

    token.transferFrom(from, address(0xBEEF), 1337);

    assertEq(token.getApproved(1337), address(0));
    assertEq(token.ownerOf(1337), address(0xBEEF));
    assertEq(token.balanceOf(address(0xBEEF)), 1);
    assertEq(token.balanceOf(from), 0);
  }

  function testSafeTransferFromToEOA() public {
    address from = address(0xABCD);

    multiToken.mint(address(token), from, 1337);

    vm.prank(from);
    token.setApprovalForAll(address(this), true);

    token.safeTransferFrom(from, address(0xBEEF), 1337);

    assertEq(token.getApproved(1337), address(0));
    assertEq(token.ownerOf(1337), address(0xBEEF));
    assertEq(token.balanceOf(address(0xBEEF)), 1);
    assertEq(token.balanceOf(from), 0);
  }

  function testSafeTransferFromToERC721Recipient() public {
    address from = address(0xABCD);
    ERC721Recipient recipient = new ERC721Recipient();

    multiToken.mint(address(token), from, 1337);

    vm.prank(from);
    token.setApprovalForAll(address(this), true);

    token.safeTransferFrom(from, address(recipient), 1337);

    assertEq(token.getApproved(1337), address(0));
    assertEq(token.ownerOf(1337), address(recipient));
    assertEq(token.balanceOf(address(recipient)), 1);
    assertEq(token.balanceOf(from), 0);

    assertEq(recipient.operator(), address(this));
    assertEq(recipient.from(), from);
    assertEq(recipient.id(), 1337);
    assertEq(recipient.data(), "");
  }

  function testSafeTransferFromToERC721RecipientWithData() public {
    address from = address(0xABCD);
    ERC721Recipient recipient = new ERC721Recipient();

    multiToken.mint(address(token), from, 1337);

    vm.prank(from);
    token.setApprovalForAll(address(this), true);

    token.safeTransferFrom(from, address(recipient), 1337, "testing 123");

    assertEq(token.getApproved(1337), address(0));
    assertEq(token.ownerOf(1337), address(recipient));
    assertEq(token.balanceOf(address(recipient)), 1);
    assertEq(token.balanceOf(from), 0);

    assertEq(recipient.operator(), address(this));
    assertEq(recipient.from(), from);
    assertEq(recipient.id(), 1337);
    assertEq(recipient.data(), "testing 123");
  }
}
