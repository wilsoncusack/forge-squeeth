pragma solidity =0.7.6;
pragma abicoder v2;

import {DSTest} from 'ds-test/test.sol';
import {NonfungiblePositionManager} from 'v3-periphery/NonfungiblePositionManager.sol';
import {UniswapV3Pool} from 'v3-core/contracts/UniswapV3Pool.sol';
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";


import {Controller} from 'src/core/Controller.sol';
import {Oracle} from 'src/core/Oracle.sol';
import {ShortPowerPerp} from 'src/core/ShortPowerPerp.sol';
import {WPowerPerp} from 'src/core/WPowerPerp.sol';
import {IWETH9} from 'src/interfaces/IWETH9.sol';
import {Power2Base} from 'src/libs/Power2Base.sol';
import {VaultLib} from 'src/libs/VaultLib.sol';
import {Uint256Casting} from "../libs/Uint256Casting.sol";
import {ABDKMath64x64} from "../libs/ABDKMath64x64.sol";
import {Vm} from "src/test/Vm.sol";


contract Intuition is DSTest {
    using SafeMath for uint256;
    using Uint256Casting for uint256;
    using ABDKMath64x64 for int128;

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

    uint256 constant LOWER_MARK_RATIO = 8e17;
    uint256 constant UPPER_MARK_RATIO = 140e16;
    uint256 constant ONE = 1e18;
    uint256 public constant FUNDING_PERIOD = 420 hours;

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

    function testCompareSqthRates() public {
        uint256 v = debtValueInEth(1e18);
        emit log_named_uint("(controller) 1 oSQTH -> ETH", v);
        uint256 v2 = Power2Base._getDebtValueInEth(1e18, address(oracle), 0x82c427AdFDf2d245Ec51D8046b41c4ee87F0d29C, address(wPowerPerp), address(weth));
        emit log_named_uint("(Uniswap) 1 oSQTH -> ETH", v2);
        emit log_named_uint("uniswap - controller", v2 - v);
    }

    // function testPlaygroundNormalization() public {
    //     uint32 period = block.timestamp.sub(controller.lastFundingUpdateTimestamp()).toUint32();
    //     emit log_named_uint('period', period);
    //     // if (period == 0) {
    //     //     return normalizationFactor;
    //     // }

    //     // make sure we use the same period for mark and index
    //     uint32 periodForOracle = _getConsistentPeriodForOracle(period);

    //     // avoid reading normalizationFactor from storage multiple times
    //     uint256 cacheNormFactor = controller.normalizationFactor();

    //     uint256 mark = Power2Base._getDenormalizedMark(
    //         periodForOracle,
    //         address(oracle),
    //         address(wPowerPerpPool),
    //         address(ethQuoteCurrencyPool),
    //         address(weth),
    //         address(quoteCurrency),
    //         address(wPowerPerp),
    //         cacheNormFactor
    //     );
    //     uint256 index = Power2Base._getIndex(
    //         periodForOracle,
    //         address(oracle),
    //         address(ethQuoteCurrencyPool), 
    //         address(weth), 
    //         address(quoteCurrency)
    //         );

    //     //the fraction of the funding period. used to compound the funding rate
    //     int128 rFunding = ABDKMath64x64.divu(period, FUNDING_PERIOD);

    //     // floor mark to be at least LOWER_MARK_RATIO of index
    //     uint256 lowerBound = index.mul(LOWER_MARK_RATIO).div(ONE);
    //     if (mark < lowerBound) {
    //         mark = lowerBound;
    //     } else {
    //         // cap mark to be at most UPPER_MARK_RATIO of index
    //         uint256 upperBound = index.mul(UPPER_MARK_RATIO).div(ONE);
    //         if (mark > upperBound) mark = upperBound;
    //     }

    //     // normFactor(new) = multiplier * normFactor(old)
    //     // multiplier = (index/mark)^rFunding
    //     // x^r = n^(log_n(x) * r)
    //     // multiplier = 2^( log2(index/mark) * rFunding )

    //     int128 base = ABDKMath64x64.divu(index, mark);
    //     int128 logTerm = ABDKMath64x64.log_2(base).mul(rFunding);
    //     int128 multiplier = logTerm.exp_2();
    //     uint256 result = multiplier.mulu(cacheNormFactor);
    // }

    function _getConsistentPeriodForOracle(uint32 _period) internal view returns (uint32) {
        uint32 maxPeriodPool1 = oracle.getMaxPeriod(address(ethQuoteCurrencyPool));
        uint32 maxPeriodPool2 = oracle.getMaxPeriod(address(wPowerPerpPool));

        uint32 maxSafePeriod = maxPeriodPool1 > maxPeriodPool2 ? maxPeriodPool2 : maxPeriodPool1;
        return _period > maxSafePeriod ? maxSafePeriod : _period;
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
        uint256 _normalizationFactor = controller.getExpectedNormalizationFactor();
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