// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.7.6;

import "./TimeLockupVault.sol";
import "./MultiSig.sol";

/// @title TimeLockupMultiSigVault
/// @notice You can use this contract to lockup your funds for a predetermined amount of time while allowing you to override the timelock with the approval of a trusted group of addresses.
/// @dev Use TimeLockupVault if you want no way to withdraw until the time limit is up.
contract TimeLockupMultiSigVault is TimeLockupVault, MuliSig {
    /// @notice Constructor that sets the timelock for all deposits and sets the amount of keyholders (trusted addresses that will allow you to override the timelock) to have.
    /// @param _keyholderAmount The amount of keyholders to start with.
    /// @param _timelock Amount of seconds deposits will be locked up for (unless bypassed by keyholder's votes).
    constructor(uint256 _keyholderAmount, uint256 _timelock)
        MuliSig(_keyholderAmount)
        TimeLockupVault(_timelock)
    {}

    /// @notice Withdraws all the eth in the contract ignoring the timelock of each deposit.
    /// @notice All keyholders must attest to the string "bypass all withdraw timelocks" first.
    function withdrawMaxWithTimelockBypass() external onlyOwner {
        require(
            allKeyholdersAttest(
                MuliSig.ActionCode.ATTEST_TO_DATA,
                "bypass all withdraw timelocks"
            ),
            "All keyholders must attest first."
        );

        _withdrawMax({ignoreTimelock: true});
    }

    /// @notice Withdraws a specific amount from the contract ignroing the timelock of each deposit it withdraws from.
    /// @notice If a deposit is left partially withdrawn the same timelock will still apply to the remaining wei; it will not reset the countdown.
    /// @notice All keyholders must attest to the string "bypass withdraw timelock for amount: `amount`" first.
    /// @param amount The amount in wei to withdraw from the contract.
    function withdrawAmountWithTimelockBypass(uint256 amount)
        external
        onlyOwner
    {
        require(
            allKeyholdersAttest(
                MuliSig.ActionCode.ATTEST_TO_DATA,
                string(
                    abi.encodePacked(
                        "bypass withdraw timelock for amount: ",
                        amount
                    )
                )
            ),
            "All keyholders must attest first."
        );

        uint256 amountWithdrawn = 0;
        for (uint256 i = 0; i < timeKeys.length; i++) {
            uint256 timeKey = timeKeys[i];
            uint256 timeKeyBalance = getBalanceForTimeKey(timeKey);
            uint256 remainingToBeWithdrawn = amount - amountWithdrawn;
            // If the timeKey is not empty:
            if (timeKeyBalance > 0) {
                // If we can withdraw the max amount from this timeKey without withdrawing too much:
                if (remainingToBeWithdrawn > timeKeyBalance) {
                    deposits[timeKey] = 0;
                    amountWithdrawn += timeKeyBalance;
                } else {
                    // If withdrawing the max from this timeKey will withdraw too much, withdraw only the amount we need.
                    deposits[timeKey] = timeKeyBalance - amount;
                    amountWithdrawn += remainingToBeWithdrawn;

                    break;
                }
            }
        }

        require(
            amountWithdrawn == amount,
            "There was not enough deposited to withdraw this amount."
        );

        msg.sender.transfer(amount);
    }
}
