// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Base64} from "openzeppelin-contracts/contracts/utils/Base64.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {Counters} from "openzeppelin-contracts/contracts/utils/Counters.sol";
import {console} from "forge-std/console.sol";

contract Fossil {
    using Strings for uint256;

    function constructImageURI(uint seed) public view returns (string memory) {
        string memory svg = generateSVG(seed);
        string memory image = Base64.encode(bytes(svg));
        string memory output = string(
            abi.encodePacked("data:image/svg+xml;base64,", image)
        );

        console.log(svg);
        return output;
    }

    bytes16 internal constant ALPHABET = '0123456789abcdef';
    function toHexStringNoPrefix(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = buffer.length; i > 0; i--) {
            buffer[i - 1] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }

    function generateRandom(uint min, uint max, uint seed) internal view returns (uint) {
        // safely generates a random uint between min and max using the seed
        require(max > min, "max must be greater than min");
        require(max != 0, "max must be greater than 0");
        uint rand = uint(keccak256(abi.encodePacked(seed)));
        return rand % (max - min) + min;
    }

    // function generateRandomColor(uint seed) internal view returns (string memory) {
    //     return string.concat('#', toHexStringNoPrefix(generateRandom(0, 16777215, seed), uint(3)));
    // }

    function generateRandomGrayColor(uint seed) internal view returns (string memory) {
        uint grayVal = generateRandom(0, 255, seed);
        return toString(RGB(grayVal, grayVal, grayVal));
    }

    function generateFrequency(uint tokenId, bool turbulenceType) public view returns (uint, string memory) {
        uint random;
        if (turbulenceType) {
            // Fractal noise
            random = generateRandom(20, 150, tokenId);
        } else {
            // Turbulent noise
            // random = generateRandom(1, 60, tokenId);
            random = generateRandom(15, 60, tokenId);
        }

        string memory frequency; 
        if (random >= 100) {
             frequency = string.concat('0.', random.toString()); // E.g. 0.200
        } else if (random >= 10) {
            frequency = string.concat('0.0', random.toString()); // E.g. 0.020
        } else {
            frequency = string.concat('0.00', random.toString()); // E.g. 0.002
        }

        return (random, frequency);
    }

    function generateOctaves(uint tokenId, bool isFractalNoise, uint frequency) public view returns (string memory) {
        return generateRandom(1, 5, tokenId).toString();
        // uint octaves;
        // if (isFractalNoise) {
        //     return generateRandom(1, 5, tokenId).toString();
        //     // if (frequency >= 100) {
        //     //     octaves = 1;
        //     // } else if (frequency >= 50) {
        //     //     octaves = generateRandom(2, 5, tokenId);
        //     // } else if (frequency > 20) {
        //     //     octaves = generateRandom(3, 5, tokenId);
        //     // } else {
        //     //     octaves = generateRandom(4, 8, tokenId);
        //     // }

        //     // Fractal noise
        //     // return octaves.toString();
        //     // return generateRandom(1, 3, tokenId).toString();
        // }
        // // Turbulence
        // // return generateRandom(2, 5, tokenId).toString();
        // return generateRandom(1, 5, tokenId).toString();
    }

    function generateScale(uint tokenId, bool isFractalNoise, uint frequency) public view returns (string memory) {
        if (isFractalNoise) {
            return generateRandom(0, 100, tokenId).toString();
            // if (frequency > 150) {
            //     return generateRandom(0, 25, tokenId).toString();
            // } else if (frequency > 50) {
            //     return generateRandom(15, 50, tokenId).toString();
            // } else if (frequency > 0) {
            //     return generateRandom(0, 100, tokenId).toString();
            // }
        }
        // Turbulence noise
        return generateRandom(0, 80, tokenId).toString();
    }


    function generateSpecularLighting(uint tokenId, bool isFractalNoise) public view returns (string memory) {
        // string memory surfaceScale = string.concat('-', generateRandom(2, 4, tokenId).toString()); // Was -3.10131121
        string memory surfaceScale = '-3.10131121';

        // Perhaps we limit the specular lighting for HSL color generation techniques.
        // originall (probably should be 0, 99)
        // string memory specularConstant = string.concat('1.', generateRandom(25, 99, tokenId).toString()); // Was 2.13708425
        string memory specularConstant = '2.13708425';
        return
            // prettier-ignore
            string.concat(
              '<feSpecularLighting lighting-color="#ffffff" surfaceScale="', surfaceScale,'" result="r4" specularConstant="', specularConstant,'" specularExponent="15.19753456" in="r2">',
                '<feDistantLight elevation="30" azimuth="60">',
                    // '<animate attributeName="azimuth" values="0;360" dur="10s" repeatCount="indefinite"/>',
                '</feDistantLight>',
              '</feSpecularLighting>'
            );
    }

    struct RGB {
        uint r; // Value between 0 and 255
        uint g; // Value between 0 and 255
        uint b; // Value between 0 and 255
    }

    struct HSL {
        uint h; // Value between 0 and 360
        uint s; // Value between 0 and 100
        uint l; // Value between 0 and 100
    }

    function randomMix(RGB memory color1, RGB memory color2, RGB memory color3, uint greyControl) public view returns (RGB memory) {
        uint randomIndex = uint(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 3);

        uint mixRatio1;
        uint mixRatio2;
        uint mixRatio3;

        if (randomIndex == 0) {
            mixRatio1 = uint(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % (greyControl + 1));
        } else {
            mixRatio1 = uint(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 256);
        }

        if (randomIndex == 1) {
            mixRatio2 = uint(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % (greyControl + 1));
        } else {
            mixRatio2 = uint(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 256);
        }

        if (randomIndex == 2) {
            mixRatio3 = uint(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % (greyControl + 1));
        } else {
            mixRatio3 = uint(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 256);
        }

        uint256 sum = mixRatio1 + mixRatio2 + mixRatio3;

        mixRatio1 = uint(mixRatio1 * 255 / sum);
        mixRatio2 = uint(mixRatio2 * 255 / sum);
        mixRatio3 = uint(mixRatio3 * 255 / sum);

        RGB memory newRGB;
        newRGB.r = mixRatio1 * color1.r + mixRatio2 * color2.r + mixRatio3 * color3.r;
        newRGB.g = mixRatio1 * color1.g + mixRatio2 * color2.g + mixRatio3 * color3.g;
        newRGB.b = mixRatio1 * color1.b + mixRatio2 * color2.b + mixRatio3 * color3.b;

        return newRGB;
    }

    function toString(RGB memory rgb) internal pure returns (string memory) {
        return string.concat('rgb(', rgb.r.toString(), ', ', rgb.g.toString(), ', ', rgb.b.toString(), ')');
    }

    function divideAndFormat(uint input, uint divisor, uint decimalPlaces) public view returns (string memory) {
        // divide input by divisor and format as a string to decimalPlaces decimal places
        // rounding to the nearest decimal place
        uint quotient = input / divisor;
        uint remainder = input % divisor;
        uint decimal = remainder * (10 ** decimalPlaces) / divisor;

        // round up if the decimal is >= 5
        if (decimal >= 5) {
            decimal = decimal + 1;
        }

        return string.concat(quotient.toString(), '.', decimal.toString());
    }
    function generateComponentTransfer(uint tokenId, RGB[5] memory colors) public view returns (string memory) {
        string memory filter = '<feComponentTransfer id="palette" result="rct">';
        string memory funcR = '<feFuncR type="table" tableValues="0 ';
        string memory funcG = '<feFuncG type="table" tableValues="0 ';
        string memory funcB = '<feFuncB type="table" tableValues="0 ';

        // for (uint i=0; i < colors.length; i++) {
        for (uint i=0; i < 5; i++) {
            RGB memory color = colors[i];
            funcR = string.concat(funcR, divideAndFormat(color.r, 256, 1), ' ');
            funcG = string.concat(funcG, divideAndFormat(color.g, 256, 1), ' ');
            funcB = string.concat(funcB, divideAndFormat(color.b, 256, 1), ' ');
        }

        funcR = string.concat(funcR, '" />');
        funcG = string.concat(funcG, '" />');
        funcB = string.concat(funcB, '" />');

        filter = string.concat(filter, funcR, funcG, funcB, '</feComponentTransfer>');
        return filter;
    }

    function generateComponentTransfer(uint tokenId) public view returns (string memory) {
        uint p = 1;
        string[3] memory tableValues;
        for (uint i=0; i < 3; i++) {
            string memory tableValue = '0';
            for (uint j=0; j<2; j++) {
                uint random = generateRandom(0, 10, tokenId + p);
                string memory v = random == 10 ? '1' : string.concat('0.', random.toString());
                tableValue = string.concat(tableValue, ' ', v);
                p++;
            }
            tableValues[i] = string.concat(tableValue, ' 1');
        }

        return
            // prettier-ignore
            string.concat(
              '<feComponentTransfer result="result2">',
                '<feFuncR type="table" tableValues="', tableValues[0], '" />',
                '<feFuncG type="table" tableValues="', tableValues[1], '" />',
                '<feFuncB type="table" tableValues="', tableValues[2], '" />',
              '</feComponentTransfer>'
            );
    }

    // Color pallete of all random colors
    function generateRandomColorPalette(uint seed) public view returns (RGB[5] memory) {
        uint j = 0;
        RGB[5] memory colors;
        for (uint i=0; i < colors.length; i++) {
            // console.log(seed + i + j, 'seed + i + j');
            colors[i] = RGB(
                generateRandom(0, 255, seed + i + j),
                generateRandom(0, 255, seed + i + 1 + j),
                generateRandom(0, 255, seed + i + 2 + j)
            );
            j += 3;
        }

        return colors;
    }

    function averageWithWhite(RGB memory color) public pure returns (RGB memory) {
        RGB memory white = RGB(255, 255, 255);
        // return a new color that is the average of the two colors
        return RGB(
            (color.r + white.r) / 2,
            (color.g + white.g) / 2,
            (color.b + white.b) / 2
        );
    }

    function generateTriadicColors(uint seed) public view returns (RGB[5] memory) {
        RGB memory color = RGB(
            generateRandom(0, 255, seed),
            generateRandom(0, 255, seed + 1),
            generateRandom(0, 255, seed + 2)
        );
        RGB memory complement = RGB(255 - color.r, 255 - color.g, 255 - color.b);
        RGB memory splitComplementary1 = RGB((color.r + 85) % 256, (color.g + 85) % 256, (color.b + 85) % 256);
        RGB memory splitComplementary2 = RGB((color.r + 170) % 256, (color.g + 170) % 256, (color.b + 170) % 256);
        RGB[5] memory colors = [
            color,
            complement,
            splitComplementary1,
            splitComplementary2,
            RGB(color.r, complement.g, complement.b)
        ];

        return colors;
    }

    /* new */
    function generateSVG(uint seed) public view returns (string memory) {
        /* Filter parameters */
        bool isFractalNoise = true;
        string memory turbulenceType = isFractalNoise ? "fractalNoise" : "turbulence";
        // string memory turbulenceType = "turbulence";
        (uint frequencyInt, string memory frequency) = generateFrequency(seed, isFractalNoise);
        string memory octaves = generateOctaves(seed, isFractalNoise, frequencyInt);
        string memory scale = generateScale(seed, isFractalNoise, frequencyInt);

        // RGB[5] memory colors = generateRandomColorPalette(seed);
        // RGB[5] memory colors = generateTriadicColors(seed);
        // string memory feComponentTransfer = generateComponentTransfer(
        //     seed,
        //     colors
        // );
        string memory feComponentTransfer = generateComponentTransfer(seed);

        return
            // prettier-ignore
            string.concat(
                '<svg width="500" height="500" viewBox="0 0 500 500" version="1.1" xmlns="http://www.w3.org/2000/svg">',
                  '<defs>',
                    '<filter id="cracked-lava" color-interpolation-filters="sRGB">',
                      '<feFlood flood-color="rgb(152,152,152)" result="r15" />',
                      // '<feFlood flood-color="', grayRGB2,'" result="r15" />',

                      '<feTurbulence baseFrequency="', frequency, '" type="', turbulenceType, '" numOctaves="', octaves,'" result="r1" />',
                      '<feDisplacementMap result="r5" xChannelSelector="R" in2="r1" in="r1" yChannelSelector="G" scale="', scale, '" />',
                      '<feComposite result="r2" operator="in" in="r15" in2="r5" />',
                      generateSpecularLighting(seed, isFractalNoise),
                      '<feComposite k1="0.3874092" k3="1" k2="-0.5" in2="r2" in="r4" operator="arithmetic" result="r91" k4="0" />',
                      '<feComposite in="r91" result="r4" operator="arithmetic" k2="2" k3="3.9779434" in2="r91" k1="0" k4="-0.57127724" />',
                      feComponentTransfer,
                      // '<feFlood result="result1" flood-color="', generateRandomColor(seed),'" />',

                      // '<feFlood result="result1" flood-color="', grayRGB,'" />',
                      // '<feBlend mode="normal" in2="result1" in="rct" />',
                    '</filter>',
                  '</defs>',
                  '<rect width="500" height="500" filter="url(#cracked-lava)" style="filter:url(#cracked-lava)" />',
                  // '<rect width="50" height="50" x="0" y="0" fill="', toString(colors[0]),'" />',
                  // '<rect width="50" height="50" x="50" y="0" fill="', toString(colors[1]),'" />',
                  // '<rect width="50" height="50" x="100" y="0" fill="', toString(colors[2]),'" />',
                  // '<rect width="50" height="50" x="150" y="0" fill="', toString(colors[3]),'" />',
                  // '<rect width="50" height="50" x="200" y="0" fill="', toString(colors[4]),'" />',
                '</svg>'
            );
    }
}
