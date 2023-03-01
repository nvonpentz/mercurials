// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Mercurial.sol";
import {Counters} from "openzeppelin-contracts/contracts/utils/Counters.sol";
import "openzeppelin-contracts/contracts/utils/Counters.sol";

contract MercurialTest is Test {
    Mercurial mercurial;
    using Counters for Counters.Counter;

    function setUp() public {
        mercurial = new Mercurial();
    }

    receive() external payable {}

    function testGenerateSVGOnce() public view {
        mercurial.generateSVG(0);
    }

    // Token tests
    function testNextToken() public {
        uint256 tokenId;
        string memory svg;
        uint256 price;
        bytes32 hash;
        uint8 ttl;

        (tokenId, svg, price, hash, ttl) = mercurial.nextToken();
        assertEq(tokenId, 0); // tokenId should start at 0
        assertGt(bytes(svg).length, 0); // SVG should be non-empty
        assertGt(price, 0); // price should be greater than 0
        assertEq(hash, blockhash(block.number - 1)); // hash should be the previous blockhash
        assertEq(ttl, 5); // ttl should be 5
    }

    function testMint() public {
        uint256 tokenId;
        string memory svg;
        uint256 price;
        bytes32 hash;
        uint8 ttl;

        uint balanceBefore = address(this).balance;

        // Get values for mint
        (tokenId, svg, price, hash, ttl) = mercurial.nextToken();

        // Attempt to mint with incorrect token ID
        vm.expectRevert("Invalid or expired token ID");
        mercurial.mint{value: price}(tokenId + 1, hash);

        // Attempt to mint with incorrect hash
        vm.expectRevert("Invalid or expired blockhash");
        mercurial.mint{value: price}(tokenId, blockhash(block.number));

        // Attempt to mint with too little ETH
        vm.expectRevert("Insufficient funds");
        mercurial.mint{value: price - 1}(tokenId, hash);

        // Mint with correct values
        mercurial.mint{value: price}(tokenId, hash);
        assertEq(mercurial.balanceOf(address(this)), 1); // Token should be owned by this contract
        assertEq(address(this).balance, balanceBefore - price); // ETH should have gone to the token contract
        // assertEq(mercurial.tokenURI(tokenId), TODO); // TODO
        assertEq(mercurial.totalSold(), 1); // Total supply should be 1

        // Mint with too much ETH
        balanceBefore = address(this).balance;
        (tokenId, svg, price, hash, ttl) = mercurial.nextToken();
        mercurial.mint{value: price + 1}(tokenId, hash);
        assertEq(address(this).balance, balanceBefore - price); // Extra ETH should have been refunded
    }

    function testGenerateSeed() public {
        uint256 seed1;
        uint8 ttl1;
        uint256 seed2;
        uint8 ttl2;

        // Token should be the same within one interval (5 blocks)
        uint expectedSeedFirstFiveBlocksTokenIdZero = 47325194593512000241468536448559833359437483699567969619987864577538981999987;

        vm.roll(1);
        (seed1, ttl1) = mercurial.generateSeed(0);
        (seed2, ttl2) = mercurial.generateSeed(1);
        assertEq(seed1, expectedSeedFirstFiveBlocksTokenIdZero);
        assertTrue(seed1 != seed2);

        vm.roll(2);
        (seed1, ttl1) = mercurial.generateSeed(0);
        assertEq(seed1, expectedSeedFirstFiveBlocksTokenIdZero);

        vm.roll(3);
        (seed1, ttl1) = mercurial.generateSeed(0);
        assertEq(seed1, expectedSeedFirstFiveBlocksTokenIdZero);

        vm.roll(4);
        (seed1, ttl1) = mercurial.generateSeed(0);
        assertEq(seed1, expectedSeedFirstFiveBlocksTokenIdZero);

        vm.roll(5);
        (seed1, ttl1) = mercurial.generateSeed(0);
        assertEq(seed1, expectedSeedFirstFiveBlocksTokenIdZero);

        vm.roll(6);
        (seed1, ttl1) = mercurial.generateSeed(0);
        assertTrue(seed1 != expectedSeedFirstFiveBlocksTokenIdZero);

        vm.roll(7);
        (seed1, ttl1) = mercurial.generateSeed(0);
    }
}
