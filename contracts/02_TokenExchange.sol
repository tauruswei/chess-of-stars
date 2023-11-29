// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./01_TokenExchange.sol";

// 对 FundsMUltiPoolUpgradeERC20 进行升级
contract TokenExchangeContractV2 is TokenExchangeContract {

    ///@dev returns the contract version
    function MSHKVersion() external pure returns (uint256) {
        return 2;
    }
}
