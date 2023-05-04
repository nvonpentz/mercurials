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

    event TokenMinted(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 price
    );

    /// @notice The total number of tokens sold, also used as the next token ID
    uint256 public totalSold;

    /// @notice The time at which the auction starts
    uint256 public immutable startTime = block.timestamp;

    /// @notice The seed used to generate the token's attributes
    mapping(uint256 => uint256) public seeds;

    constructor()
        ERC721("Mercurials", "MERC")
        LinearVRGDA(
            // Target price
            0.001e18,
            // Price decay percent
            0.05e18,
            // Per time unit
            1e18
        )
    {}

    /// @notice Mint a new token
    /// @param tokenId The token ID to mint
    /// @param blockHash The parent blockhash
    function mint(
        uint256 tokenId,
        bytes32 blockHash
    ) external payable nonReentrant {
        // Do not mint if transaction is late by checking the user supplied
        // supplied token ID and blockhash match the current token ID and
        // blockhash
        bytes32 expectedBlockHash = blockhash(
            (block.number - 1) - ((block.number - 1) % 5)
        );
        require(blockHash == expectedBlockHash, "Invalid or expired blockhash");
        require(tokenId == totalSold, "Invalid or expired token ID");

        unchecked {
            // Validate the purchase request against the VRGDA rules.
            uint256 price = getCurrentVRGDAPrice();
            require(msg.value >= price, "Insufficient funds");

            // Mint the NFT
            _mint(msg.sender, tokenId);
            emit TokenMinted(tokenId, msg.sender, price);

            // Increment the total sold counter.
            totalSold += 1;

            // Generate the seed and store it
            (uint256 seed, ) = generateSeed(tokenId);
            seeds[tokenId] = seed;

            // Refund the user any ETH they spent over the current price of the NFT.
            // Unchecked is safe here because we validate msg.value >= price above.
            SafeTransferLib.safeTransferETH(msg.sender, msg.value - price);
        }
    }

    /// @notice Returns information about the next token that can be minted.
    /// @dev This function should be called using the `pending` block tag.
    /// @dev The id and hash should passed as arguments to the `mint` function.
    /// @return id The token ID of the next token
    /// @return uri The token URI of the next token
    /// @return price The price of the next token
    /// @return blockHash The parent blockhash rounded to the nearest 5
    /// @return ttl The time to live, in blocks, of the next token
    function nextToken()
        external
        view
        returns (
            uint256 id,
            string memory uri,
            uint256 price,
            bytes32 blockHash,
            uint256 ttl
        )
    {
        // Coveniently, the next token ID is also the total sold.
        id = totalSold;

        // Fetch the current seed and it's TTL
        uint256 seed;
        (seed, ttl) = generateSeed(id);

        // Generate the token URI using the seed
        uri = generateTokenUri(seed, id);

        // Calculate the current price according to VRGDA rules
        price = getVRGDAPrice(toDaysWadUnsafe(block.timestamp - startTime), id);

        // Calculate the parent blockhash rounded down to the nearest 5.
        blockHash = blockhash((block.number - 1) - ((block.number - 1) % 5));

        return (id, uri, price, blockHash, ttl);
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

    /// @notice Generate the seed for a given token ID
    /// @param tokenId The token ID to generate the seed for
    /// @return seed The seed for the given token ID
    /// @return ttl The time to live, in blocks, of the seed
    function generateSeed(
        uint256 tokenId
    ) public view returns (uint256 seed, uint256 ttl) {
        // Seed is calculated as the hash of current token ID and the parent
        // blockhash, rounded down to the nearest 5.
        seed = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash((block.number - 1) - ((block.number - 1) % 5)),
                    tokenId
                )
            )
        );

        // TODO
        ttl = 5 - ((block.number - 1) % 5);

        return (seed, ttl);
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
        uint256 nonce
    ) internal pure returns (uint256 random, uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(seed, nonce)));
        nonce++;
        return ((rand % (max - min)) + min, nonce);
    }

    function generateRandomBool(
        uint256 seed,
        uint256 nonce
    ) internal pure returns (bool, uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(seed, nonce)));
        nonce++;
        return (rand % 2 == 0, nonce);
    }

    function intToString(
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
        uint256 nonce
    ) internal pure returns (string memory baseFrequency, uint256) {
        uint256 random;
        (random, nonce) = generateRandom(50, 301, seed, nonce);
        if (random < 100) {
            baseFrequency = string.concat("0.00", random.toString());
        } else {
            baseFrequency = string.concat("0.0", random.toString());
        }

        return (baseFrequency, nonce);
    }

    /// @notice Generates the feTurbulence SVG element
    function generateFeTurbulenceElement(
        uint256 seed,
        uint256 nonce
    )
        internal
        pure
        returns (
            string memory feTurbulence,
            string memory,
            string memory baseFrequency,
            uint256
        )
    {
        (baseFrequency, nonce) = generateBaseFrequency(seed, nonce);

        uint256 numOctaves;
        (numOctaves, nonce) = generateRandom(1, 4, seed, 0);

        uint256 seedForSvg;
        (seedForSvg, nonce) = generateRandom(
            0,
            // Note: 65535 is the max value for the seed attribute of
            // the feTurbulence SVG element.
            65536,
            seed,
            nonce
        );
        feTurbulence = string.concat(
            '<feTurbulence baseFrequency="',
            baseFrequency,
            '" numOctaves="',
            numOctaves.toString(),
            '" seed="',
            seedForSvg.toString(),
            '" result="turbulenceResult"/> '
        );
        return (feTurbulence, numOctaves.toString(), baseFrequency, nonce);
    }

    /// @notice Generates feComposite elements
    function generateFeCompositeElements(
        uint256 seed,
        uint256 nonce
    )
        internal
        pure
        returns (
            string memory feCompositeElements,
            string memory attributes,
            uint256
        )
    {
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

        feCompositeElements = string.concat(
            '<feComposite in="rotateResult" in2="colorChannelResult" operator="',
            operator,
            '" result="compositeResult2"/>',
            '<feComposite in="compositeResult2" in2="compositeResult2" operator="arithmetic" k1="1" k2="1" k3="1" k4="',
            k4,
            '"/>'
        );

        attributes = string.concat(
            '{ "trait_type": "K4", "value": "',
            k4,
            '" }, { "trait_type": "Composite Operator", "value": "',
            operator,
            '" }, '
        );
        return (feCompositeElements, attributes, nonce);
    }

    /// @notice Generates the feDiffuseLighting SVG element
    function generateFeDiffuseLightingElement(
        uint256 seed,
        uint256 nonce
    )
        internal
        pure
        returns (
            string memory feDiffuseLightingElement,
            string memory attributes,
            uint256
        )
    {
        uint256 diffuseConstant;
        (diffuseConstant, nonce) = generateRandom(1, 4, seed, nonce);

        // 10 is the largest surface scaled rendered on mobile devices
        uint256 surfaceScale;
        (surfaceScale, nonce) = generateRandom(5, 11, seed, nonce);

        uint256 elevation;
        (elevation, nonce) = generateRandom(3, 21, seed, nonce);

        feDiffuseLightingElement = string.concat(
            '<feDiffuseLighting lighting-color="white" diffuseConstant="',
            diffuseConstant.toString(),
            '" result="diffuseResult" surfaceScale="',
            surfaceScale.toString(),
            '"><feDistantLight elevation="',
            elevation.toString(),
            '"></feDistantLight></feDiffuseLighting>'
        );

        attributes = string.concat(
            '{ "trait_type": "Diffuse Constant", "value": "',
            diffuseConstant.toString(),
            '" }, ',
            '{ "trait_type": "Surface Scale", "value": "',
            surfaceScale.toString(),
            '" }, { "trait_type": "Elevation", "value": "',
            elevation.toString(),
            '" },'
        );
        return (feDiffuseLightingElement, attributes, nonce);
    }

    /// @notice Generates the feColorMatrix SVG element for (maybe) inverting the colors
    function generateFeColorMatrixForInversionElement(
        uint256 seed,
        uint256 nonce
    )
        internal
        pure
        returns (string memory feColorMatrixForInversionElement, uint256)
    {
        bool random;
        (random, nonce) = generateRandomBool(seed, nonce);
        // Apply the inversion half the time
        if (random) {
            feColorMatrixForInversionElement = '<feColorMatrix type="matrix" values="-1 0 0 0 1 0 -1 0 0 1 0 0 -1 0 1 0 0 0 1 0"/>';
        }

        return (feColorMatrixForInversionElement, nonce);
    }

    /// @notice TODO
    function generateScale(
        uint256 seed,
        uint256 nonce
    )
        internal
        pure
        returns (string memory scaleStart, string memory scaleValues, uint256)
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
        scaleStart = intToString(start, startNegative);

        scaleValues = string.concat(
            scaleStart,
            ";",
            intToString(end, endNegative),
            ";",
            scaleStart,
            ";"
        );

        return (scaleStart, scaleValues, nonce);
    }

    /// @notice Generates feDisplacementMap SVG element
    function generateFeDisplacementMapAttributes(
        uint256 seed,
        uint256 nonce
    )
        internal
        pure
        returns (
            string memory staticFeDisplacementMapElement,
            string memory animatedFeDisplacementMapElement,
            string memory attributes,
            uint256
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
        animatedFeDisplacementMapElement = string.concat(
            '<feDisplacementMap result="displacementResult"><animate attributeName="scale" ',
            'values="',
            scaleValues,
            '" keyTimes="0; ',
            keyTimeStr,
            '; 1" dur="',
            animationDurationFeDisplacementMap,
            '" repeatCount="indefinite" result="displacementResult" calcMode="spline" keySplines="0.3 0 0.7 1; 0.3 0 0.7 1"/>'
            "</feDisplacementMap>"
        );

        staticFeDisplacementMapElement = string.concat(
            '<feDisplacementMap scale="',
            scaleStart,
            '" result="displacementResult"></feDisplacementMap>'
        );

        attributes = string.concat(
            '{ "trait_type": "Scale", "value": "',
            scaleValues,
            '" }, { "trait_type": "Scale Animation", "value": "',
            animationDurationFeDisplacementMap,
            '" }, { "trait_type": "Key Time", "value": "',
            keyTimeStr,
            '" }, '
        );
        return (
            staticFeDisplacementMapElement,
            animatedFeDisplacementMapElement,
            attributes,
            nonce
        );
    }

    /// @notice TODO
    function generateFeColorMatrixHueRotateElement(
        uint256 seed,
        uint256 nonce
    )
        internal
        pure
        returns (
            string memory animatedFeColorMatrixElement,
            string memory attributes,
            uint256
        )
    {
        uint256 animationDurationHueRotate;
        (animationDurationHueRotate, nonce) = generateRandom(
            1,
            25,
            seed,
            nonce
        );

        animatedFeColorMatrixElement = string.concat(
            '<animate attributeName="values" from="0" to="360" ',
            'dur="',
            animationDurationHueRotate.toString(),
            's" ',
            'repeatCount="indefinite" result="colorMatrixResult"/>'
        );
        attributes = string.concat(
            '{ "trait_type": "Hue Rotate Animation", "value": "',
            animationDurationHueRotate.toString(),
            's" }'
        );

        return (animatedFeColorMatrixElement, attributes, nonce);
    }

    /// @notice TODO
    function generateSVGPartOne(
        uint256 seed
    )
        internal
        pure
        returns (string memory partOne, string memory attributes, uint256 nonce)
    {
        string memory feTurbulenceElement;
        string memory numOctaves;
        string memory baseFrequency;
        (
            feTurbulenceElement,
            numOctaves,
            baseFrequency,
            nonce
        ) = generateFeTurbulenceElement(seed, nonce);

        partOne = string.concat(
            '<svg width="350" height="350" version="1.1" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg">',
            '<filter id="a">',
            feTurbulenceElement
        );

        attributes = string.concat(
            '{ "trait_type": "Base Frequency", "value": "',
            baseFrequency,
            '" }, { "trait_type": "Octaves", "value": "',
            numOctaves,
            '" }, '
        );

        return (partOne, attributes, nonce);
    }

    // @notice TODO
    function generateSVGPartTwo(
        uint256 seed,
        uint256 nonce
    )
        internal
        pure
        returns (string memory partTwo, string memory attributes, uint256)
    {
        string memory feCompositeElements;
        string memory feCompositeAttributes;
        (
            feCompositeElements,
            feCompositeAttributes,
            nonce
        ) = generateFeCompositeElements(seed, nonce);

        string memory feDiffuseLightingAttributes;
        string memory feDiffuseLightingElement;
        (
            feDiffuseLightingElement,
            feDiffuseLightingAttributes,
            nonce
        ) = generateFeDiffuseLightingElement(seed, nonce);

        string memory feColorMatrixForInversionElement;
        (
            feColorMatrixForInversionElement,
            nonce
        ) = generateFeColorMatrixForInversionElement(seed, nonce);
        partTwo = string.concat(
            '<feColorMatrix type="matrix" result="colorChannelResult" ',
            'values="0 0 0 0 0 ',
            "0 0 0 0 0 ",
            "0 0 0 0 0 ",
            '1 0 0 0 0">',
            "</feColorMatrix>",
            // Add inside-out effect and flatness effect
            feCompositeElements,
            // Light
            feDiffuseLightingElement,
            // Invert the colors half the time
            feColorMatrixForInversionElement,
            "</filter>",
            '<rect width="350" height="350" filter="url(#a)"/>',
            "</svg>"
        );

        attributes = string.concat(
            feCompositeAttributes,
            feDiffuseLightingAttributes
        );

        return (partTwo, attributes, nonce);
    }

    ///@notice Combines partOne and partTwo to create the animated and static SVGs
    function generateSvgPartThree(
        string memory partOne,
        string memory partTwo,
        // string memory attributes,
        uint256 nonce,
        uint256 seed
    )
        internal
        pure
        returns (
            string memory svgImage,
            string memory svgAnimation,
            string memory
        )
    {
        string memory staticFeDisplacementMapElement;
        string memory animatedFeDisplacementMapElement;
        string memory feDisplacementMapAttributes;
        (
            staticFeDisplacementMapElement,
            animatedFeDisplacementMapElement,
            feDisplacementMapAttributes,
            nonce
        ) = generateFeDisplacementMapAttributes(seed, nonce);

        string memory animatedFeColorMatrixElement;
        string memory feColorMatrixAttributes;
        (
            animatedFeColorMatrixElement,
            feColorMatrixAttributes,
            nonce
        ) = generateFeColorMatrixHueRotateElement(seed, nonce);

        // Image
        svgImage = string.concat(
            partOne,
            staticFeDisplacementMapElement,
            '<feColorMatrix type="hueRotate" result="rotateResult">',
            "</feColorMatrix>",
            partTwo
        );

        // Animation
        svgAnimation = string.concat(
            partOne,
            animatedFeDisplacementMapElement,
            '<feColorMatrix type="hueRotate" result="rotateResult">',
            animatedFeColorMatrixElement,
            "</feColorMatrix>",
            partTwo
        );

        return (
            svgImage,
            svgAnimation,
            string.concat(feDisplacementMapAttributes, feColorMatrixAttributes)
        );
    }

    /// @notice Generates the raw SVG code and the attributes
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
        // Nonce is incremented after each random number is generated
        uint256 nonce;
        string memory partOne;
        string memory partTwo;
        string memory partOneAttributes;
        string memory partTwoAttributes;
        (partOne, partOneAttributes, nonce) = generateSVGPartOne(seed);
        (partTwo, partTwoAttributes, nonce) = generateSVGPartTwo(seed, nonce);
        (svgImage, svgAnimation, attributes) = generateSvgPartThree(
            partOne,
            partTwo,
            nonce,
            seed
        );

        attributes = string.concat(
            partOneAttributes,
            partTwoAttributes,
            attributes
        );

        return (svgImage, svgAnimation, attributes);
    }

    /// @notice Generates the entire SVG
    function generateTokenUri(
        uint256 seed,
        uint256 tokenId
    ) internal pure returns (string memory tokenUri) {
        // Generate the code for the static SVG, the code for the
        // animated SVG, and the attributes for the metadata.
        (
            string memory svgImage,
            string memory svgAnimation,
            string memory attributes
        ) = generateSVG(seed);

        // Create token URI from base64 encoded metadata JSON
        tokenUri = string.concat(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    string.concat(
                        '{ "name": "Mercurial #',
                        tokenId.toString(),
                        '", ',
                        '"description": "On chain generative art project.", ',
                        '"image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(svgImage)),
                        '", ',
                        '"animation_url": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(svgAnimation)),
                        '", ',
                        '"attributes": [ ',
                        attributes,
                        " ] }"
                    )
                )
            )
        );

        return tokenUri;
    }
}
