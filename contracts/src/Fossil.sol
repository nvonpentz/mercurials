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

    function generateChannelSelector(uint seed) internal view returns (string memory) {
        // generates a random channel selector or empty string
        uint rand = generateRandom(0, 4, seed);
        if (rand == 0) {
            return "";
        } else if (rand == 1) {
            return "R";
        } else if (rand == 2) {
            return "G";
        } else {
            return "B";
        }
    }

    function generateFrequency(
        uint seed,
        bool isFractalNoise,
        uint octaves
    ) public view returns (string memory, uint frequency) {
        uint frequencyUint;
        if (isFractalNoise) {
            // Fractal noise
            if (octaves == 1) {
                frequencyUint = generateRandom(30, 100, seed);
            } else if (octaves == 2 || octaves == 3) {
                frequencyUint = generateRandom(20, 90, seed);
            } else if (octaves >= 4) {
                frequencyUint = generateRandom(10, 70, seed);
            }


        } else {
            // Turbulent noise
            // frequencyUint = generateRandom(1, 60, seed);
            frequencyUint = generateRandom(1, 20, seed);
        }

        // convert to string
        string memory frequency; 
        if (frequencyUint >= 100) {
             frequency = string.concat('0.', frequencyUint.toString()); // E.g. 0.200
        } else if (frequencyUint >= 10) {
            frequency = string.concat('0.0', frequencyUint.toString()); // E.g. 0.020
        } else {
            frequency = string.concat('0.00', frequencyUint.toString()); // E.g. 0.002
        }

        return (frequency, frequencyUint);
    }

    function generateSurfaceScale(uint seed, bool isFractalNoise) public view returns (string memory) {
        // if (isFractalNoise) {
        // // return '-5';
        //     return '1';
        // } else {
        //     // return '-5';
        // }

        return '-5';
    }

    function generateOctaves(uint seed, bool isFractalNoise) public view returns (string memory, uint) {
        uint octaves;
        if (isFractalNoise) {
            octaves = generateRandom(1, 6, seed);
        } else {
            // octaves = generateRandom(1, 3, seed);
            octaves = 1;
        }
        return (octaves.toString(), octaves);
    }

    function generateScale(
        uint seed,
        bool isFractalNoise,
        uint frequency,
        uint octaves
    ) public view returns (string memory) {
        uint lower = 0;
        uint upper = 100;
        if (isFractalNoise && octaves <= 2 && frequency <= 50) {
            lower = 60;
        } else {
            upper = 80;
        }
        return generateRandom(lower, upper, seed).toString();
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

    function toString(HSL memory hsl) internal pure returns (string memory) {
        return string.concat('hsl(', hsl.hue.toString(), ', ', hsl.saturation.toString(), '%, ', hsl.lightness.toString(), '%)');
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

    function generateComponentTransfer(uint seed, RGB[] memory colors) public view returns (string memory) {
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

    function generatePalette2(uint seed) public view returns (RGB[] memory) {
        // generate a random hue value
        uint hue = generateRandom(0, 361, seed);
        uint colorsLength = 5;
        // RGB[] memory colors = new RGB[](colorsLength-1);
        RGB[] memory colors = new RGB[](colorsLength-1);
        HSL[] memory colorsHsl = new HSL[](colorsLength-1);

        uint lightnessDelta = 100 / colorsLength;
        uint lightness = 0;
        // generate random saturation
        // uint saturation = generateRandom(20, 100, seed);
        uint saturation = 0;
        for (uint i=0; i < colors.length; i++) {
            // generate a hue within 121 degrees of the previous hue
            uint delta = generateRandom(0, 121, seed + i);
            if (generateRandom(0, 2, seed + i) % 2 == 0) {
                hue = hue + delta;
            } else if (delta > hue) {
                uint diff = delta - hue;
                hue = 360 - diff;
            } else {
                hue = hue - delta;
            }
            hue = hue % 361;

            // override hue for the last color and set to 180 from the first
            if (i == colors.length-1) {
                hue = (colorsHsl[0].hue + 180) % 360;
            }

            lightness += lightnessDelta;
            colorsHsl[i] = HSL(hue, saturation, lightness);
            colors[i] = toColorRGB(HSL(hue, saturation, lightness));
        }

        // randomize
        // for (uint i=0; i < colors.length; i++) {
        //     uint randomIndex = generateRandom(0, colors.length, seed + i);
        //     RGB memory temp = colors[i];
        //     colors[i] = colors[randomIndex];
        //     colors[randomIndex] = temp;
        // }

        // reverse
        // for (uint i=0; i < colors.length / 2; i++) {
        //     RGB memory temp = colors[i];
        //     colors[i] = colors[colors.length - i - 1];
        //     colors[colors.length - i - 1] = temp;
        // }

        // swap middle two elements
        // RGB memory temp = colors[1];
        // colors[1] = colors[2];
        // colors[2] = temp;

        return colors;
    }

    function complementaryColor(RGB memory color) public pure returns (RGB memory) {
        return RGB(255 - color.r, 255 - color.g, 255 - color.b);
    }

    /* new */
    function generateSVG(uint seed) public view returns (string memory) {
        /* Filter parameters */
        // bool isFractalNoise = seed % 2 == 0;
        bool isFractalNoise = false;
        string memory turbulenceType = isFractalNoise ? "fractalNoise" : "turbulence";
        // string memory turbulenceType = "turbulence";
        (string memory octaves, uint octavesUint) = generateOctaves(seed, isFractalNoise);
        (string memory frequency, uint frequencyUint) = generateFrequency(seed, isFractalNoise, octavesUint);
        string memory scale = generateScale(seed, isFractalNoise, frequencyUint, octavesUint);
        // RGB[] memory colors = generatePalette(seed);
        RGB[] memory colors = generatePalette2(seed);
        string memory feComponentTransfer = generateComponentTransfer(seed, colors);
        string memory rects = createRectsForColors(colors);
        string memory light;
        // uint xLight = generateRandom(0, 501, seed+200);
        uint xLight = 250;
        uint yLight = 250;
        // uint zLight = generateRandom(0, 10, seed+202);
        uint zLight = 5; // maybe 0 for fractal
        light = string.concat(
            // prettier-ignore
            '<fePointLight x="',
                xLight.toString(),
                '" y="', yLight.toString(),
                '" z="-', zLight.toString(),
                // '" lighting-color="',
                // toString(colors[colors.length-1]),
                '"></fePointLight>'
        );
        string memory diffuseConstant;
        if (isFractalNoise) {
            diffuseConstant = '10';
        } else {
            diffuseConstant = '4';
        }

        uint frequency2 = generateRandom(30, 301, seed -1);
        string memory frequency2Str; 
        if (frequency2 >= 0 && frequency2 < 10) {
            frequency2Str = string.concat('0.000', frequency2.toString()); // 0.0001 - 0.0010
        } else if (frequency2 >= 10 && frequency2 < 100) {
            frequency2Str = string.concat('0.00', frequency2.toString()); // 0.010 - 0.100
        } else if (frequency2 >= 100) {
            frequency2Str = string.concat('0.0', frequency2.toString()); // 0.100 - 0.200
        } else {
            console.log('should never happen');
            assert(false);
        }

        // generate random k4 value between 0.01 and 0.50
        uint k4Uint = generateRandom(0, 76, seed - 2);
        string memory operator;
        string memory k4;
        if (generateRandom(0, 2, seed - 3) % 2 == 0) {
            operator = 'out';
            k4 = string.concat('-0.', (25 + k4Uint).toString());
        } else{
            operator = 'in';
            k4 = string.concat('0.', k4Uint.toString());
        }

        // string memory k4 = string.concat('0.', );
        string memory feComposites = string.concat(
            '<feComposite in="blurResult" in2="displacementResult" operator="', operator, '" result="compositeResult2"/>'
            // '<feComposite in="compositeResult2" in2="compositeResult2" operator="arithmetic" k1="0" k2="1" k3="1" k4="', k4,'"/>'
        );

        // generate two random strings xChannelSelector and yChannelSelector
        // that are either R, G, B or ''
        return
            // prettier-ignore
            string.concat(
                '<svg width="500" height="500" viewBox="0 0 500 500" version="1.1" xmlns="http://www.w3.org/2000/svg">',
                    
                    '<filter id="a">',
                        // Blur for edges
                        '<feGaussianBlur in="SourceGraphic" stdDeviation="10" result="blurResult"/>'

                        // Core filter
                        '<feTurbulence in="blurResult" baseFrequency="', frequency2Str, '" numOctaves="', generateRandom(1, 4, seed+1).toString(), '"',
                            'result="turbulenceResult"> </feTurbulence>',

                        // For animation
                        // '<feColorMatrix type="hueRotate">',
                        //   // '<animate attributeName="values" from="0" to="360"',
                        //   //          'dur="60s" repeatCount="indefinite" result="colorMatrixResult"/>',
                        // '</feColorMatrix>',
                        // For animation
                        // '<feColorMatrix type="matrix"',
                        //    'values="0 0 0 0 0 ',
                        //            '0 0 0 0 0 ',
                        //            '0 0 0 0 0 ',
                        //            '1 0 0 0 0">',
                        // '</feColorMatrix>',

                        // For scale effect
                        '<feDisplacementMap scale="', generateRandom(0, 101, seed+2).toString(),'" result="displacementResult"> </feDisplacementMap>',

                        // Add the flatness
                        // '<feComposite in="blurResult" in2="displacementResult" operator="', (generateRandom(0, 2, seed +3) % 2) == 0 ? 'in' : 'out', '" result="compositeResult2"/>',
                        // '<feComposite in="blurResult" in2="displacementResult" operator="in" result="compositeResult2"/>',
                        // '<feComposite in="compositeResult2" in2="compositeResult2" operator="arithmetic" k1="0" k2="1" k3="1" k4="', k4,'"/>',
                        feComposites,

                        // Light
                        '<feDiffuseLighting lighting-color="white" diffuseConstant="', generateRandom(1, 11, seed+6).toString(), '"',
                                           'result="diffuseResult" surfaceScale="-5">',
                          // '<feDistantLight elevation="', generateRandom(0, 5, seed+4).toString(),'">',
                          '<feDistantLight elevation="', generateRandom(0, 5, seed+4).toString(),'">',
                          '</feDistantLight>',
                        '</feDiffuseLighting>',

                        // // Inverse the colors
                        // (generateRandom(0, 2, seed+5) % 2) == 0 ? '' : '<feColorMatrix type="luminanceToAlpha" />',
                    '</filter>',
                  '</defs>',
                  '<rect width="1000" height="1000" filter="url(#a)"/>',
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
