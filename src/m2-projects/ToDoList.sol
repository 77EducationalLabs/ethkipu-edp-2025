///SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title Contrato ToDoList
 * @author i3arba - 77 Innovation Labs
 * @notice Esse contrato é parte do primeiro projeto
 * 			do Ethereum Developer Pack
 * @custom:security Esse é um contrato educacional
 * 					e não deve ser usado em produção
 */
contract ToDoList {
    ///@notice Estrutura para armazenar informações de tarefas
    struct Tarefa {
        string descricao;
        uint256 tempoDeCricao;
    }

    ///@notice Array para Armazenar a Estrutura de Dados
    Tarefa[] public s_tarefas;

    ///@notice evento emitido quando uma nova tarefa é adicionada
    event ToDoList_TarefaAdiciona(Tarefa tarefa);
    ///@notice evento emitido quando uma tarefa é completada e removida
    event ToDoList_TarefaCompletadaERemovida(string _descricao);

    /**
     * @notice função para adicionar tarefas no storage do contrato
     * @param _descricao A descrição da tarefa que está sendo adicionada
     */
    function setTarefa(string memory _descricao) external {
        Tarefa memory tarefa = Tarefa({descricao: _descricao, tempoDeCricao: block.timestamp});

        s_tarefas.push(tarefa);

        emit ToDoList_TarefaAdiciona(tarefa);
    }

    /**
     * @notice função para remover tarefas completadas
     * @param _descricao descrição da tarefa que será removida
     */
    function deletarTarefa(string memory _descricao) external {
        uint256 tamanho = s_tarefas.length;

        //declaração aqui
        for (uint256 i = 0; i < tamanho; ++i) {
            if (keccak256(abi.encodePacked(_descricao)) == keccak256(abi.encodePacked(s_tarefas[i].descricao))) {
                // bytes32 => bytes => string

                s_tarefas[i] = s_tarefas[tamanho - 1];
                s_tarefas.pop();

                emit ToDoList_TarefaCompletadaERemovida(_descricao);
                return;
            }
        }
    }

    /**
     * @notice função retorna todas as tarefas armazenadas no array s_tarefas
     * @return tarefa_ array de tarefas
     */
    function getTarefa() external view returns (Tarefa[] memory tarefa_) {
        tarefa_ = s_tarefas;
    }
}
