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

    function generateComplementaryColor(uint color) public pure returns(uint) {
        uint red = color >> 16;
        uint green = (color >> 8) & 0xFF;
        uint blue = color & 0xFF;
        
        red = 255 - red;
        green = 255 - green;
        blue = 255 - blue;
        
        return (red << 16) | (green << 8) | blue;
    }

    function generateRandomColor(uint seed) internal view returns (string memory) {
        return string.concat('#', toHexStringNoPrefix(generateRandom(0, 16777215, seed), uint(3)));
    }

    function toHexColor(uint colorInt) public view returns (string memory) {
        return string.concat('#', toHexStringNoPrefix(colorInt, uint(3)));
    } 

    function generateBackgroundColor(uint tokenId) public view returns (string memory) {
        string memory valForColor = generateRandom(0, 256, tokenId).toString();
        return string.concat('rgb(', valForColor, ',', valForColor, ',', valForColor, ')');
    }

    function generatePrimaryColor(uint tokenId) public view returns (uint) {
        uint seed = uint(keccak256(abi.encodePacked(tokenId, uint(0))));
        return generateRandom(0, 16777215, seed);
    }

    function generateFrequency(uint tokenId) public view returns (string memory) {
        uint random = generateRandom(1, 50, tokenId);
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

    function generateTurbulenceType(uint tokenId) public view returns (string memory) {
        return '"turbulence"';
    }

    function generateOctaves(uint tokenId) public view returns (string memory) {
        uint random = generateRandom(1, 5, tokenId);
        return random.toString();
    }

    function generateScale(uint tokenId) public view returns (string memory) {
        return generateRandom(0, 80, tokenId).toString();
    }

    function generateStyles(uint tokenId, string memory backgroundColor, string memory color) public view returns (string memory) {
        return
            // prettier-ignore
            string.concat(
                '<style>',
                    '.rect0 { fill: ', backgroundColor,' }',
                    '.rect1 { fill: ', color, '; filter: url(#cracked-lava) }',
                '</style>'
            );
    }

    function generateFilters(uint tokenId, string memory lightingColor) public view returns (string memory) {
        return // prettier-ignore
            string.concat(
                '<filter id="cracked-lava">',
                  '<feTurbulence baseFrequency="0.', generateFrequency(tokenId), '" type=',generateTurbulenceType(tokenId), ' numOctaves="', generateOctaves(tokenId),'" result="r1" id="feTurbulence2338"/>',
                  '<feDisplacementMap result="r5" xChannelSelector="R" in2="r1" in="r1" yChannelSelector="G">',
                    '<animate attributeName="scale" dur="10s" repeatCount="indefinite" values="', generateScale(tokenId), ';0;" />',
                  '</feDisplacementMap>', // can be paramerized

                  '<feComposite result="r2" operator="in" in2="r5" in="SourceGraphic"/>',
                  '<feSpecularLighting lighting-color="white" surfaceScale="2" result="r4" specularConstant="2" specularExponent="65" in="r2">',
                    '<feDistantLight elevation="60" azimuth="0">', // TODO maybe parameterize elevation to be between 90 and 120
                      '<animate attributeName="azimuth" values="0;360;" dur="10s" repeatCount="indefinite"/>',
                    '</feDistantLight>',
                  '</feSpecularLighting>'
                  '<feComposite k1="2.5" k3="1" k2="-0.5" in2="r2" in="r4" operator="arithmetic" result="r91"/>',
                  '<feBlend result="fbSourceGraphic" mode="multiply" in2="r91"/>',
                  '<feGaussianBlur stdDeviation="2" in="fbSourceGraphic" result="SourceGraphic"/>', // Could parameterize or animate the stdDeviation
                  '<feSpecularLighting in="SourceGraphic" result="r1" lighting-color="', lightingColor,'" surfaceScale="4" specularConstant="0.8" specularExponent="15">',
                    '<fePointLight x="-5000" y="-10000" z="20000"/>', // Could parameterize this
                  '</feSpecularLighting>',
                  '<feComposite in2="fbSourceGraphic" in="r1" result="r22" operator="out"/>',
                  '<feComposite in="fbSourceGraphic" result="r4" operator="arithmetic" k2="2" k3="2" in2="r22"/>', // Frankly I should support both
                  // '<feComposite in="fbSourceGraphic" result="r4" operator="arithmetic" k2="2" k3="2"/>', // This is an alternative version of the thing above with a different in2 with a much shorter circuit
                '</filter>'
            );
    }

    function render(uint256 _tokenId) public view returns (string memory) {
        string memory backgroundColor = generateBackgroundColor(_tokenId);
        uint primaryColorInt = generatePrimaryColor(_tokenId);
        uint secondaryColorInt =  generateComplementaryColor(primaryColorInt);
        string memory primaryColor = toHexColor(primaryColorInt);
        string memory secondaryColor = toHexColor(secondaryColorInt);

        // string memory color = generateColor(_tokenId);
        // string memory lightingColor = generateLightingColor(_tokenId);

        string memory styles = generateStyles(_tokenId, backgroundColor, primaryColor);

        string memory height = '500';
        return
            // prettier-ignore
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="', height, '" height="', height,'">',
                    '<defs>',
                        generateFilters(_tokenId, secondaryColor),
                    '</defs>',
                    styles,
                    '<rect class="rect0" width="', height, '" height="', height, '"/>',
                    '<rect class="rect1" width="', height, '" height="', height, '"/>',
                    '<rect fill="', backgroundColor,'" width="50" height="50" x="0"/>',
                    '<rect fill="', primaryColor,'" width="50" height="50" x="50"/>',
                    '<rect fill="', secondaryColor,'" width="50" height="50" x="100"/>',
                '</svg>'
            );
    }

    function example(uint random) external view returns (string memory) {
        return render(random);
    }

    function constructImageURI(uint seed) public view returns (string memory) {
        console.log('start constructImageURI');
        string memory svg = render(seed);
        console.log(svg);
        string memory image = Base64.encode(bytes(svg));
        string memory output = string(
            abi.encodePacked("data:image/svg+xml;base64,", image)
        );

        console.log('end constructImageURI');
        return output;
    }
}
