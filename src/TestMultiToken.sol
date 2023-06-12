// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import "./MultiToken.sol";

contract TestMultiToken is MultiToken {
  function mint(
    address token,
    address account,
    uint256 amount
  ) external {
    _mint(token, account, amount);
  }

  function burn(
    address token,
    address account,
    uint256 amount
  ) external {
    _burn(token, account, amount);
  }
}
