const MultiSig = artifacts.require("MultiSig");
const TimeLockupMultiSigVault = artifacts.require("TimeLockupMultiSigVault");
require("dotenv").config({ path: __dirname + "/../.env" });

module.exports = function (deployer) {
  const KEYHOLDER_AMOUNT = process.env.KEYHOLDER_AMOUNT;
  const TIMELOCK_SECONDS = process.env.TIMELOCK_SECONDS;

  deployer.deploy(MultiSig, KEYHOLDER_AMOUNT);
  deployer.deploy(TimeLockupMultiSigVault, KEYHOLDER_AMOUNT, TIMELOCK_SECONDS);
};
