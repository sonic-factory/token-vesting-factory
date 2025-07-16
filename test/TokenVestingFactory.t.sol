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

        // Give user some ETH for testing
        vm.deal(user, 10e18); // 10 ETH to user
    }

    function test_initialization() public view {
        assertEq(factory.lockerImplementation(), address(vesting), "Locker implementation should match");
        assertEq(factory.treasury(), owner, "Treasury should be the owner");
        assertEq(factory.creationFee(), 1e18, "Creation fee should be 1 ETH");
        assertEq(factory.getTotalLockers(), 0, "Initial locker counter should be zero");
    }

    function test_createLocker_isNative() public {
        uint256 creationFee = factory.creationFee();
        uint256 ethAmount = 1e18; // 1 ETH
        uint64 startTimestamp = uint64(block.timestamp + 1 days);
        uint64 durationSeconds = 1 days;

        // Create a locker with native tokens
        vm.prank(user);
        TokenVesting locker = TokenVesting(factory.createLocker{value: creationFee + ethAmount}(
            startTimestamp, 
            durationSeconds, 
            true, 
            address(0), 
            ethAmount
        ));

        // Check the locker information
        assertEq(locker.start(), startTimestamp, "Start timestamp should match");
        assertEq(locker.duration(), durationSeconds, "Duration should match");
        assertEq(locker.owner(), user, "Locker owner should be the user");
        assertEq(address(locker).balance, 1e18, "Locker balance should be 1 ETH");
    }

    function test_createLocker_isNotNative() public {
        uint256 creationFee = factory.creationFee();
        uint256 tokenAmount = 1e18; // 1 token
        uint64 startTimestamp = uint64(block.timestamp + 1 days);
        uint64 durationSeconds = 1 days;
        token.mint(user, 10e18); // Mint tokens to user

        // Create a locker with ERC20 tokens
        vm.startPrank(user);
        token.approve(address(factory), 1e18); // Approve the factory to spend tokens
        TokenVesting locker = TokenVesting(factory.createLocker{value: creationFee}(
            startTimestamp, 
            durationSeconds, 
            false, 
            address(token), 
            tokenAmount
        ));
        vm.stopPrank();

        // Check the locker information
        assertEq(locker.start(), startTimestamp, "Start timestamp should match");
        assertEq(locker.duration(), durationSeconds, "Duration should match");
        assertEq(locker.owner(), user, "Locker owner should be the user");
        assertEq(token.balanceOf(address(locker)), 1e18, "Locker should hold 1 token");
    }
    
    
}