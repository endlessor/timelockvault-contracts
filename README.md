# timelockvault-contracts [![Coverage Status](https://coveralls.io/repos/github/TransmissionsDev/timelockvault-contracts/badge.svg?branch=master)](https://coveralls.io/github/TransmissionsDev/timelockvault-contracts?branch=master)

Lock up your ETH for a set duration to force you into saving, **while allowing you to bypass the timelock if a group of your trusted friends (keyholders) vote to permit you to bypass in the case of an emergency or unexpected event.**

*The docs below will teach you how to configure and deploy your own instance of the `TimeLockMultiSigVault` contract.*

## Configuration Guide:

- Rename `.env.example` to `.env`
- Set `KEYHOLDER_LIMIT` to the number of keyholders you wish to have (ex: `2`)
- Set `TIMELOCK_SECONDS` to the number of seconds you would like your to deposit to be unwithdrawable (ex: `2628000`)
- Set `GWEI_GAS_PRICE` to the price of gas in GWEI to deploy your contract with ([use the fast price from ethgasstation.info](https://ethgasstation.info))
- Set `INFURA_KEY` to an Infura project ID ([more info here](https://blog.infura.io/getting-started-with-infura-28e41844cc89))
- Set `ETHERSCAN_API_KEY` to an Etherscan API key ([get one here](https://etherscan.io/myapikey))
- Set `PRIVATE_KEY` to your private key ([more info here](https://metamask.zendesk.com/hc/en-us/articles/360015289632-How-to-Export-an-Account-Private-Key))

## Deployment Guide:

- Run `npm run deploy-mainnet` to deploy to the mainnet & verify the contract on Etherscan automatically *(Change `mainnet` to `kovan` or `ropsten` to deploy to those testnets respectively).*

Your contract will now start deploying! Get the contract address by copying it from the command output from truffle:

![Output](https://user-images.githubusercontent.com/26209401/103076424-8e46c600-4582-11eb-9180-6f73993a0e58.png)

- Once the transaction has confirmed, it's time to add your keyholders.

- Go to [etherscan.io/address/YOUR_DELPOYED_CONTRACT_ADDRESS](/#)

![Etherscan](https://user-images.githubusercontent.com/26209401/103075910-6e62d280-4581-11eb-80b4-e14ff981d4a2.png)

- Call the contract's `addKeyholder` method with the address of each person you wish to add as keyholder until you've reached the `KEYHOLDER_LIMIT` you set.

### You should now be able to send ether to your contract and it will be locked up for the `TIMELOCK_SECONDS` amount you set! 

- If you want to check to see how much you can withdraw at a certian time call `getWithdrawableAmount` which will return the max amount you can withdraw at the current time (factoring in the timelock).

- Once the timelock has expired on any of your deposits you can call `withdraw` to withdraw all unlocked funds!

- You can also tell your keyholders to call `allowMaxAmountTimelockBypass` or `allowAmountTimelockBypass(uint256 amount)` to allow you to bypass the limit. 
  - Once all of your keyholders have called one of those methods, call `withdrawMaxWithTimelockBypass` or `withdrawAmountWithTimelockBypass(uint256 amount)` respectively to get withdraw your ETH!
  
### To go beyond the basics and learn all the cool things you or your keyholders can do with this contract, take a look at the contracts yourself under the [contracts folder](https://github.com/TransmissionsDev/timelockvault-contracts/tree/master/contracts) or look at some usage examples in the [tests folder](https://github.com/TransmissionsDev/timelockvault-contracts/tree/master/test)!
