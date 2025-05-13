///SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol){}

    function mint(address _account, uint256 _value) external {
        _mint(_account, _value);
    }

    function decimals() public view override returns(uint8) {
        return 6;
    }
}