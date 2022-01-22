pragma solidity =0.7.6;
pragma abicoder v2;

import {DSTest} from 'ds-test/test.sol';
import {NonfungiblePositionManager} from 'v3-periphery/NonfungiblePositionManager.sol';
import {UniswapV3Pool} from 'v3-core/contracts/UniswapV3Pool.sol';
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Vm} from "forge-std/Vm.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";


import {Controller} from 'src/core/Controller.sol';
import {Oracle} from 'src/core/Oracle.sol';
import {ShortPowerPerp} from 'src/core/ShortPowerPerp.sol';
import {WPowerPerp} from 'src/core/WPowerPerp.sol';
import {IWETH9} from 'src/interfaces/IWETH9.sol';
import {Power2Base} from 'src/libs/Power2Base.sol';
import {VaultLib} from 'src/libs/VaultLib.sol';


contract Intuition is DSTest {
    using SafeMath for uint256;

    Vm vm = Vm(HEVM_ADDRESS);
    Oracle oracle = Oracle(0x65D66c76447ccB45dAf1e8044e918fA786A483A1);
    ShortPowerPerp shortPowerPerp = ShortPowerPerp(0xa653e22A963ff0026292Cc8B67941c0ba7863a38);
    WPowerPerp wPowerPerp = WPowerPerp(0xf1B99e3E573A1a9C5E6B2Ce818b617F0E664E86B);
    IWETH9 weth = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    ERC20 quoteCurrency = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // USDC
    UniswapV3Pool ethQuoteCurrencyPool = UniswapV3Pool(0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8);
    UniswapV3Pool wPowerPerpPool = UniswapV3Pool(0x82c427AdFDf2d245Ec51D8046b41c4ee87F0d29C);
    NonfungiblePositionManager uniPositionManager = NonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    uint24 feeTier = 3000;
    uint32 public constant TWAP_PERIOD = 420 seconds;
    Controller controller = Controller(0x64187ae08781B09368e6253F9E94951243A493D5);

    function setUp() public {
        vm.deal(address(this), 1e30);
        // if you wanted to change controller code
        // you could and then use the etch cheat code
        // to set the mainnet controller address to have 
        // your code
        //
        // controller = new Controller(
        //     address(oracle),
        //     address(shortPowerPerp),
        //     address(wPowerPerp),
        //     address(weth),
        //     address(quoteCurrency),
        //     address(ethQuoteCurrencyPool),
        //     address(wPowerPerp),
        //     address(uniPositionManager),
        //     feeTier
        // );
    }

    function testMintPowerPerp() public {
        emit log_named_uint("balance 0", address(this).balance);
        (uint256 vaultId, uint256 amount) = controller.mintPowerPerpAmount{value: 1e20}(0, 1e20, 0);
        emit log_named_uint("balance 01", address(this).balance);
        uint128 n1 = controller.normalizationFactor();
        emit log_named_uint("wPowerPerpMinted", amount);
        emit log_named_uint("n1", n1);
        (address operator, uint32 NftCollateralId, uint96 collateralAmount, uint128 shortAmount) = controller.vaults(vaultId);
        uint256 debtInEth = debtValueInEth(vaultId);
        emit log_named_uint("debtInEth", debtInEth);
        
        vm.warp(block.timestamp + 1e6);
        controller.applyFunding();
        uint256 l1 = maxEthWithdrawable(vaultId);
        emit log_named_uint("withdrawable", l1);
        emit log_named_uint("balance 1", address(this).balance);
        controller.withdraw(vaultId, l1);
        emit log_named_uint("balance 2",  address(this).balance);
        controller.applyFunding();
        uint256 l2 = maxEthWithdrawable(vaultId);
        emit log_named_uint("withdrawable!!", l2);
        controller.withdraw(vaultId, l2);
    }

    function testMaxMint() public {
        uint256 ethAmount = 1e20;
        uint256 maxDebt = ethAmount * 2 / 3;
        uint256 _ethQuoteCurrencyPrice = Power2Base._getScaledTwap(
            address(oracle),
            address(ethQuoteCurrencyPool),
            address(weth),
            address(quoteCurrency),
            TWAP_PERIOD,
            true 
        );
        uint128 n = controller.normalizationFactor();
        uint256 maxWPowerPerp = maxDebt.mul(1e36).div(n).div(_ethQuoteCurrencyPrice);
        uint256 vaultId = controller.mintWPowerPerpAmount{value: ethAmount}(0, maxWPowerPerp, 0);
        uint256 limit = maxEthWithdrawable(vaultId);
        emit log_named_uint("withdrawable eth", limit - 10);
        controller.withdraw(vaultId, limit);

        // uint256 max_mint = uint256(n).mul(_ethQuoteCurrencyPrice).div(1e36).div(maxDebt);
        // emit log_named_uint("max", max_mint);
        // (uint256 vaultId, uint256 amount) = controller.mintWPowerPerpAmount{value: ethAmount}(0, max_mint, 0);
        // uint256 limit = maxEthWithdrawable(vaultId);
        // emit log_named_uint("withdrawable", limit);

        // uint256 _debtValueInETH = uint256(n).mul(_ethQuoteCurrencyPrice);
            
        // uint256 max_mint = _debtValueInETH.mul(1e18).mul(maxDebt).div(1e18);
        // emit log_named_uint("n", n); 
        // emit log_named_uint("_ethQuoteCurrencyPrice", _ethQuoteCurrencyPrice); 
        // emit log_named_uint("max", max_mint); 
        // uint256 vaultId = controller.mintWPowerPerpAmount{value: ethAmount}(0, max_mint + 10, 0);
        // controller.applyFunding();
        // uint256 limit = maxEthWithdrawable(vaultId);
        // emit log_named_uint("withdrawable", limit);

        // 1 debt in eth 
        
        //     // .div(1e18);
        // emit log_named_uint("other", _debtValueInETH);

        // _debtValueInETH = uint256(_ethQuoteCurrencyPrice)
        //     .div(n);
        // emit log_named_uint("other1", _debtValueInETH);

        // _debtValueInETH = uint256(_ethQuoteCurrencyPrice)
        //     .div(n);
        // emit log_named_uint("other2", _debtValueInETH.div(1e18));

        // 1 eth in debt 
        // but isn't that just the live quote for it? 
        // no I think I want the contract definition ? 
    }

    // need to compute a different normalization factor? Or can just take current 

    function maxWPowerPerpMintable(uint256 vaultId) public returns (uint256) {
    }

    function maxEthWithdrawable(uint256 vaultId) public returns (uint256) {
        uint256 debtInEth = debtValueInEth(vaultId);
        // ensure slightly more than 150% 
        // of debt is left as collateral
        (, , uint96 collateralAmount, ) = controller.vaults(vaultId);
        return uint256(collateralAmount).sub(debtInEth.mul(3).div(2)).sub(1);
    }

    function debtValueInEth(uint256 vaultId) public returns (uint256 _debtValueInETH){
        (, , , uint128 _shortAmount) = controller.vaults(vaultId);
        uint128 _normalizationFactor = controller.normalizationFactor();
        uint256 _ethQuoteCurrencyPrice = Power2Base._getScaledTwap(
            address(oracle),
            address(ethQuoteCurrencyPool),
            address(weth),
            address(quoteCurrency),
            TWAP_PERIOD,
            true 
        );

        _debtValueInETH = uint256(_shortAmount)
            .mul(_normalizationFactor)
            .mul(_ethQuoteCurrencyPrice)
            .div(1e36);
    }

    function onERC721Received(address, address, uint256, bytes memory) public returns (bytes4) {
        return this.onERC721Received.selector;
    }

    receive() external payable {
    
    }

}