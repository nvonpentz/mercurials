// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Base64} from "openzeppelin-contracts/contracts/utils/Base64.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {console} from "forge-std/console.sol";
import {LinearVRGDA} from "VRGDAs/LinearVRGDA.sol";
import {toDaysWadUnsafe} from "solmate/utils/SignedWadMath.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

contract Mercurial is ERC721, LinearVRGDA, ReentrancyGuard {
    using Strings for uint256;
    using Strings for int256;

    // Events
    event TokenMinted(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 price
    );

    // The total number of tokens sold so far.
    uint256 public totalSold;

    // When VRGDA sales begun.
    uint256 public immutable startTime = block.timestamp;
    mapping(uint256 => uint256) public seeds;

    constructor()
        ERC721("Mercurials", "MERC")
        LinearVRGDA(
            // Target price
            0.01e18,
            // Price decay percent
            0.1e18,
            // Per time unit
            1e18
        )
    {}

    function mint(
        uint256 tokenId,
        bytes32 blockHash
    ) external payable nonReentrant {
        // Only settle if desired token would be minted by checking the
        // parent blockhash and the expected token ID.
        bytes32 expectedBlockHash = blockhash(
            (block.number - 1) - ((block.number - 1) % 5)
        );
        require(blockHash == expectedBlockHash, "Invalid or expired blockhash");
        require(tokenId == totalSold, "Invalid or expired token ID");

        unchecked {
            // Validate the purchase request against the VRGDA rules.
            uint256 price = getCurrentVRGDAPrice();
            require(msg.value >= price, "Insufficient funds");

            // Mint the NFT using mintedId.
            _mint(msg.sender, tokenId);
            emit TokenMinted(tokenId, msg.sender, price);

            // Increment the total sold counter.
            totalSold += 1;

            // Generate the seed and store it
            (uint256 seed, ) = generateSeed(tokenId);
            seeds[tokenId] = seed;

            // Note: We do this at the end to avoid creating a reentrancy vector.
            // Refund the user any ETH they spent over the current price of the NFT.
            // Unchecked is safe here because we validate msg.value >= price above.
            SafeTransferLib.safeTransferETH(msg.sender, msg.value - price);
        }
    }

    /// @notice Returns information about the next token that can be minted.
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
        uint256 seed;
        (seed, ttl) = generateSeed(id);
        uri = generateTokenUri(seed, id);
        price = getVRGDAPrice(toDaysWadUnsafe(block.timestamp - startTime), id);
        hash = blockhash((block.number - 1) - ((block.number - 1) % 5));

        return (id, uri, price, hash, ttl);
    }

    function getCurrentVRGDAPrice() public view returns (uint256) {
        // Note: By using toDaysWadUnsafe(block.timestamp - startTime) we are
        // establishing that 1 "unit of time" is 1 day.
        return
            getVRGDAPrice(
                toDaysWadUnsafe(block.timestamp - startTime),
                totalSold
            );
    }

    function generateSeed(uint256 tokenId) public view returns (uint, uint8) {
        uint8 ttl = 5 - uint8((block.number - 1) % 5);
        return (
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(
                            (block.number - 1) - ((block.number - 1) % 5)
                        ),
                        tokenId
                    )
                )
            ),
            ttl
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

    /// @notice Generates a psuedo-random number from min (inclusive) to max (exclusive)
    /// @param seed The seed to use for the random number (the same across multiple calls)
    /// @param nonce The nonce to use for the random number (different between calls)
    function generateRandom(
        uint256 min,
        uint256 max,
        uint256 seed,
        uint8 nonce
    ) internal pure returns (uint256 random, uint8) {
        uint256 rand = uint256(keccak256(abi.encodePacked(seed, nonce)));
        nonce++;
        return ((rand % (max - min)) + min, nonce);
    }

    function generateRandomBool(
        uint256 seed,
        uint8 nonce
    ) internal pure returns (bool, uint8) {
        uint256 rand = uint256(keccak256(abi.encodePacked(seed, nonce)));
        nonce++;
        return (rand % 2 == 0, nonce);
    }

    function convertSignedUintToString(
        uint256 value,
        bool isNegative
    ) internal pure returns (string memory valueString) {
        if (isNegative) {
            valueString = string.concat("-", value.toString());
        } else {
            valueString = value.toString();
        }
        return valueString;
    }

    /// @notice Generates a baseFrequency string for a feTurbulence element
    function generateBaseFrequency(
        uint256 seed,
        uint8 nonce
    ) internal pure returns (string memory, uint8) {
        uint256 baseFrequency;
        (baseFrequency, nonce) = generateRandom(50, 301, seed, nonce);
        string memory baseFrequencyStr;
        if (baseFrequency < 100) {
            baseFrequencyStr = string.concat("0.00", baseFrequency.toString());
        } else {
            baseFrequencyStr = string.concat("0.0", baseFrequency.toString());
        }

        return (baseFrequencyStr, nonce);
    }

    /// @notice Generates feComposite elements
    function generateFeComposites(
        uint256 seed,
        uint8 nonce,
        string memory attributes
    ) internal pure returns (string memory, string memory, uint8) {
        uint256 random;

        // k4
        string memory k4;
        (random, nonce) = generateRandom(0, 51, seed, nonce);
        if (random < 10) {
            k4 = string.concat("0.0", random.toString());
        } else {
            k4 = string.concat("0.", random.toString());
        }

        // Randomly make k4 negative
        string memory operator;
        bool randomBool;
        (randomBool, nonce) = generateRandomBool(seed, nonce);
        if (randomBool) {
            k4 = string.concat("-", k4);
            operator = "out";
        } else {
            (randomBool, nonce) = generateRandomBool(seed, nonce);
            if (randomBool) {
                operator = "out";
            } else {
                operator = "in";
            }
        }

        // prettier-ignore
        attributes = string.concat(
            attributes,
            '{ "trait_type": "K4", "value": "', k4, '" }, ',
            '{ "trait_type": "Composite Operator", "value": "', operator, '" }, '
        );

        // prettier-ignore
        string memory feComposites = string.concat(
            '<feComposite in="rotateResult" in2="colorChannelResult" operator="', operator,
                       '" result="compositeResult2"/>',
            '<feComposite in="compositeResult2" in2="compositeResult2" operator="arithmetic" k1="1" k2="1" k3="1" k4="',
            k4,
            '"/>'
        );

        return (feComposites, attributes, nonce);
    }

    function generateScale(
        uint256 seed,
        uint8 nonce
    )
        internal
        pure
        returns (string memory scaleStart, string memory scaleValues, uint8)
    {
        uint256 start;
        bool startNegative;
        uint256 end;
        bool endNegative;
        (start, nonce) = generateRandom(0, 201, seed, nonce);
        (startNegative, nonce) = generateRandomBool(seed, nonce);

        uint256 delta;
        bool deltaNegative;
        (delta, nonce) = generateRandom(50, 250, seed, nonce);
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

        // prettier-ignore
        scaleValues = string.concat(
            scaleStart, ";",
            convertSignedUintToString(end, endNegative), ";",
            scaleStart, ";"
        );

        return (scaleStart, scaleValues, nonce);
    }

    /// @notice Generates feDisplacementMap SVG element
    function generateFeDisplacementMap(
        uint256 seed,
        uint8 nonce,
        string memory attributes
    )
        internal
        pure
        returns (
            string memory staticFeDisplacementMap,
            string memory animatedFeDisplacementMap,
            string memory, // attributes
            uint8
        )
    {
        // Generate initial scale value (scaleStart) for static image and animation,
        // and start and end values for animated image (scaleValues)
        string memory scaleStart;
        string memory scaleValues;
        (scaleStart, scaleValues, nonce) = generateScale(seed, nonce);

        // Generate an animation duration for the scale effect
        uint256 animationDurationFeDisplacementMapUint;
        (animationDurationFeDisplacementMapUint, nonce) = generateRandom(
            1,
            81,
            seed,
            nonce
        );
        string memory animationDurationFeDisplacementMap = string.concat(
            animationDurationFeDisplacementMapUint.toString(),
            "s"
        );

        uint256 keyTime;
        (keyTime, nonce) = generateRandom(3, 8, seed, nonce);
        string memory keyTimeStr = string.concat("0.", keyTime.toString());

        // Create the static and animated feDisplacementMap elements
        // prettier-ignore
        animatedFeDisplacementMap = string.concat(
            '<feDisplacementMap result="displacementResult">',
            '<animate attributeName="scale" ',
                     'values="', scaleValues,
                   '" keyTimes="0; ', keyTimeStr, '; 1" dur="', animationDurationFeDisplacementMap,
                   '" repeatCount="indefinite" result="displacementResult" calcMode="spline" keySplines="0.3 0 0.7 1; 0.3 0 0.7 1"/>',
            "</feDisplacementMap>"
        );

        // prettier-ignore
        staticFeDisplacementMap = string.concat(
            '<feDisplacementMap scale="', scaleStart,
                             '" result="displacementResult">',
            "</feDisplacementMap>"
        );

        attributes = string.concat(
            attributes,
            '{ "trait_type": "Scale", "value": "',
            scaleValues,
            '" }, ',
            '{ "trait_type": "Scale Animation", "value": "',
            animationDurationFeDisplacementMap,
            '" }, ',
            '{ "trait_type": "Key Time", "value": "',
            keyTimeStr,
            '" }, '
        );

        return (
            staticFeDisplacementMap,
            animatedFeDisplacementMap,
            attributes,
            nonce
        );
    }

    /// @notice Generates the feTurbulence SVG element
    function generateFeTurbulence(
        uint256 seed,
        uint8 nonce
    )
        internal
        pure
        returns (string memory, string memory, string memory, uint8)
    {
        string memory baseFrequencyStr;
        (baseFrequencyStr, nonce) = generateBaseFrequency(seed, nonce);

        uint256 numOctaves;
        (numOctaves, nonce) = generateRandom(1, 4, seed, 0);

        uint256 seedForSvg;
        (seedForSvg, nonce) = generateRandom(
            0,
            // 65535 is the max value for a uint16 (seed used in SVG)
            65536,
            seed,
            nonce
        );
        return (
            // prettier-ignore
            string.concat(
                '<feTurbulence baseFrequency="', baseFrequencyStr,
                            '" numOctaves="', numOctaves.toString(),
                            '" seed="', seedForSvg.toString(),
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
        uint8 nonce,
        string memory attributes
    ) internal pure returns (string memory, string memory, uint8) {
        uint256 diffuseConstant;
        (diffuseConstant, nonce) = generateRandom(1, 4, seed, nonce);

        // 10 is the largest surface scaled rendered on mobile devices (tested on iPhone 13)
        uint256 surfaceScale;
        (surfaceScale, nonce) = generateRandom(5, 11, seed, nonce);

        uint256 elevation;
        (elevation, nonce) = generateRandom(3, 21, seed, nonce);

        // prettier-ignore
        attributes = string.concat(
            attributes,
            '{ "trait_type": "Diffuse Constant", "value": "', diffuseConstant.toString(), '" }, ',
            '{ "trait_type": "Surface Scale", "value": "', surfaceScale.toString(), '" }, ',
            '{ "trait_type": "Elevation", "value": "', elevation.toString(), '" },'
        );
        return (
            // prettier-ignore
            string.concat(
                '<feDiffuseLighting lighting-color="white" diffuseConstant="', diffuseConstant.toString(),
                                 '" result="diffuseResult" surfaceScale="', surfaceScale.toString(),
                '"><feDistantLight elevation="', elevation.toString(),
                '"></feDistantLight></feDiffuseLighting>'
            ),
            attributes,
            nonce
        );
    }

    /// @notice Generates the feColorMatrix SVG element for (maybe) inverting the colors
    function generateFeColorMatrixForInversion(
        uint256 seed,
        uint8 nonce
    ) internal pure returns (string memory, uint8) {
        bool random;
        (random, nonce) = generateRandomBool(seed, nonce);
        string memory feColorMatrixForInversion;
        // Apply the inversion half the time
        if (random) {
            feColorMatrixForInversion = '<feColorMatrix type="matrix" values="-1 0 0 0 1 0 -1 0 0 1 0 0 -1 0 1 0 0 0 1 0"/>';
        }

        return (feColorMatrixForInversion, nonce);
    }

    function generateSVGPartOne(
        uint256 seed
    )
        internal
        pure
        returns (string memory partOne, string memory attributes, uint8 nonce)
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

        // prettier-ignore
        partOne = string.concat(
            '<svg width="350" height="350" version="1.1" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg">',
                '<filter id="a">',
                    feTurbulence
        );

        // prettier-ignore
        attributes = string.concat(
            '{ "trait_type": "Base Frequency", "value": "', baseFrequencyStr, '" }, ',
            '{ "trait_type": "Octaves", "value": "', numOctaves, '" }, '
        );

        return (partOne, attributes, nonce);
    }

    function generateSVGPartTwo(
        uint256 seed,
        uint8 nonce,
        string memory attributes
    ) internal pure returns (string memory partTwo, string memory, uint8) {
        string memory feComposites;
        (feComposites, attributes, nonce) = generateFeComposites(
            seed,
            nonce,
            attributes
        );

        string memory feDiffuseLighting;
        (feDiffuseLighting, attributes, nonce) = generateFeDiffuseLighting(
            seed,
            nonce,
            attributes
        );

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
        internal
        pure
        returns (
            string memory svgImage,
            string memory svgAnimation,
            string memory attributes
        )
    {
        uint8 nonce;
        string memory partOne;
        string memory partTwo;
        (partOne, attributes, nonce) = generateSVGPartOne(seed);
        (partTwo, attributes, nonce) = generateSVGPartTwo(
            seed,
            nonce,
            attributes
        );

        string memory staticFeDisplacementMap;
        string memory animatedFeDisplacementMap;
        (
            staticFeDisplacementMap,
            animatedFeDisplacementMap,
            attributes,
            nonce
        ) = generateFeDisplacementMap(seed, nonce, attributes);

        // Attributes
        // prettier-ignore
        uint256 animationDurationHueRotate;
        (animationDurationHueRotate, nonce) = generateRandom(
            1,
            25,
            seed,
            nonce
        );
        attributes = string.concat(
            attributes,
            '{ "trait_type": "Hue Rotate Animation", "value": "',
            animationDurationHueRotate.toString(),
            's" }'
        );

        // Image
        svgImage = string.concat(
            partOne,
            staticFeDisplacementMap,
            '<feColorMatrix type="hueRotate" result="rotateResult">',
            "</feColorMatrix>",
            partTwo
        );

        // Animation
        // prettier-ignore
        string memory animatedFeColorMatrix = string.concat(
            '<animate attributeName="values" from="0" to="360" ',
                     'dur="', animationDurationHueRotate.toString(), 's" ',
                     'repeatCount="indefinite" result="colorMatrixResult"/>'
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
        uint256 seed,
        uint256 tokenId
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
                            attributes, ' }'
                    )
                )
            )
        );

        return
            string(
                abi.encodePacked("data:application/json;base64,", metadataJson)
            );
    }
}
