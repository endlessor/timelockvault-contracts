// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MultiSig is Ownable {
    /// @notice The limit of keyholders the multsig can have. Can be expanded with a vote of all active keyholders.
    uint256 public keyholderLimit;
    /// @dev An array of the addresses of all current keyholders.
    address[] internal keyholders;

    /// @dev All possible actions keyholders can attest/vote to do.
    enum ActionCode {
        /// @dev Vote to remove a keyholder and strip their voting/attesting power. The associated hash in `attestations` will be of the address of the keyholder they are voting to remove.
        VOTE_TO_REMOVE_KEYHOLDER,
        /// @dev Vote to add another keyholder and give them voting/attesting power. The associated hash in `attestations` will be of the address of the keyholder they are voting to add.
        VOTE_TO_ADD_KEYHOLDER,
        /// @dev Vote to increase the limit of keyholders. The associated hash in `attestations` will be the number they are voting to change the keyholder limit to.
        VOTE_TO_CHANGE_KEYHOLDER_LIMIT,
        /// @dev Remove the owner's ability to add keyholders. Owner must take this action. This action will be auto-taken after they add enough keyholders to reach the `keyholderLimit`. The associated data in `attestations` will be an empty bytes32.
        LOCK_OWNER_OUT,
        /// @dev Attest to arbitrary hashed data. The associated hash in `attestations` will be an packed version of the data they are attesting to.
        ATTEST_TO_DATA
    }

    /// @dev A mapping of addresses to actions mapped to hashes mapped to bools.
    mapping(address => mapping(ActionCode => mapping(bytes32 => bool)))
        internal attestations;

    /// @notice Constructor that sets the keyholder limit.
    /// @param _keyholderLimit Max amount of keyholders the multisig can have (can be changd by keyholders).
    constructor(uint256 _keyholderLimit) {
        keyholderLimit = _keyholderLimit;
    }

    /// @dev Takes a string and packs it and hashes it using keccak256.
    /// @return The bytes of the hashed and packed data.
    function packAndHash(string memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(data));
    }

    /// @dev Takes an address and packs it and hashes it using keccak256.
    /// @return The bytes of the hashed and packed data.
    function packAndHash(address data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(data));
    }

    /// @dev Takes a uint256 and packs it and hashes it using keccak256.
    /// @return The bytes of the hashed and packed data.
    function packAndHash(uint256 data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(data));
    }

    /// @dev Checks that all keyholders attested to an entry with the `code` and `hash`.
    /// @param code The ActionCode of the entry to look for.
    /// @param hash The data in the entry to look for.
    /// @return If all keyholders have attested to an entry with the `code` and `hash`.
    function _allKeyholdersAttestToHash(ActionCode code, bytes32 hash)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < keyholders.length; i++) {
            if (attestations[keyholders[i]][code][hash] == false) {
                return false;
            }
        }

        return true;
    }

    /// @notice Checks that all keyholders attested to an entry with the `code` and `user`.
    /// @param code The ActionCode of the entry to look for.
    /// @param user The data in the entry to look for.
    /// @return If all keyholders have attested to an entry with the `code` and `user`.
    function allKeyholdersAttest(ActionCode code, address user)
        public
        view
        returns (bool)
    {
        return _allKeyholdersAttestToHash(code, packAndHash(user));
    }

    /// @notice Checks that all keyholders attested to an entry with the `code` and `data`.
    /// @param code The ActionCode of the entry to look for.
    /// @param data The data in the entry to look for.
    /// @return If all keyholders have attested to an entry with the `code` and `data`.
    function allKeyholdersAttest(ActionCode code, string memory data)
        public
        view
        returns (bool)
    {
        return _allKeyholdersAttestToHash(code, packAndHash(data));
    }

    /// @notice Checks that all keyholders attested to an entry with the `code` and `data`.
    /// @param code The ActionCode of the entry to look for.
    /// @param data The data in the entry to look for.
    /// @return If all keyholders have attested to an entry with the `code` and `data`.
    function allKeyholdersAttest(ActionCode code, uint256 data)
        public
        view
        returns (bool)
    {
        return _allKeyholdersAttestToHash(code, packAndHash(data));
    }

    /// @dev Checks that all but one keyholders attested to an entry with the `code` and `hash`.
    /// @param code The ActionCode of the entry to look for.
    /// @param hash The data in the entry to look for.
    /// @return If all but one keyholders have attested to an entry with the `code` and `hash`.
    function _allButOneKeyholdersAttestToHash(ActionCode code, bytes32 hash)
        internal
        view
        returns (bool)
    {
        uint256 nonAttested = 0;
        for (uint256 i = 0; i < keyholders.length; i++) {
            if (attestations[keyholders[i]][code][hash] == false) {
                nonAttested++;

                if (nonAttested > 1) {
                    return false;
                }
            }
        }

        return true;
    }

    /// @notice Checks that all but one keyholders attested to an entry with the `code` and `user`.
    /// @param code The ActionCode of the entry to look for.
    /// @param user The data in the entry to look for.
    /// @return If all but one keyholders have attested to an entry with the `code` and `user`.
    function allButOneKeyholdersAttest(ActionCode code, address user)
        public
        view
        returns (bool)
    {
        return _allButOneKeyholdersAttestToHash(code, packAndHash(user));
    }

    /// @notice Checks that all but one keyholders attested to an entry with the `code` and `user`.
    /// @param code The ActionCode of the entry to look for.
    /// @param data The data in the entry to look for.
    /// @return If all but one keyholders have attested to an entry with the `code` and `user`.
    function allButOneKeyholdersAttest(ActionCode code, string calldata data)
        public
        view
        returns (bool)
    {
        return _allButOneKeyholdersAttestToHash(code, packAndHash(data));
    }

    /// @dev Removes an attestation/action from the map.
    /// @param code The action code of the entry to void.
    /// @param hash The data of the entry to void.
    function _voidAttestationsFromHash(ActionCode code, bytes32 hash) internal {
        for (uint256 i = 0; i < keyholders.length; i++) {
            attestations[keyholders[i]][code][hash] = false;
        }
    }

    /// @dev Removes an address attestation/action from the map.
    /// @param code The action code of the entry to void.
    /// @param user The data of the entry to void.
    function voidAttestations(ActionCode code, address user) internal {
        _voidAttestationsFromHash(code, packAndHash(user));
    }

    /// @dev Removes a string attestation/action from the map.
    /// @param code The action code of the entry to void.
    /// @param data data of the entry to void.
    function voidAttestations(ActionCode code, string memory data) public {
        _voidAttestationsFromHash(code, packAndHash(data));
    }

    /// @notice Gets all keyholders. May be lower than the limit but cannot be higher.
    /// @return An array of the addresses of all keyholders.
    function getKeyholders() public view returns (address[] memory) {
        return keyholders;
    }

    /// @notice Checks if an address is a keyholder.
    /// @return If an address is a keyholder.
    function isKeyholder(address user) public view returns (bool) {
        for (uint256 i = 0; i < keyholders.length; i++) {
            if (keyholders[i] == user) {
                return true;
            }
        }

        return false;
    }

    /// @notice Adds a keyholder if a slot is open.
    /// @notice The owner of the contract can add keyholders until they lock themselves out or fill all slots.
    /// @notice After the owner is locked out only keyholders can add if a slot is open and they all vote.
    /// @notice Will void all attestations voting for this addition if the addition is completed successfully.
    /// @param person The address to add as a keyholder.
    function addKeyholder(address person) external {
        require(
            keyholderLimit > keyholders.length,
            "A keyholder slot must be open!"
        );

        // If owner has added all original keyholders already:
        if (attestations[owner()][ActionCode.LOCK_OWNER_OUT][""]) {
            require(
                allKeyholdersAttest(ActionCode.VOTE_TO_ADD_KEYHOLDER, person),
                "All keyholders must attest first."
            );
            keyholders.push(person);
            voidAttestations(ActionCode.VOTE_TO_ADD_KEYHOLDER, person);
        } else {
            require(
                msg.sender == owner(),
                "You must be the owner of the contract to add keyholders before the owner is locked out."
            );
            keyholders.push(person);

            // If all keyholder slots have been filled: lock the owner out.
            if (keyholders.length == keyholderLimit) {
                attestations[owner()][ActionCode.LOCK_OWNER_OUT][""] = true;
            }
        }
    }

    /// @notice Removes a keyholder if all but one current keyholders vote to remove them.
    /// @notice Will void all attestations voting for this removal if the addition is completed successfully.
    /// @param keyholder The address of the keyholder to remove.
    function removeKeyholder(address keyholder) external {
        require(
            allButOneKeyholdersAttest(
                ActionCode.VOTE_TO_REMOVE_KEYHOLDER,
                keyholder
            ),
            "All but one keyholders must attest first."
        );
        require(
            isKeyholder(keyholder),
            "The keyholder you wish to remove is not a keyholder."
        );
        address[] memory newKeyholders = new address[](keyholders.length - 1);

        bool foundOldKeyholder = false;

        for (uint256 i = 0; i < newKeyholders.length; i++) {
            if (keyholders[i] == keyholder) {
                foundOldKeyholder = true;
            }

            if (!foundOldKeyholder) {
                newKeyholders[i] = keyholders[i];
            } else {
                newKeyholders[i] = keyholders[i + 1];
            }
        }

        keyholders = newKeyholders;

        voidAttestations(ActionCode.VOTE_TO_REMOVE_KEYHOLDER, keyholder);
    }

    /// @notice Changes the limit of keyholders if all keyholders vote to change it. Cannot set the limit lower than the amount of current keyholders.
    function changeKeyholderLimit(uint256 newLimit) external {
        require(
            allKeyholdersAttest(
                ActionCode.VOTE_TO_CHANGE_KEYHOLDER_LIMIT,
                newLimit
            ),
            "All keyholders must attest first."
        );
        require(
            keyholders.length <= newLimit,
            "You cannot set the limit lower than amount of current keyholders!"
        );

        keyholderLimit = newLimit;
    }

    /// @dev Requires that the function caller is a keyholder.
    modifier onlyKeyholder {
        require(
            isKeyholder(msg.sender),
            "You are not a keyholder for this contract's multisig."
        );
        _;
    }

    /// @notice Adds an attestation log associated with the sender's address with the `data` and action code ATTEST_TO_DATA.
    /// @param data The string to be hashed and stored.
    function attestToData(string memory data) public onlyKeyholder {
        attestations[msg.sender][ActionCode.ATTEST_TO_DATA][
            packAndHash(data)
        ] = true;
    }

    /// @notice Adds an attestation log associated with the sender's address with the `keyholder` and action code VOTE_TO_REMOVE_KEYHOLDER.
    /// @param keyholder The address of the keyholder calling will vote to remove.
    function voteToRemoveKeyholder(address keyholder) external onlyKeyholder {
        attestations[msg.sender][ActionCode.VOTE_TO_REMOVE_KEYHOLDER][
            packAndHash(keyholder)
        ] = true;
    }

    /// @notice Adds an attestation log associated with the sender's address with the `keyholder` and action code VOTE_TO_ADD_KEYHOLDER.
    /// @param person The address of the person calling will vote to add as a keyholder.
    function voteToAddKeyholder(address person) external onlyKeyholder {
        attestations[msg.sender][ActionCode.VOTE_TO_ADD_KEYHOLDER][
            packAndHash(person)
        ] = true;
    }

    /// @notice Adds an attestation log associated with the sender's address with the `limit` and action code VOTE_TO_CHANGE_KEYHOLDER_LIMIT.
    /// @param limit The amount the caller is voting to change the limit to.
    function voteToChangeKeyholderLimit(uint256 limit) external onlyKeyholder {
        attestations[msg.sender][ActionCode.VOTE_TO_CHANGE_KEYHOLDER_LIMIT][
            packAndHash(limit)
        ] = true;
    }
}
