// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/finance/VestingWalletUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Token Vesting
 * @notice @inheritdoc VestingWalletUpgradeable
 * 
 */
contract TokenVesting is Initializable, VestingWalletUpgradeable {
    using SafeERC20 for IERC20;

    /// @notice Thrown when the address is zero.
    error ZeroAddress();
    /// @notice Thrown when the amount is zero.
    error ZeroAmount();

    /// @notice Modifier to ensure that the amount is not zero.
    modifier nonZeroAmount(uint256 amount) {
        require(amount > 0, ZeroAmount());
        _;
    }
    /// @notice Modifier to ensure that the address is not zero.
    modifier nonZeroAddress(address addr) {
        require(addr != address(0), ZeroAddress());
        _;
    }

    /// @notice Disables the initializer function to prevent re-initialization.
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract with the given token address and unlock time.
    /// @param _asset The address of the ERC20 token to be locked in this vault.
    /// @param _unlockTime The timestamp when withdrawals will be allowed.
    /// @param _owner The address that will own the vault and be able to deposit.
    function initialize(
        address _beneficiary,
        uint64 _startTimestamp,
        uint64 _durationSeconds
    )
        public 
        initializer
        nonZeroAddress(_asset)
        nonZeroAmount(_startTimestamp)
        nonZeroAmount(_durationSeconds)
    {

        __VestingWallet_init(_beneficiary, _startTimestamp, _durationSeconds);
        __ReentrancyGuard_init();
    }
}