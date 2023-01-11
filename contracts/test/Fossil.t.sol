// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Fossil.sol";

contract FossilTest is Test {
    Fossil fossil;
    function setUp() public {
        fossil = new Fossil();
    }

    function testMint() public {
        fossil.mint(address(this));
        assertEq(fossil.balanceOf(address(this)), 1);
        assertEq(fossil.ownerOf(1), address(this));
    }

    function testTokenURI() public {
        fossil.mint(address(this));
        string memory tokenURI = fossil.tokenURI(1);
        assertTrue(bytes(tokenURI).length > 0);
    }
}
