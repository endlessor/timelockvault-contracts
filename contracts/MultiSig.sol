// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MuliSig is Ownable {
    uint256 internal keyholderAmount;
    address[] internal keyholders;

    enum ActionCode {
        VOTE_TO_REMOVE_KEYHOLDER,
        VOTE_TO_ADD_KEYHOLDER,
        VOTE_TO_INCREASE_KEYHOLDER_AMOUNT,
        LOCK_OWNER_OUT,
        ATTEST_TO_DATA
    }

    mapping(address => mapping(ActionCode => mapping(bytes32 => bool)))
        internal attestations;

    constructor(uint256 _keyholderAmount) {
        keyholderAmount = _keyholderAmount;
    }

    function packAndHash(string memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(data));
    }

    function packAndHash(address data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(data));
    }

    function packAndHash(uint256 data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(data));
    }

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

    function allKeyholdersAttest(ActionCode code, address user)
        public
        view
        returns (bool)
    {
        return _allKeyholdersAttestToHash(code, packAndHash(user));
    }

    function allKeyholdersAttest(ActionCode code, string memory data)
        public
        view
        returns (bool)
    {
        return _allKeyholdersAttestToHash(code, packAndHash(data));
    }

    function allKeyholdersAttest(ActionCode code, uint256 data)
        public
        view
        returns (bool)
    {
        return _allKeyholdersAttestToHash(code, packAndHash(data));
    }

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

    function allButOneKeyholdersAttest(ActionCode code, address user)
        public
        view
        returns (bool)
    {
        return _allButOneKeyholdersAttestToHash(code, packAndHash(user));
    }

    // function allButOneKeyholdersAttest(ActionCode code, string memory data) public view returns (bool) {
    // return _allButOneKeyholdersAttestToHash(code, packAndHash(data));
    // }

    function _voidAttestationsFromHash(ActionCode code, bytes32 hash) internal {
        for (uint256 i = 0; i < keyholders.length; i++) {
            attestations[keyholders[i]][code][hash] = false;
        }
    }

    function voidAttestations(ActionCode code, address user) internal {
        _voidAttestationsFromHash(code, packAndHash(user));
    }

    // function voidAttestations(ActionCode code, string memory data) internal {
    // _voidAttestationsFromHash(code, packAndHash(data));
    // }

    function isKeyholder(address user) public view returns (bool) {
        for (uint256 i = 0; i < keyholders.length; i++) {
            if (keyholders[i] == user) {
                return true;
            }
        }

        return false;
    }

    modifier onlyKeyholder {
        require(
            isKeyholder(msg.sender),
            "You are not a keyholder for this contract's multisig."
        );
        _;
    }

    function addKeyholder(address person) external {
        require(
            keyholderAmount > keyholders.length,
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
            if (keyholders.length == keyholderAmount) {
                attestations[owner()][ActionCode.LOCK_OWNER_OUT][""] = true;
            }
        }
    }

    function removeKeyholder(address keyholder) external onlyKeyholder {
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

    function increaseKeyholderAmount(uint256 newAmount) external onlyKeyholder {
        require(
            allKeyholdersAttest(
                ActionCode.VOTE_TO_INCREASE_KEYHOLDER_AMOUNT,
                newAmount
            ),
            "All but one keyholders must attest first."
        );

        keyholderAmount = newAmount;
    }

    function attestToData(string memory data) external onlyKeyholder {
        attestations[msg.sender][ActionCode.ATTEST_TO_DATA][
            packAndHash(data)
        ] = true;
    }

    function voteToRemoveKeyholder(address keyholder) external onlyKeyholder {
        attestations[msg.sender][ActionCode.VOTE_TO_REMOVE_KEYHOLDER][
            packAndHash(keyholder)
        ] = true;
    }

    function voteToAddKeyholder(address person) external onlyKeyholder {
        attestations[msg.sender][ActionCode.VOTE_TO_ADD_KEYHOLDER][
            packAndHash(person)
        ] = true;
    }

    function voteToIncreaseKeyholderAmount(uint256 amount)
        external
        onlyKeyholder
    {
        attestations[msg.sender][ActionCode.VOTE_TO_INCREASE_KEYHOLDER_AMOUNT][
            packAndHash(amount)
        ] = true;
    }
}
