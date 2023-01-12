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

    function generateBackgroundColor(uint tokenId) public view returns (string memory) {
        uint seed = uint(keccak256(abi.encodePacked(tokenId, uint(0))));
        return generateRandomColor(seed);
    }

    function generateLightingColor(uint tokenId) public view returns (string memory) {
        uint seed = uint(keccak256(abi.encodePacked(tokenId, uint(1))));
        return generateRandomColor(seed);
        // return 'black';
    }

    function generateColor(uint tokenId) internal view returns (string memory) {
        uint seed = uint(keccak256(abi.encodePacked(tokenId, uint(2))));
        return generateRandomColor(seed);

        // return 'darkblue';
    }

    function generateStyles(uint tokenId) public view returns (string memory) {
        return
            // prettier-ignore
            string.concat(
                '<style>',
                    '.rect0 { fill: ', generateBackgroundColor(tokenId),' }',
                    '.rect1 { fill: ', generateColor(tokenId), '; filter: url(#cracked-lava) }',
                '</style>'
            );
    }

    function generateFilters(uint tokenId) public view returns (string memory) {
        return // prettier-ignore
            string.concat(
                '<filter id="cracked-lava">',
                  '<feGaussianBlur result="result0" in="SourceGraphic" stdDeviation="0.5" id="feGaussianBlur2336"/>',
                  '<feTurbulence baseFrequency="0.', generateFrequency(tokenId), '" type=',generateTurbulenceType(tokenId), ' seed="488" numOctaves="', generateOctaves(tokenId),'" result="result1" id="feTurbulence2338"/>',
                  '<feDisplacementMap result="result5" xChannelSelector="R" scale="', generateScale(tokenId), '" in2="result1" in="result1" yChannelSelector="G" id="feDisplacementMap2340"/>',
                  '<feComposite result="result2" operator="in" in2="result5" in="result0" id="feComposite2342"/>',
                  '<feSpecularLighting lighting-color="white" surfaceScale="2" result="result4" specularConstant="2" specularExponent="65" in="result2" id="feSpecularLighting2346">',
                    '<feDistantLight elevation="62" azimuth="225" id="feDistantLight2344"/>',
                  '</feSpecularLighting>',
                  '<feComposite k1="2.5" k3="1" k2="-0.5" in2="result2" in="result4" operator="arithmetic" result="result91" id="feComposite2348"/>',
                  '<feBlend result="fbSourceGraphic" mode="multiply" in2="result91" id="feBlend2350"/>',
                  '<feColorMatrix values="1 0 0 -1 0 1 0 1 -1 0 1 0 0 -1 0 -2 -0.5 0 5 -2" in="fbSourceGraphic" result="fbSourceGraphicAlpha" id="feColorMatrix2352"/>',
                  '<feGaussianBlur stdDeviation="8" in="fbSourceGraphicAlpha" result="result0" id="feGaussianBlur2354"/>',
                  '<feOffset dx="2" dy="2" in="result0" result="result3" id="feOffset2356"/>',
                  '<feSpecularLighting in="result0" result="result1" lighting-color="', generateLightingColor(tokenId),'" surfaceScale="4" specularConstant="0.8" specularExponent="15" id="feSpecularLighting2360">',
                    '<fePointLight x="-5000" y="-10000" z="20000" id="fePointLight2358"/>',
                  '</feSpecularLighting>',
                  '<feComposite in2="fbSourceGraphicAlpha" in="result1" result="result2" operator="out" id="feComposite2362"/>',
                  '<feComposite in="fbSourceGraphic" result="result4" operator="arithmetic" k2="2" k3="2" in2="result2" id="feComposite2364"/>',
                  '<feBlend mode="darken" in2="result4" id="feBlend2366"/>',
                '</filter>'
            );
    }

    function render(uint256 _tokenId) public view returns (string memory) {
        return
            // prettier-ignore
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="500" height="500">',
                    '<defs>',
                        generateFilters(_tokenId),
                    '</defs>',
                    generateStyles(_tokenId),
                    '<rect class="rect0" width="500" height="500"/>',
                    '<rect class="rect1" width="500" height="500"/>',
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
