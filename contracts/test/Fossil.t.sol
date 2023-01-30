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

    function testGenerateRandom2() public {
        uint seed = 0;
        uint nonce = 0;
        uint rand1;
        uint rand2;
        (rand1, nonce) = fossil.generateRandom(0, 3, seed, nonce);
        assertEq(nonce, 1);
        (rand2, nonce) = fossil.generateRandom(0, 3, seed, nonce);
        assertEq(nonce, 2);
        assertTrue(rand1 != rand2);
    }

    function testGenerateSVG() public view {
        fossil.generateSVG(10);
    }
}
