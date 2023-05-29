// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import { MultiToken } from "../../../src/MultiToken.sol";

contract MockMultiToken is MultiToken {
  constructor() MultiToken() {}

  function mint(
    address token,
    address account,
    uint256 amount
  ) public {
    _mint(token, account, amount);
  }
}
