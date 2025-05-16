//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/*///////////////////////
        Imports
///////////////////////*/
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ETHDevPackNFT} from "src/m3-projects/ETHDevPackNFT.sol";

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
 * @title Contrato Donations
 * @notice Esse é um contrato para fins educacionais.
 * @author i3arba - 77 Innovation Labs
 * @custom:security Não use em produção.
 */
contract DonationsV2 is Ownable {
    /*///////////////////////
        TYPE DECLARATIONS
    ///////////////////////*/
    using SafeERC20 for IERC20;

    /*///////////////////////
    Variables
    ///////////////////////*/
    ///@notice immutable variable to store the USDC address
    IERC20 immutable i_usdc;
    ///@notice immutable variable to store the EDP's NFT
     ETHDevPackNFT immutable i_edp;

    ///@notice constant variable to store Data Feeds Heartbeat
    uint256 constant ORACLE_HEARTBEAT = 3600;
    ///@notice constant variable to store the decimals factor
    uint256 constant DECIMAL_FACTOR = 1 * 10 ** 20;
    ///@notice constant variable to store the reward threshold
    uint32 constant REWARD_THRESHOLD = 1000*10**6;

    ///@notice variable to store Chainlink Feeds address
    AggregatorV3Interface public s_feeds; //0x694AA1769357215DE4FAC081bf1f309aDC325306 Ethereum ETH/USD
    ///@notice mapping para armazenar o valor doado por usuário
    mapping(address usuario => uint256 valor) public s_doacoes;

    /*///////////////////////
    Events
    ////////////////////////*/
    ///@notice evento emitido quando uma nova doação é feita
    event DonationsV2_DoacaoRecebida(address doador, uint256 valor);
    ///@notice evento emitido quando um saque é realizado
    event DonationsV2_SaqueRealizado(address recebedor, uint256 valor);
    ///@notice event emitted when the Chainlink Feed is updated
    event DonationsV2_ChainlinkFeedUpdated(address feed);

    /*///////////////////////
    Errors
    ///////////////////////*/
    ///@notice erro emitido quando uma transação falha
    error DonationsV2_TrasacaoFalhou(bytes erro);
    ///@notice error emitted when the oracle return is wrong
    error KipuBank_OracleCompromised();
    ///@notice error emitted when the last oracle update is bigger than the heartbeat
    error KipuBank_StalePrice();

    /*///////////////////////
            Functions
    ///////////////////////*/
    constructor(address _feed, address _usdc, address _owner) Ownable(_owner) {
        s_feeds = AggregatorV3Interface(_feed);
        i_usdc = IERC20(_usdc);
        i_edp = new ETHDevPackNFT(_owner, _owner, address(this));
    }

    /**
     * @notice função para receber doações
     * @dev essa função deve somar o valor doado por cada endereço no decorrer do tempo
     * @dev essa função precisa emitir um evento informando a doação.
     */
    function doeETH() external payable {
        uint256 amountDonatedInUSD = convertEthInUSD(msg.value);

        s_doacoes[msg.sender] = s_doacoes[msg.sender] + amountDonatedInUSD;

        emit DonationsV2_DoacaoRecebida(msg.sender, amountDonatedInUSD);

        if(s_doacoes[msg.sender] > REWARD_THRESHOLD && i_edp.balanceOf(msg.sender) == 0 ){
            _mintRewardNFT(msg.sender);
        }
    }

    /**
     * @notice external function to receive native deposits
     * @notice Emit an event when deposits succeed.
     * @param _usdcAmount the amount to be donated
     */
    function doeUSDC(uint256 _usdcAmount) external {
        s_doacoes[msg.sender] += _usdcAmount;

        emit DonationsV2_DoacaoRecebida(msg.sender, _usdcAmount);

        i_usdc.safeTransferFrom(msg.sender, address(this), _usdcAmount);
        
        if(s_doacoes[msg.sender] > REWARD_THRESHOLD && i_edp.balanceOf(msg.sender) == 0 ){
            _mintRewardNFT(msg.sender);
        }
    }

    /**
     * @notice função para saque do valor das doações
     * @notice o valor do saque deve ser o valor da nota enviada
     * @dev somente o beneficiário pode sacar
     */
    function saque() external onlyOwner {
        uint256 ethBalance = address(this).balance;
        uint256 usdcBalance = i_usdc.balanceOf(address(this));

        if (ethBalance > 0) {
            emit DonationsV2_SaqueRealizado(msg.sender, ethBalance);

            _transferirEth(ethBalance);
        }
        if (usdcBalance > 0) {
            emit DonationsV2_SaqueRealizado(msg.sender, usdcBalance);

            i_usdc.safeTransfer(msg.sender, usdcBalance);
        }
    }

    /**
     * @notice function to update the Chainlink Price Feed
     * @param _feed the new Price Feed address
     * @dev must only be called by the owner
     */
    function setFeeds(address _feed) external onlyOwner {
        s_feeds = AggregatorV3Interface(_feed);

        emit DonationsV2_ChainlinkFeedUpdated(_feed);
    }

    /**
     * @notice internal function to perform decimals conversion from ETH to USDC
     * @param _ethAmount the amount of ETH to be converted
     * @return convertedAmount_ the calculations result.
     */
    function convertEthInUSD(uint256 _ethAmount) internal view returns (uint256 convertedAmount_) {
        convertedAmount_ = (_ethAmount * chainlinkFeed()) / DECIMAL_FACTOR;
    }

    /**
     * @notice function to query the USD price of ETH
     * @return ethUSDPrice_ the price provided by the oracle.
     * @dev this is a simplified implementation, and it's not fully best practices compliant
     */
    function chainlinkFeed() internal view returns (uint256 ethUSDPrice_) {
        (, int256 ethUSDPrice,, uint256 updatedAt,) = s_feeds.latestRoundData();

        if (ethUSDPrice == 0) revert KipuBank_OracleCompromised();
        if (block.timestamp - updatedAt > ORACLE_HEARTBEAT) revert KipuBank_StalePrice();

        ethUSDPrice_ = uint256(ethUSDPrice);
    }

    /**
     * @notice função privada para realizar a transferência do ether
     * @param _valor O valor à ser transferido
     * @dev precisa reverter se falhar
     */
    function _transferirEth(uint256 _valor) private {
        (bool sucesso, bytes memory erro) = msg.sender.call{value: _valor}("");
        if (!sucesso) revert DonationsV2_TrasacaoFalhou(erro);
    }

    /**
     * @notice private function to reward benefactors with a unique NFT
     * @param _user the address to receive the NFT
    */
    function _mintRewardNFT(address _user) private {
        i_edp.safeMint(_user);
    }
}
