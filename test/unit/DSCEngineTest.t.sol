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
    address public ethUsdPriceFeed;
    address public btcUsdPriceFeed;
    address public weth;
    address public wbtc;
    uint256 public deployerKey;
    address user1 = makeAddr("user1");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant AMOUNT_DSC = 5 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;
    uint256 public constant USER_STARTING_BALANCE = 10 ether;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, engine, config) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth, wbtc, deployerKey) = config.activeNetworkConfig();
        ERC20Mock(weth).mint(user1, STARTING_ERC20_BALANCE);
        ERC20Mock(wbtc).mint(user1, STARTING_ERC20_BALANCE);

    }

    /*´:.*:˚.°*.˚•´.°:°•.+.*•´.*:*/
    /*   Constructor Tests       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.°.•*/

    address[] public priceFeedAddresses;
    address[] public tokenAddresses;

    function testRevertIfTokenLengthDoesntMatchPriceFeedLength() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(ethUsdPriceFeed);
        priceFeedAddresses.push(btcUsdPriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesLengthMustBeEqual.selector);

        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));

        // uint256 tokenAddressLength = tokenAddresses.length;
        // uint256 priceFeedAddressLength = priceFeedAddresses.length;
        // assert(tokenAddressLength == priceFeedAddressLength);
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

    function test_getTokenAmountFromUsd() public {
        uint256 usdAmount = 100 ether;
        uint256 expectedWeth = 0.05 ether;
        uint256 actualWeth = engine.getTokenAmountFromUsd(weth, usdAmount);

        assertEq(expectedWeth, actualWeth);
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

    function testRevertsWithUnapprovedCollateral() public {
         ERC20Mock RandomToken = new ERC20Mock();
         RandomToken.mint(user1, AMOUNT_COLLATERAL);
        vm.startPrank(user1);
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        engine.depositCollateral(address(RandomToken), AMOUNT_COLLATERAL);
        vm.stopPrank();

    }

    function testStateUpdatesAfterDeposit() public depositedCollateral {
        uint256 expectedDepositAmount = engine.getCollateralDeposited(user1,weth);
        assertEq(expectedDepositAmount, AMOUNT_COLLATERAL);
    }

// forge test coverage --report debug --lcov-version 1
    modifier depositedCollateral() {
        vm.startPrank(user1);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

        modifier depositedCollateralAndMintedDsc() {
        vm.startPrank(user1);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateralAndMintDsc(weth, AMOUNT_COLLATERAL, AMOUNT_DSC);
        vm.stopPrank();
        
        _;
    }

    function testCanDepositCollateralAndGetAccountInfo() public depositedCollateral { 
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine.getAccountInformation(user1);

        uint256 expectedTotalDscMinted = 0;
        uint256 expectedDepositAmount = engine.getTokenAmountFromUsd(weth, collateralValueInUsd);

        assertEq(totalDscMinted, expectedTotalDscMinted);
        assertEq(AMOUNT_COLLATERAL, expectedDepositAmount);
    }

        function testDepositCollateralAndMintDsc() public depositedCollateralAndMintedDsc {
        uint256 totalDscMinted = engine.getDscMinted(user1);
        uint256 totalCollateralDeposited = engine.getCollateralDeposited(user1, weth);

        console.log("totalDscMinted:",totalDscMinted);
        console.log("totalCollateralDeposited", totalCollateralDeposited);

        assert(totalDscMinted > 0);
        assert(totalCollateralDeposited > 0);
        assert(totalDscMinted * 2 == totalCollateralDeposited);
    }


    /*´:.*:˚.°*.˚•´.°:°•.+.*•´.*:*/
    /*  RedeemCollateral Tests   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.°.•*/

    function testRevertIfRedeemZeroCollateral() public depositedCollateral {
        vm.startPrank(user1);
        dsc.approve(address(engine), 1);
        vm.expectRevert(DSCEngine.DSCEngine__CanNotBeZero.selector);
        engine.redeemCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRedeemCollateralAfterDepositedCollateralAndMintedDsc() public depositedCollateralAndMintedDsc {
        uint256 totalDscMinted = engine.getDscMinted(user1);
        uint256 totalCollateralDeposited = engine.getCollateralDeposited(user1, weth);
        vm.startPrank(user1);
        vm.expectRevert();
        engine.redeemCollateral(weth,AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

        function testBurnOneDscToRedeemAll() public depositedCollateralAndMintedDsc{
        vm.startPrank(user1);
        dsc.approve(address(engine), 1);
        vm.expectRevert();
        engine.redeemCollateralForDsc(weth, AMOUNT_COLLATERAL, 1);
        vm.stopPrank();

    }

    function testBurnAllDscToRedeemAllCollateral() public depositedCollateralAndMintedDsc{
        vm.startPrank(user1);
        dsc.approve(address(engine), AMOUNT_DSC);
        vm.expectRevert();
        engine.redeemCollateralForDsc(weth, AMOUNT_COLLATERAL, AMOUNT_DSC);
        vm.stopPrank();

    }


    /*´:.*:˚.°*.˚•´.°:°•.+.*•´.*:*/
    /*     Mint and Burn Tests   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.°.•*/

    function testRevertIfMintZero() public  depositedCollateral {
        vm.startPrank(user1);
        vm.expectRevert(DSCEngine.DSCEngine__CanNotBeZero.selector);
        engine.mintDsc(0);
        vm.stopPrank();
    }

    function testMint() public depositedCollateral {
        vm.startPrank(user1);
        engine.mintDsc(AMOUNT_DSC);
        uint256 expectedDscBalance = AMOUNT_DSC;
        uint256 dscBalance = dsc.balanceOf(user1);
        assertEq(expectedDscBalance, dscBalance);
        vm.stopPrank();
    }

    function testRevertIfBurnZero() public depositedCollateral {
        vm.startPrank(user1);
        vm.expectRevert(DSCEngine.DSCEngine__CanNotBeZero.selector);
        engine.burnDsc(0);
        vm.stopPrank();
    }

    function testBurn() public depositedCollateralAndMintedDsc {
        vm.startPrank(user1);
        dsc.approve(address(engine),AMOUNT_DSC);
        engine.burnDsc(4 ether);
        uint256 DscBalance = dsc.balanceOf(user1);
        uint256 expectedDscBalance = AMOUNT_DSC - 4 ether;
        console.log("DscBalance:",DscBalance);
        console.log("expectedDscBalance",expectedDscBalance);
        assertEq(DscBalance,expectedDscBalance);
        vm.stopPrank();

    }




    

}
