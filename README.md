# timelockvault-contracts [![Coverage Status](https://coveralls.io/repos/github/TransmissionsDev/timelockvault-contracts/badge.svg?branch=master)](https://coveralls.io/github/TransmissionsDev/timelockvault-contracts?branch=master)

Lock up your ETH for a set duration to force you into saving, **while allowing a bypass if a group of your trusted friends (keyholders) vote to allow you to bypass in the case of an emergency or unexpected event.**

## Deployment Guide:

This step by step guide will teach how how to deploy your own intance of the `TimeLockMultiSigVault` contract. 

- Rename `.env.example` to `.env`
- Set `KEYHOLDER_LIMIT` to the number of keyholders you wish to have (ex: `2`)
- Set the `TIMELOCK_SECONDS` to the number of seconds you would like your to deposit to be unwithdrawable (ex: `2628000`)

## TODO: Info about HDWalletProvider

- Run `truffle migrate`

Your contract will now start deploying! Get the contract address by copying it from the command output from truffle:

![output](https://www.trufflesuite.com/img/blog/an-easier-way-to-deploy-your-smart-contracts/truffle.png)

- Once the transaction has confirmed, it's time to add your keyholders.

- Call the contract's `addKeyholder` method with the address of each person you wish to add as keyholder until you've reached the `KEYHOLDER_LIMIT` you set.

### You should now be able to send ether to your contract and it will be locked up for the `TIMELOCK_SECONDS` amount you set! 

- If you want to check to see how much you can withdraw at a certian time call `getWithdrawableAmount` which will return the max amount you can withdraw at the current time (factoring in the timelock).

- Once the timelock has expired on any of your deposits you can call `withdraw` to withdraw all unlocked funds!

- You can also tell your keyholders to call `allowMaxAmountTimelockBypass` or `allowAmountTimelockBypass(uint256 amount)` to allow you to bypass the limit. 
  - Once all of your keyholders have called one of those methods, call `withdrawMaxWithTimelockBypass` or `withdrawAmountWithTimelockBypass(uint256 amount)` respectively to get withdraw your ETH!
  
### To go beyond the basics and learn all the cool things you or your keyholders can do with this contract, take a look at the contracts yourself under the [contracts folder](https://github.com/TransmissionsDev/timelockvault-contracts/tree/master/contracts) or look at some usage examples in the [tests folder](https://github.com/TransmissionsDev/timelockvault-contracts/tree/master/test)!
