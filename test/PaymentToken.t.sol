// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import './GiversPFP.t.sol';

contract PaymentTokenTest is GiversPFPTest {
    function setUp() public override {
        super.setUp();
    }

    function testChangePaymentToken() public {
        // create new ERC20 token
        vm.startPrank(owner);
        ERC20Mintable altPaymentToken = new ERC20Mintable("another token", "ANTO");
        //mint new tokens
        altPaymentToken.mint(minterOne, 5000);
        nftContract.setAllowListOnly(false);
        // change payment token
        nftContract.setPaymentToken(altPaymentToken);
        vm.stopPrank();
        vm.startPrank(minterOne);
        // approve and mint token with new payment token
        altPaymentToken.approve(address(nftContract), 5000);
        nftContract.mint(1);
        vm.stopPrank();
        //verify balance
        assertEq(altPaymentToken.balanceOf(address(nftContract)), _price * 1);
        vm.prank(owner);
        nftContract.withdraw();
        assertEq(altPaymentToken.balanceOf(address(owner)), _price * 1);
    }
}
