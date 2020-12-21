const chai = require("chai");
const chaiAsPromised = require("chai-as-promised");
chai.should();
chai.use(chaiAsPromised);

const TimeLockupMultiSigVault = artifacts.require("TimeLockupMultiSigVault");

contract("TimeLockupMultiSigVault", (accounts) => {
  let [owner, keyholder1, keyholder2] = accounts;

  it("should enforce the keyholder limit", async () => {});
});
