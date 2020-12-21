const chai = require("chai");
const chaiAsPromised = require("chai-as-promised");
chai.should();
chai.use(chaiAsPromised);

const MultiSig = artifacts.require("MultiSig");

const ATTEST_TO_DATA_ACTION_CODE = 4;

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

    multiSig.isKeyholder(keyholderToBeRemoved).should.become(true);

    await multiSig.voteToRemoveKeyholder(keyholderToBeRemoved, {
      from: keyholder1,
    });
    await multiSig.voteToRemoveKeyholder(keyholderToBeRemoved, {
      from: keyholder2,
    });

    await multiSig.removeKeyholder(keyholderToBeRemoved);

    multiSig.isKeyholder(keyholderToBeRemoved).should.become(false);
  });

  it("should enforce the keyholder lockout", async () => {
    const multiSig = await MultiSig.deployed();

    multiSig
      .addKeyholder(keyholder1, { from: deployer })
      .should.be.rejectedWith("All keyholders must attest first");
  });

  it("should allow adding keyholders", async () => {
    const multiSig = await MultiSig.deployed();

    multiSig.isKeyholder(keyholderToBeAdded1).should.become(false);

    await multiSig.voteToAddKeyholder(keyholderToBeAdded1, {
      from: keyholder1,
    });
    await multiSig.voteToAddKeyholder(keyholderToBeAdded1, {
      from: keyholder2,
    });

    await multiSig.addKeyholder(keyholderToBeAdded1);

    multiSig.isKeyholder(keyholderToBeAdded1).should.become(true);
  });

  it("should allow increasing the keyholder limit", async () => {
    const multiSig = await MultiSig.deployed();

    // Returns a BN so we must convert to string first.
    (await multiSig.keyholderLimit()).toString().should.equal("3");

    await multiSig.voteToChangeKeyholderLimit(4, { from: keyholder1 });
    await multiSig.voteToChangeKeyholderLimit(4, { from: keyholder2 });
    await multiSig.voteToChangeKeyholderLimit(4, { from: keyholderToBeAdded1 });

    await multiSig.changeKeyholderLimit(4);

    // Returns a BN so we must convert to string first.
    (await multiSig.keyholderLimit()).toString().should.equal("4");
  });
  it("should allow adding keyholders after the limit has increased", async () => {
    const multiSig = await MultiSig.deployed();

    multiSig.isKeyholder(keyholderToBeAdded2).should.become(false);

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

    multiSig.isKeyholder(keyholderToBeAdded2).should.become(true);

    multiSig.getKeyholders().should.eventually.have.lengthOf(4);
    multiSig
      .getKeyholders()
      .should.eventually.to.include.members([
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
    multiSig.methods["allKeyholdersAttest(uint8,string)"](
      ATTEST_TO_DATA_ACTION_CODE,
      testString
    ).should.become(false);
    multiSig.methods["allButOneKeyholdersAttest(uint8,string)"](
      ATTEST_TO_DATA_ACTION_CODE,
      testString
    ).should.become(false);

    await multiSig.attestToData(testString, { from: keyholder1 });
    await multiSig.attestToData(testString, { from: keyholder2 });
    await multiSig.attestToData(testString, { from: keyholderToBeAdded1 });

    multiSig.methods["allKeyholdersAttest(uint8,string)"](
      ATTEST_TO_DATA_ACTION_CODE,
      testString
    ).should.become(false);
    multiSig.methods["allButOneKeyholdersAttest(uint8,string)"](
      ATTEST_TO_DATA_ACTION_CODE,
      testString
    ).should.become(true);

    await multiSig.attestToData(testString, { from: keyholderToBeAdded2 });

    multiSig.methods["allKeyholdersAttest(uint8,string)"](
      ATTEST_TO_DATA_ACTION_CODE,
      testString
    ).should.become(true);
  });
});
