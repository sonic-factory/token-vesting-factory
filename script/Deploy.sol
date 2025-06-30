// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/LiquidityLockerFactory.sol";
import "../src/LiquidityLocker.sol";

contract Deploy is Script {

    // Command line input
    // forge script script/Deploy.sol \
    // --sig "run(address,address)" \
    // $INITIAL_OWNER $INITIAL_OWNER \
    // --rpc-url $TESTNET_RPC_URL \ 
    // --etherscan-api-key $SONICSCAN_API_KEY \
    // --verify -vvvv --slow --broadcast --interactives 1

    function run(address _treasury, address _owner) external {
        
        vm.startBroadcast();

        LiquidityLocker lockerImplementation = new LiquidityLocker();

        LiquidityLockerFactory factory = new LiquidityLockerFactory(
            address(lockerImplementation),
            _treasury,
            _owner,
            10e18 // 10 S
        );

        console.log("Locker Implementation deployed at: ", address(lockerImplementation));
        console.log("Locker Factory deployed at: ", address(factory));

        vm.stopBroadcast();
    }
}