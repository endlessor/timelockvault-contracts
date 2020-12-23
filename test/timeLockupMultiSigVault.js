const TimeLockupMultiSigVault = artifacts.require("TimeLockupMultiSigVault");
const timeMachine = require("ganache-time-traveler");

contract("TimeLockupMultiSigVault", (accounts) => {
  const [owner, keyholder1, keyholder2, keyholder3] = accounts;

  const depositAmount = web3.utils.toWei("1", "ether");

  it("allows deposits via fallback function", async () => {
    const timeLockupMultiSigVault = await TimeLockupMultiSigVault.deployed();

    // Send 1 ETH to the contract
    const { receipt } = await timeLockupMultiSigVault.send(depositAmount, {
      from: owner,
    });

    const timeKey = (await web3.eth.getBlock(receipt.blockNumber)).timestamp;

    // Check that the timeKeyBalance is the same as the deposit amount
    await timeLockupMultiSigVault
      .getBalanceForTimeKey(timeKey)
      .should.eventually.bnEqual(depositAmount);

    // Gets the first key in the array of timeKeys (the first deposit timeKey) and checks it is equal to the timestamp
    (await timeLockupMultiSigVault.getTimeKeys())[0]
      .toString()
      .should.equal(timeKey.toString());

    // Checks the balance of the timeKey is the same as the amount of ETH deposited.
    await timeLockupMultiSigVault
      .getBalanceForTimeKey(timeKey)
      .should.eventually.bnEqual(depositAmount);

    // Check the deposited amount is equal to 1 eth
    await timeLockupMultiSigVault
      .getDepositedAmount()
      .should.eventually.bnEqual(depositAmount);
  });

  it("enforces the timelock", async () => {
    const timeLockupMultiSigVault = await TimeLockupMultiSigVault.deployed();

    const halfOfTimelock = parseInt(process.env.TIMELOCK_SECONDS) / 2;

    // Advance the time so we're half way done with the timelock
    await timeMachine.advanceTimeAndBlock(halfOfTimelock);

    // Get the timeKey of the first deposit
    const firstDepositTimeKey = (
      await timeLockupMultiSigVault.getTimeKeys()
    )[0];

    // Check the amount of seconds left is equal to half of the timelock.
    await timeLockupMultiSigVault
      .getSecondsLeftOnTimeKey(firstDepositTimeKey)
      .should.eventually.bnEqual(halfOfTimelock.toString());

    // Check the withdrawable amount is 0
    await timeLockupMultiSigVault
      .getWithdrawableAmount()
      .should.eventually.bnEqual(0);
  });

  it("suports withdrawing after timelock is over", async () => {
    const timeLockupMultiSigVault = await TimeLockupMultiSigVault.deployed();

    // Advance the time by the timelock so we should be 1.5x over (as we already advanced by 0.5x in the last test)
    await timeMachine.advanceTimeAndBlock(
      parseInt(process.env.TIMELOCK_SECONDS)
    );

    // Check the withdrawable amount is the depositAmount
    await timeLockupMultiSigVault
      .getWithdrawableAmount()
      .should.eventually.bnEqual(depositAmount);

    await timeLockupMultiSigVault.withdraw({ from: owner });

    // Check the deposited amount is 0
    await timeLockupMultiSigVault
      .getDepositedAmount()
      .should.eventually.bnEqual(0);

    // Check the withdrawable amount is 0
    await timeLockupMultiSigVault
      .getWithdrawableAmount()
      .should.eventually.bnEqual(0);
  });

  it("it allows redepositing", async () => {
    const timeLockupMultiSigVault = await TimeLockupMultiSigVault.deployed();

    // Deposit 1x the depositAmount
    await timeLockupMultiSigVault.send(depositAmount, {
      from: owner,
    });

    // Advance the timestamp and block
    await timeMachine.advanceTimeAndBlock(60);

    // Deposit 1x the depositAmount
    await timeLockupMultiSigVault.send(depositAmount, {
      from: owner,
    });

    // Advance the timestamp and block
    await timeMachine.advanceTimeAndBlock(60);

    // Deposit 1x the depositAmount
    await timeLockupMultiSigVault.send(depositAmount, {
      from: owner,
    });

    // Check the deposited amount is 3x the depositAmount
    await timeLockupMultiSigVault
      .getDepositedAmount()
      .should.eventually.bnEqual(
        web3.utils.toBN(depositAmount).mul(web3.utils.toBN(3)).toString()
      );

    // Check the withdrawable amount is 0
    await timeLockupMultiSigVault
      .getWithdrawableAmount()
      .should.eventually.bnEqual(0);
  });

  it("allows adding keyholders", async () => {
    const timeLockupMultiSigVault = await TimeLockupMultiSigVault.deployed();

    timeLockupMultiSigVault.addKeyholder(keyholder1, { from: owner });
    timeLockupMultiSigVault.addKeyholder(keyholder2, { from: owner });
    timeLockupMultiSigVault.addKeyholder(keyholder3, { from: owner });
  });

  it("allows a bypass for a certian amount", async () => {
    const timeLockupMultiSigVault = await TimeLockupMultiSigVault.deployed();

    // Bypass half of the amount deposited aka withdrawing 1.5x the deposit amount which is half of 3x the deposit amount
    const bypassAmount = web3.utils
      .toBN(depositAmount)
      .add(web3.utils.toBN(depositAmount).div(web3.utils.toBN(2)))
      .toString();

    await timeLockupMultiSigVault.allowAmountTimelockBypass(bypassAmount, {
      from: keyholder1,
    });
    await timeLockupMultiSigVault.allowAmountTimelockBypass(bypassAmount, {
      from: keyholder2,
    });
    await timeLockupMultiSigVault.allowAmountTimelockBypass(bypassAmount, {
      from: keyholder3,
    });

    await timeLockupMultiSigVault.withdrawAmountWithTimelockBypass(
      bypassAmount,
      { from: owner }
    );

    // Since we withdrew half of the deposited amount, the amount left should be the same as the bypassAmount (as it's the other half left)
    await timeLockupMultiSigVault
      .getDepositedAmount()
      .should.eventually.bnEqual(bypassAmount);
  });

  it("allows a bypass for the max amount", async () => {
    const timeLockupMultiSigVault = await TimeLockupMultiSigVault.deployed();

    await timeLockupMultiSigVault.allowMaxAmountTimelockBypass({
      from: keyholder1,
    });
    await timeLockupMultiSigVault.allowMaxAmountTimelockBypass({
      from: keyholder2,
    });
    await timeLockupMultiSigVault.allowMaxAmountTimelockBypass({
      from: keyholder3,
    });

    await timeLockupMultiSigVault.withdrawMaxWithTimelockBypass({
      from: owner,
    });

    // We should have emptied the whole contract now.
    await timeLockupMultiSigVault
      .getDepositedAmount()
      .should.eventually.bnEqual(0);
  });
});
