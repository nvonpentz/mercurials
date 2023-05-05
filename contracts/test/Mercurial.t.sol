// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Mercurial.sol";
import {Base64} from "openzeppelin-contracts/contracts/utils/Base64.sol";

contract MercurialTest is Test {
    Mercurial mercurial;
    using Strings for uint256;

    function setUp() public {
        mercurial = new Mercurial();
    }

    receive() external payable {}

    // Token tests
    function testNextToken() public {
        uint256 tokenId;
        string memory svg;
        uint256 price;
        bytes32 hash;
        uint256 ttl;

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
        uint256 ttl;

        uint balanceBefore = address(this).balance;

        // Get values for mint
        (tokenId, svg, price, hash, ttl) = mercurial.nextToken();

        // Attempt to mint with incorrect token ID
        vm.expectRevert("Invalid token ID");
        mercurial.mint{value: price}(tokenId + 1, hash);

        // Attempt to mint with incorrect hash
        vm.expectRevert("Invalid blockhash");
        mercurial.mint{value: price}(tokenId, blockhash(block.number));

        // Attempt to mint with too little ETH
        vm.expectRevert("Insufficient funds");
        mercurial.mint{value: price - 1}(tokenId, hash);

        // Mint with correct values
        vm.expectEmit(true, true, false, false, address(mercurial));
        mercurial.mint{value: price}(tokenId, hash);
        assertEq(mercurial.balanceOf(address(this)), 1); // Token should be owned by this contract
        assertEq(address(this).balance, balanceBefore - price); // ETH should have gone to the token contract
        assertEq(mercurial.totalSold(), 1); // Total supply should be 1

        // Mint with too much ETH
        balanceBefore = address(this).balance;
        (tokenId, svg, price, hash, ttl) = mercurial.nextToken();
        mercurial.mint{value: price + 1}(tokenId, hash);
    }

    function testMintWithOldButNotExpiredDetails() public {
        // This test simulates if you submit your mint request, but it takes a block
        // or two to be confirmed
        uint256 tokenId;
        string memory svg;
        uint256 price;
        bytes32 hash;
        uint256 ttl;

        vm.roll(1);
        (tokenId, svg, price, hash, ttl) = mercurial.nextToken();
        assertEq(ttl, 5);

        vm.roll(2);
        (, , price, , ttl) = mercurial.nextToken();
        assertEq(ttl, 4);
        mercurial.mint{value: price}(tokenId, hash);
        assertEq(mercurial.balanceOf(address(this)), 1);
        assertEq(mercurial.ownerOf(tokenId), address(this));

        vm.roll(3);
        (, , price, , ttl) = mercurial.nextToken();
        assertEq(ttl, 3);
        mercurial.mint{value: price}(tokenId + 1, hash);
        assertEq(mercurial.balanceOf(address(this)), 2);
        assertEq(mercurial.ownerOf(tokenId + 1), address(this));

        vm.roll(4);
        (, , price, , ttl) = mercurial.nextToken();
        assertEq(ttl, 2);
        mercurial.mint{value: price}(tokenId + 2, hash);
        assertEq(mercurial.balanceOf(address(this)), 3);
        assertEq(mercurial.ownerOf(tokenId + 2), address(this));

        vm.roll(5);
        (, , price, , ttl) = mercurial.nextToken();
        assertEq(ttl, 1);
        mercurial.mint{value: price}(tokenId + 3, hash);
        assertEq(mercurial.balanceOf(address(this)), 4);
        assertEq(mercurial.ownerOf(tokenId + 3), address(this));

        // Should not work with expired details
        vm.roll(6);
        (, , price, , ttl) = mercurial.nextToken();
        assertEq(ttl, 5);
        vm.expectRevert("Invalid blockhash");
        mercurial.mint{value: price}(tokenId + 4, hash);
    }

    function testCanMintFiveBlocksInARow() public {
        uint256 tokenId;
        string memory svg;
        uint256 price;
        bytes32 hash;
        uint256 ttl;

        uint256 blockNumber = block.number;
        for (uint256 i = 0; i < 5; i++) {
            (tokenId, svg, price, hash, ttl) = mercurial.nextToken();
            mercurial.mint{value: price}(tokenId, hash);
            vm.roll(blockNumber + 1);
        }
    }

    function testTransfer() public {
        uint256 tokenId;
        string memory svg;
        uint256 price;
        bytes32 hash;
        uint256 ttl;

        (tokenId, svg, price, hash, ttl) = mercurial.nextToken();
        mercurial.mint{value: price}(tokenId, hash);
        assertEq(mercurial.balanceOf(address(this)), 1);
        assertEq(mercurial.ownerOf(tokenId), address(this));

        mercurial.transferFrom(address(this), address(0xdead), tokenId);
        assertEq(mercurial.balanceOf(address(this)), 0);
        assertEq(mercurial.ownerOf(tokenId), address(0xdead));
    }

    function testGenerateSeed() public {
        uint256 seed1;
        uint256 ttl1;
        uint256 seed2;
        uint256 ttl2;

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

    function testCannotReceiveETH() public {
        vm.expectRevert("Cannot receive ETH");
        // Send 1 wei to the contract
        (bool success, ) = address(mercurial).call{value: 1}("");
        assertEq(address(mercurial).balance, 0);
        assertEq(success, false);
    }

    function testOverpaymentRefund() public {
        uint256 tokenId;
        string memory svg;
        uint256 price;
        bytes32 hash;
        uint256 ttl;

        // Get values for mint
        (tokenId, svg, price, hash, ttl) = mercurial.nextToken();

        // Mint with more ETH than the required price
        uint256 overpaymentAmount = 10 ether;
        uint256 totalPayment = price + overpaymentAmount;

        uint256 balanceBefore = address(this).balance;
        mercurial.mint{value: totalPayment}(tokenId, hash);

        // Check that the NFT has been minted successfully
        assertEq(mercurial.balanceOf(address(this)), 1);
        assertEq(mercurial.ownerOf(tokenId), address(this));

        // Verify that the overpayment amount has been refunded
        uint256 expectedBalanceAfter = balanceBefore - price;
        assertEq(address(this).balance, expectedBalanceAfter);
    }
}
