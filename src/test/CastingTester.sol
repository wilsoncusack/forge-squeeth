//SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.7.6;

import {Uint256Casting} from "../libs/Uint256Casting.sol";

contract CastingTester{    
    using Uint256Casting for uint256;

    function testToUint128(uint256 y) external pure returns (uint128 z) {
        if(uint128(y) != y) return 0;
        return y.toUint128();
    }

    function testToUint96(uint256 y) external pure returns (uint96 z) {
        if(uint96(y) != y) return 0;
        return y.toUint96();
    }

    function testToUint32(uint256 y) external pure returns (uint32 z) {
        if(uint32(y) != y) return 0;
        return y.toUint32();
    }
}