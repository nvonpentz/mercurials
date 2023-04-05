// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Base64} from "openzeppelin-contracts/contracts/utils/Base64.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {console} from "forge-std/console.sol";
import {LinearVRGDA} from "VRGDAs/LinearVRGDA.sol";
import {toDaysWadUnsafe} from "solmate/utils/SignedWadMath.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

contract Mercurial is ERC721, LinearVRGDA {
    using Strings for uint256;
    using Strings for int256;

    uint256 public totalSold; // The total number of tokens sold so far.
    uint256 public immutable startTime = block.timestamp; // When VRGDA sales begun.
    mapping(uint256 => uint256) public seeds;

    constructor()
        ERC721(
            "Mercurials", // Name.
            "MERC" // Symbol.
        )
        LinearVRGDA(
            0.001e18, // Target price. TODO change
            0.01e18, // Price decay percent.
            24 * 30e18 // Per time unit.
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
        require(expectedTokenId == totalSold, "Invalid or expired token ID");

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
        (uint seed, ) = generateSeed(expectedTokenId);
        seeds[expectedTokenId] = seed;
    }

    /// @dev This function should be called using the `pending` block tag.
    /// @dev The id and hash should passed as arguments to the `mint` function.
    function nextToken()
        external
        view
        returns (
            uint256 id,
            string memory uri,
            uint256 price,
            bytes32 hash,
            uint8 ttl
        )
    {
        id = totalSold;
        uint seed;
        (seed, ttl) = generateSeed(id);
        uri = generateTokenUri(seed, id); // TODO use tokenURI
        price = getVRGDAPrice(toDaysWadUnsafe(block.timestamp - startTime), id);
        hash = blockhash(block.number - 1);

        return (id, uri, price, hash, ttl);
    }

    function getCurrentVRGDAPrice() public view returns (uint256) {
        // Note: By using toDaysWadUnsafe(block.timestamp - startTime) we are establishing that 1 "unit of time" is 1 day.
        return
            getVRGDAPrice(
                toDaysWadUnsafe(block.timestamp - startTime),
                totalSold
            );
    }

    // function generateSeed(uint256 tokenId) public view returns (uint, uint8) {
    //     uint8 ttl = 5 - uint8((block.number - 1) % 5);
    //     return (
    //         uint256(
    //             keccak256(
    //                 abi.encodePacked(
    //                     blockhash(
    //                         (block.number - 1) - ((block.number - 1) % 5)
    //                     ),
    //                     tokenId
    //                 )
    //             )
    //         ),
    //         ttl
    //     );
    // }
    function generateSeed(uint256 tokenId) public view returns (uint, uint8) {
        uint8 ttl = 1;
        return (
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        tokenId
                    )
                )
            ),
            ttl
        );
    }

    function composeSVGsFromParts(
        string memory feTurbulence,
        string memory staticFeDisplacementMap,
        string memory animatedFeDisplacementMap,
        string memory animatedFeColorMatrix,
        string memory feComposites,
        string memory feDiffuseLighting,
        string memory feColorMatrixForInversion
    ) public pure returns (string memory svgImage, string memory svgAnimation) {
        string memory firstPart = string.concat(
            '<svg width="350" height="350" version="1.1" xmlns="http://www.w3.org/2000/svg">',
            '<filter id="a">',
            feTurbulence
        );

        string memory bottomPart = string.concat(
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
            '<rect width="350" height="350" filter="url(#a)"/>',
            "</svg>"
        );

        svgImage = string.concat(
            firstPart,
            staticFeDisplacementMap,
            '<feColorMatrix type="hueRotate" result="rotateResult">',
            "</feColorMatrix>",
            bottomPart
        );

        svgAnimation = string.concat(
            firstPart,
            animatedFeDisplacementMap,
            '<feColorMatrix type="hueRotate" result="rotateResult">',
            animatedFeColorMatrix,
            "</feColorMatrix>",
            bottomPart
        );

        return (svgImage, svgAnimation);
    }

    function generateSVGPartOne(
        uint256 seed
    )
        public
        pure
        returns (string memory partOne, string memory attributes, uint256 nonce)
    {
        string memory feTurbulence;
        string memory numOctaves;
        string memory baseFrequencyStr;
        (
            feTurbulence,
            numOctaves,
            baseFrequencyStr,
            nonce
        ) = generateFeTurbulence(seed, nonce);

        partOne = string.concat(
            '<svg width="350" height="350" version="1.1" xmlns="http://www.w3.org/2000/svg">',
            '<filter id="a">',
            feTurbulence
        );

        attributes = string.concat(
            '{ "trait_type": "Base Frequency", "value": "',
            baseFrequencyStr,
            '" }, ',
            '{ "trait_type": "Octaves", "value": "',
            numOctaves,
            '" }, '
        );

        return (partOne, attributes, nonce);
    }

    function generateSVGPartTwo(
        uint256 seed,
        uint256 nonce,
        string memory attributes
    ) public pure returns (string memory partTwo, string memory, uint256) {
        string memory feComposites;
        (feComposites, nonce) = generateFeComposites(seed, nonce);

        string memory feDiffuseLighting;
        (feDiffuseLighting, nonce) = generateFeDiffuseLighting(seed, nonce);

        string memory feColorMatrixForInversion;
        (feColorMatrixForInversion, nonce) = generateFeColorMatrixForInversion(
            seed,
            nonce
        );
        partTwo = string.concat(
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
            '<rect width="350" height="350" filter="url(#a)"/>',
            "</svg>"
        );

        return (partTwo, attributes, nonce);
    }

    /// @notice Generates the entire SVG
    function generateSVG(
        uint256 seed
    )
        public
        pure
        returns (
            string memory svgImage,
            string memory svgAnimation,
            string memory attributes
        )
    {
        uint256 nonce;
        string memory partOne;
        string memory partTwo;
        (partOne, attributes, nonce) = generateSVGPartOne(seed);
        (partTwo, attributes, nonce) = generateSVGPartTwo(
            seed,
            nonce,
            attributes
        );
        (uint animationDurationHueRotate, ) = generateRandom(
            1,
            30,
            seed,
            nonce
        );

        string memory staticFeDisplacementMap;
        string memory animatedFeDisplacementMap;
        string memory scale;
        string memory animationDurationFeDisplacementMap;
        (
            scale,
            staticFeDisplacementMap,
            animatedFeDisplacementMap,
            animationDurationFeDisplacementMap,
            nonce
        ) = generateFeDisplacementMap(seed, nonce);

        attributes = string.concat(
            attributes,
            '{ "trait_type": "Scale", "value": "',
            scale,
            '" }, ',
            '{ "trait_type": "Scale Animation", "value": "',
            animationDurationFeDisplacementMap,
            '" }, ',
            '{ "trait_type": "Hue Rotate Animation", "value": "',
            animationDurationHueRotate.toString(),
            's" }'
        );

        string memory animatedFeColorMatrix = string.concat(
            '<animate attributeName="values" from="0" to="360" ',
            'dur="',
            animationDurationHueRotate.toString(),
            's" ',
            'repeatCount="indefinite" result="colorMatrixResult"/>'
        );

        svgImage = string.concat(
            partOne,
            staticFeDisplacementMap,
            '<feColorMatrix type="hueRotate" result="rotateResult">',
            "</feColorMatrix>",
            partTwo
        );

        svgAnimation = string.concat(
            partOne,
            animatedFeDisplacementMap,
            '<feColorMatrix type="hueRotate" result="rotateResult">',
            animatedFeColorMatrix,
            "</feColorMatrix>",
            partTwo
        );

        return (svgImage, svgAnimation, attributes);
    }

    function generateTokenUri(
        uint seed,
        uint tokenId
    ) internal pure returns (string memory) {
        string memory attributes;
        string memory svgImage;
        string memory svgAnimation;
        (svgImage, svgAnimation, attributes) = generateSVG(seed);
        attributes = string.concat('"attributes": [ ', attributes, " ]");

        string memory metadataJson = Base64.encode(
            bytes(
                string(
                    // prettier-ignore
                    abi.encodePacked(
                        '{ "name": "Mercurial #', tokenId.toString(), '", ',
                            '"description": "On chain generative art project.", ',
                            '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(svgImage)), '", ',
                            '"animation_url": "data:image/svg+xml;base64,', Base64.encode(bytes(svgAnimation)), '", ',
                            attributes,
                        ' }'
                    )
                )
            )
        );

        return
            string(
                abi.encodePacked("data:application/json;base64,", metadataJson)
            );
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        uint256 seed = seeds[tokenId];
        return generateTokenUri(seed, tokenId);
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

    function generateRandomBool(
        uint256 seed,
        uint256 nonce
    ) internal pure returns (bool, uint) {
        uint256 rand = uint(keccak256(abi.encodePacked(seed, nonce)));
        nonce++;
        return (rand % 2 == 0, nonce);
    }

    /// @notice Generates a baseFrequency string for a feTurbulence element
    function generateBaseFrequency(
        uint256 seed,
        uint256 nonce
    ) internal pure returns (string memory, uint) {
        uint256 baseFrequency;
        // (baseFrequency, nonce) = generateRandom(30, 251, seed, nonce);
        (baseFrequency, nonce) = generateRandom(50, 301, seed, nonce);
        string memory baseFrequencyStr;
        if (baseFrequency >= 0 && baseFrequency < 10) {
            // TODO remove this case, never hits
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

    function generateScale(
        uint256 seed,
        uint256 nonce
    )
        internal
        pure
        returns (
            string memory scaleStart,
            string memory scaleValues,
            // uint start,
            // bool startNegative,
            // uint end,
            // bool endNegative,
            uint256
        )
    {
        uint start;
        bool startNegative;
        uint end;
        bool endNegative;
        (start, nonce) = generateRandom(0, 151, seed, nonce);
        (startNegative, nonce) = generateRandomBool(seed, nonce);

        uint256 delta;
        bool deltaNegative;
        (delta, nonce) = generateRandom(75, 250, seed, nonce);
        (deltaNegative, nonce) = generateRandomBool(seed, nonce);

        if (startNegative == deltaNegative) {
            end = start + delta;
            endNegative = startNegative;
        } else {
            if (start > delta) {
                end = start - delta;
                endNegative = startNegative;
            } else {
                end = delta - start;
                endNegative = deltaNegative;
            }
        }
        scaleStart = convertSignedUintToString(start, startNegative);
        scaleValues = string.concat(
            scaleStart,
            ";",
            convertSignedUintToString(end, endNegative),
            ";",
            scaleStart,
            ";"
        );

        return (scaleStart, scaleValues, nonce);
    }

    function convertSignedUintToString(
        uint value,
        bool isNegative
    ) internal pure returns (string memory valueString) {
        if (isNegative) {
            valueString = string.concat("-", value.toString());
        } else {
            valueString = value.toString();
        }
        return valueString;
    }

    /// @notice Generates feDisplacementMap SVG element
    function generateFeDisplacementMap(
        uint256 seed,
        uint256 nonce
    )
        internal
        pure
        returns (
            string memory scaleStart,
            string memory staticFeDisplacementMap,
            string memory animatedFeDisplacementMap,
            string memory animationDurationFeDisplacementMap,
            uint256
        )
    {
        // Generate initial scale value (scaleStart) for static image and animation,
        // and start and end values for animated image (scaleValues)
        string memory scaleValues;
        (scaleStart, scaleValues, nonce) = generateScale(seed, nonce);

        // Generate an animation duration for the scale effect
        uint256 animationDurationFeDisplacementMapUint;
        (animationDurationFeDisplacementMapUint, nonce) = generateRandom(
            1,
            61,
            seed,
            nonce
        );
        animationDurationFeDisplacementMap = string.concat(
            animationDurationFeDisplacementMapUint.toString(),
            "s"
        );

        // Create the static and animated feDisplacementMap elements
        animatedFeDisplacementMap = string.concat(
            // prettier-ignore
            '<feDisplacementMap result="displacementResult">',
            '<animate attributeName="scale" ',
            'values="',
            scaleValues,
            '" keyTimes="0; 0.5; 1" dur="',
            animationDurationFeDisplacementMap,
            '" repeatCount="indefinite" result="displacementResult" calcMode="spline" keySplines="0.3 0 0.7 1; 0.3 0 0.7 1"/>',
            "</feDisplacementMap>"
        );

        staticFeDisplacementMap = string.concat(
            '<feDisplacementMap scale="',
            scaleStart,
            '" result="displacementResult">',
            "</feDisplacementMap>"
        );

        return (
            scaleStart,
            staticFeDisplacementMap,
            animatedFeDisplacementMap,
            animationDurationFeDisplacementMap,
            nonce
        );
    }

    /// @notice Generates the feTurbulence SVG element
    function generateFeTurbulence(
        uint256 seed,
        uint256 nonce
    )
        internal
        pure
        returns (string memory, string memory, string memory, uint)
    {
        string memory baseFrequencyStr;
        (baseFrequencyStr, nonce) = generateBaseFrequency(seed, nonce);

        uint256 numOctaves;
        (numOctaves, nonce) = generateRandom(1, 4, seed, 0);

        uint seedForSvg;

        (seedForSvg, nonce) = generateRandom(
            0,
            65536, // 65535 is the max value for a uint16 (seed used in SVG)
            seed,
            nonce
        );
        return (
            string.concat(
                '<feTurbulence baseFrequency="',
                baseFrequencyStr,
                '" numOctaves="',
                numOctaves.toString(),
                '" seed="',
                seedForSvg.toString(),
                '" result="turbulenceResult"/> '
            ),
            numOctaves.toString(),
            baseFrequencyStr,
            nonce
        );
    }

    /// @notice Generates the feDiffuseLighting SVG element
    function generateFeDiffuseLighting(
        uint256 seed,
        uint256 nonce
    ) internal pure returns (string memory, uint) {
        uint256 diffuseConstant;
        (diffuseConstant, nonce) = generateRandom(2, 4, seed, nonce);

        uint256 surfaceScale;
        // (surfaceScale, nonce) = generateRandom(10, 30, seed, nonce); TODO

        (surfaceScale, nonce) = generateRandom(5, 11, seed, nonce);

        uint256 elevation;
        // (elevation, nonce) = generateRandom(0, 30, seed, nonce);
        (elevation, nonce) = generateRandom(0, 25, seed, nonce);
        return (
            string.concat(
                '<feDiffuseLighting lighting-color="white" diffuseConstant="',
                diffuseConstant.toString(),
                '" result="diffuseResult" surfaceScale="',
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
        bool random;
        (random, nonce) = generateRandomBool(seed, nonce);
        string memory feColorMatrixForInversion;
        // Apply the inversion half the time
        if (random) {
            feColorMatrixForInversion = '<feColorMatrix type="matrix" values="-1 0 0 0 1 0 -1 0 0 1 0 0 -1 0 1 0 0 0 1 0"/>';
        }

        return (feColorMatrixForInversion, nonce);
    }
}
