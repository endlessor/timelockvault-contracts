const chai = require("chai");
const chaiAsPromised = require("chai-as-promised");
const chaiBnEqual = require("chai-bn-equal");
chai.use(chaiBnEqual);
chai.use(chaiAsPromised);
chai.should();

const MultiSig = artifacts.require("MultiSig");

const {
  VOTE_TO_REMOVE_KEYHOLDER_ACTION_CODE,
  VOTE_TO_ADD_KEYHOLDER_ACTION_CODE,
  VOTE_TO_CHANGE_KEYHOLDER_LIMIT_ACTION_CODE,
  ATTEST_TO_DATA_ACTION_CODE,
  TEST_KEYHOLDER_LIMIT,
} = require("../utils");

contract("MultiSig", (accounts) => {
  let [
    deployer,
    keyholder1,
    keyholder2,
    keyholderToBeRemoved,
    keyholderToBeAdded1,
    keyholderToBeAdded2,
  ] = accounts;

  it("should enforce the keyholder limit", async () => {
    const multiSig = await MultiSig.deployed();

    await multiSig.addKeyholder(keyholder1, { from: deployer });
    await multiSig.addKeyholder(keyholderToBeRemoved, { from: deployer });
    await multiSig.addKeyholder(keyholder2, { from: deployer });

    multiSig
      .addKeyholder(keyholderToBeAdded1, { from: deployer })
      .should.be.rejectedWith("A keyholder slot must be open");
  });

  it("should allow removing keyholders", async () => {
    const multiSig = await MultiSig.deployed();

    await multiSig.isKeyholder(keyholderToBeRemoved).should.become(true);

    await multiSig.voteToRemoveKeyholder(keyholderToBeRemoved, {
      from: keyholder1,
    });
    await multiSig.voteToRemoveKeyholder(keyholderToBeRemoved, {
      from: keyholder2,
    });

    await multiSig.removeKeyholder(keyholderToBeRemoved);

    await multiSig.isKeyholder(keyholderToBeRemoved).should.become(false);
  });

  it("should enforce the keyholder lockout", async () => {
    const multiSig = await MultiSig.deployed();

    multiSig
      .addKeyholder(deployer, { from: deployer })
      .should.be.rejectedWith("All keyholders must attest first");
  });

  it("should allow adding keyholders", async () => {
    const multiSig = await MultiSig.deployed();

    await multiSig.isKeyholder(keyholderToBeAdded1).should.become(false);

    await multiSig.voteToAddKeyholder(keyholderToBeAdded1, {
      from: keyholder1,
    });
    await multiSig.voteToAddKeyholder(keyholderToBeAdded1, {
      from: keyholder2,
    });

    await multiSig.addKeyholder(keyholderToBeAdded1);

    await multiSig.isKeyholder(keyholderToBeAdded1).should.become(true);
  });

  it("should allow increasing the keyholder limit", async () => {
    const multiSig = await MultiSig.deployed();

    multiSig.keyholderLimit().should.eventually.bnEqual(TEST_KEYHOLDER_LIMIT);

    await multiSig.voteToChangeKeyholderLimit(4, { from: keyholder1 });
    await multiSig.voteToChangeKeyholderLimit(4, { from: keyholder2 });
    await multiSig.voteToChangeKeyholderLimit(4, { from: keyholderToBeAdded1 });

    await multiSig.changeKeyholderLimit(4);

    multiSig.keyholderLimit().should.eventually.bnEqual(4);
  });

  it("should allow adding keyholders after the limit has increased", async () => {
    const multiSig = await MultiSig.deployed();

    await multiSig.isKeyholder(keyholderToBeAdded2).should.become(false);

    await multiSig.voteToAddKeyholder(keyholderToBeAdded2, {
      from: keyholder1,
    });
    await multiSig.voteToAddKeyholder(keyholderToBeAdded2, {
      from: keyholder2,
    });
    await multiSig.voteToAddKeyholder(keyholderToBeAdded2, {
      from: keyholderToBeAdded1,
    });

    await multiSig.addKeyholder(keyholderToBeAdded2);

    await multiSig.isKeyholder(keyholderToBeAdded2).should.become(true);

    await multiSig.getKeyholders().should.eventually.have.lengthOf(4);
    await multiSig
      .getKeyholders()
      .should.eventually.include.members([
        keyholder1,
        keyholder2,
        keyholderToBeAdded1,
        keyholderToBeAdded2,
      ]);
  });

  it("should allow all keyholders to attest and allKeyholdersAttest should return true", async () => {
    const multiSig = await MultiSig.deployed();

    const testString = "hello world";

    // Have to call methods directly because they're overloaded
    await multiSig.methods["allKeyholdersAttest(uint8,string)"](
      ATTEST_TO_DATA_ACTION_CODE,
      testString
    ).should.become(false);
    await multiSig.methods["allButOneKeyholdersAttest(uint8,string)"](
      ATTEST_TO_DATA_ACTION_CODE,
      testString
    ).should.become(false);

    await multiSig.attestToData(testString, { from: keyholder1 });
    await multiSig.attestToData(testString, { from: keyholder2 });
    await multiSig.attestToData(testString, { from: keyholderToBeAdded1 });

    await multiSig.methods["allKeyholdersAttest(uint8,string)"](
      ATTEST_TO_DATA_ACTION_CODE,
      testString
    ).should.become(false);
    await multiSig.methods["allButOneKeyholdersAttest(uint8,string)"](
      ATTEST_TO_DATA_ACTION_CODE,
      testString
    ).should.become(true);

    await multiSig.attestToData(testString, { from: keyholderToBeAdded2 });

    await multiSig.methods["allKeyholdersAttest(uint8,string)"](
      ATTEST_TO_DATA_ACTION_CODE,
      testString
    ).should.become(true);
  });

  it("allows retracting attestations", async () => {
    const multiSig = await MultiSig.new(1, { from: deployer });

    await multiSig.addKeyholder(keyholder1, { from: deployer });

    const testString = "hello world";

    // Atest to testString
    await multiSig.attestToData(testString, { from: keyholder1 });

    // Retract attestation for the testString and check that allKeyholdersAttest is now false
    await multiSig.retractAttestationForData(testString, { from: keyholder1 });
    await multiSig.methods["allKeyholdersAttest(uint8,string)"](
      ATTEST_TO_DATA_ACTION_CODE,
      testString
    ).should.become(false);

    // Vote to remove keyholder1
    await multiSig.voteToRemoveKeyholder(keyholder1, {
      from: keyholder1,
    });

    // Retract vote and check that allKeyholdersAttest is now false
    await multiSig.retractVoteToRemoveKeyholder(keyholder1, {
      from: keyholder1,
    });
    await multiSig.methods["allKeyholdersAttest(uint8,address)"](
      VOTE_TO_REMOVE_KEYHOLDER_ACTION_CODE,
      keyholder1
    ).should.become(false);

    // Vote to add keyholder1
    await multiSig.voteToAddKeyholder(keyholder1, {
      from: keyholder1,
    });

    // Retract vote and check that allKeyholdersAttest is now false
    await multiSig.retractVoteToAddKeyholder(keyholder1, {
      from: keyholder1,
    });
    await multiSig.methods["allKeyholdersAttest(uint8,address)"](
      VOTE_TO_ADD_KEYHOLDER_ACTION_CODE,
      keyholder1
    ).should.become(false);

    const newLimitTestAmount = 2;

    // Vote to change keyholderLimit
    await multiSig.voteToChangeKeyholderLimit(newLimitTestAmount, {
      from: keyholder1,
    });

    // Retract vote and check that allKeyholdersAttest is now false
    await multiSig.retractVoteToChangeKeyholderLimit(newLimitTestAmount, {
      from: keyholder1,
    });

    await multiSig.methods["allKeyholdersAttest(uint8,uint256)"](
      VOTE_TO_CHANGE_KEYHOLDER_LIMIT_ACTION_CODE,
      newLimitTestAmount
    ).should.become(false);
  });
});
