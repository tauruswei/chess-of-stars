// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./01_FundsMUltiPoolUpgradeERC20.sol";

// 对 FundsMUltiPoolUpgradeERC20 进行升级
contract FundsMUltiPoolUpgradeERC20V2 is FundsMUltiPoolUpgradeERC20 {

    ///@dev returns the contract version
    function MSHKVersion() external pure returns (uint256) {
        return 2;
    }
}
