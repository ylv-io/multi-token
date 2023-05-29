// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MultiToken is Ownable {
  event Transfer(address indexed token, address indexed from, address indexed to, uint256 value);

  event Approval(address indexed token, address indexed owner, address indexed spender, uint256 value);

  event TokenAdded(address indexed token);

  mapping(address => mapping(address => uint256)) private _balances;
  mapping(address => mapping(address => mapping(address => uint256))) private _allowances;
  mapping(address => uint256) private _totalSupply;
  mapping(address => bool) private _tokens;

  modifier onlyToken(address token) {
    require(_tokens[token], "MultiToken: Not a valid token");
    _;
  }

  function totalSupply(address token) public view returns (uint256) {
    return _totalSupply[token];
  }

  function balanceOf(address token, address account) public view returns (uint256) {
    return _balances[token][account];
  }

  function allowance(
    address token,
    address owner,
    address spender
  ) public view returns (uint256) {
    return _allowances[token][owner][spender];
  }

  function addToken(address token) public onlyOwner {
    _tokens[token] = true;
    emit TokenAdded(token);
  }

  function transfer(
    address token,
    address owner,
    address to,
    uint256 amount
  ) public onlyToken(token) returns (bool) {
    _transfer(token, owner, to, amount);
    return true;
  }

  function approve(
    address token,
    address sender,
    address spender,
    uint256 amount
  ) public onlyToken(token) returns (bool) {
    _approve(token, sender, spender, amount);
    return true;
  }

  function transferFrom(
    address token,
    address spender,
    address from,
    address to,
    uint256 amount
  ) public onlyToken(token) returns (bool) {
    _spendAllowance(token, from, spender, amount);
    _transfer(token, from, to, amount);
    return true;
  }


  function _mint(
    address token,
    address account,
    uint256 amount
  ) internal {
    require(account != address(0), "ERC20: mint to the zero address");

    _totalSupply[token] += amount;
    unchecked {
      // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
      _balances[token][account] += amount;
    }
    emit Transfer(token, address(0), account, amount);
  }

  function _burn(
    address token,
    address account,
    uint256 amount
  ) internal {
    require(account != address(0), "ERC20: burn from the zero address");

    uint256 accountBalance = _balances[token][account];
    require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
      _balances[token][account] = accountBalance - amount;
      // Overflow not possible: amount <= accountBalance <= totalSupply.
      _totalSupply[token] -= amount;
    }

    emit Transfer(token, account, address(0), amount);
  }

  function _transfer(
    address token,
    address from,
    address to,
    uint256 amount
  ) internal {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");

    uint256 fromBalance = _balances[token][from];
    require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
      _balances[token][from] = fromBalance - amount;
      // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
      // decrementing then incrementing.
      _balances[token][to] += amount;
    }

    emit Transfer(token, from, to, amount);
  }

  function _approve(
    address token,
    address owner,
    address spender,
    uint256 amount
  ) internal {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[token][owner][spender] = amount;
    emit Approval(token, owner, spender, amount);
  }

  function _spendAllowance(
    address token,
    address owner,
    address spender,
    uint256 amount
  ) internal {
    uint256 currentAllowance = allowance(token, owner, spender);
    if (currentAllowance != type(uint256).max) {
      require(currentAllowance >= amount, "ERC20: insufficient allowance");
      unchecked {
        _approve(token, owner, spender, currentAllowance - amount);
      }
    }
  }
}
