///SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

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

contract KipuBankV3Test is BaseForkedTest {

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

    function test_depositArbitraryTokenWorks() public {
        uint128 amountIn = 5e6;
        uint128 minAmountOut = 5_000e6;

        vm.startPrank(BARBA);
        WBTC.approve(address(s_bank), amountIn);

        uint256 balanceBeforeDeposit = USDC.balanceOf(address(s_bank));
        s_bank.depositArbitraryToken(
            WBTC_USDC_KEY,
            amountIn,
            minAmountOut,
            uint48(block.timestamp + 30)
        );
        uint256 balanceAfterDeposit = USDC.balanceOf(address(s_bank));
        vm.stopPrank();

        assertEq(WBTC.balanceOf(BARBA), BTC_INITIAL_AMOUNT - amountIn);
        assertGt(s_bank.s_vault(BARBA, USDC_ADDRESS), minAmountOut);
        assertEq(WBTC.balanceOf(address(s_bank)), 0);
        assertGt(balanceAfterDeposit, balanceBeforeDeposit + minAmountOut);
    }

}