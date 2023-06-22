// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { Script } from "forge-std/Script.sol";

import "../src/TestMultiTokenERC721.sol";
import "../src/WrappedERC721.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract Deploy is Script {
  function run() public {
    vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
    address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));

    TestMultiTokenERC721 multiToken = new TestMultiTokenERC721();
    WrappedERC721 tokenA = new WrappedERC721(multiToken, "NFT A", "NFTA");
    WrappedERC721 tokenB = new WrappedERC721(multiToken, "NFT B", "NFTB");
    WrappedERC721 tokenC = new WrappedERC721(multiToken, "NFT C", "NFTC");

    multiToken.addToken(address(tokenA));
    multiToken.addToken(address(tokenB));
    multiToken.addToken(address(tokenC));

    multiToken.mint(address(tokenA), deployer, 1);
    multiToken.mint(address(tokenB), deployer, 1);
    multiToken.mint(address(tokenC), deployer, 1);

    vm.stopBroadcast();
  }
}
