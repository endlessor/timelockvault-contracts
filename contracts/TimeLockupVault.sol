// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./MultiSig.sol";

/// @title TimeLockupVault
/// @notice You can use this contract to lockup your funds for a predetermined amount of time with no way to withdraw.
/// @dev Use TimeLockupMultiSigVault if you would like to be able to override the timelock with the approval of some trusted friends/addresses.
contract TimeLockupVault is Ownable {
    /// @notice Amount of time between a deposit and withdraw in seconds.
    uint256 public timelock;

    /// @dev Maps the time in seconds since unix epoch when every deposit was made with the amount of wei that was deposited at that time.
    mapping(uint256 => uint256) internal deposits;

    /// @dev Array of all timestamps that were or still are mapped to amounts in the `deposits` map.
    uint256[] internal timeKeys;

    /// @notice Constructor that sets the timelock for all deposits.
    /// @param _timelock The amount of seconds that a deposit should be locked up before it can be withdrawn.
    constructor(uint256 _timelock) {
        timelock = _timelock;
    }

    /// @dev Gets the balance in wei for a deposit.
    /// @param timeKey The timestamp of the deposit.
    /// @return Amount in wei deposited at this timestamp. Can be 0.
    function getBalanceForTimeKey(uint256 timeKey)
        internal
        view
        returns (uint256)
    {
        return deposits[timeKey];
    }

    /// @dev Gets the amount of seconds left on a deposit.
    /// @param timeKey The timestamp of the deposit.
    /// @return The seconds left on the timestamp at this deposit. Will stop at 0.
    function getSecondsLeftOnTimeKey(uint256 timeKey)
        internal
        view
        returns (uint256)
    {
        require(
            getBalanceForTimeKey(timeKey) > 0,
            "This timeKey does not have a deposit associated with it!"
        );

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

    /// @dev Sends the amount of eth deposited at a timestamp to the sender.
    /// @param timeKey The timestamp of the deposit.
    function _withdrawMaxFromTimeKey(uint256 timeKey) internal {
        delete deposits[timeKey];
        msg.sender.transfer(getBalanceForTimeKey(timeKey));
    }

    /// @dev Sends all eth in the contract to the sender and empties all the timeKeys (deposits mapped to amounts).
    /// @param validateSeconds If true the function will check that the timelock has expired on the deposit, if false it will ignore the timelock and send the eth anyway.
    function _withdrawMax(bool validateSeconds) internal {
        for (uint256 i = 0; i < timeKeys.length; i++) {
            uint256 timeKey = timeKeys[i];
            if (
                getBalanceForTimeKey(timeKey) > 0 &&
                (validateSeconds ? getSecondsLeftOnTimeKey(timeKey) == 0 : true)
            ) {
                _withdrawMaxFromTimeKey(timeKey);
            }
        }
    }

    /// @notice Withdraws the max amount of withdrawable eth (deposits that have expired timelocks) from the contract.
    function withdraw() external onlyOwner {
        _withdrawMax({validateSeconds: true});
    }

    receive() external payable {
        timeKeys.push(block.timestamp);
        deposits[block.timestamp] = msg.value;
    }
}
