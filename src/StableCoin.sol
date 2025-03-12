// SPDX-License-Identifier: MIT

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

pragma solidity ^0.8.20;

/**
 * @title Decentralized Stablecoin
 * @author Biswajit Debnath
 * Collateral: Exogenous (wETH & wBTC)
 * Minting & burning: Algorithmic
 * Relative Stability: Pegged to USD
 *
 * This is a contract meant to be govern by StableCoinEngine. This contract is just the ERC20 token.
 */
contract StableCoin is ERC20Burnable {
    /* Errors */
    error StableCoin__MintZeroAddress();
    error StableCoin__AmountZero();
    error StableCoin__AmountZeroBurn();
    error StableCoin__BurnAmountExceedsBalance();

    constructor() ERC20("Stable Coin", "SC") {}

    function mint(address _to, uint256 _amount) external {
        if (msg.sender == address(0)) {
            revert StableCoin__MintZeroAddress();
        }
        if (_amount <= 0) {
            revert StableCoin__AmountZero();
        }
        _mint(_to, _amount);
    }

    function burn(uint256 _amount) public override {
        uint256 userCurrentBalance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert StableCoin__AmountZeroBurn();
        }
        if (userCurrentBalance < _amount) {
            revert StableCoin__BurnAmountExceedsBalance();
        }

        super.burn(_amount);
    }
}
