// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {KipuBankV2} from "src/m3-exam/KipuBankV2.sol";

contract KipuBankV2Test is Test {
    //Instances
    KipuBankV2 bank;

    //Variables ~ Users
    address Barba = makeAddr("Barba");
    address student1 = makeAddr("student1");
    address student2 = makeAddr("student2");

    //Variables ~ Utils
    uint256 constant BANK_CAP = 10_000 * 10 ** 6;
    uint256 constant ETHER_INITIAL_BALANCE = 100 * 10 ** 18;
    uint256 constant USDC_INITIAL_BALANCE = 1_000 * 10 ** 6;
    address constant CL_FEED = address(0);

    function setUp() public {
        bank = new KipuBankV2(BANK_CAP, CL_FEED, Barba);

        vm.deal(Barba, ETHER_INITIAL_BALANCE);
        vm.deal(student1, ETHER_INITIAL_BALANCE);
        vm.deal(student2, ETHER_INITIAL_BALANCE);
    }

    modifier processDeposit() {
        uint256 amount = 1 * 10 ** 18;
        vm.prank(Barba);
        bank.depositEther{value: amount}();
        _;
    }

    /// Testing functions ///
    error KipuBankV2_BankCapReached(uint256);

    function test_depositFailsBecauseOfCap() public {
        vm.prank(Barba);
        vm.expectRevert(abi.encodeWithSelector(KipuBankV2_BankCapReached.selector, BANK_CAP));
        bank.depositEther{value: ETHER_INITIAL_BALANCE}();
    }

    event KipuBankV2_SuccessfullyDeposited(address, uint256);

    function test_depositSucceed() public {
        uint256 amount = 1 * 10 ** 18;
        uint256 userBalance = student1.balance;

        vm.prank(student1);
        vm.expectEmit();
        emit KipuBankV2_SuccessfullyDeposited(student1, amount);
        bank.depositEther{value: amount}();

        uint256 contractBalanceInUSD = bank.contractBalanceInUSD();
        assertEq(student1.balance, userBalance - amount);
        assertEq(bank.s_depositsCounter(), 1);
        assertEq(bank.s_vault(student1, address(0)), amount);
        assertEq(contractBalanceInUSD, amount);
    }

    error KipuBankV2_AmountExceedBalance(uint256, uint256);

    function test_withdrawFailedBecauseOfUserBalance() public processDeposit {
        uint256 complaintAmount = 1 * 10 ** 15;
        uint256 exceedingAmount = 1 * 10 ** 18;

        vm.prank(student1);
        vm.expectRevert(abi.encodeWithSelector(KipuBankV2_AmountExceedBalance.selector, complaintAmount, 0));
        bank.withdrawEther(complaintAmount);

        vm.prank(Barba);
        vm.expectRevert(
            abi.encodeWithSelector(KipuBankV2_AmountExceedBalance.selector, exceedingAmount, exceedingAmount)
        );
        bank.withdrawEther(exceedingAmount);

        assertEq(bank.s_withdrawsCounter(), 0);
        assertEq(bank.s_vault(Barba, address(0)), exceedingAmount);
        assertEq(bank.contractBalanceInUSD(), exceedingAmount);
    }

    event KipuBankV2_SuccessfullyWithdrawn(address, uint256);

    function test_WithdrawSucceed() public processDeposit {
        uint256 complaintAmount = 1 * 10 ** 15;
        uint256 amountAfterWithdrawal = 1 * 10 ** 18 - complaintAmount;

        vm.prank(Barba);
        vm.expectEmit();
        emit KipuBankV2_SuccessfullyWithdrawn(Barba, complaintAmount);
        bank.withdrawEther(complaintAmount);

        assertEq(bank.s_withdrawsCounter(), 1);
        assertEq(bank.s_vault(Barba, address(0)), amountAfterWithdrawal);
        assertEq(bank.contractBalanceInUSD(), amountAfterWithdrawal);
    }
}
