module.exports = {
  // Replacements for the values set in .env for testing
  TEST_TIMELOCK_SECONDS: 600,
  TEST_KEYHOLDER_LIMIT: 3,
  // Indexes for the ActionCode enum in the MultiSig contract
  VOTE_TO_REMOVE_KEYHOLDER_ACTION_CODE: 0,
  VOTE_TO_ADD_KEYHOLDER_ACTION_CODE: 1,
  VOTE_TO_CHANGE_KEYHOLDER_LIMIT_ACTION_CODE: 2,
  ATTEST_TO_DATA_ACTION_CODE: 4,

  gweiToWei: (gwei) => {
    return 1e9 * gwei;
  },
};
