// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./TokenVesting.sol";

/**
 * @notice This is a factory for creating TokenVesting contracts.
 * @dev Proxy implementation are Clones. Implementation is immutable and not upgradeable.
 */
contract TokenVestingFactory is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Information of each locker
    struct LockerInfo {
        address lockerAddress;
        address creator;
        uint64 startTimestamp;
        uint64 durationSeconds;
        uint256 lockerId;
    }

    /// @notice The address of the locker implementation contract.
    address public immutable lockerImplementation;
    /// @notice The address of the treasury where the fees are sent.
    address public treasury;

    /// @notice The fee to create a new locker.
    uint256 public creationFee;
    /// @notice The number of lockers created.
    uint256 internal lockerCounter;

    /// @notice Mapping from locker ID to locker address.
    mapping(uint256 lockerId => address lockerAddress) internal IdToAddress;
    /// @notice Mapping from creator address to their locker addresses.
    mapping(address creator => address[] lockers) internal creatorToLockers;
    /// @notice Mapping from locker address to its registry information.
    mapping(address locker => LockerInfo info) internal lockerInfo;

    /// @notice Emitted when a new locker is created.
    event LockerCreated(
        address indexed locker, 
        address indexed creator,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint256 indexed lockerId
    );
    /// @notice Emitted when the treasury address is updated.
    event TreasuryUpdated(address treasury);
    /// @notice Emitted when the creation fee is updated.
    event CreationFeeUpdated(uint256 creationFee);

    /// @notice Thrown when the address set is zero
    error ZeroAddress();
    /// @notice Thrown when the payable amount is zero
    error IncorrectFee();

    /**
     * @notice Constructor arguments for the locker factory.
     * @param _lockerImplementation This is the address of the locker to be cloned.
     * @param _treasury The multi-sig or contract address where the fees are sent.
     * @param _owner The owner of the factory contract.
     * @param _creationFee The amount to collect for every contract creation.
    */
    constructor(
        address _lockerImplementation,
        address _treasury,
        address _owner,
        uint256 _creationFee
    ) Ownable (_owner) {
        require(
            _lockerImplementation != address(0) && 
            _treasury != address(0) &&
            _owner != address(0),
            ZeroAddress()
        );

        lockerImplementation = _lockerImplementation;
        treasury = _treasury;
        creationFee = _creationFee;

        _pause();
    }

    receive() external payable {}

    /**
     * @notice This function is called to create a new token vesting contract (locker).
     * @param _startTimestamp The timestamp when the vesting starts.
     * @param _durationSeconds The duration in seconds for which the tokens will be vested.
    */
    function createLocker(
        uint64 _startTimestamp,
        uint64 _durationSeconds
    ) external payable whenNotPaused nonReentrant returns (address payable locker) {

        lockerCounter = lockerCounter + 1;

        locker = payable(Clones.clone(lockerImplementation));

        TokenVesting(locker).initialize(
            msg.sender,
            _startTimestamp,
            _durationSeconds
        );

        IdToAddress[lockerCounter] = locker;
        creatorToLockers[msg.sender].push(locker);

        lockerInfo[locker] = LockerInfo({
            lockerAddress: locker,
            creator: msg.sender,
            startTimestamp: _startTimestamp,
            durationSeconds: _durationSeconds,
            lockerId: lockerCounter
        });

        emit LockerCreated(locker, msg.sender, _startTimestamp, _durationSeconds, lockerCounter);
    }

    /// @notice This function sets the treasury address.
    /// @param _treasury The address of the treasury to set.
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), ZeroAddress());

        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    /// @notice This function sets the creation fee.
    /// @param _creationFee The amount to set as the creation fee.
    function setCreationFee(uint256 _creationFee) external onlyOwner {       
        creationFee = _creationFee;
        emit CreationFeeUpdated(_creationFee);
    }

    /// @notice This function allows the owner to collect the contract balance.
    function collectFees() external onlyOwner {
        (bool success, ) = treasury.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }

    /// @notice This function allows the owner to collect foreign tokens sent to the contract.
    /// @param token The address of the token to collect.
    function collectTokens(address token) external onlyOwner {
        IERC20(token).safeTransfer(treasury, IERC20(token).balanceOf(address(this)));
    }

    /// @notice This function allows the owner to pause the contract.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice This function allows the owner to unpause the contract.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Get the total number of lockers created.
    function getTotalLockers() external view returns (uint256) {
        return lockerCounter;
    }

    /// @notice  Get the locker address by its ID.
    /// @param lockerId The ID of the locker to retrieve.
    function getLockerById(uint256 lockerId) external view returns (address) {
        return IdToAddress[lockerId];
    }

    /// @notice Get all lockers created by a specific creator.
    /// @param creator The address of the creator to retrieve lockers for.
    function getLockersByCreator(address creator) external view returns (address[] memory) {
        return creatorToLockers[creator];
    }

    /// @notice Get the locker information by its address.
    /// @param locker The address of the locker to retrieve information for.
    function getLockerInfo(address locker) external view returns (LockerInfo memory) {
        return lockerInfo[locker];
    }

    /// @notice Validates if the locker address is valid.
    /// @param locker The address of the locker to validate.
    function isValidLocker(address locker) external view returns (bool) {
        return locker != address(0) && lockerInfo[locker].lockerAddress == locker;
    }
}