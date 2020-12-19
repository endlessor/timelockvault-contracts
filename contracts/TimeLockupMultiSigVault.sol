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

    /// @dev Withdraws a specific amount from a timekey. Will withdraw more than its balance.
    /// @param amount The amount of wei to withdraw from the timeKey.
    /// @param timeKey The timestamp of the deposit.
    function _withdrawAmountFromTimeKey(uint256 amount, uint256 timeKey)
        internal
    {
        uint256 timeKeyBalance = getBalanceForTimeKey(timeKey);
        require(
            amount <= timeKeyBalance,
            "This timeKey does not have enough deposited to withdraw this amount."
        );
        deposits[timeKey] = timeKeyBalance - amount;
        msg.sender.transfer(amount);
    }

    /// @dev Withdraws a specific amount by looping through each timeKey and withdrawing from each until the `amount` has been withdrawn. Will revert if there is not enough deposited to withdraw.
    /// @param amount The amount of wei to withdraw.
    /// @param validateSeconds If true the function will check that the timelock has expired on each deposit, if false it will ignore the timelock and withdraw anyway.
    function _withdrawAmount(uint256 amount, bool validateSeconds) internal {
        uint256 amountWithdrawn = 0;
        for (uint256 i = 0; i < timeKeys.length; i++) {
            uint256 timeKey = timeKeys[i];
            uint256 timeKeyBalance = getBalanceForTimeKey(timeKey);
            uint256 remainingToBeWithdrawn = amount - amountWithdrawn;
            if (
                timeKeyBalance > 0 &&
                (validateSeconds ? getSecondsLeftOnTimeKey(timeKey) == 0 : true)
            ) {
                if (remainingToBeWithdrawn > timeKeyBalance) {
                    _withdrawMaxFromTimeKey(timeKey);
                    amountWithdrawn += timeKeyBalance;
                } else {
                    _withdrawAmountFromTimeKey(remainingToBeWithdrawn, amount);
                    amountWithdrawn += remainingToBeWithdrawn;
                }
            }
        }

        require(
            amountWithdrawn == amount,
            "There was not enough deposited to withdraw this amount."
        );
    }

    /// @notice Withdraws all the eth in the contract ignoring the timelock of each deposit. All keyholders must attest to the string "bypass all withdraw timelocks" first.
    function withdrawMaxWithTimelockBypass() external onlyOwner {
        require(
            allKeyholdersAttest(
                MuliSig.ActionCode.ATTEST_TO_DATA,
                "bypass all withdraw timelocks"
            ),
            "All keyholders must attest first."
        );

        _withdrawMax({validateSeconds: false});
    }

    /// @notice Withdraws a specific amount from the contract ignroing the timelock of each deposit it withdraws from. All keyholders must attest to the string "bypass withdraw timelock for amount: `amount`" first.
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

        _withdrawAmount({amount: amount, validateSeconds: false});
    }
}
