pragma solidity =0.7.6;

import "ds-test/test.sol";
import 'src/libs/VaultLib.sol';

contract VaultGasTest is DSTest {
    VaultLib.Vault vault;
    mapping(uint256 => VaultLib.Vault) public vaults;

    function setUp() public {
        VaultLib.Vault memory v = VaultLib.Vault({
            NftCollateralId: 1,
            collateralAmount: 1,
            shortAmount: 1,
            operator: address(1)
        });
        vaults[1] = v;
    }

    function testWilson1() public {
        VaultLib.addUniNftCollateral(vault, 1);
    }

    function testStructExplicitZeros() public { 
        VaultLib.Vault memory v = VaultLib.Vault({
            NftCollateralId: 0,
            collateralAmount: 0,
            shortAmount: 0,
            operator: address(0)
        });
    }

    function testStructImplicitZeroes() public { 
        VaultLib.Vault memory v;
    }

    function testSaveStructToStorage() public { 
        VaultLib.Vault memory v = VaultLib.Vault({
            NftCollateralId: 1,
            collateralAmount: 1,
            shortAmount: 1,
            operator: address(1)
        });
        vaults[2] = v;
    }

    function testGetNFTCollateralId() public { 
        uint32 a = vaults[1].NftCollateralId;
    }

    function testGetVaultCollateralAmount() public { 
        uint96 a = vaults[1].collateralAmount;
    }

    function testGetVaultShortAmount() public { 
        uint128 a = vaults[1].shortAmount;
    }

    function testGetVaultOperator() public { 
        address a = vaults[1].operator;
    }
}