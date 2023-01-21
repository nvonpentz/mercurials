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

    function generateRandom(uint min, uint max, uint seed) public view returns (uint) {
        // safely generates a random uint between min and max using the seed
        require(max > min, "max must be greater than min");
        require(max != 0, "max must be greater than 0");
        uint rand = uint(keccak256(abi.encodePacked(seed)));
        return rand % (max - min) + min;
    }

    function generateBaseColor(uint seed) internal view returns (HSL memory) {
        // generates a random primary, secondary, or tertiary color
        console.log("generating base color -->");
        uint rand = generateRandom(0, 3 + 3 + 6, seed);
        if (rand < 3) {
            console.log("  primary");
            return generatePrimaryColor(seed);
        } else if (rand < 6) {
            console.log("  secondary");
            return generateSecondaryColor(seed);
        } else {
            console.log("  tertiary");
            return generateTertiaryColor(seed);
        }
    }

    function generateRandomGrayColor(uint seed) internal view returns (string memory) {
        uint grayVal = generateRandom(0, 255, seed);
        return toString(RGB(grayVal, grayVal, grayVal));
    }

    function generateFrequency(uint tokenId, bool isFractalNoise) public view returns (string memory) {
        // return  (53, "0.053");
        uint xVal;
        if (isFractalNoise) {
            // Fractal noise
            // xVal = generateRandom(20, 150, tokenId);
            xVal = generateRandom(40, 85, tokenId);
        } else {
            // Turbulent noise
            // xVal = generateRandom(1, 60, tokenId);
            xVal = generateRandom(15, 40, tokenId);
        }

        string memory frequency; 
        if (xVal >= 100) {
             frequency = string.concat('0.', xVal.toString()); // E.g. 0.200
        } else if (xVal >= 10) {
            frequency = string.concat('0.0', xVal.toString()); // E.g. 0.020
        } else {
            frequency = string.concat('0.00', xVal.toString()); // E.g. 0.002
        }

        return frequency;
    }

    function generateOctaves(uint tokenId) public view returns (string memory) {
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

    function generateScale(uint tokenId, bool isFractalNoise) public view returns (string memory) {
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
    function generateBaseColorPalette(uint seed) public view returns (RGB[] memory) {
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

        // randomize the array manually
        // for (uint i=0; i < colors.length; i++) {
        //     uint random = generateRandom(0, colors.length - 1, seed + i);
        //     RGB memory temp = colors[i];
        //     colors[i] = colors[random];
        //     colors[random] = temp;
        // }

        return colors;
    }

    function generateAnalogousColorPalette(uint seed) public view returns(RGB[] memory) {
        RGB[] memory colors = new RGB[](5);
        HSL memory hsl = HSL(
            generateRandom(0, 360, seed),
            generateRandom(50, 100, seed + 1), // saturation
            generateRandom(50, 100, seed + 2) // lightness
            // 100, // saturation
            // 50 // lightness
        );
        HSL memory initialColor = HSL({
            hue: hsl.hue,
            saturation: hsl.saturation,
            lightness: hsl.lightness
        });
        uint degrees = 360 / colors.length;
        for (uint i=0; i < colors.length; i++) {
            colors[i] = toColorRGB(hsl);
            hsl.hue = (hsl.hue + degrees) % 360;
            if (i == colors.length - 1) {

                // console.log('initialHue', initialHue);
                hsl.hue = (initialColor.hue + 180) % 360;
                hsl.saturation = initialColor.saturation;
                hsl.lightness = initialColor.lightness;


                // console.log('hsl.hue', hsl.hue);
                continue;
            }
            hsl.saturation = generateRandom(0, 100, seed + i + 3);
            hsl.lightness = generateRandom(0, 100, seed + i + 4);
        }
        return colors;
    }

    function generatePrimaryColor(uint seed) public view returns (HSL memory) {
        uint random = generateRandom(0, 3, seed);
        if (random == 0) {
            return HSL(0, 100, 50); // red
        } else if (random == 1) {
            return HSL(60, 100, 50); // yellow
        } else {
            return HSL(240, 100, 50); // blue
        }
    }

    // purple green orange
    function generateSecondaryColor(uint seed) public view returns (HSL memory) {
        uint random = generateRandom(0, 3, seed);
        require(random != 3, 'random cannot be 0');
        if (random == 0) {
            return HSL(300, 100, 50); // purple
        } else if (random == 1) {
            return HSL(120, 100, 50); // green
        } else {
            return HSL(30, 100, 50); // orange
        }
    }

    // Tertiary colors come from mixing one of the primary colors with one of the nearest secondary colors. Tertiary colors are found in between all of the primary colors and secondary colors.
    // Red + Orange = Red-orange
    // Yellow + Orange = Yellow-orange
    // Yellow + Green = Yellow-green
    // Blue + Green = Blue-green
    // Blue + Purple = Blue-purple
    // Red + Purple = Red-purple
    function generateTertiaryColor(uint seed) public view returns (HSL memory) {
        uint random = generateRandom(0, 6, seed);
        if (random == 0) {
            return HSL(15, 100, 50); // red-orange
        } else if (random == 1) {
            return HSL(45, 100, 50); // yellow-orange
        } else if (random == 2) {
            return HSL(75, 100, 50); // yellow-green
        } else if (random == 3) {
            return HSL(165, 100, 50); // blue-green
        } else if (random == 4) {
            return HSL(255, 100, 50); // blue-purple
        } else {
            return HSL(345, 100, 50); // red-purple
        }
    }

    function generateTetradicColorPalette(uint seed) public view returns (RGB[] memory) {
        seed = seed + 1;

        uint satStart = generateRandom(20, 80, seed);
        uint satEnd = generateRandom(satStart+1, 100, seed + 1);
        uint lightStart = generateRandom(50, 80, seed + 2);
        uint lightEnd = generateRandom(lightStart+1, 100, seed + 3);

        // generate a random color
        HSL memory hsl = HSL(
            generateRandom(0, 360, seed),
            generateRandom(satStart, satEnd, seed+1), // 25 75
            generateRandom(lightStart, lightEnd, seed+2)  // 40 75
            // generateRandom(0, lightnessDelta-5, seed+2)
        );

        HSL memory darkHsl = HSL({
            hue: hsl.hue,
            saturation: hsl.saturation,
            // lightness: generateRandom(0, 15, seed+3)
            lightness: generateRandom(0, 15, seed+3)
        });

        // add it to the final output
        RGB[] memory colors = new RGB[](6);
        colors[0] = toColorRGB(darkHsl);
        colors[1] = toColorRGB(hsl);

        // Generate the remaining three tetradic colors by rotating the hue,
        // increasing the lightness
        uint degrees = 360 / 4; // 90 degrees
        for (uint i=2; i < colors.length; i++) {
            hsl.hue = (hsl.hue + degrees) % 360;
            hsl.saturation = generateRandom(satStart, satEnd, seed + i);
            hsl.lightness = generateRandom(lightStart, lightEnd, seed + i + 1);
            // hsl.lightness = i * 20 + generateRandom(0, lightnessDelta, seed + i + 2);
            console.log('hsl', hsl.hue, hsl.saturation, hsl.lightness);
            colors[i] = toColorRGB(hsl);
        }

        colors[5] = toColorRGB(HSL({
            hue: hsl.hue,
            saturation: hsl.saturation,
            lightness: generateRandom(85, 100, seed+4)
        }));

        return colors;
    }

    function generateAnalogousColors(HSL memory color) public view returns (HSL memory, HSL memory) {
        uint degrees = 30;
        // generate left and right safely such that we don't risk integer underflow
        HSL memory left = HSL({
            hue: color.hue >= degrees ? color.hue - degrees : 360 - (degrees - color.hue),
            // hue: color.hue - degrees,
            saturation: color.saturation,
            lightness: color.lightness
        });
        HSL memory right = HSL({
            hue: (color.hue + degrees) % 360,
            // hue: color.hue + degrees,
            saturation: color.saturation,
            lightness: color.lightness
        });
        return (left, right);
    }

    function generateTriadicColors(HSL memory color) public view returns (HSL memory, HSL memory) {
        uint degrees = 120;
        // generate left and right safely such that we don't risk integer underflow
        HSL memory left = HSL({
            // hue: color.hue - degrees, // <-- risks integer underflow
            hue: (color.hue + 360 - degrees) % 360,
            saturation: color.saturation,
            lightness: color.lightness
        });
        HSL memory right = HSL({
            hue: (color.hue + degrees) % 360,
            saturation: color.saturation,
            lightness: color.lightness
        });
        return (left, right);
    }

    function generateComplementaryColor(HSL memory color) public view returns (HSL memory) {
        uint degrees = 180;
        HSL memory color = HSL({
            hue: (color.hue + degrees) % 360,
            saturation: color.saturation,
            lightness: color.lightness
        });

        return color;
    }

    function mixColors(HSL memory color1, HSL memory color2) public view returns (HSL memory) {
        HSL memory color = HSL({
            hue: (color1.hue + color2.hue) / 2,
            saturation: (color1.saturation + color2.saturation) / 2,
            lightness: (color1.lightness + color2.lightness) / 2
        });

        return color;
    }

    function generatePalette(uint seed) public view returns (RGB[] memory) {
        HSL[] memory hslColors = new HSL[](9);

        // Gray (utility color)
        HSL memory gray = HSL(0, 0, 50);

        // Black (edge color)
        HSL memory black = HSL(0, 0, 0);

        // Base color
        HSL memory base = generateBaseColor(seed);

        // Secondary colors (2) 
        HSL memory second1;
        HSL memory second2;
        console.log("generating second two colors -->");
        if (seed % 2 == 0) {
            console.log("  splitcomplementary");
            HSL memory complementary = generateComplementaryColor(base);
            (second1, second2) = generateAnalogousColors(complementary);
        } else {
            console.log("  triadic");
            (second1, second2) = generateTriadicColors(base);
        }

        // White (edge color)
        HSL memory white = HSL(0, 0, 100);

        // Create intermediate colors by mixing 
        HSL memory mix1 = mixColors(black, base);
        HSL memory mix2 = mixColors(base, second1);
        HSL memory mix3 = mixColors(second1, second2);
        HSL memory mix4 = mixColors(second2, white);

        // Add the colors to the array
        hslColors[0] = black;
        hslColors[1] = mix1;
        hslColors[2] = base;
        hslColors[3] = mix2;
        hslColors[4] = second1;
        hslColors[5] = mix3;
        hslColors[6] = second2;
        hslColors[7] = mix4;
        hslColors[8] = white;

        // mix every color with gray
        // for (uint i=0; i < hslColors.length; i++) {
        //     hslColors[i] = mixColors(hslColors[i], gray);
        //     console.log(i, 'hsl:');
        //     console.log(hslColors[i].hue, hslColors[i].saturation, hslColors[i].lightness);
        //     // hslColors[i] = mixColors(hslColors[i], white);
        //     // hslColors[i] = mixColors(hslColors[i], black);
        // }

        // Convert to RGB
        RGB[] memory colors = new RGB[](hslColors.length);
        for (uint i=0; i < hslColors.length; i++) {
            colors[i] = toColorRGB(hslColors[i]);
        }

        return colors;
    }

    // function generateRandomMonotonicSubset(uint size, uint max, uint seed) public view returns (uint[] memory) {
    //     // generate a random subset of size `size` from the set {0, 1, ..., max-1}
    //     // the subset is guaranteed to be monotonic (i.e. increasing)
    //     uint[] memory subset = new uint[](size);
    //     uint[] memory indices = new uint[](max);
    //     for (uint i=0; i < max; i++) {
    //         indices[i] = i;
    //     }
    //     for (uint i=0; i < size; i++) {
    //         uint index = generateRandom(i, max, seed+i);
    //         subset[i] = indices[index];
    //         indices[index] = indices[i];
    //     }
    //     return subset;
    // }

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

        // uint numStops = generateRandom(2, 4, seed + 1);
        // uint numStops = (seed % 2 == 0) || (seed % 3 == 0) ? 2 : 3;

        // uint numStops = (seed % 2 == 0) || (seed % 3 == 0) ? 2 : 3;
        uint numStops = 2;

        for (uint i=0; i < numStops; i++) {
            uint offset = i * 100 / (numStops - 1);
            string memory color = i % 2 == 0 ? 'white' : 'black';
            stops = string.concat(stops, '<stop offset="', offset.toString(), '%" stop-color="', color, '"/>');
        }

        return string.concat(
            // prettier-ignore
            '<linearGradient id="linearGradient14277" gradientTransform="rotate(',rotation.toString(),')" gradientUnits="userSpaceOnUse">',
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
        string memory frequency = generateFrequency(seed, isFractalNoise);
        string memory octaves = generateOctaves(seed);
        string memory scale = generateScale(seed, isFractalNoise);

        // RG4[4] memory colors = generateRandomColorPalette(seed);
        // RGB[] memory colors = generateColorsNovelApproach(seed);
        // RGB[] memory colors = generateTetradicColorPalette(seed);
        // RGB[] memory colors = generateAnalogousColorPalette(seed);
        // RGB[] memory colors = generateMonochromaticColorPalette(seed);
        // RGB[] memory colors = generateTetradicAnalogousColorPalette(seed);

        RGB[] memory colors = generatePalette(seed);

        // RGB memory averageColor = averageColors(colors);
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

                      '<feFlood result="result1" flood-color="', toString(colors[0]),'" />',
                      // '<feFlood result="result1" flood-color="', toString(complementaryColor(averageColor)),'" />',
                      // '<feFlood result="result1" flood-color="white" />',
                      '<feBlend mode="normal" in="rct" in2="result1" />',
                    '</filter>',
                  '</defs>',
                  '<rect width="500" height="500" fill="url(#linearGradient14277)" filter="url(#cracked-lava)" style="filter:url(#cracked-lava)" />',
                  rects,
                '</svg>'
            );
    }

    function createRectsForColors(RGB[] memory colors) public pure returns (string memory) {
        string memory rects = "";
        for (uint i=0; i < colors.length; i++) {
            rects = string.concat(rects,
                '<rect width="50" height="50" x="', (i * 50).toString(), '" y="0" fill="', toString(colors[i]),'" />'
            );
        }

        return rects;
    }
}
