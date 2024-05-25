// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Constants } from "src/libraries/Constants.sol";

/// @title SoulGasToken
/// @notice The SoulGasToken is a soul-bounded ERC20 contract which cab be used to pay gas on L2.
///         It has 2 modes:
///             1. when Constants.IS_SOUL_BACKED_BY_NATIVE(or in other words: SoulQKC mode), the token can be minted by
///                anyone depositing native token into the contract.
///             2. when !Constants.IS_SOUL_BACKED_BY_NATIVE(or in other words: SoulETH mode), the token can only be
///                minted by whitelist minters specified by contract owner.
contract SoulGasToken is ERC20Upgradeable, OwnableUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.SoulGasToken
    struct SoulGasTokenStorage {
        // _minters are be whitelist EOAs, only used when !Constants.IS_SOUL_BACKED_BY_NATIVE
        mapping(address => bool) _minters;
        // _burners are whitelist EOAs, only used when !Constants.IS_SOUL_BACKED_BY_NATIVE
        mapping(address => bool) _burners;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.SoulGasToken")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant _SOULGASTOKEN_STORAGE_LOCATION =
        0x135c38e215d95c59dcdd8fe622dccc30d04cacb8c88c332e4e7441bac172dd00;

    function _getSoulGasTokenStorage() private pure returns (SoulGasTokenStorage storage $) {
        assembly {
            $.slot := _SOULGASTOKEN_STORAGE_LOCATION
        }
    }

    constructor() {
        _disableInitializers();
    }

    /// @custom:legacy
    /// @notice initialize is used to initialize SoulGasToken contract.
    function initialize(string calldata name_, string calldata symbol_, address owner_) external initializer {
        __Ownable_init();
        if (Constants.IS_SOUL_BACKED_BY_NATIVE) {
            require(owner_ == address(0), "owner_ should be zero when Constants.IS_SOUL_BACKED_BY_NATIVE");
            renounceOwnership();
        } else {
            require(
                owner_ != Constants.DEPOSITOR_ACCOUNT && owner_ != address(0),
                "owner_ should not be neither DEPOSITOR_ACCOUNT nor zero when !Constants.IS_SOUL_BACKED_BY_NATIVE"
            );
            transferOwnership(owner_);
        }

        // initialize the inherited ERC20Upgradeable
        __ERC20_init(name_, symbol_);
    }

    /// @custom:legacy
    /// @notice deposit can be called by anyone to deposit native token for SoulGasToken when
    /// Constants.IS_SOUL_BACKED_BY_NATIVE.
    function deposit() external payable {
        require(
            Constants.IS_SOUL_BACKED_BY_NATIVE, "deposit should only be called when Constants.IS_SOUL_BACKED_BY_NATIVE"
        );

        _mint(_msgSender(), msg.value);
    }

    /// @custom:legacy
    /// @notice batchDeposit can be called by anyone to deposit native token for SoulGasToken in batch when
    /// Constants.IS_SOUL_BACKED_BY_NATIVE.
    function batchDeposit(address[] calldata accounts, uint256[] calldata values) external payable {
        require(accounts.length == values.length, "invalid arguments");

        require(
            Constants.IS_SOUL_BACKED_BY_NATIVE,
            "batchDeposit should only be called when Constants.IS_SOUL_BACKED_BY_NATIVE"
        );

        uint256 totalValue = 0;
        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], values[i]);
            totalValue += values[i];
        }
        require(msg.value == totalValue, "unexpected msg.value");
    }

    /// @custom:legacy
    /// @notice batchMint is called:
    ///                        1. by EOA minters to mint SoulGasToken in batch when !Constants.IS_SOUL_BACKED_BY_NATIVE.
    ///                        2. by DEPOSITOR_ACCOUNT to refund SoulGasToken
    function batchMint(address[] calldata accounts, uint256[] calldata values) external {
        require(accounts.length == values.length, "invalid arguments");

        SoulGasTokenStorage storage $ = _getSoulGasTokenStorage();
        require(_msgSender() == Constants.DEPOSITOR_ACCOUNT || $._minters[_msgSender()], "not a minter");

        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], values[i]);
        }
    }

    /// @custom:legacy
    /// @notice addMinters is called by the owner to add minters when !Constants.IS_SOUL_BACKED_BY_NATIVE.
    function addMinters(address[] calldata minters_) external onlyOwner {
        // addMinters should only be called when !Constants.IS_SOUL_BACKED_BY_NATIVE, but we don't check it explicitly
        // since it's ensured by onlyOwner
        SoulGasTokenStorage storage $ = _getSoulGasTokenStorage();
        uint256 i;
        for (i = 0; i < minters_.length; i++) {
            $._minters[minters_[i]] = true;
        }
    }

    /// @custom:legacy
    /// @notice delMinters is called by the owner to delete minters when !Constants.IS_SOUL_BACKED_BY_NATIVE.
    function delMinters(address[] calldata minters_) external onlyOwner {
        // delMinters should only be called when !Constants.IS_SOUL_BACKED_BY_NATIVE, but we don't check it explicitly
        // since it's ensured by onlyOwner
        SoulGasTokenStorage storage $ = _getSoulGasTokenStorage();
        uint256 i;
        for (i = 0; i < minters_.length; i++) {
            delete $._minters[minters_[i]];
        }
    }

    /// @custom:legacy
    /// @notice addBurners is called by the owner to add burners when !Constants.IS_SOUL_BACKED_BY_NATIVE.
    function addBurners(address[] calldata burners_) external onlyOwner {
        // addBurners should only be called when !Constants.IS_SOUL_BACKED_BY_NATIVE, but we don't check it explicitly
        // since it's ensured by onlyOwner
        SoulGasTokenStorage storage $ = _getSoulGasTokenStorage();
        uint256 i;
        for (i = 0; i < burners_.length; i++) {
            $._burners[burners_[i]] = true;
        }
    }

    /// @custom:legacy
    /// @notice delBurners is called by the owner to delete burners when !Constants.IS_SOUL_BACKED_BY_NATIVE.
    function delBurners(address[] calldata burners_) external onlyOwner {
        // delBurners should only be called when !Constants.IS_SOUL_BACKED_BY_NATIVE, but we don't check it explicitly
        // since it's ensured by onlyOwner
        SoulGasTokenStorage storage $ = _getSoulGasTokenStorage();
        uint256 i;
        for (i = 0; i < burners_.length; i++) {
            delete $._burners[burners_[i]];
        }
    }

    /// @custom:legacy
    /// @notice burnFrom is called:
    ///                             1. by the burner to burn SoulGasToken.
    ///                             2. by DEPOSITOR_ACCOUNT to burn SoulGasToken.
    function burnFrom(address account, uint256 value) external {
        SoulGasTokenStorage storage $ = _getSoulGasTokenStorage();
        require(_msgSender() == Constants.DEPOSITOR_ACCOUNT || $._burners[_msgSender()], "not the burner");
        _burn(account, value);
    }

    /// @custom:legacy
    /// @notice transferFrom is disabled for SoulGasToken.
    function transfer(address, uint256) public virtual override returns (bool) {
        revert("transfer is disabled for SoulGasToken");
    }

    /// @custom:legacy
    /// @notice transferFrom is disabled for SoulGasToken.
    function transferFrom(address, address, uint256) public virtual override returns (bool) {
        revert("transferFrom is disabled for SoulGasToken");
    }

    /// @custom:legacy
    /// @notice approve is disabled for SoulGasToken.
    function approve(address, uint256) public virtual override returns (bool) {
        revert("approve is disabled for SoulGasToken");
    }
}
