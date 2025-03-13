// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {StableCoin} from "./StableCoin.sol";

contract SCEngine {
    /* Errors */
    error SCEngine__CollateralDepositAmountMustBeMoreThanZero();
    error SCEngine__TokenTypeNotApprovedForCollateral(address token);
    error SCEngine__TransferFailed();
    error SCEngine__mintingAmountMustBeMoreThanZero();

    /* Events */
    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);

    /* State Variables */
    StableCoin private immutable i_scoin;
    mapping(address => bool) private s_allowedTokens;
    mapping(address => mapping(address => uint256)) private s_userCollateralBalances;
    mapping(address => uint256) private s_userSCoinBalance;


    constructor(StableCoin _scoinAddress) {
        i_scoin = StableCoin(_scoinAddress);
    }

    function depositCollateral(address _collateralType, uint256 _amountCollateral) external {
        if (_amountCollateral <= 0) {
            revert SCEngine__CollateralDepositAmountMustBeMoreThanZero();
        }
        if (!s_allowedTokens[_collateralType]) {
            revert SCEngine__TokenTypeNotApprovedForCollateral(_collateralType);
        }
        s_userCollateralBalances[msg.sender][_collateralType] += _amountCollateral;
        emit CollateralDeposited(msg.sender, _collateralType, _amountCollateral);
        
        bool success = IERC20(_collateralType).transferFrom(msg.sender, address(this), _amountCollateral);
        if (!success) revert SCEngine__TransferFailed();
    }

    function mintSCoin(uint256 _amountToMint) external {
        if (_amountToMint <= 0) {
            revert SCEngine__mintingAmountMustBeMoreThanZero();
        }

        s_userSCoinBalance[msg.sender] += _amountToMint;
        
        revertIfHealthFactorBroken();

        // Mint the sCoin to the user
        i_scoin.mint(msg.sender, _amountToMint);

    }


    function revertIfHealthFactorBroken() internal view {
        // Get the user's health factor
        // If it's broken, revert
    }

}