// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Base64} from "openzeppelin-contracts/contracts/utils/Base64.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {LinearVRGDA} from "VRGDAs/LinearVRGDA.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {toDaysWadUnsafe} from "solmate/utils/SignedWadMath.sol";

contract Mercurial is ERC721, LinearVRGDA, ReentrancyGuard {
    using Strings for uint256;

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

    // @notice Sets the VRGDA params, and the ERC721 name and symbol
    constructor()
        ERC721("Mercurials (Test)", "MERC")
        LinearVRGDA(
            // Target price, 0.001 Ether
            0.001e18,
            // Price decay percent, 5%
            0.05e18,
            // Per time unit, 1 day
            1e18
        )
    {}

    /// @notice Mint a new token
    /// @param tokenId The token ID to mint
    /// @param blockHash The hash of the parent block number rounded down
    /// to the nearest multiple of 5
    function mint(
        uint256 tokenId,
        bytes32 blockHash
    ) external payable nonReentrant {
        // Don't mint if the user supplied token ID and blockHash
        // don't match the current values
        require(
            blockHash ==
                blockhash((block.number - 1) - ((block.number - 1) % 5)),
            "Invalid blockhash"
        );
        require(tokenId == totalSold, "Invalid token ID");

        // Validate the purchase request against the VRGDA rules.
        uint256 price = getCurrentVRGDAPrice();
        require(msg.value >= price, "Insufficient funds");

        // Mint the NFT
        _mint(msg.sender, tokenId);
        emit TokenMinted(tokenId, msg.sender, price);

        // Increment the total sold counter.
        totalSold += 1;

        // Generate the seed and store it
        seeds[tokenId] = generateSeed(tokenId);

        // Refund the user any ETH they spent over the current price of the NFT.
        SafeTransferLib.safeTransferETH(msg.sender, msg.value - price);
    }

    /// @notice Returns information about the next token that can be minted.
    /// @dev This function should be called using the `pending` block tag.
    /// @dev The id and hash should passed as arguments to the `mint` function.
    /// @return id The token ID of the next token
    /// @return uri The token URI of the next token
    /// @return price The price of the next token
    /// @return blockHash The hash of the parent block number rounded down to
    /// the nearest multiple of 5
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

        // Generate the token URI using the seed
        uri = generateTokenUri(generateSeed(id), id);

        // Calculate the current price according to VRGDA rules
        price = getVRGDAPrice(toDaysWadUnsafe(block.timestamp - startTime), id);

        // Calculate the block hash corresponding to the next token
        blockHash = blockhash((block.number - 1) - ((block.number - 1) % 5));

        // Calculate the time to live
        ttl = 5 - ((block.number - 1) % 5);

        return (id, uri, price, blockHash, ttl);
    }

    /// @notice Get the current price of the token based according to VRGDA rules
    function getCurrentVRGDAPrice() public view returns (uint256) {
        // Note: By using toDaysWadUnsafe(block.timestamp - startTime) we are
        // establishing that 1 "unit of time" is 1 day.
        return
            getVRGDAPrice(
                toDaysWadUnsafe(block.timestamp - startTime),
                totalSold
            );
    }

    /// @notice Generates the seed for a given token ID
    /// @param tokenId The token ID to generate the seed for
    /// @return seed The seed for the given token ID
    function generateSeed(uint256 tokenId) public view returns (uint256) {
        // Seed is calculated as the hash of current token ID with the parent
        // block rounded down to the nearest 5.
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(
                            (block.number - 1) - ((block.number - 1) % 5)
                        ),
                        tokenId
                    )
                )
            );
    }

    // @notice Returns the token URI for a given token ID
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist.");
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

    /// @notice Generates a random value that is either true or false
    function generateRandomBool(
        uint256 seed,
        uint256 nonce
    ) internal pure returns (bool, uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(seed, nonce)));
        nonce++;
        return (rand % 2 == 0, nonce);
    }

    /// @notice Returns a string representation of a signed integer
    function intToString(
        uint256 value,
        bool isNegative
    ) internal pure returns (string memory) {
        if (isNegative) {
            return string.concat("-", value.toString());
        }
        return value.toString();
    }

    /// @notice Generates the feTurbulence SVG element
    function generateFeTurbulenceElement(
        uint256 seed,
        uint256 nonce
    )
        internal
        pure
        returns (string memory element, string memory attributes, uint256)
    {
        uint256 random;

        // Generate a random value to use for the baseFrequency attribute
        (random, nonce) = generateRandom(50, 301, seed, nonce);
        string memory baseFrequency;
        if (random < 100) {
            baseFrequency = string.concat("0.00", random.toString());
        } else {
            baseFrequency = string.concat("0.0", random.toString());
        }

        // Generate a random value to use for the numOctaves attribute
        string memory numOctaves;
        (random, nonce) = generateRandom(1, 4, seed, 0);
        numOctaves = random.toString();

        // Generate a random value to use for the seed attribute of the SVG
        string memory seedForSvg;
        (random, nonce) = generateRandom(
            0,
            // Note: 65535 is the max value for the seed attribute of
            // the feTurbulence SVG element.
            65536,
            seed,
            nonce
        );
        seedForSvg = random.toString();

        // Create the SVG element
        element = string.concat(
            '<feTurbulence baseFrequency="',
            baseFrequency,
            '" numOctaves="',
            numOctaves,
            '" seed="',
            seedForSvg,
            '" />'
        );

        // Create the attributes
        attributes = string.concat(
            '{ "trait_type": "Base Frequency", "value": "',
            baseFrequency,
            '" }, { "trait_type": "Octaves", "value": "',
            numOctaves,
            '" }, '
        );

        return (element, attributes, nonce);
    }

    /// @notice Generates feComposite elements
    function generateFeCompositeElements(
        uint256 seed,
        uint256 nonce
    )
        internal
        pure
        returns (string memory elements, string memory attributes, uint256)
    {
        uint256 random;

        // Generate a random value for the k4 attribute
        string memory k4;
        (random, nonce) = generateRandom(0, 51, seed, nonce);
        if (random < 10) {
            k4 = string.concat("0.0", random.toString());
        } else {
            k4 = string.concat("0.", random.toString());
        }

        // Make k4 negative half the time
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

        // Create the feComposite elements
        elements = string.concat(
            '<feComposite in="b" in2="c" operator="',
            operator,
            '" result="d"/><feComposite in="d" in2="d" operator="arithmetic" k1="1" k2="1" k3="1" k4="',
            k4,
            '"/>'
        );

        // Create the attributes
        attributes = string.concat(
            '{ "trait_type": "K4", "value": "',
            k4,
            '" }, { "trait_type": "Composite Operator", "value": "',
            operator,
            '" }, '
        );

        return (elements, attributes, nonce);
    }

    /// @notice Generates the feDiffuseLighting SVG element
    function generateFeDiffuseLightingElement(
        uint256 seed,
        uint256 nonce
    )
        internal
        pure
        returns (string memory element, string memory attributes, uint256)
    {
        uint256 random;
        // Generate a random value from 1 up to 4 for the diffuse constant.
        string memory diffuseConstant;
        (random, nonce) = generateRandom(1, 4, seed, nonce);
        diffuseConstant = random.toString();

        // Generate a random value from 5 up to 11 for the surfaceScale.
        string memory surfaceScale;
        // Note: 10 is the largest surface scale rendered on mobile devices
        (random, nonce) = generateRandom(5, 11, seed, nonce);
        surfaceScale = random.toString();

        // Generate a random value from 3 up to 21 for the elevation.
        string memory elevation;
        (random, nonce) = generateRandom(3, 21, seed, nonce);
        elevation = random.toString();

        // Create the feDiffuseLighting element
        element = string.concat(
            '<feDiffuseLighting lighting-color="#fff" diffuseConstant="',
            diffuseConstant,
            '" surfaceScale="',
            surfaceScale,
            '"><feDistantLight elevation="',
            elevation,
            '"/></feDiffuseLighting>'
        );

        // Create the attributes
        attributes = string.concat(
            '{ "trait_type": "Diffuse Constant", "value": "',
            diffuseConstant,
            '" }, { "trait_type": "Surface Scale", "value": "',
            surfaceScale,
            '" }, { "trait_type": "Elevation", "value": "',
            elevation,
            '" },'
        );

        return (element, attributes, nonce);
    }

    /// @notice Generates the feColorMatrix SVG element for (maybe) inverting the colors
    function generateFeColorMatrixForInversionElement(
        uint256 seed,
        uint256 nonce
    )
        internal
        pure
        returns (string memory element, string memory attributes, uint256)
    {
        // Apply the inversion half the time.
        bool invert;
        (invert, nonce) = generateRandomBool(seed, nonce);
        if (invert) {
            element = '<feColorMatrix type="matrix" values="-1 0 0 0 1 0 -1 0 0 1 0 0 -1 0 1 0 0 0 1 0"/>';
        }

        attributes = string.concat(
            '{ "trait_type": "Inverted", "value": ',
            invert ? "true" : "false",
            " } " // No comma here because this is the last attribute.
        );

        return (element, attributes, nonce);
    }

    /// @notice Generates the scale values for the feDisplacementMap SVG element
    function generateScale(
        uint256 seed,
        uint256 nonce
    ) internal pure returns (string memory scaleValues, uint256) {
        // Generate a start value from -200 through 200.
        uint256 start;
        bool startNegative;
        (start, nonce) = generateRandom(0, 201, seed, nonce);
        (startNegative, nonce) = generateRandomBool(seed, nonce);

        // Generate a delta value from 50 up to 251, or -50 up to -250 to add
        // to the start value to get the middle value.
        uint256 delta;
        bool deltaNegative;
        (delta, nonce) = generateRandom(50, 251, seed, nonce);
        (deltaNegative, nonce) = generateRandomBool(seed, nonce);

        // Based on the start and delta values, add start and delta together to
        // get the middle value.
        uint256 end;
        bool endNegative;
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

        // Convert the start value to a string representation
        string memory scaleStart = intToString(start, startNegative);

        // Concatenate the start, middle, and end values of the scale animation
        scaleValues = string.concat(
            scaleStart,
            ";",
            intToString(end, endNegative),
            ";",
            scaleStart,
            ";"
        );

        return (scaleValues, nonce);
    }

    /// @notice Generates feDisplacementMap SVG element
    function generateFeDisplacementMapElement(
        uint256 seed,
        uint256 nonce
    )
        internal
        pure
        returns (string memory element, string memory attributes, uint256)
    {
        // Generate scale values for the animation.
        string memory scaleValues;
        (scaleValues, nonce) = generateScale(seed, nonce);

        // Generate a random value between 1 and 80 to be the scale animation
        // duration in seconds.
        uint256 random;
        (random, nonce) = generateRandom(1, 81, seed, nonce);

        // Convert to string and append 's' to represent seconds in the SVG.
        string memory animationDuration = string.concat(random.toString(), "s");

        // Generate a random number from 3 up to 8 to be the middle keyTime value.
        (random, nonce) = generateRandom(3, 8, seed, nonce);
        string memory keyTime = string.concat("0.", random.toString());

        element = string.concat(
            '<feDisplacementMap><animate attributeName="scale" values="',
            scaleValues,
            '" keyTimes="0; ',
            keyTime,
            '; 1" dur="',
            animationDuration,
            '" repeatCount="indefinite" calcMode="spline" keySplines="0.3 0 0.7 1; 0.3 0 0.7 1"/></feDisplacementMap>'
        );

        attributes = string.concat(
            '{ "trait_type": "Scale", "value": "',
            scaleValues,
            '" }, { "trait_type": "Scale Animation", "value": "',
            animationDuration,
            '" }, { "trait_type": "Key Time", "value": "',
            keyTime,
            '" }, '
        );
        return (element, attributes, nonce);
    }

    /// @notice Generates the feColorMatrix element used for the rotation animation
    function generateFeColorMatrixHueRotateElement(
        uint256 seed,
        uint256 nonce
    )
        internal
        pure
        returns (string memory element, string memory attributes, uint256)
    {
        // Generate a value from 1 to 25 to be the duration of the animation
        uint256 random;
        (random, nonce) = generateRandom(1, 25, seed, nonce);
        string memory animationDuration = random.toString();

        // Create the feColorMatrix element with the <animate> element inside
        element = string.concat(
            '<feColorMatrix type="hueRotate" result="b"><animate attributeName="values" from="0" to="360" dur="',
            animationDuration,
            's" repeatCount="indefinite"/></feColorMatrix>'
        );

        // Save the animation duration
        attributes = string.concat(
            '{ "trait_type": "Hue Rotate Animation", "value": "',
            animationDuration,
            's" }, '
        );

        return (element, attributes, nonce);
    }

    /// @notice Generates the first part of the SVG
    function generateSvgPartOne(
        uint256 seed,
        uint256 nonce
    ) internal pure returns (string memory svg, string memory attributes) {
        // Generate the feTurbulence element
        string memory feTurbulenceElement;
        string memory feTurbulenceAttributes;
        (
            feTurbulenceElement,
            feTurbulenceAttributes,
            nonce
        ) = generateFeTurbulenceElement(seed, nonce);

        // Generate teh feDisplacementMap element
        string memory feDisplacementMapElement;
        string memory feDisplacementMapAttributes;
        (
            feDisplacementMapElement,
            feDisplacementMapAttributes,
            nonce
        ) = generateFeDisplacementMapElement(seed, nonce);

        // Concatenate the two elements with the SVG start
        svg = string.concat(
            '<svg width="350" height="350" version="1.1" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg"><filter id="a">',
            feTurbulenceElement,
            feDisplacementMapElement
        );

        // Concatenate the attributes
        attributes = string.concat(
            feTurbulenceAttributes,
            feDisplacementMapAttributes
        );

        return (svg, attributes);
    }

    function generateSvg(
        uint256 seed
    ) internal pure returns (string memory svg, string memory attributes) {
        uint256 nonce;

        // Generate the first part of the SVG in a separate function
        (svg, attributes) = generateSvgPartOne(seed, nonce);

        // Generate the feColorMatrix element
        string memory feColorMatrixElement;
        string memory feColorMatrixAttributes;
        (
            feColorMatrixElement,
            feColorMatrixAttributes,
            nonce
        ) = generateFeColorMatrixHueRotateElement(seed, nonce);

        // Generate the feCompositeElements
        string memory feCompositeElements;
        string memory feCompositeAttributes;
        (
            feCompositeElements,
            feCompositeAttributes,
            nonce
        ) = generateFeCompositeElements(seed, nonce);

        // Generate the feDiffuseLighting element
        string memory feDiffuseLightingElement;
        string memory feDiffuseLightingAttributes;
        (
            feDiffuseLightingElement,
            feDiffuseLightingAttributes,
            nonce
        ) = generateFeDiffuseLightingElement(seed, nonce);

        // Generate the feColorMatrix element used for inverting colors
        string memory feColorMatrixForInversionElement;
        string memory feColorMatrixForInversionAttributes;
        (
            feColorMatrixForInversionElement,
            feColorMatrixForInversionAttributes,
            nonce
        ) = generateFeColorMatrixForInversionElement(seed, nonce);

        // Concatenate all the SVG elements creating the final SVG
        svg = string.concat(
            svg,
            feColorMatrixElement,
            '<feColorMatrix type="matrix" result="c" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0"/>',
            feCompositeElements,
            feDiffuseLightingElement,
            feColorMatrixForInversionElement,
            '</filter><rect width="350" height="350" filter="url(#a)"/></svg>'
        );

        // Concatenate all the attributes
        attributes = string.concat(
            attributes,
            feColorMatrixAttributes,
            feCompositeAttributes,
            feDiffuseLightingAttributes,
            feColorMatrixForInversionAttributes
        );

        return (svg, attributes);
    }

    /// @notice Generates the entire SVG
    function generateTokenUri(
        uint256 seed,
        uint256 tokenId
    ) internal pure returns (string memory tokenUri) {
        // Generate the code for the SVG
        (string memory svg, string memory attributes) = generateSvg(seed);

        // Create token URI from base64 encoded metadata JSON
        tokenUri = string.concat(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    string.concat(
                        '{ "name": "Mercurial #',
                        tokenId.toString(),
                        '", "description": "Mercurials is an on-chain generative art project.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg)),
                        '", "attributes": [ ',
                        attributes,
                        " ] }"
                    )
                )
            )
        );

        return tokenUri;
    }
}
