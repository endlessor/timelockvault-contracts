const MultiSig = artifacts.require("MultiSig");
const TimeLockupMultiSigVault = artifacts.require("TimeLockupMultiSigVault");

module.exports = function (deployer) {
  const KEYHOLDER_AMOUNT = 3;
  const TIMELOCK_SECONDS = 5;

  deployer.deploy(MultiSig, KEYHOLDER_AMOUNT);
  deployer.deploy(TimeLockupMultiSigVault, KEYHOLDER_AMOUNT, TIMELOCK_SECONDS);
};
