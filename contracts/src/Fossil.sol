// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Base64} from "openzeppelin-contracts/contracts/utils/Base64.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {Counters} from "openzeppelin-contracts/contracts/utils/Counters.sol";
import {console} from "forge-std/console.sol";

contract Fossil {
    using Strings for uint256;

    function constructImageURI(uint seed) public view returns (string memory) {
        string memory svg = generateSVG(seed);
        console.log(svg);
        string memory image = Base64.encode(bytes(svg));
        string memory output = string(
            abi.encodePacked("data:image/svg+xml;base64,", image)
        );

        console.log('end constructImageURI');
        return output;
    }

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
        // safely generates a random uint between min and max using the seed
        require(max > min, "max must be greater than min");
        require(max != 0, "max must be greater than 0");
        uint rand = uint(keccak256(abi.encodePacked(seed)));
        return rand % (max - min) + min;
    }

    function generateRandomColor(uint seed) internal view returns (string memory) {
        return string.concat('#', toHexStringNoPrefix(generateRandom(0, 16777215, seed), uint(3)));
    }

    function generateFrequency(uint tokenId, bool turbulenceType) public view returns (uint, string memory) {
        uint random;
        if (turbulenceType) {
            // Fractal noise
            random = generateRandom(20, 150, tokenId);
        } else {
            // Turbulent noise
            random = generateRandom(1, 60, tokenId);
        }

        string memory frequency; 
        if (random >= 100) {
             frequency = string.concat('0.', random.toString()); // E.g. 0.200
        } else if (random >= 10) {
            frequency = string.concat('0.0', random.toString()); // E.g. 0.020
        } else {
            frequency = string.concat('0.00', random.toString()); // E.g. 0.002
        }

        return (random, frequency);
    }

    function generateOctaves(uint tokenId, bool isFractalNoise, uint frequency) public view returns (string memory) {
        uint random;
        if (isFractalNoise) {
            if (frequency >= 100) {
                random = 1;
            } else if (frequency >= 50) {
                random = generateRandom(2, 5, tokenId);
            } else if (frequency > 20) {
                random = generateRandom(3, 5, tokenId);
            } else {
                random = generateRandom(4, 8, tokenId);
            }

            // Fractal noise
            return random.toString();
            // return generateRandom(1, 3, tokenId).toString();
        }

        // Turbulence
        return generateRandom(2, 5, tokenId).toString();
    }

    function generateScale(uint tokenId, bool isFractalNoise, uint frequency) public view returns (string memory) {
        if (isFractalNoise) {
            if (frequency > 150) {
                return generateRandom(0, 25, tokenId).toString();
            } else if (frequency > 50) {
                return generateRandom(25, 75, tokenId).toString();
            } else if (frequency > 0) {
                return generateRandom(50, 100, tokenId).toString();
            }
        }
        // Turbulence noise
        return generateRandom(0, 80, tokenId).toString();
    }


    function generateSpecularLighting(uint tokenId, bool isFractalNoise) public view returns (string memory) {
        string memory surfaceScale = string.concat('-', generateRandom(2, 4, tokenId).toString()); // Was -3.10131121
        string memory specularConstant = string.concat('1.', generateRandom(0, 99, tokenId).toString()); // Was 2.13708425
        console.log('surfaceScale', surfaceScale);
        console.log('specularConstant', specularConstant);
        return
            // prettier-ignore
            string.concat(
              '<feSpecularLighting lighting-color="#ffffff" surfaceScale="', surfaceScale,'" result="r4" specularConstant="', specularConstant,'" specularExponent="15.19753456" in="r2">',
                '<feDistantLight elevation="60" azimuth="60">',
                    // '<animate attributeName="azimuth" values="0;360" dur="10s" repeatCount="indefinite"/>',
                '</feDistantLight>',
              '</feSpecularLighting>'
            );
    }

    function generateComponentTransfer(uint tokenId) public view returns (string memory) {
        uint p = 1;
        string[3] memory tableValues;
        for (uint i=0; i < 3; i++) {
            string memory tableValue = '0';
            for (uint j=0; j<2; j++) {
                uint random = generateRandom(0, 10, tokenId + p);
                string memory v = random == 10 ? '1' : string.concat('0.', random.toString());
                tableValue = string.concat(tableValue, ' ', v);
                p++;
            }
            tableValues[i] = string.concat(tableValue, ' 1');
        }

        return
            // prettier-ignore
            string.concat(
              '<feComponentTransfer result="result2">',
                '<feFuncR type="table" tableValues="', tableValues[0], '" />',
                '<feFuncG type="table" tableValues="', tableValues[1], '" />',
                '<feFuncB type="table" tableValues="', tableValues[2], '" />',
              '</feComponentTransfer>'
            );
    }

    // createFilter is a JavaScript function that returns a string of SVG code
    // It takes a list of RGB colors, and outputs an feComponentTransfer filter,
    // that when applied to my black and white SVG image gives it the colors from my color palette.
    // Please convert this function from JavaScript to  Solidity.
    // function createFilter(colors) {
    //   const filter = document.createElementNS("http://www.w3.org/2000/svg", "filter");
    //   filter.setAttribute("id", "palette");
    //   const funcR = document.createElementNS("http://www.w3.org/2000/svg", "feFuncR");
    //   funcR.setAttribute("type", "table");
    //   funcR.setAttribute("tableValues", colors.map(c => c[0]).join(" "));
    //   filter.appendChild(funcR);
    //   const funcG = document.createElementNS("http://www.w3.org/2000/svg", "feFuncG");
    //   funcG.setAttribute("type", "table");
    //   funcG.setAttribute("tableValues", colors.map(c => c[1]).join(" "));
    //   filter.appendChild(funcG);
    //   const funcB = document.createElementNS("http://www.w3.org/2000/svg", "feFuncB");
    //   funcB.setAttribute("type", "table");
    //   funcB.setAttribute("tableValues", colors.map(c => c[2]).join(" "));
    //   filter.appendChild(funcB);
    //   return filter;
    // }
    // 
    // Converted function:

    struct RGB {
        uint r;
        uint g;
        uint b;
    }

    function divideAndFormat(uint input, uint divisor, uint decimalPlaces) public view returns (string memory) {
        // divide input by divisor and format as a string to decimalPlaces decimal places
        // rounding to the nearest decimal place
        uint quotient = input / divisor;
        uint remainder = input % divisor;
        uint decimal = remainder * (10 ** decimalPlaces) / divisor;

        // round up if the decimal is >= 5
        if (decimal >= 5) {
            decimal = decimal + 1;
        }

        return string.concat(quotient.toString(), '.', decimal.toString());
    }


    function generateComponentTransfer(uint tokenId, RGB[5] memory colors) public view returns (string memory) {
        string memory filter = '<feComponentTransfer id="palette">';
        string memory funcR = '<feFuncR type="table" tableValues="';
        string memory funcG = '<feFuncG type="table" tableValues="';
        string memory funcB = '<feFuncB type="table" tableValues="';

        for (uint i=0; i < colors.length; i++) {
            RGB memory color = colors[i];
            funcR = string.concat(funcR, divideAndFormat(color.r, 256, 2), ' ');
            funcG = string.concat(funcG, divideAndFormat(color.g, 256, 2), ' ');
            funcB = string.concat(funcB, divideAndFormat(color.b, 256, 2), ' ');
        }

        funcR = string.concat(funcR, '" />');
        funcG = string.concat(funcG, '" />');
        funcB = string.concat(funcB, '" />');

        filter = string.concat(filter, funcR, funcG, funcB, '</feComponentTransfer>');
        return filter;
    }

    function generateColorPalette(uint seed) public view returns (RGB[5] memory) {
        RGB[5] memory colors;
        for (uint i=0; i < colors.length; i++) {
            colors[i] = RGB(
                generateRandom(0, 255, seed + i),
                generateRandom(0, 255, seed + i + 1),
                generateRandom(0, 255, seed + i + 2)
            );
        }
        return colors;
    }

    /* new */
    function generateSVG(uint seed) public view returns (string memory) {
        /* Color parameters*/
        string memory backgroundColor = generateRandomColor(seed); // TODO maybe a gradient
        console.log('backgroundColor', backgroundColor);

        /* Filter parameters */
        bool isFractalNoise = true;
        string memory turbulenceType = isFractalNoise ? "fractalNoise" : "turbulence";
        (uint frequencyInt, string memory frequency) = generateFrequency(seed, isFractalNoise);
        string memory octaves = generateOctaves(seed, isFractalNoise, frequencyInt);
        string memory scale = generateScale(seed, isFractalNoise, frequencyInt);

        string memory feComponentTransfer = generateComponentTransfer(
            seed,
            generateColorPalette(seed)
        );
        console.log('feComponentTransfer', feComponentTransfer);

        // console.log('turblenceType:', turbulenceType);
        // console.log('frequency:', frequency);
        // console.log('scale:', scale);
        // console.log('octaves:', octaves);

        return
            // prettier-ignore
            string.concat(
                '<svg width="500" height="500" viewBox="0 0 500 500" version="1.1" xmlns="http://www.w3.org/2000/svg">',
                  '<defs>',
                    '<filter id="cracked-lava">',
                      '<feFlood flood-color="rgb(152,152,152)" result="r15" />',
                      '<feTurbulence baseFrequency="', frequency, '" type="', turbulenceType, '" numOctaves="', octaves,'" result="r1" />',
                      '<feDisplacementMap result="r5" xChannelSelector="R" in2="r1" in="r1" yChannelSelector="G" scale="', scale, '" />',
                      '<feComposite result="r2" operator="in" in="r15" in2="r5" />',
                      generateSpecularLighting(seed, isFractalNoise),
                      '<feComposite k1="0.3874092" k3="1" k2="-0.5" in2="r2" in="r4" operator="arithmetic" result="r91" k4="0" />',
                      '<feComposite in="r91" result="r4" operator="arithmetic" k2="2" k3="3.9779434" in2="r91" k1="0" k4="-0.57127724" />',
                      // generateComponentTransfer(seed),

                      feComponentTransfer,

                      // '<feFlood result="result1" flood-color="', generateRandomColor(seed),'" />',
                      // '<feFlood result="result1" flood-color="', 'white','" />',
                      // '<feBlend mode="normal" in2="result1" in="result2" />',
                    '</filter>',
                  '</defs>',
                  '<rect width="500" height="500" filter="url(#cracked-lava)" style="fill:#c4c4bc;fill-opacity:1;filter:url(#cracked-lava)" />',
                '</svg>'
            );
            // string.concat(
            //     '<svg width="500" height="500" viewBox="0 0 500 500" version="1.1" xmlns="http://www.w3.org/2000/svg">',
            //       '<defs>',
            //         '<filter id="cracked-lava">',
            //           '<feFlood flood-color="rgb(152,152,152)" result="r15" />',
            //           '<feTurbulence baseFrequency="', frequency, '" type="', turbulenceType, '" numOctaves="', octaves,'" result="r1" />',
            //           '<feDisplacementMap result="r5" xChannelSelector="R" in2="r1" in="r1" yChannelSelector="G" scale="', scale, '" />',
            //           '<feComposite result="r2" operator="in" in="r15" in2="r5" />',
            //           generateSpecularLighting(seed, isFractalNoise),
            //           '<feComposite k1="0.3874092" k3="1" k2="-0.5" in2="r2" in="r4" operator="arithmetic" result="r91" k4="0" />',
            //           '<feComposite in="r91" result="r4" operator="arithmetic" k2="2" k3="3.9779434" in2="r91" k1="0" k4="-0.57127724" />',
            //           generateComponentTransfer(seed),
            //           '<feFlood result="result1" flood-color="', generateRandomColor(seed),'" />',
            //           '<feBlend mode="normal" in2="result1" in="result2" />',
            //         '</filter>',
            //       '</defs>',
            //       '<rect width="500" height="500" filter="url(#cracked-lava)" style="fill:#c4c4bc;fill-opacity:1;filter:url(#cracked-lava)" />',
            //     '</svg>'
            // );
    }
}
