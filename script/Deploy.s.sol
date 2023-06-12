// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { Script } from "forge-std/Script.sol";

import "../src/TestMultiToken.sol";
import "../src/WrappedERC20.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract Deploy is Script {
  function run() public {
    vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
    address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));

    TestMultiToken multiToken = new TestMultiToken();
    WrappedERC20 tokenA = new WrappedERC20(multiToken, "Token A", "TKNA");
    WrappedERC20 tokenB = new WrappedERC20(multiToken, "Token B", "TKNB");
    WrappedERC20 tokenC = new WrappedERC20(multiToken, "Token C", "TKNC");

    multiToken.addToken(address(tokenA));
    multiToken.addToken(address(tokenB));
    multiToken.addToken(address(tokenC));

    multiToken.mint(address(tokenA), deployer, 1000e18);
    multiToken.mint(address(tokenB), deployer, 1000e18);
    multiToken.mint(address(tokenC), deployer, 1000e18);

    vm.stopBroadcast();
  }
}
