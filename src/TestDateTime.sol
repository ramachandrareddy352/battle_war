// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./BokkyPooBahsDateTimeLibrary.sol";

// ----------------------------------------------------------------------------
// Testing BokkyPooBah's DateTime Library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

contract TestDateTime {
    using BokkyPooBahsDateTimeLibrary for uint256;

    function getYear(uint256 timestamp) internal pure returns (uint256 year) {
        year = BokkyPooBahsDateTimeLibrary.getYear(timestamp);
    }

    function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
        month = BokkyPooBahsDateTimeLibrary.getMonth(timestamp);
    }

    function getDay(uint256 timestamp) internal pure returns (uint256 day) {
        day = BokkyPooBahsDateTimeLibrary.getDay(timestamp);
    }

    function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
        hour = BokkyPooBahsDateTimeLibrary.getHour(timestamp);
    }

    function getMinute(uint256 timestamp) internal pure returns (uint256 minute) {
        minute = BokkyPooBahsDateTimeLibrary.getMinute(timestamp);
    }

    function getSecond(uint256 timestamp) internal pure returns (uint256 second) {
        second = BokkyPooBahsDateTimeLibrary.getSecond(timestamp);
    }

    function uintToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }

        uint256 temp = value;
        uint256 digits;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + (value % 10))); // Convert digit to ASCII
            value /= 10;
        }

        return string(buffer);
    }

    function concatStrings(string memory a, string memory b, string memory c, string memory d, string memory e)
        internal
        pure
        returns (string memory)
    {
        bytes memory bytesA = bytes(a);
        bytes memory bytesB = bytes(b);
        bytes memory bytesC = bytes(c);
        bytes memory bytesD = bytes(d);
        bytes memory bytesE = bytes(e);

        uint256 totalLength = bytesA.length + bytesB.length + bytesC.length + bytesD.length + bytesE.length;

        string memory concatenatedString = new string(totalLength);
        bytes memory bytesConcatenated = bytes(concatenatedString);

        uint256 k = 0;

        for (uint256 i = 0; i < bytesA.length; i++) {
            bytesConcatenated[k++] = bytesA[i];
        }

        for (uint256 i = 0; i < bytesB.length; i++) {
            bytesConcatenated[k++] = bytesB[i];
        }

        for (uint256 i = 0; i < bytesC.length; i++) {
            bytesConcatenated[k++] = bytesC[i];
        }

        for (uint256 i = 0; i < bytesD.length; i++) {
            bytesConcatenated[k++] = bytesD[i];
        }

        for (uint256 i = 0; i < bytesE.length; i++) {
            bytesConcatenated[k++] = bytesE[i];
        }

        return string(bytesConcatenated);
    }
}
