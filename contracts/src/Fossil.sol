// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Base64} from "openzeppelin-contracts/contracts/utils/Base64.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {console} from "forge-std/console.sol";
import {LinearVRGDA} from "VRGDAs/LinearVRGDA.sol";

contract Fossil is ERC721, LinearVRGDA {
    /*//////////////////////////////////////////////////////////////
                              SALES STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSold; // The total number of tokens sold so far.

    uint256 public immutable startTime = block.timestamp; // When VRGDA sales begun.

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor()
        ERC721(
            "Example Linear NFT", // Name.
            "LINEAR" // Symbol.
        )
        LinearVRGDA(
            0.01e18, // Target price.
            0.01e18, // Price decay percent.
            48e18 // Per time unit.
        )
    {}

    using Strings for uint256;

    function generateRandom(
        uint min,
        uint max,
        uint seed,
        uint nonce
    ) public pure returns (uint random, uint) {
        // safely generates a random uint between min and max using the seed
        uint rand = uint(keccak256(abi.encodePacked(seed, nonce)));
        nonce++;
        return ((rand % (max - min)) + min, nonce);
    }

    function generateBaseFrequency(
        uint256 seed,
        uint nonce
    ) public pure returns (string memory, uint) {
        uint baseFrequency;
        (baseFrequency, nonce) = generateRandom(50, 251, seed, nonce);
        string memory baseFrequencyStr;
        if (baseFrequency >= 0 && baseFrequency < 10) {
            baseFrequencyStr = string.concat("0.000", baseFrequency.toString()); // 0.0001 - 0.0010
        } else if (baseFrequency >= 10 && baseFrequency < 100) {
            baseFrequencyStr = string.concat("0.00", baseFrequency.toString()); // 0.010 - 0.100
        } else if (baseFrequency >= 100) {
            baseFrequencyStr = string.concat("0.0", baseFrequency.toString()); // 0.100 - 0.200
        } else {
            assert(false);
        }

        return (baseFrequencyStr, nonce);
    }

    function generateFeComposites(
        uint256 seed,
        uint nonce
    ) public pure returns (string memory, uint) {
        // feComposite operator
        uint random;
        (random, nonce) = generateRandom(0, 3, seed, nonce);
        string memory operator;
        if (random % 2 == 0) {
            operator = "out";
        } else {
            operator = "in";
        }

        // feComposite
        string memory k1;
        string memory k2;
        string memory k3;
        string memory k4;

        //  k1, k2, k3
        (random, nonce) = generateRandom(0, 3, seed, nonce);
        k1 = random % 2 == 0 ? "0" : "1";
        (random, nonce) = generateRandom(0, 3, seed, nonce);
        k2 = random % 2 == 0 ? "1" : "1";
        (random, nonce) = generateRandom(0, 3, seed, nonce);
        k3 = random % 2 == 0 ? "0" : "1";

        // randomly choose which of k1, k2, or k3 to set to '1'
        (random, nonce) = generateRandom(1, 4, seed, nonce);
        if (random == 1) {
            k1 = "1";
        } else if (random == 2) {
            k2 = "1";
        } else if (random == 3) {
            k3 = "1";
        } else {
            assert(false);
        }

        // k4
        (random, nonce) = generateRandom(0, 51, seed, nonce);
        if (random > 0 && random < 10) {
            k4 = string.concat("0.0", random.toString());
        } else if (random >= 10 && random < 100) {
            k4 = string.concat("0.", random.toString());
        } else {
            assert(false);
        }

        // randomly make k4 negative
        uint k4NegativeRandom;
        (k4NegativeRandom, nonce) = generateRandom(0, 2, seed, nonce);
        if ((k4NegativeRandom % 2 == 0)) {
            k4 = string.concat("-", k4);
        }

        string memory feComposites = string.concat(
            '<feComposite in="rotateResult" in2="colorChannelResult" operator="',
            operator,
            '" result="compositeResult2"/>',
            '<feComposite in="compositeResult2" in2="compositeResult2" operator="arithmetic" k1="',
            k1,
            '" k2="',
            k2,
            '" k3="',
            k3,
            '" k4="',
            k4,
            '"/>'
        );

        return (feComposites, nonce);
    }

    function generateFeDisplacementMap(
        uint seed,
        uint nonce,
        bool animate,
        string memory animationDuration
    ) public pure returns (string memory, uint) {
        uint scale;
        (scale, nonce) = generateRandom(1, 201, seed, nonce);
        string memory from;
        string memory to;
        from = scale.toString();
        to = (scale + 100).toString();
        uint random;
        (random, nonce) = generateRandom(0, 2, seed, nonce);
        if (random % 2 == 0) {
            (to, from) = (from, to);
        }

        return (
            string.concat(
                '<feDisplacementMap scale="',
                scale.toString(),
                '" result="displacementResult">',
                animate
                    ? string.concat(
                        '<animate attributeName="scale" from="',
                        from,
                        '" to="',
                        to,
                        '"',
                        'dur="',
                        animationDuration,
                        '" repeatCount="indefinite" result="displacementResult"/>'
                    )
                    : "",
                "</feDisplacementMap>"
            ),
            nonce
        );
    }

    function generateAnimationDuration(
        uint seed,
        uint nonce
    ) public pure returns (string memory, uint) {
        uint animationDuration;
        (animationDuration, nonce) = generateRandom(0, 3, seed, nonce);
        string memory animationLengthStr;
        if (animationDuration == 0) {
            animationLengthStr = "3s";
        } else if (animationDuration == 1) {
            animationLengthStr = "6s";
        } else if (animationDuration == 2) {
            animationLengthStr = "12s";
        } else {
            assert(false);
        }

        return (animationLengthStr, nonce);
    }

    function generateFeTurbulence(
        uint seed,
        uint nonce
    ) public pure returns (string memory, uint) {
        string memory baseFrequencyStr;
        (baseFrequencyStr, nonce) = generateBaseFrequency(seed, nonce);

        uint numOctaves;
        (numOctaves, nonce) = generateRandom(1, 4, seed, 0);

        return (
            string.concat(
                '<feTurbulence baseFrequency="',
                baseFrequencyStr,
                '" numOctaves="',
                numOctaves.toString(),
                '"',
                'result="turbulenceResult"> </feTurbulence>'
            ),
            nonce
        );
    }

    function generateFeDiffuseLighting(
        uint seed,
        uint nonce
    ) public pure returns (string memory, uint) {
        uint diffuseConstant;
        (diffuseConstant, nonce) = generateRandom(2, 3, seed, nonce);

        uint surfaceScale;
        (surfaceScale, nonce) = generateRandom(10, 30, seed, nonce);

        uint elevation;
        (elevation, nonce) = generateRandom(0, 30, seed, nonce);
        return (
            string.concat(
                '<feDiffuseLighting lighting-color="white" diffuseConstant="',
                diffuseConstant.toString(),
                '"result="diffuseResult" surfaceScale="',
                surfaceScale.toString(),
                '"><feDistantLight elevation="',
                elevation.toString(),
                '"></feDistantLight></feDiffuseLighting>'
            ),
            nonce
        );
    }

    function generateFeColorMatrixForInversion(
        uint seed,
        uint nonce
    ) public pure returns (string memory, uint) {
        uint random;
        (random, nonce) = generateRandom(0, 2, seed, nonce);
        string memory feColorMatrixForInversion;
        // apply inversion half the time
        if (random == 0) {
            feColorMatrixForInversion = '<feColorMatrix type="matrix" values="-1 0 0 0 1 0 -1 0 0 1 0 0 -1 0 1 0 0 0 1 0"/>';
        }

        return (feColorMatrixForInversion, nonce);
    }

    function generateSVG(uint seed) public pure returns (string memory) {
        uint nonce = 0;

        uint animationType;
        (animationType, nonce) = generateRandom(0, 2, seed, nonce);

        string memory animationDuration;
        (animationDuration, nonce) = generateAnimationDuration(seed, nonce);

        string memory feTurbulence;
        (feTurbulence, nonce) = generateFeTurbulence(seed, nonce);

        string memory feDisplacementMap;
        (feDisplacementMap, nonce) = generateFeDisplacementMap(
            seed,
            nonce,
            animationType == 0,
            animationDuration
        );

        string memory feComposites;
        (feComposites, nonce) = generateFeComposites(seed, nonce);

        string memory feDiffuseLighting;
        (feDiffuseLighting, nonce) = generateFeDiffuseLighting(seed, nonce);

        string memory feColorMatrixForInversion;
        (feColorMatrixForInversion, nonce) = generateFeColorMatrixForInversion(
            seed,
            nonce
        );

        // randomly assign string variable to represent the animation length: 3s, 6s, 12s

        return
            string.concat(
                '<svg width="500" height="500" viewBox="0 0 500 500" version="1.1" xmlns="http://www.w3.org/2000/svg">',
                    
                    '<filter id="a">',
                        // Core filter
                        feTurbulence,

                        // For scale effect
                        feDisplacementMap,

                        // For animation
                        '<feColorMatrix type="hueRotate" result="rotateResult">',
                          animationType == 1 ? string.concat(
                              '<animate attributeName="values" from="0" to="360"',
                                   'dur="', animationDuration, '" repeatCount="indefinite" result="colorMatrixResult"/>'
                          ) : '',
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
                        feDiffuseLighting,

                        // Invert the colors half the time
                        feColorMatrixForInversion,
                    '</filter>',
                  '</defs>',
                  '<rect width="1000" height="1000" filter="url(#a)"/>',
                '</svg>'
            );
    }
}
