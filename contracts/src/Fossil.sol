// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Base64} from "openzeppelin-contracts/contracts/utils/Base64.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {Counters} from "openzeppelin-contracts/contracts/utils/Counters.sol";

contract Fossil is ERC721 {
    using Counters for Counters.Counter;

    Counters.Counter public _tokenIds;
    mapping(uint256 => uint256) private _seeds;

    constructor() ERC721("Fossil", "FOSSIL") {}

    function getSeed(uint tokenId) internal view returns (uint256) {
        return uint256(
            keccak256(abi.encodePacked(blockhash((block.number - 1) / 5), tokenId))
        );
    }

    function nextToken() external view returns (string memory) {
        return 'false';
        return constructTokenURI(getSeed(_tokenIds.current()));
    }

    function mint(address to) external {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _seeds[newTokenId] = getSeed(newTokenId);
        _mint(to, newTokenId); // _safeMint?
    }

    function constructTokenURI(uint256 seed) public view returns (string memory) {
        string memory svg = render(seed);
        string memory json = Base64.encode(
            bytes(
                string(
                    // prettier-ignore
                    string.concat(
                        '{"name": "Fossil #', '",',
                          '"description": "Generative art',
                          '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)),
                       '"}'
                    )
                )
            )
        );
        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
        return output;

    } 

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");
        return constructTokenURI(_seeds[tokenId]);
    }

    function generateRandom(uint min, uint max, uint seed) internal view returns (uint) {
      return min + uint(keccak256(abi.encodePacked(seed, min, max))) % (max - min + 1);
    }

    function generateFrequency(uint tokenId) public view returns (string memory) {
        uint random = generateRandom(1, 50, tokenId);
        string memory frequency;
        if (random < 100) {
            frequency = string.concat('0', Strings.toString(random));
        } else if (random < 10) {
            frequency = string.concat('00', Strings.toString(random));
        } else {
            frequency = Strings.toString(random);
        }

        return frequency;
    }

    function generateTurbulenceType(uint tokenId) public view returns (string memory) {
        // if (tokenId % 2 == 0) {
        //     return 'fractalNoise';
        // }
        return 'turbulence';
        // return 'fractalNoise';
    }

    function generateOctaves(uint tokenId) public view returns (string memory) {
        uint random = generateRandom(1, 5, tokenId);
        return Strings.toString(random);
    }

    function generateScale(uint tokenId) public view returns (string memory) {
        return Strings.toString(generateRandom(0, 80, tokenId));
    }

    function generateBackgroundColor(uint tokenId) public view returns (string memory) {
        return 'gray';
    }

    function generateLightingColor(uint tokenId) public view returns (string memory) {
        return 'black';
    }

    function generateColor(uint tokenId) internal view returns (string memory) {
        return 'gray';
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
                  '<feTurbulence baseFrequency="0.', generateFrequency(tokenId),
                  '" type="',generateTurbulenceType(tokenId),'"', '" seed="488" numOctaves="', generateOctaves(tokenId),'" result="result1" id="feTurbulence2338"/>',
                  '<feDisplacementMap result="result5" xChannelSelector="R" scale="', generateScale(tokenId), '" in2="result1" in="result1" yChannelSelector="G" id="feDisplacementMap2340"/>',
                  '<feComposite result="result2" operator="in" in2="result5" in="result0" id="feComposite2342"/>',
                  '<feSpecularLighting lighting-color="4d4d4dff" surfaceScale="2" result="result4" specularConstant="2" specularExponent="65" in="result2" id="feSpecularLighting2346">',
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
                  '<feComposite in2="fbSourceGraphicAlpha" in="result1" result="result2" operator="in" id="feComposite2362"/>',
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
}
