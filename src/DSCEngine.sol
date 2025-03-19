// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;



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

    function depositCollateralAndMintDsc() external {

    }

    function redeemCollateralForDsc() external {}

    function burnDsc() external {}

}