// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.7.6;

import "./TimeLockupVault.sol";
import "./MultiSig.sol";

/// @title TimeLockupMultiSigVault
/// @notice You can use this contract to lockup your funds for a predetermined amount of time while allowing you to override the timelock with the approval of a trusted group of addresses.
/// @dev Use TimeLockupVault if you want no way to withdraw until the time limit is up.
contract TimeLockupMultiSigVault is TimeLockupVault, MultiSig {
    /// @notice Constructor that sets the timelock for all deposits and sets the amount of keyholders (trusted addresses that will allow you to override the timelock) to have.
    /// @param _keyholderAmount The amount of keyholders to start with.
    /// @param _timelock Amount of seconds deposits will be locked up for (unless bypassed by keyholder's votes).
    constructor(uint256 _keyholderAmount, uint256 _timelock)
        MultiSig(_keyholderAmount)
        TimeLockupVault(_timelock)
    {}

    /// @dev Generates the required attestation string to bypass the timelock for `amount`.
    function requiredAttestationForAmountBypass(uint256 amount)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "bypass withdraw timelock for amount: ",
                    amount
                )
            );
    }

    /// @dev Generates the required attestation string to bypass the timelock for the max amount in the contract.
    function requiredAttestationForMaxAmountBypass()
        internal
        pure
        returns (string memory)
    {
        return "bypass withdraw timelock";
    }

    /// @notice Withdraws all the eth in the contract ignoring the timelock of each deposit.
    /// @notice All keyholders must call `allowMaxAmountTimelockBypass` first.
    function withdrawMaxWithTimelockBypass() external onlyOwner {
        string memory requiredAttestation =
            requiredAttestationForMaxAmountBypass();

        require(
            allKeyholdersAttest(
                MultiSig.ActionCode.ATTEST_TO_DATA,
                requiredAttestation
            ),
            "All keyholders must attest first."
        );

        voidAttestations(ActionCode.ATTEST_TO_DATA, requiredAttestation);

        _withdrawMax({ignoreTimelock: true});
    }

    /// @notice Withdraws a specific amount from the contract ignroing the timelock of each deposit it withdraws from.
    /// @notice If a deposit is left partially withdrawn the same timelock will still apply to the remaining wei; it will not reset the countdown.
    /// @notice All keyholders must call `allowAmountTimelockBypass` with `amount` first.
    /// @param amount The amount in wei to withdraw from the contract.
    function withdrawAmountWithTimelockBypass(uint256 amount)
        external
        onlyOwner
    {
        string memory requiredAttestation =
            requiredAttestationForAmountBypass(amount);

        require(
            allKeyholdersAttest(
                MultiSig.ActionCode.ATTEST_TO_DATA,
                requiredAttestation
            ),
            "All keyholders must attest first."
        );

        uint256 amountWithdrawn = 0;

        for (uint256 i = 0; i < timeKeys.length; i++) {
            uint256 timeKey = timeKeys[i];
            uint256 timeKeyBalance = getBalanceForTimeKey(timeKey);

            // If the timeKey is not empty:
            if (timeKeyBalance > 0) {
                uint256 remainingToBeWithdrawn = amount - amountWithdrawn;

                // If we can withdraw the max amount from this timeKey without withdrawing too much:
                if (remainingToBeWithdrawn > timeKeyBalance) {
                    deposits[timeKey] = 0;
                    amountWithdrawn += timeKeyBalance;
                } else {
                    // If withdrawing the max from this timeKey will withdraw too much, withdraw only the amount we need.
                    // The else case will also be run if remainingToBeWithdrawn == timeKeyBalance so it will break right after (for gas efficiency).
                    deposits[timeKey] -= remainingToBeWithdrawn;
                    amountWithdrawn += remainingToBeWithdrawn;

                    break;
                }
            }
        }

        require(
            amountWithdrawn == amount,
            "There was not enough deposited to withdraw this amount."
        );

        voidAttestations(ActionCode.ATTEST_TO_DATA, requiredAttestation);
        emit Withdraw(amountWithdrawn);
        msg.sender.transfer(amount);
    }

    /// @notice If all keyholders call this function with `amount` it will allow the owner of the vault to `amount` wei from the contract without the timelock applying.
    /// @param amount The amount in wei to allow to be withdrawn from the contract.
    function allowAmountTimelockBypass(uint256 amount) external onlyKeyholder {
        attestToData(requiredAttestationForAmountBypass(amount));
    }

    /// @notice If all keyholders call this function it will allow the owner of the vault to withdraw the max amount of wei in the contract without the timelock applying.
    function allowMaxAmountTimelockBypass() external onlyKeyholder {
        attestToData(requiredAttestationForMaxAmountBypass());
    }
}
