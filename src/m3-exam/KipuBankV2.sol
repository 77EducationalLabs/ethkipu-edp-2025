// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/*///////////////////////
        Imports
///////////////////////*/
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*///////////////////////
        Libraries
///////////////////////*/
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/*///////////////////////
        Interfaces
///////////////////////*/
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title KipuBankV2
 * @author Barba - 77 Innovation Labs
 * @dev Do not use it in production
 * @notice This is an example contract used as a parameter for the third module of the Ethereum Developer Pack - São Paulo / Brazil
 * @custom:contact anySocial/i3arba
 */
contract KipuBankV2 is Ownable {
    /*///////////////////////
        TYPE DECLARATIONS
    ///////////////////////*/
    using SafeERC20 for IERC20;

    /*///////////////////////
           VARIABLES
    ///////////////////////*/
    ///@notice immutable variable to hold the max amount the vault can store
    uint256 immutable i_bankCap;
    ///@notice immutable variable to store the USDC address
    IERC20 immutable i_usdc;

    ///@notice constant variable to hold Data Feeds Heartbeat
    uint256 constant ORACLE_HEARTBEAT = 3600;
    ///@notice constant variable to gold the decimals factor
    uint256 constant DECIMAL_FACTOR = 1 * 10 ** 20;
    ///@notice constant variable to remove magic number
    uint256 constant ZERO = 0;

    ///@notice variable to store Chainlink Feeds address
    AggregatorV3Interface public s_feeds; //0x694AA1769357215DE4FAC081bf1f309aDC325306 Ethereum ETH/USD
    ///@notice public variable to hold the number of deposits completed
    uint256 public s_depositsCounter;
    ///@notice public variable to hold the number of withdrawals completed
    uint256 public s_withdrawsCounter;

    ///@notice mapping to keep track of deposits
    mapping(address user => mapping(address token => uint256 amount)) public s_vault;

    /*///////////////////////
           EVENTS
    ///////////////////////*/
    ///@notice event emitted when a deposit is successfully completed
    event KipuBank_SuccessfullyDeposited(address user, uint256 amount);
    ///@notice event emitted when a withdrawal is successfully completed
    event KipuBank_SuccessfullyWithdrawn(address user, uint256 amount);
    ///@notice event emitted when the Chainlink Feed is updated
    event KipuBank_ChainlinkFeedUpdated(address feed);

    /*///////////////////////
            ERRORS
    ///////////////////////*/
    ///@notice error emitted when the amount to be deposited plus the contract balance exceeds the bankCap
    error KipuBank_BankCapReached(uint256 depositCap);
    ///@notice error emitted when the amount to be withdrawn is bigger than the user's balance
    error KipuBank_AmountExceedBalance(uint256 amount, uint256 balance);
    ///@notice error emitted when the native transfer fails
    error KipuBank_TransferFailed(bytes reason);
    ///@notice error emitted when the oracle return is wrong
    error KipuBank_OracleCompromised();
    ///@notice error emitted when the last oracle update is bigger than the heartbeat
    error KipuBank_StalePrice();

    /*///////////////////////
           FUNCTIONS
    ///////////////////////*/
    constructor(uint256 _bankCap, address _feed, address _owner) Ownable(_owner) {
        i_bankCap = _bankCap;
        s_feeds = AggregatorV3Interface(_feed);
    }

    modifier bankCapCheck(uint256 _usdcAmount) {
        if (contractBalanceInUSD() + _usdcAmount > i_bankCap) revert KipuBank_BankCapReached(i_bankCap);
        _;
    }

    /*//////////////////////////
            * External *
    //////////////////////////*/
    /**
     * @notice external function to receive native deposits
     * @notice Emit an event when deposits succeed.
     * @dev after the transaction contract balance should not be bigger than the bank cap
     */
    function depositEther() external payable bankCapCheck(ZERO) {
        s_depositsCounter = s_depositsCounter + 1;

        s_vault[msg.sender][address(0)] += msg.value;

        emit KipuBank_SuccessfullyDeposited(msg.sender, msg.value);
    }

    /**
     * @notice external function to receive native deposits
     * @notice Emit an event when deposits succeed.
     * @dev after the transaction contract balance should not be bigger than the bank cap
     */
    function depositUSDC(uint256 _usdcAmount) external bankCapCheck(_usdcAmount) {
        s_depositsCounter = s_depositsCounter + 1;

        s_vault[msg.sender][address(i_usdc)] += _usdcAmount;

        emit KipuBank_SuccessfullyDeposited(msg.sender, _usdcAmount);

        i_usdc.safeTransferFrom(msg.sender, address(this), _usdcAmount);
    }

    /**
     * @notice external function to process withdrawals
     * @param _amount is the amount to be withdrawn
     * @dev User must not be able to withdraw more than deposited
     * @dev User must not be able to withdraw more than the threshold per withdraw
     */
    function withdrawEther(uint256 _amount) external {
        uint256 userBalance = s_vault[msg.sender][address(0)];

        if (_amount > userBalance) revert KipuBank_AmountExceedBalance(_amount, userBalance);

        s_withdrawsCounter = s_withdrawsCounter + 1;
        s_vault[msg.sender][address(0)] -= _amount;

        _processTransfer(_amount);
    }

    /**
     * @notice external function to process withdrawals
     * @param _amount is the amount to be withdrawn
     * @dev User must not be able to withdraw more than deposited
     * @dev User must not be able to withdraw more than the threshold per withdraw
     * @custom:newfeature
     */
    function withdrawUSDC(uint256 _amount) external {
        uint256 userBalance = s_vault[msg.sender][address(i_usdc)];

        if (_amount > userBalance) revert KipuBank_AmountExceedBalance(_amount, userBalance);

        s_withdrawsCounter = s_withdrawsCounter + 1;
        s_vault[msg.sender][address(i_usdc)] -= _amount;

        emit KipuBank_SuccessfullyWithdrawn(msg.sender, _amount);

        i_usdc.safeTransfer(msg.sender, _amount);
    }

    /**
     * @notice function to update the Chainlink Price Feed
     * @param _feed the new Price Feed address
     * @dev must only be called by the owner
     * @custom:newfeature
     */
    function setFeeds(address _feed) external onlyOwner {
        s_feeds = AggregatorV3Interface(_feed);

        emit KipuBank_ChainlinkFeedUpdated(_feed);
    }

    /*//////////////////////////
            * Private *
    //////////////////////////*/
    /**
     * @notice internal function to process the ETH transfer from: contract -> to: user
     * @dev emits an event if success
     */
    function _processTransfer(uint256 _amount) private {
        emit KipuBank_SuccessfullyWithdrawn(msg.sender, _amount);

        (bool success, bytes memory data) = msg.sender.call{value: _amount}("");
        if (!success) revert KipuBank_TransferFailed(data);
    }

    /*//////////////////////////
           * Pure & View *
    //////////////////////////*/
    /**
     * @notice external view function to return the contract's balance
     * @return balance_ the amount of ETH in the contract
     * @custom:newfeature
     */
    function contractBalanceInUSD() public view returns (uint256 balance_) {
        uint256 convertedUSDAmount = convertEthInUSD(address(this).balance);

        balance_ = convertedUSDAmount + i_usdc.balanceOf(address(this));
    }

    /**
     * @notice internal function to perform decimals conversion from ETH to USDC
     * @param _ethAmount the amount of ETH to be converted
     * @return convertedAmount_ the calculations result.
     * @custom:newfeature
     */
    function convertEthInUSD(uint256 _ethAmount) internal view returns (uint256 convertedAmount_) {
        convertedAmount_ = (_ethAmount * chainlinkFeed()) / DECIMAL_FACTOR;
    }

    /**
     * @notice function to query the USD price of ETH
     * @return ethUSDPrice_ the price provided by the oracle.
     * @dev this is a simplified implementation, and it's not fully best practices compliant
     * @custom:newfeature
     */
    function chainlinkFeed() internal view returns (uint256 ethUSDPrice_) {
        (, int256 ethUSDPrice,, uint256 updatedAt,) = s_feeds.latestRoundData();

        if (ethUSDPrice == 0) revert KipuBank_OracleCompromised();
        if (block.timestamp - updatedAt > ORACLE_HEARTBEAT) revert KipuBank_StalePrice();

        ethUSDPrice_ = uint256(ethUSDPrice);
    }
}
