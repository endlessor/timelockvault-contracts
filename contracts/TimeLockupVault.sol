// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./MultiSig.sol";

/// @title TimeLockupVault
/// @notice You can use this contract to lockup your funds for a predetermined amount of time with no way to withdraw.
/// @dev Use TimeLockupMultiSigVault if you would like to be able to override the timelock with the approval of some trusted friends/addresses.
contract TimeLockupVault is Ownable {
    /// @notice Amount of seconds before a deposit can withdrawn.
    uint256 public timelock;

    /// @dev Maps the time in seconds since unix epoch when every deposit was made with the amount of wei that was deposited at that time.
    mapping(uint256 => uint256) internal deposits;

    /// @dev Array of all timestamps that were or still are mapped to amounts in the `deposits` map.
    uint256[] internal timeKeys;

    /// @notice Emitted when ETH is sent to the contract.
    event Deposit(uint256 indexed timeKey, uint256 indexed amount);

    /// @notice Emitted when any ETH is transfered out of the contract to the owner.
    event Withdraw(uint256 indexed amount);

    /// @notice Constructor that sets the timelock for all deposits.
    /// @param _timelock The amount of seconds that a deposit should be locked up before it can be withdrawn.
    constructor(uint256 _timelock) {
        timelock = _timelock;
    }

    /// @notice Get all deposit timestamps (called timeKeys).
    /// @return An array of all depositTimestamps (they may have already been withdrawn from),.
    function getTimeKeys() external view returns (uint256[] memory) {
        return timeKeys;
    }

    /// @notice Gets the balance in wei for a deposit.
    /// @param timeKey The timestamp of the deposit.
    /// @return Amount in wei deposited at this timestamp. Can be 0.
    function getBalanceForTimeKey(uint256 timeKey)
        public
        view
        returns (uint256)
    {
        return deposits[timeKey];
    }

    /// @notice Gets the amount of seconds left on a deposit.
    /// @param timeKey The timestamp of the deposit.
    /// @return The seconds left on the timestamp at this deposit. Will stop at 0.
    function getSecondsLeftOnTimeKey(uint256 timeKey)
        public
        view
        returns (uint256)
    {
        // The time doesn't matter on an empty timeKey
        if (getBalanceForTimeKey(timeKey) == 0) {
            return 0;
        }

        uint256 timePassed = block.timestamp - timeKey;

        if (timePassed > timelock) {
            return 0;
        } else {
            return timelock - (block.timestamp - timeKey);
        }
    }

    /// @notice Gets the total amount of wei in the contract.
    /// @return The total wei in the contract.
    function getDepositedAmount() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Gets the total amount of wei that is able to be withdrawn at the current moment in the contract.
    /// @return The amount of wei currently withdrawable.
    function getWithdrawableAmount() external view returns (uint256) {
        uint256 amount = 0;

        for (uint256 i = 0; i < timeKeys.length; i++) {
            uint256 timeKey = timeKeys[i];
            if (getSecondsLeftOnTimeKey(timeKey) == 0) {
                amount += getBalanceForTimeKey(timeKey);
            }
        }

        return amount;
    }

    /// @dev It will withdraw the max amount possible based on `ignoreTimelock`. It will empty the timeKeys it withdraws from (delete each timestamp from the `deposits` map).
    /// @param ignoreTimelock If true the function will withdraw all wei in the contract. If false it will withdraw from all deposits that have expired timelocks.
    function _withdrawMax(bool ignoreTimelock) internal returns (uint256) {
        uint256 amountWithdrawn = 0;
        for (uint256 i = 0; i < timeKeys.length; i++) {
            uint256 timeKey = timeKeys[i];
            uint256 timeKeyBalance = getBalanceForTimeKey(timeKey);

            if (
                // If the timeKey has any wei left in it:
                timeKeyBalance > 0 &&
                // If we are not ignoring the timelock check the timelock has expired:
                (ignoreTimelock ? true : getSecondsLeftOnTimeKey(timeKey) == 0)
            ) {
                // Empty the deposit and increase the amountWithdrawn because we will transfer everything at once at the end.
                amountWithdrawn += timeKeyBalance;
                delete deposits[timeKey];
            }
        }

        emit Withdraw(amountWithdrawn);
        msg.sender.transfer(amountWithdrawn);

        return amountWithdrawn;
    }

    /// @notice Withdraws the max amount of withdrawable eth (deposits that have expired timelocks) from the contract.
    function withdraw() external onlyOwner {
        _withdrawMax({ignoreTimelock: false});
    }

    receive() external payable {
        uint256 timeKey = block.timestamp;
        uint256 amount = msg.value;

        timeKeys.push(timeKey);
        deposits[timeKey] = amount;
        emit Deposit(timeKey, amount);
    }
}
