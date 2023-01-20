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
        string memory image = Base64.encode(bytes(svg));
        string memory output = string(
            abi.encodePacked("data:image/svg+xml;base64,", image)
        );

        console.log(svg);
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

    function generateRandomColor(uint seed) internal view returns (RGB memory) {
        // return string.concat('#', toHexStringNoPrefix(generateRandom(0, 16777215, seed), uint(3)));
        return RGB(generateRandom(85, 170, seed),
                generateRandom(85, 170, seed+1),
                generateRandom(85, 170, seed+2));
    }

    function generateRandomGrayColor(uint seed) internal view returns (string memory) {
        uint grayVal = generateRandom(0, 255, seed);
        return toString(RGB(grayVal, grayVal, grayVal));
    }

    function generateFrequency(uint tokenId, bool isFractalNoise) public view returns (uint, string memory) {
        // return  (53, "0.053");
        uint random;
        if (isFractalNoise) {
            // Fractal noise
            // random = generateRandom(20, 150, tokenId);
            random = generateRandom(30, 90, tokenId);
        } else {
            // Turbulent noise
            // random = generateRandom(1, 60, tokenId);
            random = generateRandom(15, 60, tokenId);
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
        return generateRandom(2, 4, tokenId).toString();
        // uint octaves;
        // if (isFractalNoise) {
        //     return generateRandom(1, 5, tokenId).toString();
        //     // if (frequency >= 100) {
        //     //     octaves = 1;
        //     // } else if (frequency >= 50) {
        //     //     octaves = generateRandom(2, 5, tokenId);
        //     // } else if (frequency > 20) {
        //     //     octaves = generateRandom(3, 5, tokenId);
        //     // } else {
        //     //     octaves = generateRandom(4, 8, tokenId);
        //     // }

        //     // Fractal noise
        //     // return octaves.toString();
        //     // return generateRandom(1, 3, tokenId).toString();
        // }
        // // Turbulence
        // // return generateRandom(2, 5, tokenId).toString();
        // return generateRandom(1, 5, tokenId).toString();
    }

    function generateScale(uint tokenId, bool isFractalNoise, uint frequency) public view returns (string memory) {
        return generateRandom(50, 100, tokenId).toString();
        // return "99";
        if (isFractalNoise) {
            return generateRandom(0, 100, tokenId).toString();
            // if (frequency > 150) {
            //     return generateRandom(0, 25, tokenId).toString();
            // } else if (frequency > 50) {
            //     return generateRandom(15, 50, tokenId).toString();
            // } else if (frequency > 0) {
            //     return generateRandom(0, 100, tokenId).toString();
            // }
        }
        // Turbulence noise
        return generateRandom(0, 80, tokenId).toString();
    }


    function generateSpecularLighting(uint tokenId, bool isFractalNoise) public view returns (string memory) {
        // string memory surfaceScale = string.concat('-', generateRandom(2, 4, tokenId).toString()); // Was -3.10131121
        string memory surfaceScale = '-5';

        // Perhaps we limit the specular lighting for HSL color generation techniques.
        // originall (probably should be 0, 99)
        // string memory specularConstant = string.concat('1.', generateRandom(25, 99, tokenId).toString()); // Was 2.13708425
        string memory specularConstant = '1';
        return
            // prettier-ignore
            string.concat(
              '<feSpecularLighting lighting-color="#ffffff" surfaceScale="', surfaceScale,'" result="r4" specularConstant="', specularConstant,'" specularExponent="1" in="r2">',
                '<feDistantLight elevation="0" azimuth="0">',
                    // '<animate attributeName="azimuth" values="0;360" dur="10s" repeatCount="indefinite"/>',
                '</feDistantLight>',
              '</feSpecularLighting>'
            );
    }

    struct RGB {
        uint r; // Value between 0 and 255
        uint g; // Value between 0 and 255
        uint b; // Value between 0 and 255
        // uint red; // Value between 0 and 255
        // uint green; // Value between 0 and 255
        // uint blue; // Value between 0 and 255
    }

    struct HSL {
        uint hue; // Value between 0 and 360
        uint saturation; // Value between 0 and 100
        uint lightness; // Value between 0 and 100
    }

    function hue2rgb(int256 p, int256 q, int256 t) internal pure returns (uint256 v) {
        if(t < 0) t = t + 10000;
        if(t > 10000) t = t - 10000;
        if(t < 1666) {
            return uint256(p + (q - p) * 6 * t / 10000);
        }
        if(t < 5000) return uint256(q);
        if(t < 6666) {
            return uint256(p + 6 * ((q - p) * (6666 - t) / 10000) );
        }
        return uint256(p);
    }

    function toColorRGB(HSL memory color) public pure returns (RGB memory) {
        uint256 r;
        uint256 g;
        uint256 b;
        int256 h = int256(color.hue * 10000 / 360);
        int256 s = int256(color.saturation * 100);
        int256 l = int256(color.lightness * 100);

        if(s == 0){
            r = g = b = uint256(l);
        } else {
            int256 q = l < 5000 ? l * (10000 + s) / 10000 : l + s - ((l*s)/10000);
            int256 p = 2 * l - q;
            r = hue2rgb(p, q, h + 3333);
            g = hue2rgb(p, q, h);
            b = hue2rgb(p, q, h - 3333);
            
        }
        return RGB(255 * r / 10000, 255 * g / 10000, 255 * b / 10000);
    }

    // function toColorHSL(RGB memory colorRGB) internal pure returns (HSL memory) {
    //     int256 r = int256(colorRGB.red  * 10000 / 255);
    //     int256 g = int256(colorRGB.green * 10000 /255);
    //     int256 b = int256(colorRGB.blue * 10000 /255);

    //     int256 max = int256(Math.max(uint256(r), Math.max(uint256(g), uint256(b))));
    //     int256 min = int256(Math.min(uint256(r), Math.min(uint256(g), uint256(b))));

    //     int256 h;
    //     int256 s;
    //     int256 l = (max + min) / 2;

    //     if (max == min){
    //         h = s = 0;
    //     } else {
    //         int256 d = max - min;
    //         s = l > 5000 ? 10000 * d / (20000 - max - min) : 10000 * d / (max + min);
    //         if (max == r) {
    //             h = int256(10000) * (g - b) / d + (g < b ? int256(60000) : int256(0));
    //         } else if (max == g) {
    //             h = int256(10000) *(b - r) / d + int256(20000);
    //         } else {
    //             h = int256(10000) * (r - g) / d + int256(40000);
    //         }
    //         h = h/ 6;
    //     }
    //     return HSL(uint256(36*h/1000), uint256(s/100), uint256(l/100));
    // }

    function toString(RGB memory rgb) internal pure returns (string memory) {
        return string.concat('rgb(', rgb.r.toString(), ', ', rgb.g.toString(), ', ', rgb.b.toString(), ')');
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

        // if the decimal is 10, we need to carry the 1
        if (decimal == 10) {
            decimal = 0;
            quotient = quotient + 1;
        }

        return string.concat(quotient.toString(), '.', decimal.toString());
    }

    function generateComponentTransfer(uint tokenId, RGB[] memory colors) public view returns (string memory) {
        string memory filter = '<feComponentTransfer id="palette" result="rct">';
        string memory funcR = '<feFuncR type="table" tableValues="';
        string memory funcG = '<feFuncG type="table" tableValues="';
        string memory funcB = '<feFuncB type="table" tableValues="';

        for (uint i=0; i < colors.length; i++) {
            // if (i == 0) {
            //     continue;
            // }
            RGB memory color = colors[i];
            funcR = string.concat(funcR, divideAndFormat(color.r, 256, 1), ' ');
            funcG = string.concat(funcG, divideAndFormat(color.g, 256, 1), ' ');
            funcB = string.concat(funcB, divideAndFormat(color.b, 256, 1), ' ');
        }

        funcR = string.concat(funcR, '" />');
        funcG = string.concat(funcG, '" />');
        funcB = string.concat(funcB, '" />');

        filter = string.concat(filter, funcR, funcG, funcB, '</feComponentTransfer>');
        return filter;
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
                '<feFuncR type="discrete" tableValues="', tableValues[0], '" />',
                '<feFuncG type="discrete" tableValues="', tableValues[1], '" />',
                '<feFuncB type="discrete" tableValues="', tableValues[2], '" />',
              '</feComponentTransfer>'
            );
    }

    // Color pallete of all random colors
    function generateRandomColorPalette(uint seed) public view returns (RGB[] memory) {
        uint j = 0;
        RGB[] memory colors;
        for (uint i=0; i < colors.length; i++) {
            // console.log(seed + i + j, 'seed + i + j');
            colors[i] = RGB(
                generateRandom(0, 255, seed + i + j),
                generateRandom(0, 255, seed + i + 1 + j),
                generateRandom(0, 255, seed + i + 2 + j)
            );
            j += 3;
        }

        return colors;
    }

    function averageWithWhite(RGB memory color) public pure returns (RGB memory) {
        RGB memory white = RGB(255, 255, 255);
        // return a new color that is the average of the two colors
        return RGB(
            (color.r + white.r) / 2,
            (color.g + white.g) / 2,
            (color.b + white.b) / 2
        );
    }

    function generateMonochromaticColorPalette(uint seed) public view returns (RGB[] memory) {
        RGB[] memory colors = new RGB[](7);
        HSL memory hsl = HSL(
            generateRandom(0, 360, seed),
            100,
            generateRandom(0, 20, seed + 1)
        );
        RGB memory color = toColorRGB(hsl);
        // calculate the lightness delta each step based on size of colors
        uint delta = 100 / colors.length;
        for (uint i=0; i < colors.length; i++) {
            colors[i] = color;
            hsl.lightness = hsl.lightness + delta;
            color = toColorRGB(hsl);
        }

        // for (uint i=0; i < colors.length; i++) {
        //     colors[i] = color;
        //     hsl.lightness = hsl.lightness + 20;
        //     color = toColorRGB(hsl);
        // }
        return colors;
    }

    function generateAnalogousColorPalette(uint seed) public view returns(RGB[] memory) {
        RGB[] memory colors;
        HSL memory hsl = HSL(
            generateRandom(0, 360, seed),
            100,
            50
        );
        uint degrees = 30;
        for (uint i=0; i < colors.length; i++) {
            colors[i] = toColorRGB(hsl);
            hsl.hue = (hsl.hue + degrees) % 360;
        }
        // colors[0] = toColorRGB(hsl);
        // colors[1] = toColorRGB(HSL(hsl.hue + 30, hsl.saturation, hsl.lightness));
        // colors[2] = toColorRGB(HSL(hsl.hue + 60, hsl.saturation, hsl.lightness));
        // colors[3] = toColorRGB(HSL(hsl.hue + 90, hsl.saturation, hsl.lightness));
        return colors;
    }

    // function generateAnalogousColors(HSL memory hsl) public view returns (HSL[2] memory) {
    //     uint degrees = 15;
    //     HSL[2] memory colors;
    //     colors[0] = HSL(hsl.hue - degrees, hsl.saturation, hsl.lightness);
    //     colors[1] = HSL(hsl.hue + degrees, hsl.saturation, hsl.lightness);
    //     return colors;
    // }

    function generateTetradicColorPalette(uint seed) public view returns (RGB[] memory) {
        seed = seed + 1;
        // generate a random color
        // uint lightnessDelta = 20; // The average delta between the lightness of each color
        HSL memory hsl = HSL(
            generateRandom(0, 360, seed),
            generateRandom(50, 100, seed+1),
            generateRandom(25, 75, seed+2)
            // generateRandom(0, lightnessDelta-5, seed+2)
        );
        console.log('hsl', hsl.hue, hsl.saturation, hsl.lightness);

        // add it to the final output
        RGB[] memory colors = new RGB[](4);
        colors[0] = toColorRGB(hsl);

        // Generate the remaining three tetradic colors by rotating the hue,
        // increasing the lightness
        uint degrees = 360 / 4; // 90 degrees
        for (uint i=1; i < colors.length; i++) {
            hsl.hue = (hsl.hue + degrees) % 360;
            hsl.saturation = generateRandom(50, 100, seed + i);
            hsl.lightness = generateRandom(25, 100, seed + i + 1);
            // hsl.lightness = i * 20 + generateRandom(0, lightnessDelta, seed + i + 2);
            console.log('hsl', hsl.hue, hsl.saturation, hsl.lightness);
            colors[i] = toColorRGB(hsl);
        }

        return colors;
    }

    function generateTetradicAnalogousColorPalette(uint seed) public view returns (RGB[] memory) {
        // generate a random base color
        HSL memory hsl = HSL(
            generateRandom(0, 360, seed),
            generateRandom(100, 101, seed+1),
            generateRandom(50, 51, seed+2)
        );

        // initialize the output
        RGB[] memory colors = new RGB[](12); // 12 = 4 tetradic colors + 8 analogous colors (2 for each tetradic color)

        // Generate the remaining three tetradic colors by rotating the hue,
        // and for each tetradic color, generate two analogous colors
        uint degrees = 360 / 4; // 90 degrees
        uint analogousDegrees = 30;
        for (uint i=0; i < colors.length; i++) {
            // add the tetradic color
            colors[i] = toColorRGB(hsl);

            // add the analogous colors
            colors[i+1] = toColorRGB(HSL(hsl.hue - analogousDegrees, hsl.saturation, hsl.lightness));
            colors[i+2] = toColorRGB(HSL(hsl.hue + analogousDegrees, hsl.saturation, hsl.lightness));

            // increment the hue
            hsl.hue = (hsl.hue + degrees) % 360;
            i += 2;
        }

        // Randomly select colors from the old array and add them to the new array
        // create a new array half the size with half the colors randomly selected
        return colors;
    }

    // function generateColorsNovelApproach(uint seed) public view returns (RGB[] memory) {
    //     // It is generating a base color, its complement, and two split-complementary colors.
    //     RGB memory color = RGB(
    //         generateRandom(0, 255, seed),
    //         generateRandom(0, 255, seed + 1),
    //         generateRandom(0, 255, seed + 2)
    //     );
    //     RGB memory complement = RGB(255 - color.r, 255 - color.g, 255 - color.b);
    //     RGB memory splitComplementary1 = RGB((color.r + 85) % 256, (color.g + 85) % 256, (color.b + 85) % 256);
    //     RGB memory splitComplementary2 = RGB((color.r + 170) % 256, (color.g + 170) % 256, (color.b + 170) % 256);
    //     RGB[] memory colors = [
    //         color,
    //         complement,
    //         splitComplementary1,
    //         splitComplementary2
    //         // RGB(color.r, complement.g, complement.b)
    //     ];

    //     return colors;
    // }

    function averageColors(RGB[] memory colors) public pure returns (RGB memory) {
        uint r = 0;
        uint g = 0;
        uint b = 0;
        for (uint i=0; i < colors.length; i++) {
            r += colors[i].r;
            g += colors[i].g;
            b += colors[i].b;
        }

        return RGB(r / colors.length, g / colors.length, b / colors.length);
    }

    function complementaryColor(RGB memory color) public pure returns (RGB memory) {
        return RGB(255 - color.r, 255 - color.g, 255 - color.b);
    }

    function generateGradient(uint seed) public view returns (string memory) {
        // generate a random number between 0 and 90 for the rotation
        uint rotation = generateRandom(0, 90, seed);

        // generate the stop elements. there should be 2 or 3 stops, with offsets
        // starting at 0, and ending at 100 they should alternate between white and black
        string memory stops;
        uint numStops = generateRandom(2, 4, seed + 1);
        for (uint i=0; i < numStops; i++) {
            uint offset = i * 100 / (numStops - 1);
            string memory color = i % 2 == 0 ? 'white' : 'black';
            stops = string.concat(stops, '<stop offset="', offset.toString(), '%" stop-color="', color, '"/>');
        }

        return string.concat(
            // prettier-ignore
            '<linearGradient id="linearGradient14277" gradientTransform="rotate(',rotation.toString(),')" >',
                stops,
              // '<stop stop-color="black" offset="0" id="stop14273"/>',
              // '<stop stop-color="white" offset="1" id="stop14275"/>',
            '</linearGradient>'
        );
    }

    /* new */
    function generateSVG(uint seed) public view returns (string memory) {
        /* Filter parameters */
        bool isFractalNoise = true;
        string memory turbulenceType = isFractalNoise ? "fractalNoise" : "turbulence";
        // string memory turbulenceType = "turbulence";
        (uint frequencyInt, string memory frequency) = generateFrequency(seed, isFractalNoise);
        string memory octaves = generateOctaves(seed, isFractalNoise, frequencyInt);
        string memory scale = generateScale(seed, isFractalNoise, frequencyInt);

        // RG4[4] memory colors = generateRandomColorPalette(seed);
        // RGB[] memory colors = generateColorsNovelApproach(seed);

        RGB[] memory colors = generateTetradicColorPalette(seed);

        // RGB[] memory colors = generateAnalogousColorPalette(seed);
        // RGB[] memory colors = generateMonochromaticColorPalette(seed);
        // RGB[] memory colors = generateTetradicAnalogousColorPalette(seed);

        RGB memory averageColor = averageColors(colors);
        string memory feComponentTransfer = generateComponentTransfer(
            seed,
            colors
        );
        // string memory feComponentTransfer = generateComponentTransfer(seed);

        string memory rects = createRectsForColors(colors);
        return
            // prettier-ignore
            string.concat(
                '<svg width="500" height="500" viewBox="0 0 500 500" version="1.1" xmlns="http://www.w3.org/2000/svg">',
                  '<defs>',
                    // '<linearGradient id="linearGradient14277">',
                    //   '<stop stop-color="black" offset="0" id="stop14273"/>',
                    //   '<stop stop-color="white" offset="1" id="stop14275"/>',
                    // '</linearGradient>',
                    generateGradient(seed),

                    '<filter id="cracked-lava" color-interpolation-filters="sRGB">',
                      '<feTurbulence baseFrequency="', frequency, '" type="', turbulenceType, '" numOctaves="', octaves,'" result="r1" in="SourceGraphic" />',
                      '<feDisplacementMap result="r5" xChannelSelector="R" in2="r1" in="r1" yChannelSelector="G" scale="', scale, '" />',
                      '<feComposite result="r2" operator="in" in="SourceGraphic" in2="r5" />',
                      generateSpecularLighting(seed, isFractalNoise),
                      '<feComposite k1="0.5" k3="1" k2="-0.5" in2="r2" in="r4" operator="arithmetic" result="r91" k4="0" />',
                      '<feComposite in="r91" result="r4" operator="arithmetic" k2="0" k3="4" in2="r91" k1="0" k4="-0" />',
                      feComponentTransfer,
                      // '<feFlood result="result1" flood-color="', generateRandomColor(seed),'" />',

                      '<feFlood result="result1" flood-color="', toString(complementaryColor(averageColor)),'" />',
                      // '<feFlood result="result1" flood-color="', ," />',
                      // '<feFlood result="result1" flood-color="white" />',
                      '<feBlend mode="normal" in="rct" in2="result1" />',
                    '</filter>',
                  '</defs>',
                  '<rect width="500" height="500" fill="url(#linearGradient14277)" filter="url(#cracked-lava)" style="filter:url(#cracked-lava)" />',
                  '<rect width="50" height="50" x="0" y="0" fill="', toString(colors[0]),'" />',
                  rects,
                '</svg>'
            );
    }

    function createRectsForColors(RGB[] memory colors) public pure returns (string memory) {
        string memory rects = "";
        for (uint i=0; i < colors.length; i++) {
            rects = string.concat(rects, '<rect width="50" height="50" x="', (i * 50).toString(), '" y="0" fill="', toString(colors[i]),'" />');
        }

        return rects;
    }
}
