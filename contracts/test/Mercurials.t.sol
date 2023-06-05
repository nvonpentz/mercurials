// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Mercurials.sol";
import {Base64} from "openzeppelin-contracts/contracts/utils/Base64.sol";

contract MercurialsTest is Test, Mercurials {
    Mercurials mercurials;
    using Strings for uint256;

    function setUp() public {
        mercurials = new Mercurials();
    }

    // Can receive Ether in case of overpayment
    receive() external payable {}

    // Token tests
    function testNextToken() public {
        uint256 tokenId1;
        uint256 tokenId2;
        string memory svg1;
        string memory svg2;
        uint256 price1;
        uint256 price2;
        bytes32 hash1;
        bytes32 hash2;
        uint256 ttl1;
        uint256 ttl2;

        // Verify default vaules
        (tokenId1, svg1, price1, hash1, ttl1) = mercurials.nextToken();
        assertEq(tokenId1, 0);
        assertGt(bytes(svg1).length, 0);
        assertGt(price1, 0);
        assertEq(hash1, blockhash(block.number - 1));
        assertEq(ttl1, 5);

        // Increase block number by 1
        // Token ID, SVG, price, and hash should all be the same, TTL should be
        // 1 less
        vm.roll(block.number + 1);
        (tokenId2, svg2, price2, hash2, ttl2) = mercurials.nextToken();
        assertEq(tokenId1, tokenId2);
        assertEq(svg1, svg2);
        assertEq(price1, price2);
        assertEq(hash1, hash2);
        assertEq(ttl2, 4);

        // Increase block number by 4, so the token expires
        // Token ID, price and should all be the same, SVG should be different,
        // hash should be different, TTL should be 5
        vm.roll(block.number + 4);
        (tokenId1, svg1, price1, hash1, ttl1) = mercurials.nextToken();
        assertEq(tokenId1, tokenId2);
        assertEq(price1, price2);
        assertTrue(hash1 != hash2);
        assertEq(ttl1, 5);
        assertTrue(keccak256(bytes(svg1)) != keccak256(bytes(svg2)));

        // Increase timestamp
        // Price should decrease, everything else should be the same
        vm.warp(block.timestamp + 1 days);
        (tokenId2, svg2, price2, hash2, ttl2) = mercurials.nextToken();
        assertTrue(price1 > price2);
        assertEq(tokenId1, tokenId2);
        assertEq(hash1, hash2);
        assertEq(ttl1, ttl2);
        assertEq(svg1, svg2);
    }

    function testMint() public {
        uint256 tokenId;
        string memory svg;
        uint256 price;
        bytes32 hash;
        uint256 ttl;

        uint balanceBefore = address(this).balance;

        // Get values for mint
        (tokenId, svg, price, hash, ttl) = mercurials.nextToken();

        // Attempt to mint with incorrect token ID
        vm.expectRevert(Mercurials.InvalidTokenId.selector);
        mercurials.mint{value: price}(tokenId + 1, hash);

        // Attempt to mint with incorrect hash
        vm.expectRevert(Mercurials.InvalidBlockHash.selector);
        mercurials.mint{value: price}(tokenId, blockhash(block.number));

        // Attempt to mint with too little ETH
        vm.expectRevert(Mercurials.InsufficientFunds.selector);
        mercurials.mint{value: price - 1}(tokenId, hash);

        // Mint with correct values, verify the token is owned by test contract,
        // ether is sent to the token contract, and the total supply has gone up
        mercurials.mint{value: price}(tokenId, hash);
        assertEq(mercurials.balanceOf(address(this)), 1);
        assertEq(address(this).balance, balanceBefore - price);
        assertEq(mercurials.totalSold(), 1);

        // Attempt to mint again with same token ID
        vm.expectRevert(Mercurials.InvalidTokenId.selector);
        mercurials.mint{value: price}(tokenId, hash);

        // Mint with too much ETH
        balanceBefore = address(this).balance;
        (tokenId, svg, price, hash, ttl) = mercurials.nextToken();
        mercurials.mint{value: price + 1}(tokenId, hash);

        // Validate token ownership, balance and total sold again after minting with extra ETH
        assertEq(mercurials.balanceOf(address(this)), 2); // 2 tokens should be owned by this contract now
        assertEq(address(this).balance, balanceBefore - price); // ETH should have gone to the token contract
        assertEq(mercurials.totalSold(), 2); // Total supply should be 2 now
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
        (tokenId, svg, price, hash, ttl) = mercurials.nextToken();
        assertEq(ttl, 5);

        vm.roll(2);
        (, , price, , ttl) = mercurials.nextToken();
        assertEq(ttl, 4);
        mercurials.mint{value: price}(tokenId, hash);
        assertEq(mercurials.balanceOf(address(this)), 1);
        assertEq(mercurials.ownerOf(tokenId), address(this));

        vm.roll(3);
        (, , price, , ttl) = mercurials.nextToken();
        assertEq(ttl, 3);
        mercurials.mint{value: price}(tokenId + 1, hash);
        assertEq(mercurials.balanceOf(address(this)), 2);
        assertEq(mercurials.ownerOf(tokenId + 1), address(this));

        vm.roll(4);
        (, , price, , ttl) = mercurials.nextToken();
        assertEq(ttl, 2);
        mercurials.mint{value: price}(tokenId + 2, hash);
        assertEq(mercurials.balanceOf(address(this)), 3);
        assertEq(mercurials.ownerOf(tokenId + 2), address(this));

        vm.roll(5);
        (, , price, , ttl) = mercurials.nextToken();
        assertEq(ttl, 1);
        mercurials.mint{value: price}(tokenId + 3, hash);
        assertEq(mercurials.balanceOf(address(this)), 4);
        assertEq(mercurials.ownerOf(tokenId + 3), address(this));

        // Should not work with expired details
        vm.roll(6);
        (, , price, , ttl) = mercurials.nextToken();
        assertEq(ttl, 5);
        vm.expectRevert(Mercurials.InvalidBlockHash.selector);
        mercurials.mint{value: price}(tokenId + 4, hash);
    }

    function testCanMintFiveBlocksInARow() public {
        uint256 tokenId;
        string memory svg;
        uint256 price;
        bytes32 hash;
        uint256 ttl;

        uint256 blockNumber = block.number;
        for (uint256 i = 0; i < 5; i++) {
            (tokenId, svg, price, hash, ttl) = mercurials.nextToken();
            mercurials.mint{value: price}(tokenId, hash);
            vm.roll(blockNumber + 1);
            assertEq(mercurials.balanceOf(address(this)), i + 1);
            assertEq(mercurials.ownerOf(tokenId), address(this));
            assertEq(mercurials.totalSold(), i + 1);
        }
    }

    function testTransfer() public {
        uint256 tokenId;
        string memory svg;
        uint256 price;
        bytes32 hash;
        uint256 ttl;

        (tokenId, svg, price, hash, ttl) = mercurials.nextToken();
        mercurials.mint{value: price}(tokenId, hash);
        assertEq(mercurials.balanceOf(address(this)), 1);
        assertEq(mercurials.ownerOf(tokenId), address(this));

        mercurials.transferFrom(address(this), address(0xdead), tokenId);
        assertEq(mercurials.balanceOf(address(this)), 0);
        assertEq(mercurials.ownerOf(tokenId), address(0xdead));
    }

    function testGenerateSeed() public {
        uint256 seed1;
        uint256 seed2;

        // Token should be the same within one interval (5 blocks)
        uint expectedSeedFirstFiveBlocksTokenIdZero = 47325194593512000241468536448559833359437483699567969619987864577538981999987;

        vm.roll(1);
        seed1 = generateSeed(0);
        seed2 = generateSeed(1);
        assertEq(seed1, expectedSeedFirstFiveBlocksTokenIdZero);
        assertTrue(seed1 != seed2);

        vm.roll(2);
        seed1 = generateSeed(0);
        assertEq(seed1, expectedSeedFirstFiveBlocksTokenIdZero);

        vm.roll(3);
        seed1 = generateSeed(0);
        assertEq(seed1, expectedSeedFirstFiveBlocksTokenIdZero);

        vm.roll(4);
        seed1 = generateSeed(0);
        assertEq(seed1, expectedSeedFirstFiveBlocksTokenIdZero);

        vm.roll(5);
        seed1 = generateSeed(0);
        assertEq(seed1, expectedSeedFirstFiveBlocksTokenIdZero);

        vm.roll(6);
        seed1 = generateSeed(0);
        assertTrue(seed1 != expectedSeedFirstFiveBlocksTokenIdZero);

        vm.roll(7);
        seed1 = generateSeed(0);
    }

    function testCannotReceiveETH() public {
        vm.expectRevert("Cannot receive ETH");
        // Send 1 wei to the contract
        (bool success, ) = address(mercurials).call{value: 1}("");
        assertEq(address(mercurials).balance, 0);
        assertEq(success, false);
    }

    function testOverpaymentRefund() public {
        uint256 tokenId;
        string memory svg;
        uint256 price;
        bytes32 hash;
        uint256 ttl;

        // Get values for mint
        (tokenId, svg, price, hash, ttl) = mercurials.nextToken();

        // Mint with more ETH than the required price
        uint256 overpaymentAmount = 10 ether;
        uint256 totalPayment = price + overpaymentAmount;

        uint256 balanceBefore = address(this).balance;
        mercurials.mint{value: totalPayment}(tokenId, hash);

        // Check that the NFT has been minted successfully
        assertEq(mercurials.balanceOf(address(this)), 1);
        assertEq(mercurials.ownerOf(tokenId), address(this));

        // Verify that the overpayment amount has been refunded
        uint256 expectedBalanceAfter = balanceBefore - price;
        assertEq(address(this).balance, expectedBalanceAfter);
    }

    function testTokenUri() public {
        // Should revert if token does not exist
        vm.expectRevert(Mercurials.TokenDoesNotExist.selector);
        mercurials.tokenURI(0);
    }

    function testGenerateRandom() public {
        uint256 nonce = 0;
        uint256 seed = 0;
        uint256 min = 0;
        uint256 max = 10;
        uint256 random;
        (random, nonce) = generateRandom(min, max, seed, nonce);

        // Nonce should be incremented
        assertLt(random, max);
        assertEq(nonce, 1);

        // Nonce should be incremented
        (random, nonce) = generateRandom(min, max, seed, nonce);
        assertLt(random, max);
        assertEq(nonce, 2);
    }

    function testGenerateRandomBool() public {
        uint256 nonce = 0;
        uint256 seed = 0;
        bool random;
        (random, nonce) = generateRandomBool(seed, nonce);

        // Nonce should be incremented
        assertEq(nonce, 1);

        // Nonce should be incremented
        (random, nonce) = generateRandomBool(seed, nonce);
        assertEq(nonce, 2);
    }

    function testIntToString() public {
        // Positive
        assertEq(intToString(0, false), "0");
        assertEq(intToString(1, false), "1");
        assertEq(intToString(10, false), "10");

        // Negative
        assertEq(intToString(0, true), "0");
        assertEq(intToString(1, true), "-1");
        assertEq(intToString(10, true), "-10");
    }
}

contract MercurialsReentrancyTest is Test {
    Mercurials mercurials;
    uint256 internal tokenId;
    bytes32 internal hash;
    uint256 internal price;

    function setUp() public {
        mercurials = new Mercurials();
        (tokenId, , price, hash, ) = mercurials.nextToken();
    }

    // This fallback function will be called in the middle of the mint operation
    receive() external payable {
        vm.expectRevert("ReentrancyGuard: reentrant call");
        mercurials.mint{value: price}(tokenId, hash);
    }

    function testMintReentrancyAttack() public {
        uint256 balanceBefore = address(this).balance;
        uint256 tokenBalanceBefore = mercurials.balanceOf(address(this));

        // Mint with more ETH than the required price
        uint256 overpaymentAmount = 1 ether;
        uint256 totalPayment = price + overpaymentAmount;
        vm.expectRevert("ETH_TRANSFER_FAILED");
        mercurials.mint{value: totalPayment}(tokenId, hash);

        // Check that balance has not changed
        assertEq(address(this).balance, balanceBefore);

        // Check that the NFT has not been minted
        assertEq(mercurials.balanceOf(address(this)), tokenBalanceBefore);
    }
}
