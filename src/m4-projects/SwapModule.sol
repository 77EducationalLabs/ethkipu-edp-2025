///SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/*///////////////////////////////////
            Imports
///////////////////////////////////*/
import { UniversalRouter } from "@uniswap/universal-router/contracts/UniversalRouter.sol";
import { PoolKey } from "@uniswap/v4-core/src/types/PoolKey.sol";
import { Currency } from "@uniswap/v4-core/src/types/Currency.sol";

/*///////////////////////////////////
            Interfaces
///////////////////////////////////*/
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IV3SwapRouter } from "@swap/contracts/interfaces/IV3SwapRouter.sol";
import { IPermit2 } from "@uniswap/permit2/src/interfaces/IPermit2.sol";
import { IV4Router } from "@uniswap/v4-periphery/src/interfaces/IV4Router.sol";

/*///////////////////////////////////
            Libraries
///////////////////////////////////*/
import { SafeERC20 }  from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Commands } from "src/m4-projects/helpers/Commands.sol";
import { Actions } from "@uniswap/v4-periphery/src/libraries/Actions.sol";

contract SwapModule {
    /**
        Integrate UniswapV3 & UniswapV4
        User wants to swap a token into another one
        He will have two option to do it.
        Tested on Forked Environment
    */

    /*///////////////////////////////////
            Type declarations
    ///////////////////////////////////*/
    ///@notice enabling safe operations for IERC20 interactions
    using SafeERC20 for IERC20;

    /*///////////////////////////////////
            State variables
    ///////////////////////////////////*/
    ///@notice Uniswap Instances
    IV3SwapRouter public immutable i_routerV3;
    UniversalRouter public immutable i_router;
    IPermit2 public immutable i_permit2;

    /*///////////////////////////////////
                Events
    ///////////////////////////////////*/
    event SwapModule_SwapExecuted(address indexed user);

    /*///////////////////////////////////
                Errors
    ///////////////////////////////////*/

    /*///////////////////////////////////
                Modifiers
    ///////////////////////////////////*/

    /*///////////////////////////////////
                Functions
    ///////////////////////////////////*/

    /*///////////////////////////////////
                constructor
    ///////////////////////////////////*/
    constructor(address payable _router, address _permit2) {
        i_router = UniversalRouter(_router);
        i_permit2 = IPermit2(_permit2);
    }

    /*///////////////////////////////////
            Receive&Fallback
    ///////////////////////////////////*/

    /*///////////////////////////////////
                external
    ///////////////////////////////////*/
    function swapExactInputSingle(
        PoolKey calldata _key,
        uint128 _amountIn,
        uint128 _minAmountOut,
        uint48 _deadline
    ) external payable {
        //1. encode the Universal Router command
        bytes memory commands = abi.encodePacked(uint8(Commands.V4_SWAP));

        //2. encode V4Router actions
        bytes memory actions = abi.encodePacked(
            uint8(Actions.SWAP_EXACT_IN_SINGLE),
            uint8(Actions.SETTLE_ALL),
            uint8(Actions.TAKE_ALL)
        );

        //3. prepare parameters for each action
        bytes[] memory params = new bytes[](3);
        params[0] = abi.encode(
            IV4Router.ExactInputSingleParams({
                poolKey: _key,
                zeroForOne: true,
                amountIn: _amountIn,
                amountOutMinimum: _minAmountOut,
                hookData: bytes("")
            })
        );
        params[1] = abi.encode(_key.currency0, _amountIn);
        params[2] = abi.encode(_key.currency1, _minAmountOut);

        //4. prepare inputs
        bytes[] memory inputs = new bytes[](1);
        
        //5. Combine actions and params into inputs
        inputs[0] = abi.encode(actions, params);

        //6. Transfer tokens from user
        IERC20(Currency.unwrap(_key.currency0)).safeTransferFrom(msg.sender, address(this), _amountIn);

        //7. Approve the Universal Router
        IERC20(Currency.unwrap(_key.currency0)).approve(address(i_permit2), _amountIn);
        i_permit2.approve(Currency.unwrap(_key.currency0), address(i_router), _amountIn, _deadline);
        
        //8. Execute the swap
        i_router.execute{value: _amountIn}(commands, inputs, _deadline);

        emit SwapModule_SwapExecuted(msg.sender);
    }

    /*///////////////////////////////////
                public
    ///////////////////////////////////*/

    /*///////////////////////////////////
                internal
    ///////////////////////////////////*/

    /*///////////////////////////////////
                private
    ///////////////////////////////////*/

    /*///////////////////////////////////
                View & Pure
    ///////////////////////////////////*/
}