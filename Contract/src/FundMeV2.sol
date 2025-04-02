//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {FundMe} from "./FundMe.sol";

// New implementation for upgrade testing
contract FundMeV2 is FundMe {
    uint256 private newValue;

    event NewValueSet(uint256 newValue);

    function setNewValue(uint256 _value) public {
        newValue = _value;
        emit NewValueSet(_value);
    }

    function getNewValue() public view returns (uint256) {
        return newValue;
    }
}
