// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/TokenVesting.sol";
import "../src/TokenVestingFactory.sol";
import "../test/mocks/MockERC20.sol";

contract TokenVestingTest is Test {

    TokenVestingFactory public factory;
    TokenVesting public vesting;
    MockERC20 public token;

    address public owner = makeAddr("owner");
    address public user = makeAddr("user");
    address public beneficiary = makeAddr("beneficiary");

    function setUp() public {
        // Deploy the mock ERC20 token
        token = new MockERC20("MockToken", "MOCK", 1e24); // 1 million tokens with 18 decimals

        // Deploy the protocol
        vesting = new TokenVesting();
        factory = new TokenVestingFactory(address(vesting), owner, owner, 1e18); // 1 ETH creation fee

        // Unpause the factory to allow locker creation
        vm.prank(owner);
        factory.unpause();
    }

    function test_initialization() public view {
        assertEq(factory.lockerImplementation(), address(vesting), "Locker implementation should match");
        assertEq(factory.treasury(), owner, "Treasury should be the owner");
        assertEq(factory.creationFee(), 1e18, "Creation fee should be 1 ETH");
        assertEq(factory.getTotalLockers(), 0, "Initial locker counter should be zero");
    }

    function test_createLocker_isNative() public {
        uint64 startTimestamp = uint64(block.timestamp + 1 days);
        uint64 durationSeconds = 1 days;
        vm.deal(user, 10e18);

        // Create a locker with native tokens
        vm.prank(user);
        TokenVesting locker = TokenVesting(factory.createLocker{value: 2e18}(
            startTimestamp, 
            durationSeconds, 
            true, 
            address(0), 
            1e18
        ));

        // Check the locker information
        assertEq(locker.start(), startTimestamp, "Start timestamp should match");
        assertEq(locker.duration(), durationSeconds, "Duration should match");
        assertEq(locker.owner(), user, "Locker owner should be the user");
        assertEq(address(locker).balance, 1e18, "Locker balance should be 1 ETH");
    }

    function test_createLocker_isNotNative() public {
        
    }
    
    
}