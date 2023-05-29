// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import { WrappedERC20 } from "../../../src/WrappedERC20.sol";
import { MultiToken } from "../../../src/MultiToken.sol";

contract MockERC20 is WrappedERC20 {
  constructor(
    MultiToken _multiToken,
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) WrappedERC20(_multiToken, _name, _symbol) {}
}
