// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { WrappedERC20 } from "../src/WrappedERC20.sol";
import { MultiToken } from "../src/MultiToken.sol";
import { MockMultiToken } from "./utils/mock/MockMultiToken.sol";

contract WrappedERC20Test is PRBTest, StdCheats {
  MockMultiToken internal multiToken;
  WrappedERC20 internal token;

  /// @dev A function invoked before each test case is run.
  function setUp() public virtual {
    multiToken = new MockMultiToken();
    token = new WrappedERC20(multiToken, "Token", "TKN");
    multiToken.addToken(address(token));
  }

  function testApprove() public {
    assertTrue(token.approve(address(0xBEEF), 1e18));

    assertEq(token.allowance(address(this), address(0xBEEF)), 1e18);
  }

  function testTransfer() public {
    multiToken.mint(address(token), address(this), 1e18);

    assertTrue(token.transfer(address(0xBEEF), 1e18));
    assertEq(token.totalSupply(), 1e18);

    assertEq(token.balanceOf(address(this)), 0);
    assertEq(token.balanceOf(address(0xBEEF)), 1e18);
  }

  function testTransferFrom() public {
    address from = address(0xABCD);

    multiToken.mint(address(token), from, 1e18);

    vm.prank(from);
    token.approve(address(this), 1e18);

    assertTrue(token.transferFrom(from, address(0xBEEF), 1e18));
    assertEq(token.totalSupply(), 1e18);

    assertEq(token.allowance(from, address(this)), 0);

    assertEq(token.balanceOf(from), 0);
    assertEq(token.balanceOf(address(0xBEEF)), 1e18);
  }

  function testInfiniteApproveTransferFrom() public {
    address from = address(0xABCD);

    multiToken.mint(address(token), from, 1e18);

    vm.prank(from);
    token.approve(address(this), type(uint256).max);

    assertTrue(token.transferFrom(from, address(0xBEEF), 1e18));
    assertEq(token.totalSupply(), 1e18);

    assertEq(token.allowance(from, address(this)), type(uint256).max);

    assertEq(token.balanceOf(from), 0);
    assertEq(token.balanceOf(address(0xBEEF)), 1e18);
  }

  function testFailTransferInsufficientBalance() public {
    multiToken.mint(address(token), address(this), 0.9e18);
    token.transfer(address(0xBEEF), 1e18);
  }

  function testFailTransferFromInsufficientAllowance() public {
    address from = address(0xABCD);

    multiToken.mint(address(token), from, 1e18);

    vm.prank(from);
    token.approve(address(this), 0.9e18);

    token.transferFrom(from, address(0xBEEF), 1e18);
  }

  function testFailTransferFromInsufficientBalance() public {
    address from = address(0xABCD);

    multiToken.mint(address(token), from, 0.9e18);

    vm.prank(from);
    token.approve(address(this), 1e18);

    token.transferFrom(from, address(0xBEEF), 1e18);
  }

  function testMetadata(string calldata name, string calldata symbol) public {
    WrappedERC20 tkn = new WrappedERC20(multiToken, name, symbol);
    assertEq(tkn.name(), name);
    assertEq(tkn.symbol(), symbol);
  }
}
