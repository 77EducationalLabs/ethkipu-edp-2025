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
import { IPermit2 } from "@uniswap/permit2/src/interfaces/IPermit2.sol";
import { IV4Router } from "@uniswap/v4-periphery/src/interfaces/IV4Router.sol";

/*///////////////////////////////////
            Libraries
///////////////////////////////////*/
import { SafeERC20 }  from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Commands } from "src/m4-projects/helpers/Commands.sol"; //Dependencies are broken. So I had to copy the file from the Uni repo.
import { Actions } from "@uniswap/v4-periphery/src/libraries/Actions.sol";

contract SwapModule {

    /*///////////////////////////////////
            Type declarations
    ///////////////////////////////////*/
    ///@notice enabling safe operations for IERC20 interactions
    using SafeERC20 for IERC20;

    /*///////////////////////////////////
            State variables
    ///////////////////////////////////*/
    ///@notice Uniswap Instances
    UniversalRouter public immutable i_router;
    IPermit2 public immutable i_permit2;

    /*///////////////////////////////////
                Events
    ///////////////////////////////////*/
    ///@notice event emitted when the swap is successfully completed
    event SwapModule_SwapExecuted(address indexed user);

    /*///////////////////////////////////
                Errors
    ///////////////////////////////////*/
    ///@notice error emitted if the user inputs multiple tokens
    error SwapModule_MultipleTokenInputsAreNotAllowed(address native, address tokenIn);
    ///@notice error emitted if the native token transfer fails
    error SwapModule_TransactionFailed(bytes data);

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
    /**
        @notice function to execute swaps of exact inputs
        @notice outputs can vary accordingly to the _minAmountOut minimum value
        @param _key the Pool struct info
        @param _amountIn the amount to be swapped
        @param _minAmountOut the minimum amount accepted after a swap
        @param _deadline the maximum time a user accepts to wait for a swap completion
        @dev this function can't handle ether and ERC20 inputs at same time.
    */
    function swapExactInputSingle(
        PoolKey calldata _key,
        uint128 _amountIn,
        uint128 _minAmountOut,
        uint48 _deadline
    ) external payable {
        address tokenIn = Currency.unwrap(_key.currency0);
        address tokenOut = Currency.unwrap(_key.currency1);

        if(msg.value > 0 && tokenIn != address(0)) revert SwapModule_MultipleTokenInputsAreNotAllowed(address(0), tokenIn);
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

        //6. If the token is an ERC20, transfer from user and perform the necessary approvals.
        if(tokenIn != address(0)){
            //6.1 Transfer tokens from user
            IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
            
            //6.2 Approve the Permit2 contract
            IERC20(tokenIn).safeIncreaseAllowance(address(i_permit2), _amountIn);
            //6.3 Permit approve the Universal Router
            i_permit2.approve(tokenIn, address(i_router), _amountIn, _deadline);
        }
        
        emit SwapModule_SwapExecuted(msg.sender);
        
        //7. Execute the swap
        i_router.execute{value: _amountIn}(commands, inputs, _deadline);

        if(tokenOut != address(0)){
            IERC20(tokenOut).safeTransfer(msg.sender, IERC20(tokenOut).balanceOf(address(this)));
        } else {
            (bool success, bytes memory data) = msg.sender.call{value: address(this).balance}("");
            if(!success) revert SwapModule_TransactionFailed(data);
        }
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