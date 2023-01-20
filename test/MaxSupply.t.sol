// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import './GiversPFP.t.sol';

contract MaxSupplyTest is GiversPFPTest {
    function setUp() public override {
        super.setUp();
    }

    function testMaxSupply() public {
        // change params to get to max supply quicker
        vm.startPrank(owner);
        nftContract.setAllowListOnly(false);
        nftContract.setMaxMintAmount(255);
        nftContract.setPrice(5);
        // mint tokens for minter four
        paymentTokenContract.mint(minterFour, 5000);
        vm.stopPrank();
        // attempt to mint 1040 nfts when max supply is 1000
        vm.prank(minterOne);
        nftContract.mint(255);
        vm.prank(minterTwo);
        nftContract.mint(255);
        vm.prank(minterThree);
        nftContract.mint(255);
        vm.prank(minterFour);
        vm.expectRevert('cannot exceed the maximum supply of tokens');
        nftContract.mint(255);
        vm.prank(owner);
        // change max supply to actual nfts available
        nftContract.setMaxSupply(1290);
        vm.startPrank(minterFour);
        //attempt to mint past old max supply
        paymentTokenContract.approve(address(nftContract), 5000);
        nftContract.mint(255);
        // verify new total supply is past old max supply
        assertEq(nftContract.totalSupply(), 1020);
    }
}
