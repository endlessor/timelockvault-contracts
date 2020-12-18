// SPDX-License-Identifier: AGPL
pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./TimeLockupVault.sol";
import "./MultiSig.sol";

contract TimeLockupMultiSigVault is TimeLockupVault, MuliSig {
    constructor(uint256 _keyholderAmount, uint256 _timelock)
        MuliSig(_keyholderAmount)
        TimeLockupVault(_timelock)
    {}

    function _withdrawAmountFromTimeKey(uint256 amount, uint256 timeKey)
        internal
    {
        deposits[timeKey] = getBalanceForTimeKey(timeKey) - amount;
        msg.sender.transfer(amount);
    }

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

    function withdrawMaxWithTimelockBypass() external onlyOwner {
        require(
            allKeyholdersAttest(
                MuliSig.ActionCode.ATTEST_TO_DATA,
                "bypass withdraw timelock"
            ),
            "All keyholders must attest first."
        );

        _withdrawMax({validateSeconds: false});
    }

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
