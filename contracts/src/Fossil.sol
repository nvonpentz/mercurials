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

    function generateSVG(uint seed) public view returns (string memory) {

        // feTurbulence baseFrequency
        uint baseFrequency = generateRandom(50, 251, seed -1);
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

        // feComposites
        string memory k4Operator;
        string memory k4;

        // feComposite operator
        if (generateRandom(0, 2, seed - 10) % 2 == 0) {
            k4Operator = 'out';
        } else {
            k4Operator = 'in';
        }

        // feComposite k1, k2, k3
        string memory k1; string memory k2; string memory k3;
        // randomly choose which of k1, k2, or k3 to set to '1'
        uint kIndex = generateRandom(1, 4, seed - 11);
        if (kIndex == 1) {
            k1 = '1';
            k2 = generateRandom(0, 2, seed - 12) % 2 == 0 ? '0' : '1';
            k3 = generateRandom(0, 2, seed - 13) % 2 == 0 ? '0' : '1';
        } else if (kIndex == 2) {
            k2 = '1';
            k1 = generateRandom(0, 2, seed - 12) % 2 == 0 ? '0' : '1';
            k3 = generateRandom(0, 2, seed - 13) % 2 == 0 ? '0' : '1';
        } else if (kIndex == 3) {
            k3 = '1';
            k1 = generateRandom(0, 2, seed - 12) % 2 == 0 ? '0' : '1';
            k2 = generateRandom(0, 2, seed - 13) % 2 == 0 ? '0' : '1';
        } else {
            console.log('should never happen');
            assert(false);
        }

        // feComposite k4
        uint k4Uint = generateRandom(0, 51, seed - 2);
        if (k4Uint > 0 && k4Uint < 10) {
            k4 = string.concat('0.0', k4Uint.toString());
        } else if (k4Uint >= 10 && k4Uint < 100) {
            k4 = string.concat('0.', k4Uint.toString());
        } else {
            console.log('should never happen');
            assert(false);
        }

        // randomly make k4 negative
        if (generateRandom(0, 2, seed - 3) % 2 == 0) {
            // k4Operator = 'out';
            k4 = string.concat('-', k4);
        }

        string memory feComposites = string.concat(
            // '<feComposite in="blurResult" in2="displacementResult" operator="', operator, '" result="compositeResult2"/>',
            // (seed % 3 == 0) ? string.concat('<feComposite in="compositeResult2" in2="compositeResult2" operator="arithmetic" k1="0" k2="1" k3="1" k4="', k4,'"/>') : ''

            '<feComposite in="rotateResult" in2="colorChannelResult" operator="', k4Operator, '" result="compositeResult2"/>',
            '<feComposite in="compositeResult2" in2="compositeResult2" operator="arithmetic" k1="0" k2="1" k3="1" k4="' , k4, '"/>'
            // '<feComposite in="rotateResult" in2="colorChannelResult" operator="arithmetic" k1="0" k2="1" k3="1" k4="0"/>'
        );

        uint scale = generateRandom(1, 201, seed+2);

        // randomly assign string variable to represent the animation length: 3s, 6s, 12s
        string memory animationLength;
        uint animationLengthUint = generateRandom(0, 3, seed+3);
        if (animationLengthUint == 0) {
            animationLength = '2s';
        } else if (animationLengthUint == 1) {
            animationLength = '5s';
        } else {
            animationLength = '10s';
        }

        return
            // prettier-ignore
            string.concat(
                '<svg width="500" height="500" viewBox="0 0 500 500" version="1.1" xmlns="http://www.w3.org/2000/svg">',
                    
                    '<filter id="a">',
                        // Blur for edges
                        // '<feGaussianBlur in="SourceGraphic" stdDeviation="10" result="blurResult"/>'

                        // Core filter
                        '<feTurbulence baseFrequency="', baseFrequencyStr, '" numOctaves="', generateRandom(1, 4, seed+1).toString(), '"',
                            'result="turbulenceResult"> </feTurbulence>',

                        // For scale effect
                        '<feDisplacementMap scale="', scale.toString(),'" result="displacementResult">',
                            // '<animate attributeName="scale" from="-', scale.toString() ,'" to="', (scale+100).toString(), '"',
                            //          'dur="10s" repeatCount="indefinite" result="displacementResult"/>',
                        '</feDisplacementMap>',

                        // For animation
                        '<feColorMatrix type="hueRotate" result="rotateResult">',
                          '<animate attributeName="values" from="0" to="360"',
                                   'dur="', animationLength, '" repeatCount="indefinite" result="colorMatrixResult"/>',
                        '</feColorMatrix>',

                        // For animation
                        '<feColorMatrix type="matrix" result="colorChannelResult" ',
                           'values="0 0 0 0 0 ',
                                   '0 0 0 0 0 ',
                                   '0 0 0 0 0 ',
                                   '1 0 0 0 0">',
                        '</feColorMatrix>',

                        // Add the flatness
                        feComposites,

                        // Light
                        '<feDiffuseLighting lighting-color="white" diffuseConstant="', generateRandom(2, 3, seed+6).toString(), '"',
                                           'result="diffuseResult" surfaceScale="', generateRandom(10, 30, seed+8).toString(),'">',
                          '<feDistantLight elevation="', generateRandom(0, 30, seed+4).toString(),'">',
                            // '<animate attributeName="azimuth" from="0" to="360"', 'dur="20s" repeatCount="indefinite"/>',
                          '</feDistantLight>',
                        '</feDiffuseLighting>',

                        // Invert the colors half the time
                        (generateRandom(0, 2, seed+5) % 2) == 0 ? '' : '<feColorMatrix type="matrix" values="-1 0 0 0 1 0 -1 0 0 1 0 0 -1 0 1 0 0 0 1 0"/>',
                    '</filter>',
                  '</defs>',
                  '<rect width="1000" height="1000" filter="url(#a)"/>',
                '</svg>'
            );
    }
}
