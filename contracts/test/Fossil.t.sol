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

    function testGenerateSVGOnce() public view {
        fossil.generateSVG(0);
    }

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

    function testGenerateSeed() public {
        uint256 seed1;
        uint256 seed2;

        // Token should be the same for intervals
        uint expectedSeedFirstFiveBlocksTokenIdZero = 47325194593512000241468536448559833359437483699567969619987864577538981999987;
        uint expectedSeedSecondFiveBlocksTokenIdZero = 62208203652098549000527465663463271618757119388598162355679688326988861894765;

        vm.roll(1);
        seed1 = fossil.generateSeed(0);
        seed2 = fossil.generateSeed(1);
        assertEq(seed1, expectedSeedFirstFiveBlocksTokenIdZero);
        assertTrue(seed1 != seed2);

        vm.roll(2);
        seed1 = fossil.generateSeed(0);
        assertEq(seed1, expectedSeedFirstFiveBlocksTokenIdZero);

        vm.roll(3);
        seed1 = fossil.generateSeed(0);
        assertEq(seed1, expectedSeedFirstFiveBlocksTokenIdZero);

        vm.roll(4);
        seed1 = fossil.generateSeed(0);
        assertEq(seed1, expectedSeedFirstFiveBlocksTokenIdZero);

        vm.roll(5);
        seed1 = fossil.generateSeed(0);
        assertEq(seed1, expectedSeedFirstFiveBlocksTokenIdZero);

        vm.roll(6);
        seed1 = fossil.generateSeed(0);
        assertTrue(seed1 != expectedSeedFirstFiveBlocksTokenIdZero);
        assertEq(seed2, expectedSeedSecondFiveBlocksTokenIdZero);

        vm.roll(7);
        seed1 = fossil.generateSeed(0);
        assertEq(seed2, expectedSeedSecondFiveBlocksTokenIdZero);
    }
}
