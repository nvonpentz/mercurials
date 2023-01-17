// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Base64} from "openzeppelin-contracts/contracts/utils/Base64.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {Counters} from "openzeppelin-contracts/contracts/utils/Counters.sol";
import {console} from "forge-std/console.sol";

contract Fossil {
    using Strings for uint256;

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
      return min + uint(keccak256(abi.encodePacked(seed, min, max))) % (max - min + 1);
    }

    function generateRandomColor(uint seed) internal view returns (string memory) {
        return string.concat('#', toHexStringNoPrefix(generateRandom(0, 16777215, seed), uint(3)));
    }

    // function generateComplementaryColor(uint color) public pure returns(uint) {
    //     uint red = color >> 16;
    //     uint green = (color >> 8) & 0xFF;
    //     uint blue = color & 0xFF;
        
    //     red = 255 - red;
    //     green = 255 - green;
    //     blue = 255 - blue;
        
    //     return (red << 16) | (green << 8) | blue;
    // }

    // function toHexColor(uint colorInt) public view returns (string memory) {
    //     return string.concat('#', toHexStringNoPrefix(colorInt, uint(3)));
    // } 

    // function generateBackgroundColor(uint tokenId) public view returns (string memory) {
    //     string memory valForColor = generateRandom(0, 256, tokenId).toString();
    //     return string.concat('rgb(', valForColor, ',', valForColor, ',', valForColor, ')');
    // }

    // function generatePrimaryColor(uint tokenId) public view returns (uint) {
    //     uint seed = uint(keccak256(abi.encodePacked(tokenId, uint(0))));
    //     return generateRandom(0, 16777215, seed);
    // }

    function generateFrequency(uint tokenId) public view returns (string memory) {
        uint random = generateRandom(30, 99, tokenId);
        string memory frequency;
        if (random < 100) {
            frequency = string.concat('0', random.toString());
        } else if (random < 10) {
            frequency = string.concat('00', random.toString());
        } else {
            frequency = random.toString();
        }

        return frequency;
    }

    function generateOctaves(uint tokenId, bool turbulenceType) public view returns (string memory) {
        if (turbulenceType) {
            // Fractal noise
        }

        // Turbulence
        return generateRandom(1, 3, tokenId).toString();
    }

    function generateScale(uint tokenId, bool turbulenceType) public view returns (string memory) {
        if (turbulenceType) {
            // Fractal noise
            return generateRandom(10, 100, tokenId).toString();
        }
        // Turbulence noise
        return generateRandom(0, 80, tokenId).toString();
    }

    /* new */
    function constructImageURI(uint seed) public view returns (string memory) {
        string memory svg = generateSVG(seed);
        console.log(svg);
        string memory image = Base64.encode(bytes(svg));
        string memory output = string(
            abi.encodePacked("data:image/svg+xml;base64,", image)
        );

        console.log('end constructImageURI');
        return output;
    }

    function generateSVG(uint seed) public view returns (string memory) {
        /* Color parameters*/
        string memory backgroundColor = generateRandomColor(seed);
        console.log('backgroundColor', backgroundColor);
        // string memory foregroundColor = generateRandomColor(seed+1);
        // console.log('foregroundColor', foregroundColor);



        /* Filter parameters */
        bool turbulenceTypeBool = seed % 2 == 0; 
        string memory turbulenceType = turbulenceTypeBool ? "fractalNoise" : "turbulence";
        string memory frequency = generateFrequency(seed);
        string memory scale = generateScale(seed, turbulenceTypeBool);
        string memory octaves = generateOctaves(seed, turbulenceTypeBool);
        console.log('turblenceType:', turbulenceType);
        console.log('frequency:', frequency);
        console.log('scale:', scale);
        console.log('octaves:', octaves);

        return
            // prettier-ignore
            string.concat(
                '<svg width="500" height="500" version="1.1" viewBox="0 0 500 500" xmlns="http://www.w3.org/2000/svg">',
                  '<defs>',
                    '<filter id="cracked-lava">',
                      // '<feFlood flood-color="', foregroundColor,'" result="r15" />',
                      '<feFlood flood-color="gray" result="r15" />',
                      '<feTurbulence baseFrequency="0.', frequency, '" type="', turbulenceType, '" numOctaves="', octaves ,'" result="r1" />',
                      '<feDisplacementMap result="r5" xChannelSelector="R" in2="r1" in="r1" yChannelSelector="G" scale="', scale, '"> </feDisplacementMap>',
                      '<feComposite result="r2" operator="in" in="r15" in2="r5" />',
                      '<feSpecularLighting lighting-color="#ffffff" surfaceScale="-3.10131121" result="r4" specularConstant="2.13708425" specularExponent="15.19753456" in="r2"> <feDistantLight elevation="60" azimuth="0"> </feDistantLight> </feSpecularLighting>',
                      '<feComposite k1="0.3874092" k3="1" k2="-0.5" in2="r2" in="r4" operator="arithmetic" result="r91" k4="0" />',
                      '<feComposite in="r91" result="r4" operator="arithmetic" k2="2" k3="3.9779434" in2="r91" k1="0" k4="-0.57127724" />',
                      '<feFlood result="result2" flood-color="', backgroundColor, '" flood-opacity="1" />',
                      '<feComposite in2="result2" in="r4" operator="over" />',
                    '</filter>',
                  '</defs>',
                  '<rect width="500" height="500" filter="url(#cracked-lava)" />',
                  '<rect width="50" height="50" x="0" fill="', backgroundColor, '" />',
                  // '<rect width="50" height="50" x="50" fill="', foregroundColor, '" />',
                '</svg>'
            );
    }
}
