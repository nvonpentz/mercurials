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
        uint rand = generateRandom(0, 3 + 3 + 6, seed);
        if (rand < 3) {
            return generatePrimaryColor(seed);
        } else if (rand < 6) {
            return generateSecondaryColor(seed);
        } else {
            return generateTertiaryColor(seed);
        }
    }

    function generateFrequency(uint tokenId, bool isFractalNoise) public view returns (string memory) {
        uint frequencyUint;
        if (isFractalNoise) {
            // Fractal noise
            // frequencyUint = generateRandom(20, 150, tokenId);
            frequencyUint = generateRandom(15, 80, tokenId);
        } else {
            // Turbulent noise
            // frequencyUint = generateRandom(1, 60, tokenId);
            frequencyUint = generateRandom(15, 40, tokenId);
        }

        string memory frequency; 
        if (frequencyUint >= 100) {
             frequency = string.concat('0.', frequencyUint.toString()); // E.g. 0.200
        } else if (frequencyUint >= 10) {
            frequency = string.concat('0.0', frequencyUint.toString()); // E.g. 0.020
        } else {
            frequency = string.concat('0.00', frequencyUint.toString()); // E.g. 0.002
        }

        return frequency;
    }

    function generateOctaves(uint tokenId) public view returns (string memory) {
        return generateRandom(2, 4, tokenId).toString();
    }

    function generateScale(uint tokenId, bool isFractalNoise) public view returns (string memory) {
        return generateRandom(0, 101, tokenId).toString();
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
        // Generate a base color
        HSL memory base = generateBaseColor(seed);
        HSL[] memory hslColors = new HSL[](9);

        // Then two secondary colors, either split-complements or triadic
        // with base
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

        // Create a color pool to randomly select from when creating the final
        // set later
        HSL[] memory colorPool = new HSL[](5);
        colorPool[0] = base;
        colorPool[1] = second1;
        colorPool[2] = second2;

        // Create mix colors with base and secondary colors
        // and add to the pool
        HSL memory mix1 = mixColors(base, second1);
        HSL memory mix2 = mixColors(base, second2);
        colorPool[3] = mix1;
        colorPool[4] = mix2;

        // Create final palette using the color pool
        HSL[] memory palette = new HSL[](6);

        // Add base color to the palette
        palette[1] = base;

        // Pick the remaining colors for the palette
        // by selecting a random element from the pool
        // and mixing it with a random gray color
        for (uint i=2; i < palette.length-1; i++) {
            uint randomIndex = generateRandom(0, colorPool.length-1, seed + i);
            HSL memory randomColor = colorPool[randomIndex];
            HSL memory gray = HSL({
                hue: 0,
                saturation: 0,
                lightness: generateRandom(0, 100, seed + i + 1)
            });
            HSL memory mixed = mixColors(randomColor, gray);

            // 1/2 also use the complementary color of the mixed color
            if (seed % 2 == 0) {
                HSL memory complementary = generateComplementaryColor(mixed);
                palette[i] = complementary;
            } else {
                palette[i] = mixed;
            }
        }

        // Add black and white to the edges of the palette
        // HSL memory black = HSL(0, 0, 0);
        // HSL memory white = HSL(0, 0, 100);
        palette[0] = HSL(palette[1].hue, palette[1].saturation, 10);
        palette[5] = HSL(palette[4].hue, palette[4].saturation, 90);

        // Convert HSL colors to RGB
        RGB[] memory rgbColors = new RGB[](palette.length);
        for (uint i=0; i < palette.length; i++) {
            rgbColors[i] = toColorRGB(palette[i]);
        }

        // randomize the colors
        for (uint i=0; i < rgbColors.length; i++) {
            uint randomIndex = generateRandom(0, rgbColors.length-1, seed + i);
            RGB memory temp = rgbColors[i];
            rgbColors[i] = rgbColors[randomIndex];
            rgbColors[randomIndex] = temp;
        }

        return rgbColors;
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
        uint numStops = 2;
        for (uint i=0; i < numStops; i++) {
            uint offset = i * 100 / (numStops - 1);
            string memory color = i % 2 == 0 ? '#222' : '#ddd';
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
        bool isFractalNoise = seed % 2 == 0;
        string memory turbulenceType = isFractalNoise ? "fractalNoise" : "turbulence";
        // string memory turbulenceType = "turbulence";
        string memory frequency = generateFrequency(seed, isFractalNoise);
        string memory octaves = generateOctaves(seed);
        string memory scale = generateScale(seed, isFractalNoise);
        RGB[] memory colors = generatePalette(seed);
        string memory feComponentTransfer = generateComponentTransfer(seed, colors);
        string memory rects = createRectsForColors(colors);
        return
            // prettier-ignore
            string.concat(
                '<svg width="500" height="500" viewBox="0 0 500 500" version="1.1" xmlns="http://www.w3.org/2000/svg">',
                  '<defs>',
                    generateGradient(seed),

                    '<filter id="cracked-lava" color-interpolation-filters="sRGB">',
                      '<feTurbulence baseFrequency="', frequency, '" type="', turbulenceType, '" numOctaves="', octaves,'" result="r1" in="SourceGraphic" />',
                      '<feDisplacementMap result="r5" xChannelSelector="R" in2="r1" in="r1" yChannelSelector="G" scale="', scale, '" />',
                      '<feComposite result="r2" operator="in" in="SourceGraphic" in2="r5" />',
                      generateSpecularLighting(seed, isFractalNoise),
                      '<feComposite k1="0.5" k3="1" k2="-0.5" in2="r2" in="r4" operator="arithmetic" result="r91" k4="0" />',
                      '<feComposite in="r91" result="r4" operator="arithmetic" k2="0" k3="4" in2="r91" k1="0" k4="-0" />',
                      feComponentTransfer,
                      '<feBlend mode="normal" in="rct" in2="r2" />',
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
