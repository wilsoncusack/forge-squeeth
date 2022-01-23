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
        
    }

    function testMaxMint() public {
        
    }

    function maxWPowerPerpMintable(uint256 vaultId) public returns (uint256 maxShortMintable) {
        (, , uint96 collateralAmount, uint128 shortAmount) = controller.vaults(vaultId);
        uint256 _ethQuoteCurrencyPrice = Power2Base._getScaledTwap(
            address(oracle),
            address(ethQuoteCurrencyPool),
            address(weth),
            address(quoteCurrency),
            TWAP_PERIOD,
            true 
        );
        maxShortMintable = maxWPowerPerMintable(
            collateralAmount,
            _ethQuoteCurrencyPrice,
            3,
            2
        ).sub(shortAmount);
    }

    function maxWPowerPerMintable(
        uint256 ethAmount, 
        uint256 ethQuoteCurrencyPrice, 
        uint256 cr_numerator, 
        uint256 cr_denominator
    ) public returns (uint256) {
        uint256 maxDebtInETH = ethAmount * cr_denominator / cr_numerator;
        uint256 normalization = controller.getExpectedNormalizationFactor();
        return maxDebtInETH
            .mul(1e36)
            .div(normalization)
            .div(ethQuoteCurrencyPrice);
    } 

    function maxEthWithdrawable(
        uint256 vaultId, 
        uint256 cr_numerator, 
        uint256 cr_denominator
    ) public returns (uint256) {
        (, , uint96 collateralAmount, uint128 shortAmount) = controller.vaults(vaultId);
        uint256 debtInEth = debtValueInEth(uint256(shortAmount));
        
        return uint256(collateralAmount)
            .sub(debtInEth
                .mul(cr_numerator)
                .div(cr_denominator)
            ).sub(1); // assume less than cr;
    }

    function debtValueInEth(uint256 debt) public returns (uint256 _debtValueInETH){
        uint128 _normalizationFactor = controller.getExpectedNormalizationFactor();
        uint256 _ethQuoteCurrencyPrice = Power2Base._getScaledTwap(
            address(oracle),
            address(ethQuoteCurrencyPool),
            address(weth),
            address(quoteCurrency),
            TWAP_PERIOD,
            true 
        );

        _debtValueInETH = uint256(debt)
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