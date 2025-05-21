# Process

1. Create file
2. Add Layout
3. Install OZ
4. Install Uniswap dependencies
    - forge install Uniswap/swap-router-contracts --no-commit
    - forge install uniswap/v4-periphery --no-commit
    - forge install uniswap/permit2 --no-commit
    - forge install uniswap/universal-router --no-commit
    - forge install uniswap/v3-core --no-commit
    - forge install uniswap/v2-core --no-commit
    - forge install OpenZeppelin/openzeppelin-contracts --no-commit
5. Update remappings
    - @openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/
    - @swap/contracts/=lib/swap-router-contracts/contracts/
    - @uniswap/v4-periphery/=lib/v4-periphery/
    - @uniswap/permit2/=lib/permit2/
    - @uniswap/universal-router/=lib/universal-router/
    - @uniswap/v3-core/=lib/v3-core/
    - @uniswap/v2-core/=lib/v2-core/
6. Import Contracts
    - import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
    - import {SafeERC20}  from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
    - import {IV3SwapRouter} from "@swap/contracts/interfaces/IV3SwapRouter.sol";
    - import { UniversalRouter } from "@uniswap/universal-router/contracts/UniversalRouter.sol";
    - import { Commands } from "@uniswap/universal-router/contracts/libraries/Commands.sol";
    - import { Actions } from "@uniswap/v4-periphery/src/libraries/Actions.sol";
    - import { IPermit2 } from "@uniswap/permit2/src/interfaces/IPermit2.sol";



# Configurar a chave SSH com o GitHub
Verifique se tem uma chave SSH:
```
    ls ~/.ssh/id_rsa.pub
```

Se não tiver:
```
    ssh-keygen -t rsa -b 4096 -C "seu-email@exemplo.com"
```

Adicione a chave ao seu agente:
```
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_rsa
```

Copie a chave pública:
```
    pbcopy < ~/.ssh/id_rsa.pub
```

Vá até https://github.com/settings/keys, clique em "New SSH key", cole e salve.

Teste a conexão:
ssh -T git@github.com

Se aparecer algo como "Hi yourusername! You've successfully authenticated...", deu certo.
