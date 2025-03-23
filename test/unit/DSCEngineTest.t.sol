// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine engine;
    HelperConfig config;
    address ethUsdPriceFeed;
    address weth;
    address user1 = makeAddr("user1");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, engine, config) = deployer.run();
        (ethUsdPriceFeed,, weth,,) = config.activeNetworkConfig();
        ERC20Mock(weth).mint(user1, STARTING_ERC20_BALANCE);
    }

    /*´:.*:˚.°*.˚•´.°:°•.+.*•´.*:*/
    /*        Price Tests        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.°.•*/

    function test_getUsdtValue() public view {
        uint256 ethAmount = 15e18;
        // 15e18 * 2000/ETH = 30,000e18
        uint256 expectedUsd = 30000e18;
        uint256 actualUsd = engine.getUsdValue(weth, ethAmount);

        assertEq(expectedUsd, actualUsd);
    }

    /*´:.*:˚.°*.˚•´.°:°•.+.*•´.*:*/
    /*  DepositCollateral Tests  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.°.•*/

    function testRevertIfCollateralZero() public {
        vm.startPrank(user1);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        vm.expectRevert(DSCEngine.DSCEngine__CanNotBeZero.selector);
        engine.depositCollateral(weth, 0);
    }
}
