///SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/*///////////////////////////////////
            Imports
///////////////////////////////////*/
import { BaseForkedTest } from "test/helpers/BaseForkedTest.sol";
import { PoolKey } from "@uniswap/v4-core/src/types/PoolKey.sol";
import { Currency } from "@uniswap/v4-core/src/types/Currency.sol";

/*///////////////////////////////////
            Interfaces
///////////////////////////////////*/
import { IHooks } from "@uniswap/v4-core/src/interfaces/IHooks.sol";

/*///////////////////////////////////
            Libraries
///////////////////////////////////*/
import { Actions } from "@uniswap/v4-periphery/src/libraries/Actions.sol";

contract SwapModuleTest is BaseForkedTest {

    /*///////////////////////////////////////////
                    Test's input
    ///////////////////////////////////////////*/
    PoolKey ETH_USDC_KEY = PoolKey({
        currency0: Currency.wrap(ETH),
        currency1: Currency.wrap(USDC_ADDRESS),
        fee: 3000,
        tickSpacing: 60,
        hooks: IHooks(address(0))
    });

    PoolKey WBTC_USDC_KEY = PoolKey({
        currency0: Currency.wrap(WBTC_ADDRESS),
        currency1: Currency.wrap(USDC_ADDRESS),
        fee: 3000,
        tickSpacing: 60,
        hooks: IHooks(address(0))
    });

    bytes constant actions = abi.encodePacked(
        uint8(Actions.SWAP_EXACT_IN_SINGLE),
        uint8(Actions.SETTLE_ALL),
        uint8(Actions.TAKE_ALL)
    );

    function test_ethSwapSucceed() public {
        uint128 amountIn = 1e18;
        uint128 minAmountOut = 2400e6;

        vm.startPrank(BARBA);
        s_swap.swapExactInputSingle{value: amountIn}(
            ETH_USDC_KEY, 
            amountIn, 
            minAmountOut, 
            uint48(block.timestamp + 20)
        );
        vm.stopPrank();
    }

    function test_wBTCSwapSucceed() public {
        uint128 amountIn = 5e6;
        uint128 minAmountOut = 5_000e6;

        vm.startPrank(BARBA);
        WBTC.approve(address(s_swap), amountIn);

        s_swap.swapExactInputSingle(
            WBTC_USDC_KEY, 
            amountIn, 
            minAmountOut, 
            uint48(block.timestamp + 30)
        );
        vm.stopPrank();
    }
}