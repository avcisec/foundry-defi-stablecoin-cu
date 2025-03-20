// SPDX-License-Identifier: MIT

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions
pragma solidity 0.8.20;

/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
/*                         Imports                            */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


/**
 * @title DSCEngine
 * @author 0xavci
 *
 * This system is designed to be as minimal as possible. 1 token == $1 peg.
 * Properties of System:
 * - Exogenous collateral
 * - Algoritmic stability
 * - Dolar pegged
 *
 * Our DSC system should always be "overcollateralized". At no point, should the value of all collateral <= the $ backed value of all the DSC.
 *
 * System is similar to DAI if DAI had no governance, no fees, and was only backed by WETH and WBTC.
 *
 * @notice This contract is the core of DSC system. All the logic happens here.(minting, redeeming DSC, depositing & withdrawing collateral)
 * @notice This contract is very loosely based on the makerDAO DSS(DAI) system.
 */
contract DSCEngine is ReentrancyGuard {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          Errors                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error DSCEngine__CanNotBeZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesLengthMustBeEqual();
    error DSCEngine__AddressCanNotBeZero();
    error DSCEngine__CollateralDepositFailed();
    error DSCEngine__HealthFactorBreaks(uint256 healthFactor);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          State Variables                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // 200% overcollateralized
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1;

    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    mapping(address user => uint256 amountDscMinted) private s_DSCMinted;
    address[] private s_collateralTokens;

    DecentralizedStableCoin private immutable i_dsc;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          Events                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    event CollateralDeposited(address indexed user, address indexed collateralToken, uint256 indexed amount);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          Modifiers                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    modifier amountMoreThanZero(uint256 amount) {
        if (amount == 0) revert DSCEngine__CanNotBeZero();
        _;
    }

    modifier isAllowedToken(address tokenCollateralAddress) {
        if (s_priceFeeds[tokenCollateralAddress] == address(0)) {
            revert DSCEngine__AddressCanNotBeZero();
        }
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          Functions                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // ETH / USD 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
    // BTC / USD 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c

    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscToken) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesLengthMustBeEqual();
        }

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        i_dsc = DecentralizedStableCoin(dscToken);
    }
    }
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      External Functions                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function depositCollateralAndMintDsc() external {}

    /*
     * @param tokenCollateralAddress is the address of  Token to deposit as collateral.
     * @param amountCollateral The amount of collateral to deposit as collateral.
     *
     */

    // forge fmt

    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
        amountMoreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        // state güncelledikten sonra event deklare ederiz. 
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert DSCEngine__CollateralDepositFailed();
        }
    }

    function redeemCollateral() external {}

    /*
    * @notice follows CEI
    * @param amountDscToMint The amount of DSC token to mint.
    * @notice they must have more collateral value than minimum threshold
    */
    function mintDsc(uint256 amountDscToMint) external amountMoreThanZero(amountDscToMint) nonReentrant {
        s_DSCMinted[msg.sender] += amountDscToMint;
        _revertIfHealthFactorIsBroken(msg.sender); // control if they minted too much ($150 DSC --> $100 ETH)
    }

    function redeemCollateralForDsc() external {}

    function burnDsc() external {}

    // Threshold to %150
    // $100 ETH --> $74 ETH  Ethereum fiyati düştüğü için
    // $50 DSC

    /*
    ÖRNEK SENARYO (Threshold to %150)
    $100 ETH teminat göstererek $50 degerinde DSC borç aldık.
    **ETH fiyatı düştü ve verdiğimiz teminat değeri $74 oldu. %150 altına düştük.**
    Bir başka kullanıcı bizim $50 DSC borcumuzu öder ve teminat paramıza çöker.
    $50 dolar ödedi ve 74 dolar aldı. 24 dolar kazanmış oldu. Biz de liq olduk.
    */

    function liquidate() external {}

    function getHealthFactor() external view {}


    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               Private & Internal view Functions            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


    function _getAccountInformation(address user) private view returns(uint256 totalDscMinted,uint256 collateralValueInUsd){
        totalDscMinted = s_DSCMinted[user];
        collateralValueInUsd = getAccountCollateralValueInUsd(user);

    }


    /*
     * Returns how close to liquidation a user is
     * If a user goes below 1, then they can get liquidated.
     * @param user - address of user
     */
    

    function _healthfactor(address user) private view returns(uint256){
        // total DSC minted
        // total collateral VALUE
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
        // health factor = CollateralValue / DebtAmount(minted DSC)
        // 1000 ETH * 50  = 50.000 / 100 = 500
        // $150 ETH * 50 = 7500 / 100 = 75  (75 / 100) < 1

        // return (collateralValueInUsd / totalDscMinted);
    }


    function _revertIfHealthFactorIsBroken(address user) internal view{
        // 1. check health factor (do they have enough collateral??)
        // 2. revert if health factor isn't good enough. 
        uint256 userHealthFactor = _healthfactor(user);

        if (userHealthFactor < MIN_HEALTH_FACTOR ) {
            revert DSCEngine__HealthFactorBreaks(userHealthFactor);
        }

    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               Public & External view Functions             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


    function getAccountCollateralValueInUsd(address user) public view returns(uint256 totalCollateralValueInUsd) {
        // loop through each collateral token, get the amount they have deposited, and map it to 
        // the price, to get the USD value
        for(uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }

        return totalCollateralValueInUsd;

    }

    function getUsdValue(address token, uint256 amount) public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (,int256 price,,,) = priceFeed.latestRoundData();
        // 1 eth = 1000$ 
        // returned value from chainlink will be 1000 * 1e8
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION;
    }



}
