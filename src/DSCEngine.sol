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

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          State Variables                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;

    DecentralizedStableCoin private immutable i_dsc;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          Events                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    event CollateralDeposited(address indexed user, address indexed collateral, uint256 amount);

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
        }
        i_dsc = DecentralizedStableCoin(dscToken);
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
    }

    function redeemCollateral() external {}

    function mintDsc() external {}

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
}
