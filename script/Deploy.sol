// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/TokenVestingFactory.sol";
import "../src/TokenVesting.sol";

contract Deploy is Script {

    // Command line input
    // forge script script/Deploy.sol \
    // --rpc-url $TESTNET_RPC_URL \ 
    // --etherscan-api-key $SONICSCAN_API_KEY \
    // --verify -vvvv --slow --broadcast --interactives 1

    function run() external {
        
        vm.startBroadcast();

        address TREASURY = vm.envAddress("TREASURY");
        address OWNER = vm.envAddress("OWNER");

        TokenVesting lockerImplementation = new TokenVesting();

        TokenVestingFactory factory = new TokenVestingFactory(
            address(lockerImplementation),
            TREASURY,
            OWNER,
            10e18 // 10 S
        );

        factory.unpause();

        console.log("Token Vesting Implementation deployed at: ", address(lockerImplementation));
        console.log("Token Vesting Factory deployed at: ", address(factory));

        vm.stopBroadcast();
    }
}