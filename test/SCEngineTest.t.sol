// SPDX-Licence-Identifier: MIT

pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {StableCoin} from "../script/Deploy.s.sol";
import {StableCoin} from "../src/StableCoin.sol";
import {SCEngine} from "../src/SCEngine.sol";
import {SCEngineMock} from "./mock/SCEngineMock.t.sol";
import {Deploy} from "../script/Deploy.s.sol";

contract SCEngineTest is Test {

    StableCoin stableCoin;
    SCEngine scEngine;

    function setUp() external {
        Deploy deployer = new Deploy();
        (stableCoin, scEngine) = deployer.run();
    }

}