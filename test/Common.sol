// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/TokenVesting.sol";
import "../src/TokenVestingFactory.sol";
import "./mocks/MockERC20.sol";

contract Common is Test {
 
    TokenVestingFactory public factory;
    TokenVesting public vesting;
    MockERC20 public token;

    address public owner = makeAddr("owner");
    address public user = makeAddr("user");
    address public beneficiary = makeAddr("beneficiary");

    function setUp() public virtual {
        // Deploy the mock ERC20 token
        token = new MockERC20("MockToken", "MOCK", 1e24); // 1 million tokens with 18 decimals

        // Deploy the protocol
        vesting = new TokenVesting();
        factory = new TokenVestingFactory(address(vesting), owner, owner, 1e18); // 1 ETH creation fee

        // Unpause the factory to allow locker creation
        vm.prank(owner);
        factory.unpause();

        // Give user some ETH for testing
        vm.deal(user, 10e18); // 10 ETH to user
    }
}