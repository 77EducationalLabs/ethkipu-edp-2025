///SPDX-License_Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title Contrato Mensagem
 * @author i3arba - 77 Innovation Labs
 * @notice Esse contrato é parte do primeiro projeto
 * 			do Ethereum Developer Pack
 * @custom:security Esse é um contrato educacional
 * 					e não deve ser usado em produção
 */
contract Mensagem {
    /*////////////////////////
         State Variables
    ////////////////////////*/
    ///@notice variável para armazenar mensagens
    string s_mensagem;

    /*////////////////////////
    		Eventos
    ////////////////////////*/
    ///@notice evento emitido quando a mensagem é atualizada
    event Mensagem_MensagemAtualizada(string mensagem);

    /*////////////////////////
    		Funções
    ////////////////////////*/
    /**
     * @notice Função utilizada para armazenar uma mensagem na blockchain
     * @param _mensagem input do tipo string
     */
    function setMensagem(string memory _mensagem) external {
        s_mensagem = _mensagem;

        emit Mensagem_MensagemAtualizada(_mensagem);
    }

    /**
     * @notice função get para retornar a mensagem armazenada
     * @return _mensagem armazenada
     */
    function getMensagem() public view returns (string memory mensagem_) {
        mensagem_ = s_mensagem;
    }
}
