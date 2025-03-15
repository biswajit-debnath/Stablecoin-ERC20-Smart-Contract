// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {StableCoin} from "./StableCoin.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract SCEngine {
    /* Errors */
    error SCEngine__CollateralDepositAmountMustBeMoreThanZero();
    error SCEngine__TokenTypeNotApprovedForCollateral(address token);
    error SCEngine__TransferFailed();
    error SCEngine__mintingAmountMustBeMoreThanZero();
    error SCEngine__HealthFactorIsBroken();

    /* Events */
    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);

    /* State Variables */
    uint256 private constant THRESHOLD_VALUE_FOR_HEALTH_FACTOR = 150;
    uint256 private constant THRESHOLD_PRECISION_VALUE_FOR_HEALTH_FACTOR = 100;
    uint256 private constant PRECISION_FACTOR = 1e18;
    uint256 private constant PRICE_FEED_PRECISION = 1e10;
    uint256 private constant MINIMUM_HEALTH_FACTOR = 1e18;


    StableCoin private immutable i_scoin;
    address[] private s_allowedCollateral;
    mapping(address => mapping(address => uint256)) private s_userCollateralBalances;
    mapping(address => uint256) private s_userSCoinBalance;
    mapping(address => address) private s_collateralToPriceFeeds;

    


    constructor(StableCoin _scoinAddress) {
        i_scoin = StableCoin(_scoinAddress);

        // to do: handle adding collateral addresses to s_allowedCollateral
    }



    /* Internal Functions */
    function _revertIfHealthFactorBroken() internal {
        // Get the user's health factor
        uint256 userHealthFactor = _healthFactor(msg.sender);
        // If it's broken, revert
        if (userHealthFactor < MINIMUM_HEALTH_FACTOR) {
            revert SCEngine__HealthFactorIsBroken();
        }
    }

    function _healthFactor(address user) public returns(uint256) {
        // Get the current token minted to user
        uint256 totalTokensMinted = s_userSCoinBalance[user];

        // Get the total collateral deposited in dollars
        uint256 totalCollateralValOfUser = getUserTotalCollateralValInDollars();

        // Convert token amount to Wei precision (1e18)
        uint256 tokenValueInWei = totalTokensMinted * PRECISION_FACTOR;

        // Apply the threshold multiplier (150%)
        uint256 adjustedForThreshold = tokenValueInWei * THRESHOLD_VALUE_FOR_HEALTH_FACTOR;

        // Adjust by threshold precision (divide by 100 to get actual percentage)
        uint256 collateralNeededAdjustingThreshold = adjustedForThreshold / THRESHOLD_PRECISION_VALUE_FOR_HEALTH_FACTOR;

        uint256 healthFactor = (totalCollateralValOfUser / collateralNeededAdjustingThreshold) * PRECISION_FACTOR;

        return healthFactor;
    }

    function _collateralValueInDollarByCollateralAddress(address _collateralAddress) public returns(uint256) {
        // Get total amount of collateral deposited by the user based on the colleteral address
        uint256 totalCollateralAmountInWei = s_userCollateralBalances[msg.sender][_collateralAddress]; // e: Check if the user has not deposited any amount on this collateral what will happen, will the totalCollateralAmount be considered 0 

        // Get the price feed address based on collateral address
        address priceFeedAddress = s_collateralToPriceFeeds[_collateralAddress];

        // Get the price feed data from Chainlink price feed
        (, int256 price,,,) = AggregatorV3Interface(priceFeedAddress).latestRoundData(); // to do: test this by defaulting to 3500 e10 

        uint256 normalizedPrice = uint256(price) * PRICE_FEED_PRECISION;

        // Multiple the price feed value with the total amount to the total value
        uint256 totalValue = totalCollateralAmountInWei * normalizedPrice; 

        uint256 adjustedCollateralValue = totalValue / PRECISION_FACTOR;

        return adjustedCollateralValue;
    }


    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    // External & Public View & Pure Functions
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    function depositCollateral(address _collateralType, uint256 _amountCollateral) external {
        if (_amountCollateral <= 0) {
            revert SCEngine__CollateralDepositAmountMustBeMoreThanZero();
        }
        // if (!s_allowedCollateral[_collateralType]) {
        //     revert SCEngine__TokenTypeNotApprovedForCollateral(_collateralType);
        // } // to do: this needs to be modifier and needs to handle array instead of mapping
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
        
        _revertIfHealthFactorBroken();

        i_scoin.mint(msg.sender, _amountToMint);
    }

    function getUserTotalCollateralValInDollars() public returns(uint256) {
        uint256 totalCollateralValue = 0;

        for(uint256 i=0; i<s_allowedCollateral.length; i++) {
            uint256 currentCollateralValInDollar = _collateralValueInDollarByCollateralAddress(s_allowedCollateral[i]); // e: Check if the user has not deposited any amount on this collateral what will happen, will the currentCollateralValInDollar be considered 0 
            totalCollateralValue += currentCollateralValInDollar;
        }

        return totalCollateralValue;
    }

}