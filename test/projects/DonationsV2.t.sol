//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

///@notice Foundry Tools
import {Test, console} from "forge-std/Test.sol";

///@notice Contrato do Projeto
import {DonationsV2} from "src/m3-projects/DonationsV2.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";

///@notice Mock Chainlink
import {MockV3Aggregator} from "@chainlink-local/src/data-feeds/MockV3Aggregator.sol";

contract DonationsV2Test is Test {
    ///@notice Instância do Contrato
    DonationsV2 public s_v2;

    ///@notice Instância do Mock para USDC
    MockERC20 public s_usdc;

    ///@notice Instância do Mock do CL Feeds
    MockV3Aggregator public s_clFeed;

    ///@notice Endereços para interagir
    address s_owner = address(77);
    address s_user1 = address(1);
    address s_user2 = address(2);

    ///@notice initial amounts
    uint256 constant ETHER_INITIAL_AMOUNT = 100 * 10 ** 18;
    uint256 constant USDC_INITIAL_AMOUNT = 10_000 * 10 ** 6;

    ///@notice Parâmetros do CL Feeds
    uint8 constant DECIMALS = 8;
    int256 constant INITIAL_ANSWER = 2500 * 10 ** 8;

    ///@notice Variáveis para Testes
    uint256 constant ONE_ETHER_TO_USD = 2500 * 10 ** 6;

    /*////////////////////////////////////
            * ENVIRONMENT SETUP * 
    ////////////////////////////////////*/

    function setUp() public {
        vm.startPrank(s_owner);
        s_usdc = new MockERC20("USDC", "USDC");
        s_clFeed = new MockV3Aggregator(DECIMALS, INITIAL_ANSWER);

        s_v2 = new DonationsV2(address(s_clFeed), address(s_usdc), s_owner);
        vm.stopPrank();

        ///@notice Distribui ether
        s_usdc.mint(s_user1, USDC_INITIAL_AMOUNT);
        s_usdc.mint(s_user2, USDC_INITIAL_AMOUNT);

        ///@notice Distribui USDC
        vm.deal(s_user1, ETHER_INITIAL_AMOUNT);
        vm.deal(s_user2, ETHER_INITIAL_AMOUNT);
    }

    /*////////////////////////////////////
                * doeETH Tests * 
    ////////////////////////////////////*/
    function test_doeETH() public {
        vm.startPrank(s_user1);
        vm.expectEmit();
        emit DonationsV2.DonationsV2_DoacaoRecebida(s_user1, ONE_ETHER_TO_USD);
        s_v2.doeETH{value: 1 ether}();

        assertEq(s_v2.s_doacoes(s_user1), ONE_ETHER_TO_USD);
        assertEq(s_user1.balance, ETHER_INITIAL_AMOUNT - 1 ether);
        assertEq(address(s_v2).balance, 1 ether);
    }

    /*////////////////////////////////////
                * doeUSDC Tests * 
    ////////////////////////////////////*/
    function test_doeUSDC() public {
        vm.startPrank(s_user1);
        s_usdc.approve(address(s_v2), ONE_ETHER_TO_USD);

        vm.expectEmit();
        emit DonationsV2.DonationsV2_DoacaoRecebida(s_user1, ONE_ETHER_TO_USD);
        s_v2.doeUSDC(ONE_ETHER_TO_USD);

        assertEq(s_v2.s_doacoes(s_user1), ONE_ETHER_TO_USD);
        assertEq(s_usdc.balanceOf(s_user1), USDC_INITIAL_AMOUNT - ONE_ETHER_TO_USD);
        assertEq(s_usdc.balanceOf(address(s_v2)), ONE_ETHER_TO_USD);
    }

    /*////////////////////////////////////
                * Saque de ETH * 
    ////////////////////////////////////*/
    function test_saqueETH() public {
        depositTokens(1 ether, 0);

        vm.startPrank(s_owner);
        vm.expectEmit();
        emit DonationsV2.DonationsV2_SaqueRealizado(s_owner, 1 ether);
        s_v2.saque();

        assertEq(address(s_v2).balance, 0);
        assertEq(s_owner.balance, 1 ether);
        assertEq(s_v2.s_doacoes(s_user1), ONE_ETHER_TO_USD);
    }

    /*////////////////////////////////////
               * Saque de USDC * 
    ////////////////////////////////////*/
    function test_saqueUSDC() public {
        depositTokens(0, ONE_ETHER_TO_USD);

        vm.startPrank(s_owner);
        vm.expectEmit();
        emit DonationsV2.DonationsV2_SaqueRealizado(s_owner, ONE_ETHER_TO_USD);
        s_v2.saque();

        assertEq(s_usdc.balanceOf(address(s_v2)), 0);
        assertEq(s_usdc.balanceOf(s_owner), ONE_ETHER_TO_USD);
        assertEq(s_v2.s_doacoes(s_user1), ONE_ETHER_TO_USD);
    }

    /*////////////////////////////////////
               * Saque ETH&USDC * 
    ////////////////////////////////////*/
    function test_saqueBoth() public {
        depositTokens(1 ether, ONE_ETHER_TO_USD);

        vm.startPrank(s_owner);
        s_v2.saque();

        console.log("check v2 ether balance");
        assertEq(address(s_v2).balance, 0);
        console.log("check owner ether balance");
        assertEq(s_owner.balance, 1 ether);

        console.log("check v2 USDC balance");
        assertEq(s_usdc.balanceOf(address(s_v2)), 0);
        console.log("check owner USDC balance");
        assertEq(s_usdc.balanceOf(s_owner), ONE_ETHER_TO_USD);

        console.log("check user1 donation status");
        assertEq(s_v2.s_doacoes(s_user1), 2 * ONE_ETHER_TO_USD);
    }

    /*////////////////////////////////////
               * Saque Revert * 
    ////////////////////////////////////*/
    error OwnableUnauthorizedAccount(address caller);

    function test_saqueRevert() public {
        vm.prank(s_user1);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, s_user1));
        s_v2.saque();
    }

    /*////////////////////////////////////
                  * setFeeds * 
    ////////////////////////////////////*/
    function test_setFeeds() public {
        vm.prank(s_owner);
        vm.expectEmit();
        emit DonationsV2.DonationsV2_ChainlinkFeedUpdated(address(77));
        s_v2.setFeeds(address(77));

        assertEq(address(s_v2.s_feeds()), address(77));
    }

    /*////////////////////////////////////
            * setFeeds Revert * 
    ////////////////////////////////////*/
    function test_revertSetFeeds() public {
        vm.prank(s_user1);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, s_user1));
        emit DonationsV2.DonationsV2_ChainlinkFeedUpdated(address(77));
        s_v2.setFeeds(address(77));
    }

    /*////////////////////////////////////
                * Test Helper * 
    ////////////////////////////////////*/
    function depositTokens(uint256 _ethAmount, uint256 _usdcAmount) public {
        vm.startPrank(s_user1);
        s_v2.doeETH{value: _ethAmount}();

        s_usdc.approve(address(s_v2), _usdcAmount);
        s_v2.doeUSDC(_usdcAmount);
        vm.stopPrank();
    }
}
