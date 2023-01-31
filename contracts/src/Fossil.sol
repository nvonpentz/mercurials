// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Base64} from "openzeppelin-contracts/contracts/utils/Base64.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {console} from "forge-std/console.sol";
import {LinearVRGDA} from "VRGDAs/LinearVRGDA.sol";
import {toDaysWadUnsafe} from "solmate/utils/SignedWadMath.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

contract Fossil is ERC721, LinearVRGDA {
    using Strings for uint256;

    uint256 public totalSold; // The total number of tokens sold so far.
    uint256 public immutable startTime = block.timestamp; // When VRGDA sales begun.

    constructor(
    )
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

    function mint(
        uint256 expectedTokenId,
        bytes32 expectedParentBlockhash
    ) external payable {
        // Only settle if desired token would be minted by checking the
        // parent blockhash and the expected token ID.
        bytes32 parentBlockhash = blockhash(block.number - 1);
        require(
            expectedParentBlockhash == parentBlockhash,
            "Invalid or expired blockhash"
        );
        require(
            expectedTokenId == totalSold,
            "Invalid or expired token ID"
        );

        unchecked {
            // Validate the purchase request against the VRGDA rules.
            uint256 price = getCurrentVRGDAPrice();
            require(msg.value >= price, "Insufficient funds");

            _mint(msg.sender, expectedTokenId); // Mint the NFT using mintedId.
            totalSold += 1; // Increment the total sold counter.

            // Note: We do this at the end to avoid creating a reentrancy vector.
            // Refund the user any ETH they spent over the current price of the NFT.
            // Unchecked is safe here because we validate msg.value >= price above.
            SafeTransferLib.safeTransferETH(msg.sender, msg.value - price);
        }
    }

    /// @dev This function should be called using the `pending` block tag.
    /// @dev The tokenId and hash should passed as arguments to the `mint` function.
    function nextToken() external view returns (
        uint256 tokenId,
        string memory svg,
        uint256 price,
        bytes32 hash
    ) {
        tokenId = totalSold;
        uint seed = generateSeed(tokenId);
        svg = generateSVG(seed);
        price = getVRGDAPrice(toDaysWadUnsafe(block.timestamp - startTime), tokenId);
        hash = blockhash(block.number - 1);

        return (tokenId, svg, price, hash);
    }

    function getCurrentVRGDAPrice() public view returns (uint256) {
        // Note: By using toDaysWadUnsafe(block.timestamp - startTime) we are establishing that 1 "unit of time" is 1 day.
        return getVRGDAPrice(toDaysWadUnsafe(block.timestamp - startTime), totalSold);
    }

    function generateSeed(uint256 tokenId) public view returns (uint) {
        return uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId))
        );
    }

    /// @notice Generates the entire SVG
    function generateSVG(uint256 seed) public pure returns (string memory) {
        uint256 nonce = 0;

        uint256 animationType;
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

        return
            string.concat(
                '<svg width="500" height="500" viewBox="0 0 500 500" version="1.1" xmlns="http://www.w3.org/2000/svg">',
                '<filter id="a">',
                // Base turbulent noise
                feTurbulence,
                // For scale effect
                feDisplacementMap,
                // For 360 animation
                '<feColorMatrix type="hueRotate" result="rotateResult">',
                animationType == 1
                    ? string.concat(
                        '<animate attributeName="values" from="0" to="360"',
                        'dur="',
                        animationDuration,
                        '" repeatCount="indefinite" result="colorMatrixResult"/>'
                    )
                    : "",
                "</feColorMatrix>",
                '<feColorMatrix type="matrix" result="colorChannelResult" ',
                'values="0 0 0 0 0 ',
                "0 0 0 0 0 ",
                "0 0 0 0 0 ",
                '1 0 0 0 0">',
                "</feColorMatrix>",
                // Add inside-out effect and flatness effect
                feComposites,
                // Light
                feDiffuseLighting,
                // Invert the colors half the time
                feColorMatrixForInversion,
                "</filter>",
                "</defs>",
                '<rect width="1000" height="1000" filter="url(#a)"/>',
                "</svg>"
            );
    }

    /// @notice Generates a psuedo-random number from min (includsive) to max (exclusive)
    /// @param seed The seed to use for the random number (the same across multiple calls)
    /// @param nonce The nonce to use for the random number (different between calls)
    function generateRandom(
        uint256 min,
        uint256 max,
        uint256 seed,
        uint256 nonce
    ) internal pure returns (uint256 random, uint) {
        // safely generates a random uint256 between min and max using the seed
        uint256 rand = uint(keccak256(abi.encodePacked(seed, nonce)));
        nonce++;
        return ((rand % (max - min)) + min, nonce);
    }

    /// @notice Generates a baseFrequency string for a feTurbulence element
    function generateBaseFrequency(
        uint256 seed,
        uint256 nonce
    ) internal pure returns (string memory, uint) {
        uint256 baseFrequency;
        (baseFrequency, nonce) = generateRandom(30, 251, seed, nonce);
        string memory baseFrequencyStr;
        if (baseFrequency >= 0 && baseFrequency < 10) {
            baseFrequencyStr = string.concat("0.000", baseFrequency.toString()); // 0.0001 - 0.0010
        } else if (baseFrequency >= 10 && baseFrequency < 100) {
            baseFrequencyStr = string.concat("0.00", baseFrequency.toString()); // 0.010 - 0.100
        } else if (baseFrequency >= 100) {
            baseFrequencyStr = string.concat("0.0", baseFrequency.toString()); // 0.100 - 0.200
        } else {
            require(false, "Invalid base frequency");
            assert(false);
        }

        return (baseFrequencyStr, nonce);
    }

    /// @notice Generates feComposite elements
    function generateFeComposites(
        uint256 seed,
        uint256 nonce
    ) internal pure returns (string memory, uint) {
        // Randomly assign k1, k2, and k3 to '0' or '1'
        string memory k1;
        string memory k2;
        string memory k3;

        uint256 random;
        (random, nonce) = generateRandom(0, 3, seed, nonce);
        k1 = random % 2 == 0 ? "0" : "1";
        (random, nonce) = generateRandom(0, 3, seed, nonce);
        k2 = random % 2 == 0 ? "1" : "1"; // TODO
        (random, nonce) = generateRandom(0, 3, seed, nonce);
        k3 = random % 2 == 0 ? "0" : "1";

        // Randomly choose which of k1, k2, or k3 to set to '1'
        (random, nonce) = generateRandom(1, 4, seed, nonce);
        if (random == 1) {
            k1 = "1";
        } else if (random == 2) {
            k2 = "1";
        } else if (random == 3) {
            k3 = "1";
        } else {
            require(false, "Invalid k1, k2, k3");
            assert(false);
        }

        // k4
        string memory k4;
        (random, nonce) = generateRandom(0, 51, seed, nonce);
        if (random >= 0 && random < 10) {
            k4 = string.concat("0.0", random.toString());
        } else if (random >= 10 && random < 100) {
            k4 = string.concat("0.", random.toString());
        } else {
            require(false, "Invalid k4");
            assert(false);
        }

        // Randomly make k4 negative
        uint256 k4NegativeIfZero;
        (k4NegativeIfZero, nonce) = generateRandom(0, 2, seed, nonce);
        if (k4NegativeIfZero == 0) {
            k4 = string.concat("-", k4);
        }

        // Set operator of first feComposite to 'in' if k4 is not negative
        (random, nonce) = generateRandom(0, 3, seed, nonce);
        string memory operator;
        if ((random % 2 == 0) || (k4NegativeIfZero == 0)) {
            operator = "out";
        } else {
            operator = "in";
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

    /// @notice Generates feDisplacementMap SVG element
    function generateFeDisplacementMap(
        uint256 seed,
        uint256 nonce,
        bool animate,
        string memory animationDuration
    ) internal pure returns (string memory, uint) {
        uint256 scale;
        (scale, nonce) = generateRandom(1, 201, seed, nonce);
        string memory from;
        string memory to;
        from = scale.toString();
        to = (scale + 100).toString();
        uint256 random;
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

    /// @notice Generates the duration value for the animations
    function generateAnimationDuration(
        uint256 seed,
        uint256 nonce
    ) internal pure returns (string memory, uint) {
        uint256 animationDuration;
        (animationDuration, nonce) = generateRandom(0, 3, seed, nonce);
        string memory animationLengthStr;
        if (animationDuration == 0) {
            animationLengthStr = "3s";
        } else if (animationDuration == 1) {
            animationLengthStr = "6s";
        } else if (animationDuration == 2) {
            animationLengthStr = "12s";
        } else {
            require(false, "Invalid animation duration");
            assert(false);
        }

        return (animationLengthStr, nonce);
    }

    /// @notice Generates the feTurbulence SVG element
    function generateFeTurbulence(
        uint256 seed,
        uint256 nonce
    ) internal pure returns (string memory, uint) {
        string memory baseFrequencyStr;
        (baseFrequencyStr, nonce) = generateBaseFrequency(seed, nonce);

        uint256 numOctaves;
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

    /// @notice Generates the feDiffuseLighting SVG element
    function generateFeDiffuseLighting(
        uint256 seed,
        uint256 nonce
    ) internal pure returns (string memory, uint) {
        uint256 diffuseConstant;
        (diffuseConstant, nonce) = generateRandom(2, 3, seed, nonce);

        uint256 surfaceScale;
        (surfaceScale, nonce) = generateRandom(10, 30, seed, nonce);

        uint256 elevation;
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

    /// @notice Generates the feColorMatrix SVG element for (maybe) inverting the colors
    function generateFeColorMatrixForInversion(
        uint256 seed,
        uint256 nonce
    ) internal pure returns (string memory, uint) {
        uint256 random;
        (random, nonce) = generateRandom(0, 2, seed, nonce);
        string memory feColorMatrixForInversion;
        // apply inversion half the time
        if (random == 0) {
            feColorMatrixForInversion = '<feColorMatrix type="matrix" values="-1 0 0 0 1 0 -1 0 0 1 0 0 -1 0 1 0 0 0 1 0"/>';
        }

        return (feColorMatrixForInversion, nonce);
    }
}
