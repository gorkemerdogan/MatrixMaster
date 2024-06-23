// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ABDKMathQuad.sol";

library MM_MatrixHelper {
    using ABDKMathQuad for bytes16;

    uint256 private constant PRECISION = 2;

    // Converts a string representation of a number to a 128-bit quadruple precision floating-point number
    // @param str: the string representing the number to be converted
    // @returns a 128-bit quadruple precision floating-point number (bytes16) corresponding to the input string
    function stringToQuad(string memory str) internal pure returns (bytes16) {
        bytes memory b = bytes(str);
        uint256 length = b.length;
        bool isNegative = false;
        bool hasDecimal = false;
        uint256 decimalIndex = length;

        bytes16 result = ABDKMathQuad.fromUInt(0);
        
        for (uint256 i = 0; i < length; i++) {
            if (b[i] == "-") {
                isNegative = true;
            } else if (b[i] == ".") {
                hasDecimal = true;
                decimalIndex = i;
                break;
            }
        }

        // Process the integer part
        for (uint256 i = 0; i < (hasDecimal ? decimalIndex : length); i++) {
            if (b[i] >= "0" && b[i] <= "9") {
                result = result.mul(ABDKMathQuad.fromUInt(10));
                result = result.add(ABDKMathQuad.fromUInt(uint8(b[i]) - 48));
            }
        }

        // Process the fractional part
        if (hasDecimal) {
            bytes16 fractionalPart = ABDKMathQuad.fromUInt(0);
            bytes16 fractionalScale = ABDKMathQuad.fromUInt(1);
            for (uint256 i = decimalIndex + 1; i < length; i++) {
                if (b[i] >= "0" && b[i] <= "9") {
                    fractionalPart = fractionalPart.mul(ABDKMathQuad.fromUInt(10));
                    fractionalPart = fractionalPart.add(ABDKMathQuad.fromUInt(uint8(b[i]) - 48));
                    fractionalScale = fractionalScale.mul(ABDKMathQuad.fromUInt(10));
                }
            }
            result = result.add(fractionalPart.div(fractionalScale));
        }

        if (isNegative) {
            result = result.neg();
        }

        return result;
    }

    // Converts a 128-bit quadruple precision floating-point number to its string representation
    // @param value: 128-bit quadruple precision floating-point number (bytes16) to be converted
    // @returns a string representing the decimal form of the input floating-point number
    function quadToString(bytes16 value) internal pure returns (string memory) {
        if (value == ABDKMathQuad.fromUInt(0)) {
            return "0.0";
        }

        bool isNegative = uint128(value) & 0x80000000000000000000000000000000 > 0;
        if (isNegative) {
            value = value.neg();
        }

        // Increase precision scale to handle rounding properly
        uint256 scale = 10**(PRECISION + 1);
        bytes16 scaledValue = value.mul(ABDKMathQuad.fromUInt(scale));
        uint256 intValue = ABDKMathQuad.toUInt(scaledValue);

        uint256 integerPart = intValue / (10**(PRECISION + 1));
        uint256 fractionalPart = (intValue % (10**(PRECISION + 1))) / 10;

        // Handle rounding
        if ((intValue % 10) >= 5) {
            fractionalPart += 1;
            if (fractionalPart >= 10**PRECISION) {
                fractionalPart = 0;
                integerPart += 1;
            }
        }

        string memory fractionalStr = uintTostr(fractionalPart);
        while (bytes(fractionalStr).length < PRECISION) {
            fractionalStr = string(abi.encodePacked("0", fractionalStr));
        }

        string memory result = string(abi.encodePacked(uintTostr(integerPart), ".", fractionalStr));

        if (isNegative) {
            result = string(abi.encodePacked("-", result));
        }
        return result;
    }

    // Converts an unsigned integer to its decimal string representation
    // @param _i: the unsigned integer to be converted
    // @returns a string representing the decimal form of the input integer
    function uintTostr(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bstr[k] = bytes1(temp);
            _i /= 10;
        }
        return string(bstr);
    }

    // Extracts a slice from a given byte array
    // @param data: original byte array from which the slice will be extracted
    // @param start: starting index from where the slice will begin
    // @param len: length of the slice to be extracted
    // @returns a new byte array containing the extracted slice
    function slice(bytes memory data, uint256 start, uint256 len) internal pure returns (bytes memory) {
        bytes memory result = new bytes(len);
        for (uint256 i = 0; i < len; i++) {
            result[i] = data[i + start];
        }
        return result;
    }

    // Splits a given string into an array of substrings based on a specified delimiter
    // @param input: the original string to be split
    // @param delimiter: the delimiter string used to split the input string
    // @returns an array of strings, which are the substrings of the input string split by delimiter 
    function split(string memory input, string memory delimiter) internal pure returns (string[] memory) {
        bytes memory inputBytes = bytes(input);
        bytes memory delimiterBytes = bytes(delimiter);

        uint256 splitCount = 1;
        for (uint256 i = 0; i <= inputBytes.length - delimiterBytes.length; i++) {
            bool isMatch = true;
            for (uint256 j = 0; j < delimiterBytes.length; j++) {
                if (inputBytes[i + j] != delimiterBytes[j]) {
                    isMatch = false;
                    break;
                }
            }
            if (isMatch) {
                splitCount++;
                i += delimiterBytes.length - 1;
            }
        }

        string[] memory result = new string[](splitCount);
        uint256 resultIndex = 0;
        uint256 start = 0;
        for (uint256 i = 0; i <= inputBytes.length - delimiterBytes.length; i++) {
            bool isMatch = true;
            for (uint256 j = 0; j < delimiterBytes.length; j++) {
                if (inputBytes[i + j] != delimiterBytes[j]) {
                    isMatch = false;
                    break;
                }
            }
            if (isMatch) {
                result[resultIndex] = substring(input, start, i - start);
                resultIndex++;
                start = i + delimiterBytes.length;
                i += delimiterBytes.length - 1;
            }
        }
        result[resultIndex] = substring(input, start, inputBytes.length - start);
        return result;
    }

    // Extracts a substring from a given string
    // @param str: original string from which the substring will be extracted
    // @param startIndex: the starting index from where the substring will begin
    // @param length: the length of the substring to be extracted
    // @returns a new string containing the extracted substring
    function substring(string memory str, uint256 startIndex, uint256 length) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = strBytes[i + startIndex];
        }
        return string(result);
    }
}
