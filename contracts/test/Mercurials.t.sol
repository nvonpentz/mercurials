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

    receive() external payable {}

    function testCannotReceiveETH() public {
        vm.expectRevert("Cannot receive ETH");
        // Send 1 wei to the contract
        (bool success, ) = address(mercurials).call{value: 1}("");
        assertEq(
            address(mercurials).balance,
            0,
            "Contract balance should be 0"
        );
        assertEq(
            success,
            false,
            "Should not be able to send ETH to Mercurials contract"
        );
    }

    function testNextToken() public {
        // Verify default values (-1 days ahead of schedule)
        (
            uint tokenId1,
            string memory svg1,
            uint256 price1,
            bytes32 hash1,
            uint256 ttl1
        ) = mercurials.nextToken();
        assertEq(tokenId1, 0, "Token ID should be 0");
        assertGt(bytes(svg1).length, 0, "SVG should not be empty");
        assertEq(
            price1,
            0.001292355434899816 ether,
            "Price should be about 0.00129 ETH"
        );
        assertEq(
            hash1,
            blockhash(block.number - 1),
            "Hash should be blockhash of previous block"
        );
        assertEq(ttl1, 5, "TTL should be 5");

        // Increase block number by 1
        vm.roll(block.number + 1);
        (
            uint tokenId2,
            string memory svg2,
            uint256 price2,
            bytes32 hash2,
            uint256 ttl2
        ) = mercurials.nextToken();
        assertEq(tokenId1, tokenId2, "Token ID should be the same");
        assertEq(svg1, svg2, "SVG should be the same");
        assertEq(price1, price2, "Price should be the same");
        assertEq(hash1, hash2, "Hash should be the same");
        assertEq(ttl1 - 1, ttl2, "TTL should be 1 less");

        // Increase block number by 4, so the token expires
        vm.roll(block.number + 4);
        (
            uint tokenId3,
            string memory svg3,
            uint256 price3,
            bytes32 hash3,
            uint256 ttl3
        ) = mercurials.nextToken();
        assertEq(tokenId2, tokenId3, "Token ID should be the same");
        assertEq(price2, price3, "Price should be the same");
        assertFalse(
            keccak256(bytes(svg2)) == keccak256(bytes(svg3)),
            "SVG should be different"
        );
        assertFalse(hash2 == hash3, "Hash should be different");
        assertEq(ttl3, 5, "TTL should be 5");

        // Increase timestamp by 1 second (test price sensitivity to time)
        vm.warp(block.timestamp + 1 seconds);
        (
            uint tokenId4,
            string memory svg4,
            uint256 price4,
            bytes32 hash4,
            uint256 ttl4
        ) = mercurials.nextToken();
        assertEq(tokenId3, tokenId4, "Token ID should be the same");
        assertEq(svg3, svg4, "SVG should be the same");
        assertLt(price4, price3, "Price should be less");
        assertEq(hash3, hash4, "Hash should be the same");
        assertEq(ttl3, ttl4, "TTL should be the same");

        // Increase timestamp by 5 days - 1 second (+0 days ahead of schedule)
        vm.warp(block.timestamp + (5 days - 1 seconds));
        (uint tokenId5, , uint256 price5, bytes32 hash5, ) = mercurials
            .nextToken();
        assertEq(price5, 0.001 ether, "Price should be 0.001 ETH");

        // Mint a token (+1 days ahead of schedule)
        mercurials.mint{value: price5}(tokenId5, hash5);
        (, , uint256 price6, , ) = mercurials.nextToken();
        assertEq(price6, 0.001292355434899816 ether, "Price should be 0.00129");

        // Mint 9 tokens (+10 days ahead of schedule)
        for (uint i = 0; i < 9; i++) {
            (uint tokenId, , uint256 price, bytes32 hash, ) = mercurials
                .nextToken();
            mercurials.mint{value: price}(tokenId, hash);
        }
        (, , uint256 price7, , ) = mercurials.nextToken();
        assertEq(
            price7,
            0.012996300231480360 ether,
            "Price should be 0.012996300231480360"
        );

        // Mint 10 tokens (+20 days ahead of schedule)
        for (uint i = 0; i < 10; i++) {
            (uint tokenId, , uint256 price, bytes32 hash, ) = mercurials
                .nextToken();
            mercurials.mint{value: price}(tokenId, hash);
        }
        (, , uint256 price8, , ) = mercurials.nextToken();
        assertEq(
            price8,
            0.168903819706776462 ether,
            "Price should be 0.129963002314803600"
        );

        // Mint 10 tokens (+30 days ahead of schedule)
        for (uint i = 0; i < 10; i++) {
            (uint tokenId, , uint256 price, bytes32 hash, ) = mercurials
                .nextToken();
            mercurials.mint{value: price}(tokenId, hash);
        }
        (, , uint256 price9, , ) = mercurials.nextToken();
        assertEq(
            price9,
            2.195124751153095951 ether,
            "Price should be 0.168903819706776462"
        );

        // After 10 years without a sale, the price is zero
        vm.warp(block.timestamp + 365 days * 10);
        (, , uint256 price10, , ) = mercurials.nextToken();
        assertEq(price10, 0, "Price should be 0");
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
        assertEq(
            mercurials.balanceOf(address(this)),
            1,
            "Test contract should own 1 token"
        );
        assertEq(
            address(this).balance,
            balanceBefore - price,
            "Test contract should have less ETH"
        );
        assertEq(mercurials.totalSold(), 1, "Total sold should be 1");

        // Attempt to mint again with same token ID
        vm.expectRevert(Mercurials.InvalidTokenId.selector);
        mercurials.mint{value: price}(tokenId, hash);

        // Mint with too much ETH
        balanceBefore = address(this).balance;
        (tokenId, svg, price, hash, ttl) = mercurials.nextToken();
        mercurials.mint{value: price + 1}(tokenId, hash);

        // Validate token ownership, balance and total sold again after minting with extra ETH
        assertEq(
            mercurials.balanceOf(address(this)),
            2,
            "Test contract should own 2 tokens"
        );
        assertEq(
            address(this).balance,
            balanceBefore - price,
            "Test contract should have less ETH"
        );
        assertEq(mercurials.totalSold(), 2, "Total sold should be 2");
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
        assertEq(ttl, 5, "TTL should be 5");

        vm.roll(2);
        (, , price, , ttl) = mercurials.nextToken();
        assertEq(ttl, 4, "TTL should be 4");
        mercurials.mint{value: price}(tokenId, hash);
        assertEq(
            mercurials.balanceOf(address(this)),
            1,
            "Test contract should own 1 token"
        );
        assertEq(
            mercurials.ownerOf(tokenId),
            address(this),
            "Test contract should own token"
        );

        vm.roll(3);
        (, , price, , ttl) = mercurials.nextToken();
        assertEq(ttl, 3, "TTL should be 3");
        mercurials.mint{value: price}(tokenId + 1, hash);
        assertEq(
            mercurials.balanceOf(address(this)),
            2,
            "Test contract should own 2 tokens"
        );
        assertEq(
            mercurials.ownerOf(tokenId + 1),
            address(this),
            "Test contract should own the token"
        );

        vm.roll(4);
        (, , price, , ttl) = mercurials.nextToken();
        assertEq(ttl, 2, "TTL should be 2");
        mercurials.mint{value: price}(tokenId + 2, hash);
        assertEq(
            mercurials.balanceOf(address(this)),
            3,
            "Test contract should own 3 tokens"
        );
        assertEq(
            mercurials.ownerOf(tokenId + 2),
            address(this),
            "Test contract should own the token"
        );

        vm.roll(5);
        (, , price, , ttl) = mercurials.nextToken();
        assertEq(ttl, 1, "TTL should be 1");
        mercurials.mint{value: price}(tokenId + 3, hash);
        assertEq(
            mercurials.balanceOf(address(this)),
            4,
            "Test contract should own 4 tokens"
        );
        assertEq(
            mercurials.ownerOf(tokenId + 3),
            address(this),
            "Test contract should own the token"
        );

        // Should not work with expired details
        vm.roll(6);
        (, , price, , ttl) = mercurials.nextToken();
        assertEq(ttl, 5, "TTL should be 5");
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
            assertEq(
                mercurials.balanceOf(address(this)),
                i + 1,
                "Incorrect balance"
            );
            assertEq(
                mercurials.ownerOf(tokenId),
                address(this),
                "Incorrect owner"
            );
            assertEq(mercurials.totalSold(), i + 1, "Incorrect total sold");
        }
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
        assertEq(
            mercurials.balanceOf(address(this)),
            1,
            "Test contract should own 1 token"
        );
        assertEq(
            mercurials.ownerOf(tokenId),
            address(this),
            "Test contract should own the token"
        );

        // Verify that the overpayment amount has been refunded
        uint256 expectedBalanceAfter = balanceBefore - price;
        assertEq(
            address(this).balance,
            expectedBalanceAfter,
            "Contract should have been refunded"
        );
    }

    function testTokenUri() public {
        // Get values for mint
        uint256 tokenId;
        string memory svg;
        uint256 price;
        bytes32 hash;
        uint256 ttl;
        (tokenId, svg, price, hash, ttl) = mercurials.nextToken();

        // Should revert since token does not exist yet
        vm.expectRevert(Mercurials.TokenDoesNotExist.selector);
        mercurials.tokenURI(0);

        // Mint
        mercurials.mint{value: price}(tokenId, hash);

        // Fetch the token URI
        string memory tokenUri = mercurials.tokenURI(tokenId);
        string
            memory expectedTokenUri = "data:application/json;base64,eyAibmFtZSI6ICJNZXJjdXJpYWwgIzAiLCAiZGVzY3JpcHRpb24iOiAiQWJzdHJhY3Qgb24tY2hhaW4gZ2VuZXJhdGl2ZSBhcnQiLCAiaW1hZ2UiOiAiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCM2FXUjBhRDBpTXpVd0lpQm9aV2xuYUhROUlqTTFNQ0lnZG1WeWMybHZiajBpTVM0eElpQjJhV1YzUW05NFBTSXdJREFnTXpVd0lETTFNQ0lnZUcxc2JuTTlJbWgwZEhBNkx5OTNkM2N1ZHpNdWIzSm5Mekl3TURBdmMzWm5JajQ4Wm1sc2RHVnlJR2xrUFNKaElqNDhabVZVZFhKaWRXeGxibU5sSUdKaGMyVkdjbVZ4ZFdWdVkzazlJakF1TURFd01DSWdiblZ0VDJOMFlYWmxjejBpTkNJZ2MyVmxaRDBpTVRnNU1EWWlJQzgrUEdabFJHbHpjR3hoWTJWdFpXNTBUV0Z3UGp4aGJtbHRZWFJsSUdGMGRISnBZblYwWlU1aGJXVTlJbk5qWVd4bElpQjJZV3gxWlhNOUlqTTVPeTB6TXpzek9Uc2lJR3RsZVZScGJXVnpQU0l3T3lBd0xqUTdJREVpSUdSMWNqMGlORGh6SWlCeVpYQmxZWFJEYjNWdWREMGlhVzVrWldacGJtbDBaU0lnWTJGc1kwMXZaR1U5SW5Od2JHbHVaU0lnYTJWNVUzQnNhVzVsY3owaU1DNHpJREFnTUM0M0lERTdJREF1TXlBd0lEQXVOeUF4SWk4K1BDOW1aVVJwYzNCc1lXTmxiV1Z1ZEUxaGNENDhabVZEYjJ4dmNrMWhkSEpwZUNCMGVYQmxQU0pvZFdWU2IzUmhkR1VpSUhKbGMzVnNkRDBpWWlJK1BHRnVhVzFoZEdVZ1lYUjBjbWxpZFhSbFRtRnRaVDBpZG1Gc2RXVnpJaUJtY205dFBTSXdJaUIwYnowaU16WXdJaUJrZFhJOUlqUnpJaUJ5WlhCbFlYUkRiM1Z1ZEQwaWFXNWtaV1pwYm1sMFpTSXZQand2Wm1WRGIyeHZjazFoZEhKcGVENDhabVZEYjJ4dmNrMWhkSEpwZUNCMGVYQmxQU0p0WVhSeWFYZ2lJSEpsYzNWc2REMGlZeUlnZG1Gc2RXVnpQU0l3SURBZ01DQXdJREFnTUNBd0lEQWdNQ0F3SURBZ01DQXdJREFnTUNBeElEQWdNQ0F3SURBaUx6NDhabVZEYjIxd2IzTnBkR1VnYVc0OUltSWlJR2x1TWowaVl5SWdiM0JsY21GMGIzSTlJbWx1SWlCeVpYTjFiSFE5SW1RaUx6NDhabVZEYjIxd2IzTnBkR1VnYVc0OUltUWlJR2x1TWowaVpDSWdiM0JsY21GMGIzSTlJbUZ5YVhSb2JXVjBhV01pSUdzeFBTSXhJaUJyTWowaU1TSWdhek05SWpFaUlHczBQU0l0TUM0d015SXZQanhtWlVScFptWjFjMlZNYVdkb2RHbHVaeUJzYVdkb2RHbHVaeTFqYjJ4dmNqMGlJMlptWmlJZ1pHbG1ablZ6WlVOdmJuTjBZVzUwUFNJeElpQnpkWEptWVdObFUyTmhiR1U5SWpNMUlqNDhabVZFYVhOMFlXNTBUR2xuYUhRZ1pXeGxkbUYwYVc5dVBTSTBPQ0l2UGp3dlptVkVhV1ptZFhObFRHbG5hSFJwYm1jK1BHWmxRMjlzYjNKTllYUnlhWGdnZEhsd1pUMGliV0YwY21sNElpQjJZV3gxWlhNOUlpMHhJREFnTUNBd0lERWdNQ0F0TVNBd0lEQWdNU0F3SURBZ0xURWdNQ0F4SURBZ01DQXdJREVnTUNJdlBqd3ZabWxzZEdWeVBqeHlaV04wSUhkcFpIUm9QU0l6TlRBaUlHaGxhV2RvZEQwaU16VXdJaUJtYVd4MFpYSTlJblZ5YkNnallTa2lJSFJ5WVc1elptOXliVDBpY205MFlYUmxLRGt3SURFM05TQXhOelVwSWk4K1BDOXpkbWMrIiwgImF0dHJpYnV0ZXMiOiBbIHsgInRyYWl0X3R5cGUiOiAiQmFzZSBGcmVxdWVuY3kiLCAidmFsdWUiOiAiMC4wMTAwIiB9LCB7ICJ0cmFpdF90eXBlIjogIk9jdGF2ZXMiLCAidmFsdWUiOiAiNCIgfSwgeyAidHJhaXRfdHlwZSI6ICJTY2FsZSIsICJ2YWx1ZSI6ICIzOTstMzM7Mzk7IiB9LCB7ICJ0cmFpdF90eXBlIjogIlNjYWxlIEFuaW1hdGlvbiIsICJ2YWx1ZSI6ICI0OHMiIH0sIHsgInRyYWl0X3R5cGUiOiAiS2V5IFRpbWUiLCAidmFsdWUiOiAiMC40IiB9LCB7ICJ0cmFpdF90eXBlIjogIkh1ZSBSb3RhdGUgQW5pbWF0aW9uIiwgInZhbHVlIjogIjRzIiB9LCB7ICJ0cmFpdF90eXBlIjogIks0IiwgInZhbHVlIjogIi0wLjAzIiB9LCB7ICJ0cmFpdF90eXBlIjogIkNvbXBvc2l0ZSBPcGVyYXRvciIsICJ2YWx1ZSI6ICJpbiIgfSwgeyAidHJhaXRfdHlwZSI6ICJEaWZmdXNlIENvbnN0YW50IiwgInZhbHVlIjogIjEiIH0sIHsgInRyYWl0X3R5cGUiOiAiU3VyZmFjZSBTY2FsZSIsICJ2YWx1ZSI6ICIzNSIgfSwgeyAidHJhaXRfdHlwZSI6ICJFbGV2YXRpb24iLCAidmFsdWUiOiAiNDgiIH0sIHsgInRyYWl0X3R5cGUiOiAiSW52ZXJ0ZWQiLCAidmFsdWUiOiB0cnVlIH0sIHsgInRyYWl0X3R5cGUiOiAiUm90YXRpb24iLCAidmFsdWUiOiAiOTAiIH0gIF0gfQ==";
        assertEq(tokenUri, expectedTokenUri, "Token URI is incorrect");

        // Mint again and verify the token URI has changed
        (tokenId, svg, price, hash, ttl) = mercurials.nextToken();
        mercurials.mint{value: price}(tokenId, hash);
        tokenUri = mercurials.tokenURI(tokenId);
        assertTrue(
            keccak256(abi.encodePacked(tokenUri)) !=
                keccak256(abi.encodePacked(expectedTokenUri)),
            "Token URI is incorrect"
        );
    }

    function testTransfer() public {
        uint256 tokenId;
        string memory svg;
        uint256 price;
        bytes32 hash;
        uint256 ttl;

        (tokenId, svg, price, hash, ttl) = mercurials.nextToken();
        mercurials.mint{value: price}(tokenId, hash);
        assertEq(
            mercurials.balanceOf(address(this)),
            1,
            "Incorrect balance after mint"
        );
        assertEq(
            mercurials.ownerOf(tokenId),
            address(this),
            "Incorrect owner after mint"
        );

        mercurials.transferFrom(address(this), address(0xdead), tokenId);
        assertEq(
            mercurials.balanceOf(address(this)),
            0,
            "Incorrect balance after transfer"
        );
        assertEq(
            mercurials.ownerOf(tokenId),
            address(0xdead),
            "Incorrect owner after transfer"
        );
    }

    function testName() public {
        string memory name = mercurials.name();
        assertEq(name, "Mercurials", "Incorrect name");
    }

    function testSymbol() public {
        string memory symbol = mercurials.symbol();
        assertEq(symbol, "MERC", "Incorrect symbol");
    }

    function testGenerateSeed() public {
        uint256 seed1;
        uint256 seed2;

        // Token should be the same within one interval (5 blocks)
        uint expectedSeedFirstFiveBlocksTokenIdZero = 47325194593512000241468536448559833359437483699567969619987864577538981999987;

        assertEq(block.number, 1);
        seed1 = generateSeed(0);
        seed2 = generateSeed(1);
        assertEq(
            seed1,
            expectedSeedFirstFiveBlocksTokenIdZero,
            "Seed should be the same within one interval (+0 blocks)"
        );
        assertTrue(seed1 != seed2);

        vm.roll(2);
        seed1 = generateSeed(0);
        assertEq(
            seed1,
            expectedSeedFirstFiveBlocksTokenIdZero,
            "Seed should be the same within one interval (+1 block)"
        );

        vm.roll(3);
        seed1 = generateSeed(0);
        assertEq(
            seed1,
            expectedSeedFirstFiveBlocksTokenIdZero,
            "Seed should be the same within one interval (+2 blocks)"
        );

        vm.roll(4);
        seed1 = generateSeed(0);
        assertEq(
            seed1,
            expectedSeedFirstFiveBlocksTokenIdZero,
            "Seed should be the same within one interval (+3 blocks)"
        );

        vm.roll(5);
        seed1 = generateSeed(0);
        assertEq(
            seed1,
            expectedSeedFirstFiveBlocksTokenIdZero,
            "Seed should be the same within one interval (+4 blocks)"
        );

        vm.roll(6);
        seed1 = generateSeed(0);
        assertTrue(
            seed1 != expectedSeedFirstFiveBlocksTokenIdZero,
            "Seed should be different after one interval (+5 blocks)"
        );
    }

    function testGenerateRandom() public {
        uint256 nonce = 0;
        uint256 seed = 0;
        uint256 min = 0;
        uint256 max = 10;
        uint256 random;

        (random, nonce) = generateRandom(min, max, seed, nonce);
        assertLt(random, max, "Random number should be less than max");
        assertEq(nonce, 1, "Nonce should be incremented");

        (random, nonce) = generateRandom(min, max, seed, nonce);
        assertLt(random, max, "Random number should be less than max");
        assertEq(nonce, 2, "Nonce should be incremented");
    }

    function testGenerateRandomBool() public {
        uint256 nonce = 0;
        uint256 seed = 0;
        bool random;
        (random, nonce) = generateRandomBool(seed, nonce);

        assertEq(nonce, 1, "Nonce should be incremented");

        (random, nonce) = generateRandomBool(seed, nonce);
        assertEq(nonce, 2, "Nonce should be incremented");
    }

    function testIntToString() public {
        // Positive
        assertEq(intToString(0, false), "0", "positive 0 should be '0'");
        assertEq(intToString(1, false), "1", "positive 1 should be '1'");
        assertEq(intToString(10, false), "10", "positive 10 should be '10'");

        // Negative
        assertEq(intToString(0, true), "0", "negative 0 should be '0'");
        assertEq(intToString(1, true), "-1", "negative 1 should be '-1'");
        assertEq(intToString(10, true), "-10", "negative 10 should be '-10'");
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
        assertEq(
            address(this).balance,
            balanceBefore,
            "Balance should not change"
        );

        // Check that the NFT has not been minted
        assertEq(
            mercurials.balanceOf(address(this)),
            tokenBalanceBefore,
            "Token balance should not change"
        );
    }
}
