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
        // fossil.mint(address(this));
        // assertEq(fossil.balanceOf(address(this)), 1);
        // assertEq(fossil.ownerOf(1), address(this));
    }

    function testTokenURI() public {
        // fossil.mint(address(this));
        // string memory tokenURI = fossil.tokenURI(1);
        // assertTrue(bytes(tokenURI).length > 0);
    }

    function testDivideAndFormat () public {
        // assertEq(fossil.divideAndFormat(10, 1), "10.0");
        assertEq(fossil.divideAndFormat(33, 256, 2), "0.13");
        assertEq(fossil.divideAndFormat(0, 256, 2), "0.0");
        assertEq(fossil.divideAndFormat(256, 256, 2), "1.0");
    }

    // function testGenerateComponentTransfer() public {
    //     Fossil.RGB[5] memory colors = [
    //         Fossil.RGB(0, 33, 0),
    //         Fossil.RGB(255, 0, 0),
    //         Fossil.RGB(0, 255, 0),
    //         Fossil.RGB(0, 33, 255),
    //         Fossil.RGB(255, 255, 255)
    //     ];
    //     string memory filter = fossil.generateComponentTransfer(1, colors);
    //     assertEq(filter, 
    //         // prettier-ignore
    //         string.concat('<feComponentTransfer id="palette">',
    //                         '<feFuncR type="table" tableValues="0.0 0.100 0.0 0.0 0.100 " />',
    //                         '<feFuncG type="table" tableValues="0.13 0.0 0.100 0.13 0.100 " />',
    //                         '<feFuncB type="table" tableValues="0.0 0.0 0.0 0.100 0.100 " />',
    //                     '</feComponentTransfer>'));
    // }

    function testGenerateRandomColorPalette() public view returns (Fossil.RGB[5] memory) {
        fossil.generateRandomColorPalette(1);
    }

    function testGenerateRandomSaturationAndLuminence() public view returns (uint8[5] memory, uint8[5] memory) {
        // fossil.generateSimilarHSLColorPalette(1);
    }

    // function testhslToRgb() public {
    //     Fossil.RGB memory rgb = fossil.hslToRgb(Fossil.HSL(0, 0, 0));
    //     assertEq(rgb.r, 0);
    //     assertEq(rgb.g, 0);
    //     assertEq(rgb.b, 0);

    //     // More test cases converting HSL values to RGB
    //     // https://www.rapidtables.com/convert/color/hsl-to-rgb.html
    //     Fossil.RGB memory rgb2 = fossil.hslToRgb(Fossil.HSL(0, 100, 50));
    //     assertEq(rgb2.r, 255);
    //     assertEq(rgb2.g, 0);
    //     assertEq(rgb2.b, 0);
    // }

    function testRandomMix() public {
        Fossil.RGB memory color1 = Fossil.RGB({r: 255, g: 0, b: 0});
        Fossil.RGB memory color2 = Fossil.RGB({r: 0, g: 255, b: 0});
        Fossil.RGB memory color3 = Fossil.RGB({r: 0, g: 0, b: 255});
        uint8 greyControl = 128;
        Fossil.RGB memory mixedColor = fossil.randomMix(color1, color2, color3, greyControl);
        assertGe(mixedColor.r, 0);
        assertLe(mixedColor.r, 255);
        assertGe(mixedColor.g, 0);
        assertLe(mixedColor.g, 255);
        assertGe(mixedColor.b, 0);
        assertLe(mixedColor.b, 255);
    }
}
