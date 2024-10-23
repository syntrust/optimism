// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// Contracts
import { WETH98 } from "src/universal/WETH98.sol";

// Libraries
import { Predeploys } from "src/libraries/Predeploys.sol";

// Interfaces
import { ISemver } from "src/universal/interfaces/ISemver.sol";
import { IL1Block } from "src/L2/interfaces/IL1Block.sol";
import { IETHLiquidity } from "src/L2/interfaces/IETHLiquidity.sol";
import { ICrosschainERC20 } from "src/L2/interfaces/ICrosschainERC20.sol";
import { Unauthorized, NotCustomGasToken } from "src/libraries/errors/CommonErrors.sol";

/// @custom:proxied true
/// @custom:predeploy 0x4200000000000000000000000000000000000024
/// @title SuperchainWETH
/// @notice SuperchainWETH is a version of WETH that can be freely transfrered between chains
///         within the superchain. SuperchainWETH can be converted into native ETH on chains that
///         do not use a custom gas token.
contract SuperchainWETH is WETH98, ICrosschainERC20, ISemver {
    /// @notice Semantic version.
    /// @custom:semver 1.0.0-beta.7
    string public constant version = "1.0.0-beta.7";

    /// @inheritdoc WETH98
    function deposit() public payable override {
        if (IL1Block(Predeploys.L1_BLOCK_ATTRIBUTES).isCustomGasToken()) revert NotCustomGasToken();
        super.deposit();
    }

    /// @inheritdoc WETH98
    function withdraw(uint256 _amount) public override {
        if (IL1Block(Predeploys.L1_BLOCK_ATTRIBUTES).isCustomGasToken()) revert NotCustomGasToken();
        super.withdraw(_amount);
    }

    /// @notice Mints WETH to an address.
    /// @param _to The address to mint WETH to.
    /// @param _amount The amount of WETH to mint.
    function _mint(address _to, uint256 _amount) internal {
        balanceOf[_to] += _amount;
        emit Transfer(address(0), _to, _amount);
    }

    /// @notice Burns WETH from an address.
    /// @param _from The address to burn WETH from.
    /// @param _amount The amount of WETH to burn.
    function _burn(address _from, uint256 _amount) internal {
        balanceOf[_from] -= _amount;
        emit Transfer(_from, address(0), _amount);
    }

    /// @notice Allows the SuperchainTokenBridge to mint tokens.
    /// @param _to     Address to mint tokens to.
    /// @param _amount Amount of tokens to mint.
    function crosschainMint(address _to, uint256 _amount) external {
        if (msg.sender != Predeploys.SUPERCHAIN_TOKEN_BRIDGE) revert Unauthorized();

        _mint(_to, _amount);

        // Mint from ETHLiquidity contract.
        if (!IL1Block(Predeploys.L1_BLOCK_ATTRIBUTES).isCustomGasToken()) {
            IETHLiquidity(Predeploys.ETH_LIQUIDITY).mint(_amount);
        }

        emit CrosschainMinted(_to, _amount);
    }

    /// @notice Allows the SuperchainTokenBridge to burn tokens.
    /// @param _from   Address to burn tokens from.
    /// @param _amount Amount of tokens to burn.
    function crosschainBurn(address _from, uint256 _amount) external {
        if (msg.sender != Predeploys.SUPERCHAIN_TOKEN_BRIDGE) revert Unauthorized();

        _burn(_from, _amount);

        // Burn to ETHLiquidity contract.
        if (!IL1Block(Predeploys.L1_BLOCK_ATTRIBUTES).isCustomGasToken()) {
            IETHLiquidity(Predeploys.ETH_LIQUIDITY).burn{ value: _amount }();
        }

        emit CrosschainBurnt(_from, _amount);
    }
}
