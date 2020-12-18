// SPDX-License-Identifier: AGPL
pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./MultiSig.sol";

contract TimeLockupVault is Ownable {
    // Amount of time between a deposit and withdraw in seconds.
    uint256 public timelock;
    mapping(uint256 => uint256) internal deposits;
    uint256[] internal timeKeys;

    constructor(uint256 _timelock) {
        timelock = _timelock;
    }

    function getTimeKeys() external view returns (uint256[] memory) {
        return timeKeys;
    }

    function getBalanceForTimeKey(uint256 timeKey)
        public
        view
        returns (uint256)
    {
        return deposits[timeKey];
    }

    function getSecondsLeftOnTimeKey(uint256 timeKey)
        public
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

    function getDepositedAmount() external view returns (uint256) {
        uint256 amount = 0;
        for (uint256 i = 0; i < timeKeys.length; i++) {
            amount += getBalanceForTimeKey(timeKeys[i]);
        }

        return amount;
    }

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

    function _withdrawMaxFromTimeKey(uint256 timeKey) internal {
        delete deposits[timeKey];
        msg.sender.transfer(getBalanceForTimeKey(timeKey));
    }

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

    function withdraw() external onlyOwner {
        _withdrawMax({validateSeconds: true});
    }

    receive() external payable {
        timeKeys.push(block.timestamp);
        deposits[block.timestamp] = msg.value;
    }
}
