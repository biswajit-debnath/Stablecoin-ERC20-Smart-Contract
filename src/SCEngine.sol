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

    StableCoin private immutable i_scoin;
    mapping(address => bool) private s_allowedTokens;
    mapping(address => mapping(address => uint256)) private s_userCollateralBalances;
    mapping(address => uint256) private s_userSCoinBalance;
    mapping(address => address) private s_collateralToPriceFeeds;

    


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


    function revertIfHealthFactorBroken() internal {
        // Get the user's health factor
        uint256 userHealthFactor = getHealthFactor();
        // If it's broken, revert
        if (userHealthFactor < 1) {
            revert SCEngine__HealthFactorIsBroken();
        }
    }

    function getHealthFactor() public returns(uint256) {
        // Get the current token minted to user
        uint256 totalTokensMinted = s_userSCoinBalance[msg.sender];

        // Get the total collateral deposited in dollars
        uint256 totalCollateralVal = getUserTotalCollateralValInDollars();

        // Convert token amount to Wei precision (1e18)
        uint256 tokenValueInWei = totalTokensMinted * PRECISION_FACTOR;

        // Apply the threshold multiplier (150%)
        uint256 adjustedForThreshold = tokenValueInWei * THRESHOLD_VALUE_FOR_HEALTH_FACTOR;

        // Adjust by threshold precision (divide by 100 to get actual percentage)
        uint256 collateralNeededAdjustingThreshold = adjustedForThreshold / THRESHOLD_PRECISION_VALUE_FOR_HEALTH_FACTOR;

        return collateralNeededAdjustingThreshold;
    }


    function getValueOfGivenCollateralInDollar(address _collateralAddress) public returns(uint256) {
        // Get total amount of collateral deposited by the user based on the colleteral address
        uint256 totalCollateralAmount = s_userCollateralBalances[_collateralAddress];
        uint256 collateralAmountInWei = totalCollateralAmount * PRECISION_FACTOR;

        // Get the price feed address based on collateral address
        address priceFeedAddress = s_collateralToPriceFeeds[_collateralAddress];

        // Get the price feed data from Chainlink price feed
        (, int256 price,,,) = AggregatorV3Interface(priceFeedAddress).latestRoundData();

        uint256 normalizedPrice = uint256(price) * PRICE_FEED_PRECISION;

        // Multiple the price feed value with the total amount to the total value
        uint256 totalValue = collateralAmountInWei * normalizedPrice;
        uint256 adjustedCollateralValue = totalValue / PRECISION_FACTOR;

        return adjustedCollateralValue;
    }

}