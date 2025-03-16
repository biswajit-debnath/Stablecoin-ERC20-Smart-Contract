// SPDX-Licence-Identifier: MIT

pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {StableCoin} from "../src/StableCoin.sol";
import {SCEngine} from "../src/SCEngine.sol";



contract Deploy is Script {
    function run() external returns(StableCoin, SCEngine) {

        vm.startBroadcast();
        StableCoin stableCoin = new StableCoin();
        
        SCEngine scEngine = new SCEngine(stableCoin);
        vm.stopBroadcast();

        return(stableCoin, scEngine);
    }
}