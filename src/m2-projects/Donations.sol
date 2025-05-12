//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title Contrato Donations
 * @author i3arba - 77 Innovation Labs
 * @notice Esse contrato é parte do primeiro projeto
 * 			do Ethereum Developer Pack
 * @custom:security Esse é um contrato educacional
 * 					e não deve ser usado em produção
 */
contract Donations {
    /*///////////////////////
    	    Variables
    ///////////////////////*/
    ///@notice variável imutável para armazenar o endereço que deve sacar as doações
    address immutable i_beneficiario;

    ///@notice mapping para armazenar o valor doado por usuário
    mapping(address usuario => uint256 valor) public s_doacoes;

    /*///////////////////////
    		Events
    ////////////////////////*/
    ///@notice evento emitido quando uma nova doação é feita
    event Donations_DoacaoRecebida(address doador, uint256 valor);
    ///@notice evento emitido quando um saque é realizado
    event Donations_SaqueRealizado(address recebedor, uint256 valor);

    /*///////////////////////
    		Errors
    ///////////////////////*/
    ///@notice erro emitido quando uma transação falha
    error Donations_TrasacaoFalhou(bytes erro);
    ///@notice erro emitido quando um endereço diferente do beneficiario tentar sacar
    error Donations_SacadorNaoPermitido(address chamador, address beneficiario);

    /*///////////////////////
    	    Functions
    ///////////////////////*/
    constructor(address _beneficiario) {
        i_beneficiario = _beneficiario;
    }

    ///@notice função para receber ether diretamente
    receive() external payable {}
    fallback() external {}

    /**
     * @notice função para receber doações
     * @dev essa função deve somar o valor doado por cada endereço no decorrer do tempo
     * @dev essa função precisa emitir um evento informando a doação.
     */
    function doe() external payable {
        s_doacoes[msg.sender] = s_doacoes[msg.sender] += msg.value;

        emit Donations_DoacaoRecebida(msg.sender, msg.value);
    }

    /**
     * @notice função para saque do valor das doações
     * @notice o valor do saque deve ser o valor da nota enviada
     * @dev somente o beneficiário pode sacar
     * @param _id O ID da nota fiscal
     * @param _valor O valor da nota fiscal
     */
    function saque(uint256 _valor) external {
        if (msg.sender != i_beneficiario) revert Donations_SacadorNaoPermitido(msg.sender, i_beneficiario);

        emit Donations_SaqueRealizado(msg.sender, _valor);

        _transferirEth(_valor);
    }

    /**
     * @notice função privada para realizar a transferência do ether
     * @param _valor O valor à ser transferido
     * @dev precisa reverter se falhar
     */
    function _transferirEth(uint256 _valor) private {
        (bool sucesso, bytes memory erro) = msg.sender.call{value: _valor}("");
        if (!sucesso) revert Donations_TrasacaoFalhou(erro);
    }
}
