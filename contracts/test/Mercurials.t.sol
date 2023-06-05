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
        assertEq(address(mercurials).balance, 0);
        assertEq(success, false);
    }

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
            memory expectedTokenUri = "data:application/json;base64,eyAibmFtZSI6ICJNZXJjdXJpYWwgIzAiLCAiZGVzY3JpcHRpb24iOiAiQW4gYWJzdHJhY3QgYXJ0IHBpZWNlIGdlbmVyYXRlZCBvbi1jaGFpbi4iLCAiaW1hZ2UiOiAiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCM2FXUjBhRDBpTXpVd0lpQm9aV2xuYUhROUlqTTFNQ0lnZG1WeWMybHZiajBpTVM0eElpQjJhV1YzUW05NFBTSXlOU0F5TlNBek1EQWdNekF3SWlCNGJXeHVjejBpYUhSMGNEb3ZMM2QzZHk1M015NXZjbWN2TWpBd01DOXpkbWNpUGp4bWFXeDBaWElnYVdROUltRWlQanhtWlZSMWNtSjFiR1Z1WTJVZ1ltRnpaVVp5WlhGMVpXNWplVDBpTUM0d01UQXdJaUJ1ZFcxUFkzUmhkbVZ6UFNJMElpQnpaV1ZrUFNJeE9Ea3dOaUlnTHo0OFptVkVhWE53YkdGalpXMWxiblJOWVhBK1BHRnVhVzFoZEdVZ1lYUjBjbWxpZFhSbFRtRnRaVDBpYzJOaGJHVWlJSFpoYkhWbGN6MGlNams3TFRFMk1qc3lPVHNpSUd0bGVWUnBiV1Z6UFNJd095QXdMalk3SURFaUlHUjFjajBpTkRoeklpQnlaWEJsWVhSRGIzVnVkRDBpYVc1a1pXWnBibWwwWlNJZ1kyRnNZMDF2WkdVOUluTndiR2x1WlNJZ2EyVjVVM0JzYVc1bGN6MGlNQzR6SURBZ01DNDNJREU3SURBdU15QXdJREF1TnlBeElpOCtQQzltWlVScGMzQnNZV05sYldWdWRFMWhjRDQ4Wm1WRGIyeHZjazFoZEhKcGVDQjBlWEJsUFNKb2RXVlNiM1JoZEdVaUlISmxjM1ZzZEQwaVlpSStQR0Z1YVcxaGRHVWdZWFIwY21saWRYUmxUbUZ0WlQwaWRtRnNkV1Z6SWlCbWNtOXRQU0l3SWlCMGJ6MGlNell3SWlCa2RYSTlJalJ6SWlCeVpYQmxZWFJEYjNWdWREMGlhVzVrWldacGJtbDBaU0l2UGp3dlptVkRiMnh2Y2sxaGRISnBlRDQ4Wm1WRGIyeHZjazFoZEhKcGVDQjBlWEJsUFNKdFlYUnlhWGdpSUhKbGMzVnNkRDBpWXlJZ2RtRnNkV1Z6UFNJd0lEQWdNQ0F3SURBZ01DQXdJREFnTUNBd0lEQWdNQ0F3SURBZ01DQXhJREFnTUNBd0lEQWlMejQ4Wm1WRGIyMXdiM05wZEdVZ2FXNDlJbUlpSUdsdU1qMGlZeUlnYjNCbGNtRjBiM0k5SW05MWRDSWdjbVZ6ZFd4MFBTSmtJaTgrUEdabFEyOXRjRzl6YVhSbElHbHVQU0prSWlCcGJqSTlJbVFpSUc5d1pYSmhkRzl5UFNKaGNtbDBhRzFsZEdsaklpQnJNVDBpTVNJZ2F6STlJakVpSUdzelBTSXhJaUJyTkQwaUxUQXVNRGdpTHo0OFptVkVhV1ptZFhObFRHbG5hSFJwYm1jZ2JHbG5hSFJwYm1jdFkyOXNiM0k5SWlObVptWWlJR1JwWm1aMWMyVkRiMjV6ZEdGdWREMGlNU0lnYzNWeVptRmpaVk5qWVd4bFBTSTVJajQ4Wm1WRWFYTjBZVzUwVEdsbmFIUWdaV3hsZG1GMGFXOXVQU0l4TmlJdlBqd3ZabVZFYVdabWRYTmxUR2xuYUhScGJtYytQQzltYVd4MFpYSStQSEpsWTNRZ2QybGtkR2c5SWpNMU1DSWdhR1ZwWjJoMFBTSXpOVEFpSUdacGJIUmxjajBpZFhKc0tDTmhLU0lnZEhKaGJuTm1iM0p0UFNKeWIzUmhkR1VvT1RBZ01UYzFJREUzTlNraUx6NDhMM04yWno0PSIsICJhdHRyaWJ1dGVzIjogWyB7ICJ0cmFpdF90eXBlIjogIkJhc2UgRnJlcXVlbmN5IiwgInZhbHVlIjogIjAuMDEwMCIgfSwgeyAidHJhaXRfdHlwZSI6ICJPY3RhdmVzIiwgInZhbHVlIjogIjQiIH0sIHsgInRyYWl0X3R5cGUiOiAiU2NhbGUiLCAidmFsdWUiOiAiMjk7LTE2MjsyOTsiIH0sIHsgInRyYWl0X3R5cGUiOiAiU2NhbGUgQW5pbWF0aW9uIiwgInZhbHVlIjogIjQ4cyIgfSwgeyAidHJhaXRfdHlwZSI6ICJLZXkgVGltZSIsICJ2YWx1ZSI6ICIwLjYiIH0sIHsgInRyYWl0X3R5cGUiOiAiSHVlIFJvdGF0ZSBBbmltYXRpb24iLCAidmFsdWUiOiAiNHMiIH0sIHsgInRyYWl0X3R5cGUiOiAiSzQiLCAidmFsdWUiOiAiLTAuMDgiIH0sIHsgInRyYWl0X3R5cGUiOiAiQ29tcG9zaXRlIE9wZXJhdG9yIiwgInZhbHVlIjogIm91dCIgfSwgeyAidHJhaXRfdHlwZSI6ICJEaWZmdXNlIENvbnN0YW50IiwgInZhbHVlIjogIjEiIH0sIHsgInRyYWl0X3R5cGUiOiAiU3VyZmFjZSBTY2FsZSIsICJ2YWx1ZSI6ICI5IiB9LCB7ICJ0cmFpdF90eXBlIjogIkVsZXZhdGlvbiIsICJ2YWx1ZSI6ICIxNiIgfSx7ICJ0cmFpdF90eXBlIjogIlJvdGF0aW9uIiwgInZhbHVlIjogIjkwIiB9LCB7ICJ0cmFpdF90eXBlIjogIkludmVydGVkIiwgInZhbHVlIjogZmFsc2UgfSAgXSB9";
        assertEq(
            keccak256(abi.encodePacked(tokenUri)),
            keccak256(abi.encodePacked(expectedTokenUri))
        );

        // Mint again and verify the token URI has changed
        (tokenId, svg, price, hash, ttl) = mercurials.nextToken();
        mercurials.mint{value: price}(tokenId, hash);
        tokenUri = mercurials.tokenURI(tokenId);
        assertTrue(
            keccak256(abi.encodePacked(tokenUri)) !=
                keccak256(abi.encodePacked(expectedTokenUri))
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
        assertEq(mercurials.balanceOf(address(this)), 1);
        assertEq(mercurials.ownerOf(tokenId), address(this));

        mercurials.transferFrom(address(this), address(0xdead), tokenId);
        assertEq(mercurials.balanceOf(address(this)), 0);
        assertEq(mercurials.ownerOf(tokenId), address(0xdead));
    }

    function testGetCurrentVRGDAPrice() public {
        // Use test contract for Mercurials implementation in order to test
        // the internal function.
        mercurials = this;

        // Verify price is ~0.00105 ETH with default values.
        assertEq(block.timestamp, startTime);
        uint256 price1 = getCurrentVRGDAPrice();
        assertEq(price1, 0.001052631578947368 ether);

        // Verify price goes up after a sale.
        uint256 tokenId;
        string memory svg;
        uint256 price;
        bytes32 hash;
        uint256 ttl;
        (tokenId, svg, price, hash, ttl) = mercurials.nextToken();
        mercurials.mint{value: price}(tokenId, hash);
        uint256 price2 = getCurrentVRGDAPrice();
        assertTrue(price2 > price1, "Price should go up after a sale");

        // Verify price goes down as time passes without a sale.
        vm.warp(startTime + 2 days);
        uint256 price3 = getCurrentVRGDAPrice();
        assertTrue(
            price3 < price2,
            "Price should go down as time passes without a sale"
        );
        assertEq(price3, 0.001 ether);

        // After 10 years without a sale, the price is zero (not negative).
        vm.warp(startTime + 10 * 356 days);
        uint256 price4 = getCurrentVRGDAPrice();
        assertTrue(
            price4 < price3,
            "Price should go down as time passes without a sale"
        );
        assertEq(price4, 0 ether);
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
