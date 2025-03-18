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
/*                         IMPORTS                            */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


/*
* @title DecentralizedStableCoin
* @author 0xavci
* Collateral: Exogenous (ETH - BTC)
* Minting: Algorithmic
* Relative Stability: Pegged to USD
* 
* This is the contract meant to be governed by DSCEngine. This is just an ERC20 implamentation of our stablecoin.
*/

contract DecentralizedStableCoin {


}