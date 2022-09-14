// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Auth} from "@solmate/auth/Auth.sol";
import {Owned} from "@solmate/auth/Owned.sol";
import {ERC4626} from "@solmate/mixins/ERC4626.sol";

import {SafeCastLib} from "@solmate/utils/SafeCastLib.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {CErc20} from "./interface/CErcInterface.sol";

contract AIMVault is ERC4626, Owned {
    using SafeCastLib for uint256;
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /// @notice The underlying token the Vault accepts.
    ERC20 public immutable UNDERLYING;

    uint256 public totalUnderlyingHeld;

    /// @notice The underlying token that have been deposited into compound strategy
    uint256 public totalStrategyHoldings;

    CErc20 public cToken;

    constructor(ERC20 _asset, CErc20 _token)
        ERC4626(
            _asset,
            string(abi.encodePacked("Aim ", _asset.name(), " Vault")),
            string(abi.encodePacked("av", _asset.symbol()))
        )
        Owned(msg.sender)
    {
        UNDERLYING = _asset;
        cToken = _token;
    }

    function afterDeposit(uint256 _assets, uint256) internal override {
        uint256 depositAssets = _assets / 2;
        totalStrategyHoldings += depositAssets;
        UNDERLYING.approve(address(cToken), depositAssets);
        require(cToken.mint(_assets) == 0, "COMP: Deposit Failed");
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override returns (uint256 shares) {
        totalStrategyHoldings = compBalanceOfUnderlying();

        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max)
                allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max)
                allowance[owner][msg.sender] = allowed - shares;
        }
        totalStrategyHoldings = compBalanceOfUnderlying();

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    function beforeWithdraw(uint256 _assets, uint256 _shares)
        internal
        override
    {
        if (totalFloat() < _assets) {
            uint256 toRedeem = _assets - totalFloat();
            require(cToken.redeem(toRedeem) == 0, "COMP: Redeem failed");
        }
    }

    function totalAssets() public view override returns (uint256) {
        uint256 total = totalStrategyHoldings + totalFloat();

        return total;
    }

    /// @notice Returns the amount of underlying tokens that idly sit in the Vault.
    /// @return The amount of underlying tokens that sit idly in the Vault.
    function totalFloat() public view returns (uint256) {
        return UNDERLYING.balanceOf(address(this));
    }

    function getCompStrategyInfo()
        external
        returns (uint256 exchangeRate, uint256 supplyRate)
    {
        // Amount of current exchange rate from cToken to underlying
        exchangeRate = cToken.exchangeRateCurrent();
        // Amount added to you supply balance this block
        supplyRate = cToken.supplyRatePerBlock();
    }

    function compBalanceOfUnderlying() public returns (uint256) {
        return cToken.balanceOfUnderlying(address(this));
    }
}
