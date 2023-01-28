// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Base64} from "openzeppelin-contracts/contracts/utils/Base64.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {console} from "forge-std/console.sol";

contract Fossil {
    using Strings for uint256;

    function generateRandom(uint min, uint max, uint seed) public pure returns (uint) {
        // safely generates a random uint between min and max using the seed
        require(max > min, "max must be greater than min");
        require(max != 0, "max must be greater than 0");
        uint rand = uint(keccak256(abi.encodePacked(seed)));
        return rand % (max - min) + min;
    }

    /* new */
    function generateSVG(uint seed) public view returns (string memory) {
        /* Filter parameters */
        uint baseFrequency = generateRandom(20, 251, seed -1);
        string memory baseFrequencyStr; 
        if (baseFrequency >= 0 && baseFrequency < 10) {
            baseFrequencyStr = string.concat('0.000', baseFrequency.toString()); // 0.0001 - 0.0010
        } else if (baseFrequency >= 10 && baseFrequency < 100) {
            baseFrequencyStr = string.concat('0.00', baseFrequency.toString()); // 0.010 - 0.100
        } else if (baseFrequency >= 100) {
            baseFrequencyStr = string.concat('0.0', baseFrequency.toString()); // 0.100 - 0.200
        } else {
            console.log('should never happen');
            assert(false);
        }

        // generate random k4 value between 0.01 and 0.50
        uint k4Uint = generateRandom(0, 76, seed - 2);
        string memory operator;
        string memory k4;
        if (generateRandom(0, 2, seed - 3) % 2 == 0) {
            operator = 'out';
            k4 = string.concat('-0.', (75 + k4Uint).toString());
        } else{
            operator = 'in';
            k4 = string.concat('0.', k4Uint.toString());
        }

        // string memory k4 = string.concat('0.', );
        string memory feComposites = string.concat(
            '<feComposite in="blurResult" in2="displacementResult" operator="', operator, '" result="compositeResult2"/>',
            (seed % 3 == 0) ? string.concat('<feComposite in="compositeResult2" in2="compositeResult2" operator="arithmetic" k1="0" k2="1" k3="1" k4="', k4,'"/>') : ''
        );

        uint scale = generateRandom(0, 101, seed+2);

        return
            // prettier-ignore
            string.concat(
                '<svg width="500" height="500" viewBox="0 0 500 500" version="1.1" xmlns="http://www.w3.org/2000/svg">',
                    
                    '<filter id="a">',
                        // Blur for edges
                        '<feGaussianBlur in="SourceGraphic" stdDeviation="10" result="blurResult"/>'

                        // Core filter
                        '<feTurbulence in="blurResult" baseFrequency="', baseFrequencyStr, '" numOctaves="', generateRandom(1, 4, seed+1).toString(), '"',
                            'result="turbulenceResult"> </feTurbulence>',

                        // For animation
                        '<feColorMatrix type="hueRotate">',
                          '<animate attributeName="values" from="0" to="360"',
                                   'dur="3s" repeatCount="indefinite" result="colorMatrixResult"/>',
                        '</feColorMatrix>',

                        // For animation
                        '<feColorMatrix type="matrix"',
                           'values="0 0 0 0 0 ',
                                   '0 0 0 0 0 ',
                                   '0 0 0 0 0 ',
                                   '1 0 0 0 0">',
                        '</feColorMatrix>',

                        // For scale effect
                        '<feDisplacementMap scale="', scale.toString(),'" result="displacementResult">',
                            // '<animate attributeName="scale" from="-', scale.toString() ,'" to="', (scale+100).toString(), '"',
                            //          'dur="10s" repeatCount="indefinite" result="displacementResult"/>',
                        '</feDisplacementMap>',

                        // Add the flatness
                        feComposites,

                        // Light
                        '<feDiffuseLighting lighting-color="white" diffuseConstant="', generateRandom(1, 11, seed+6).toString(), '"',
                                           'result="diffuseResult" surfaceScale="-5">',
                          '<feDistantLight elevation="', generateRandom(0, 5, seed+4).toString(),'">',
                          '</feDistantLight>',
                        '</feDiffuseLighting>',

                        // // Inverse the colors
                        // (generateRandom(0, 2, seed+5) % 2) == 0 ? '' : '<feColorMatrix type="luminanceToAlpha" />',
                    '</filter>',
                  '</defs>',
                  '<rect width="1000" height="1000" filter="url(#a)"/>',
                '</svg>'
            );
    }
}
