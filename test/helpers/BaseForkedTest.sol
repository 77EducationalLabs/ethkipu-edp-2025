///SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Test, console } from "forge-std/Test.sol";

import { SwapModule } from "src/m4-projects/SwapModule.sol";
import { KipuBankV3 } from "src/m4-exam/KipuBankV3.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IPermit2 } from "@uniswap/permit2/src/interfaces/IPermit2.sol";

abstract contract BaseForkedTest is Test {
    ///@notice Contract Instances
    SwapModule public s_swap;
    KipuBankV3 public s_bank;

    ///@notice Ethereum Uniswap Variables
    address payable constant UNIVERSAL_ROUTER_ADDRESS = payable(0x66a9893cC07D91D95644AEDD05D03f95e1dBA8Af);
    address constant PERMIT2_ADDRESS = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    
    IPermit2 PERMIT2 = IPermit2(PERMIT2_ADDRESS);

    ///@notice Ethereum Token Variables
    address constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant WBTC_ADDRESS = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address constant ETH = address(0);
    IERC20 USDC = IERC20(USDC_ADDRESS);
    IERC20 WBTC = IERC20(WBTC_ADDRESS);

    ///@notice Testing variables
    uint256 constant ETH_INITIAL_AMOUNT = 1000e18;
    uint256 constant BTC_INITIAL_AMOUNT = 10e7;
    address constant BARBA = address(0x77);

    ///@notice KipuBankV3 variables
    uint256 constant BANK_CAP = 50_000e6;
    address constant CHAINLINK_ETH_FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));

        s_swap = new SwapModule(
            UNIVERSAL_ROUTER_ADDRESS,
            PERMIT2_ADDRESS
        );

        s_bank = new KipuBankV3(
            BANK_CAP,
            CHAINLINK_ETH_FEED,
            UNIVERSAL_ROUTER_ADDRESS,
            PERMIT2_ADDRESS,
            USDC_ADDRESS,
            BARBA
        );

        vm.label(UNIVERSAL_ROUTER_ADDRESS, "UNIVERSAL_ROUTER");
        vm.label(PERMIT2_ADDRESS, "PERMIT2");
        vm.label(USDC_ADDRESS, "USDC");
        vm.label(WBTC_ADDRESS, "wBTC");

        vm.deal(BARBA, ETH_INITIAL_AMOUNT);
        deal(WBTC_ADDRESS, BARBA, BTC_INITIAL_AMOUNT);
    }
}