// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import './GiversPFP.t.sol';

contract WithdrawTest is GiversPFPTest {
    function setUp() public override {
        super.setUp();
    }

    function testWithdraw() public {
        // turn off allow list
        vm.prank(owner);
        nftContract.setAllowListOnly(false);
        // mint 9 tokens total from three users
        vm.prank(minterOne);
        nftContract.mint(3);
        vm.prank(minterTwo);
        nftContract.mint(3);
        vm.prank(minterThree);
        nftContract.mint(3);
        // check contract token balance
        assertEq(paymentTokenContract.balanceOf(address(nftContract)), _price * 9);
        // call withdraw - can be called by anyone
        vm.prank(owner);
        nftContract.withdraw();
        // ensure owner address receives funds, nft contract is emptied
        assertEq(paymentTokenContract.balanceOf(owner), _price * 9);
        assertEq(paymentTokenContract.balanceOf(address(nftContract)), 0);
    }

    function testFailWithdraw() public {
        // turn off allow list
        vm.prank(owner);
        nftContract.setAllowListOnly(false);
        nftContract.withdraw();
        // mint 9 tokens total from three users
        vm.prank(minterOne);
        nftContract.mint(3);
        vm.prank(minterTwo);
        nftContract.mint(3);
        vm.prank(minterThree);
        nftContract.mint(3);
        // call withdraw - can be called by anyone
        nftContract.withdraw();
        nftContract.withdraw();
    }
}
