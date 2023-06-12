// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./MultiToken.sol";

contract WrappedERC20 is IERC20, IERC20Metadata {
  MultiToken private immutable _multiToken;
  string private _name;
  string private _symbol;

  constructor(
    MultiToken multiToken_,
    string memory name_,
    string memory symbol_
  ) {
    _multiToken = multiToken_;
    _name = name_;
    _symbol = symbol_;
  }

  function name() public view virtual override returns (string memory) {
    return _name;
  }

  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  function decimals() public view virtual override returns (uint8) {
    return 18;
  }

  function totalSupply() public view override returns (uint256) {
    return _multiToken.totalSupply(address(this));
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _multiToken.balanceOf(address(this), account);
  }

  function transfer(address to, uint256 amount) public override returns (bool) {
    _multiToken.transfer(address(this), msg.sender, to, amount);
    emit Transfer(msg.sender, to, amount);
    return true;
  }

  function allowance(address owner, address spender) public view override returns (uint256) {
    return _multiToken.allowance(address(this), owner, spender);
  }

  function approve(address spender, uint256 amount) public override returns (bool) {
    _multiToken.approve(address(this), msg.sender, spender, amount);
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public override returns (bool) {
    _multiToken.transferFrom(address(this), msg.sender, from, to, amount);
    emit Transfer(from, to, amount);
    return true;
  }
}
