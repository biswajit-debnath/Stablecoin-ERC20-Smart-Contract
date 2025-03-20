// SPDX-Licence-Identifier: MIT

pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {StableCoin} from "../src/StableCoin.sol";
import {SCEngine} from "../src/SCEngine.sol";



contract Deploy is Script {
    function run() external returns(StableCoin, SCEngine) {

        address[] memory allowedCollateral = new address[](1);
        address[] memory priceFeedAddresses;

        allowedCollateral[0] = (address(1));
        priceFeedAddresses[0] = (address(2));


        vm.startBroadcast();
        StableCoin stableCoin = new StableCoin();
        
        SCEngine scEngine = new SCEngine(stableCoin, allowedCollateral, priceFeedAddresses);
        vm.stopBroadcast();

        return(stableCoin, scEngine);
    }
}