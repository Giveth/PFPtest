// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import './GiversPFP.t.sol';

contract PriceTest is GiversPFPTest {
    function setUp() public override {
        super.setUp();
    }

    function testChangePrice() public {
        vm.startPrank(owner);
        uint256 newPrice = 300;
        nftContract.setPrice(newPrice);
        nftContract.setAllowListOnly(false);
        vm.stopPrank();
        // mint a pfp
        vm.prank(minterOne);
        nftContract.mint(1);
        assertEq(paymentTokenContract.balanceOf(address(nftContract)), newPrice);
        // mint 3 more pfps
        vm.prank(minterTwo);
        nftContract.mint(3);

        // check balance of contract after minting 4 total pfps
        assertEq(paymentTokenContract.balanceOf(address(nftContract)), newPrice * 4);
    }
}
