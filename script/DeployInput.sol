// SPDX-License-Identifier: AGPL-3.0-only
// slither-disable-start reentrancy-benign

pragma solidity 0.8.23;

contract DeployInput {
  address constant UNISWAP_GOVERNOR = 0x408ED6354d4973f66138C91495F2f2FCbd8724C3;
  address constant UNISWAP_GOVERNOR_TIMELOCK = 0x1a9C8182C09F50C8318d769245beA52c32BE35BC;
  address constant UNISWAP_V3_FACTORY_ADDRESS = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
  // TODO not finalized: currently WETH
  address constant PAYOUT_TOKEN_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address constant STAKE_TOKEN_ADDRESS = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
  // TODO not determined yet
  uint256 constant PAYOUT_AMOUNT = 10e18;
}
