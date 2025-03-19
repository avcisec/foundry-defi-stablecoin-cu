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




/** 
* @title DSCEngine
* @author 0xavci
*
*This system is designed to be as minimal as possible. 1 token == $1 peg.
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

contract DSCEngine {

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          Errors                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error DSCEngine__CanNotBeZero();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          State Variables                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    mapping(address token => address priceFeed) private s_priceFeeds;


    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          Modifiers                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


    modifier amountMoreThanZero(uint256 amount) {
        if( amount == 0)
        revert DSCEngine__CanNotBeZero();
        _;
    }

    // modifier isAllowedToken(address tokenCollateralAddress) {

    //     if(tokenCollateralAddress !=)
    //     _;
    // }



    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          Functions                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // ETH / USD 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
    // BTC / USD 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c

    constructor() {}

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      External Functions                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function depositCollateralAndMintDsc() external {}

    /*
    * @param tokenCollateralAdress is the address of  Token to deposit as collateral.
    * @param amountCollateral The amount of collateral to deposit as collateral.
    * 
    */    

    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral) external amountMoreThanZero(amountCollateral) {

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