// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Fossil.sol";
import {Counters} from "openzeppelin-contracts/contracts/utils/Counters.sol";
import "openzeppelin-contracts/contracts/utils/Counters.sol";

contract FossilTest is Test {
    Fossil fossil;
    using Counters for Counters.Counter;

    function setUp() public {
        fossil = new Fossil();
    }

    receive() external payable {}

    // function testGenerateRandom2() public {
    //     uint seed = 0;
    //     uint nonce = 0;
    //     uint rand1;
    //     uint rand2;
    //     (rand1, nonce) = fossil.generateRandom(0, 3, seed, nonce);
    //     assertEq(nonce, 1);
    //     (rand2, nonce) = fossil.generateRandom(0, 3, seed, nonce);
    //     assertEq(nonce, 2);
    //     assertTrue(rand1 != rand2);
    // }

    function testGenerateSVGOnce() public view {
        fossil.generateSVG(0);
    }

    // function testGenerateSVGManyTimes() public {
    //     // call generateSVG(x) once for every x from 0..10000
    //     for (uint i = 0; i < 10000; i++) {
    //         string memory svg = fossil.generateSVG(i);
    //         // check that the SVG is valid
    //         assertTrue(bytes(svg).length > 0);
    //     }
    // }

    // Token tests
    function testNextToken() public {
        uint256 tokenId;
        string memory svg;
        uint256 price;
        bytes32 hash;

        (tokenId, svg, price, hash) = fossil.nextToken();
        assertEq(tokenId, 0); // tokenId should start at 0
        assertGt(bytes(svg).length, 0); // SVG should be non-empty
        assertGt(price, 0); // price should be greater than 0
        assertEq(hash, blockhash(block.number - 1)); // hash should be the previous blockhash
    }

    function testMint() public {
        uint256 tokenId;
        string memory svg;
        uint256 price;
        bytes32 hash;

        uint balanceBefore = address(this).balance;

        // Get values for mint
        (tokenId, svg, price, hash) = fossil.nextToken();

        // Attempt to mint with incorrect token ID
        vm.expectRevert("Invalid or expired token ID");
        fossil.mint{value: price}(tokenId + 1, hash);

        // Attempt to mint with incorrect hash
        vm.expectRevert("Invalid or expired blockhash");
        fossil.mint{value: price}(tokenId, blockhash(block.number));

        // Attempt to mint with too little ETH
        vm.expectRevert("Insufficient funds");
        fossil.mint{value: price - 1}(tokenId, hash);

        // Mint with correct values
        fossil.mint{value: price}(tokenId, hash);
        assertEq(fossil.balanceOf(address(this)), 1); // Token should be owned by this contract
        assertEq(address(this).balance, balanceBefore - price); // ETH should have gone to the token contract
        // assertEq(fossil.tokenURI(tokenId), TODO); // TODO
        assertEq(fossil.totalSold(), 1); // Total supply should be 1

        // Mint with too much ETH
        balanceBefore = address(this).balance;
        (tokenId, svg, price, hash) = fossil.nextToken();
        fossil.mint{value: price + 1}(tokenId, hash);
        assertEq(address(this).balance, balanceBefore - price); // Extra ETH should have been refunded
    }
}
