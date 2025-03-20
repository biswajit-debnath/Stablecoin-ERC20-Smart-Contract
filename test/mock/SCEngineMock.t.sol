// SPDX-Licence-Identifier: MIT

pragma solidity 0.8.20;

import {SCEngine} from "../../src/SCEngine.sol";
import {StableCoin} from "../../src/StableCoin.sol";


contract SCEngineMock is SCEngine{

    constructor(StableCoin _scoin, address[] memory _allowedCollaterals, address[] memory _priceFeedAddresses) SCEngine(_scoin, _allowedCollaterals, _priceFeedAddresses) {
    }

    function collateralValueInDollarByCollateralAddress(address _collateralAddress) public view returns(uint256) {
        return _collateralValueInDollarByCollateralAddress(_collateralAddress);
    }
}