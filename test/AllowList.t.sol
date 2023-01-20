// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import './GiversPFP.t.sol';

contract WhitelistTest is GiversPFPTest {
    function setUp() public override {
        super.setUp();
    }

    function testFailAllowListMint() public {
        // test trying to mint not being on allow list
        vm.prank(minterOne);
        nftContract.mint(1);
        uint256 contractBalance = paymentTokenContract.balanceOf(address(nftContract));
        console.log(contractBalance);
        // add to allow list - test minting over max amount
        vm.prank(owner);
        nftContract.addToAllowList(minterOne);
        vm.prank(minterOne);
        //        nftContract.mint(mintAmount);
        //
    }

    function testAllowListMint() public {
        vm.startPrank(owner);
        // test minting 1 token from owner - should not cost tokens
        nftContract.mint(1);
        // allow minter one to mint tokens
        nftContract.addToAllowList(minterOne);
        vm.stopPrank();
        // mint 1 token to minterOne check contract balance
        vm.startPrank(minterOne);
        nftContract.mint(1);
        assertEq(paymentTokenContract.balanceOf(address(nftContract)), _price);
        // mint 3 tokens to minterThree check contract balance
        nftContract.mint(3);
        assertEq(paymentTokenContract.balanceOf(address(nftContract)), _price * 4);
        vm.stopPrank();
        // remove from allow list
        vm.prank(owner);
        nftContract.removeFromAllowList(minterOne);
        // attempt to mint while not on allow list
        vm.startPrank(minterOne);
        vm.expectRevert('address is not on the allow list to mint!');
        nftContract.mint(1);
        vm.stopPrank();
    }

    function testBatchAllowListMint() public {
        vm.prank(owner);
        // define allowlist array
        address[] memory allowList = new address[](3);
        allowList[0] = minterOne;
        allowList[1] = minterTwo;
        allowList[2] = minterThree;
        // add array to allowlist
        nftContract.addBatchToAllowList(allowList);
        // mint nfts for each
        vm.prank(minterOne);
        nftContract.mint(2);
        vm.prank(minterTwo);
        nftContract.mint(3);
        vm.prank(minterThree);
        nftContract.mint(1);
        // check balance is correct
        assertEq(paymentTokenContract.balanceOf(address(nftContract)), _price * 6);
    }

    function testOpenMint() public {
        // turn off allow list
        vm.prank(owner);
        nftContract.setAllowListOnly(false);
        // mint a pfp
        vm.prank(minterOne);
        nftContract.mint(1);
        assertEq(paymentTokenContract.balanceOf(address(nftContract)), _price);
        // mint 3 more pfps
        vm.prank(minterTwo);
        nftContract.mint(3);

        // check balance of contract after minting 4 total pfps
        assertEq(paymentTokenContract.balanceOf(address(nftContract)), _price * 4);
    }

    function testFailOpenMint(uint32 _mintAmount) public {
        // turn off allow list
        vm.prank(owner);
        nftContract.setAllowListOnly(false);
        // minter four has no payment tokens
        vm.startPrank(minterFour);
        paymentTokenContract.approve(address(nftContract), _price);
        nftContract.mint(1);
        vm.stopPrank();
        // minter four has tokens, but less than minting price
        vm.prank(owner);
        paymentTokenContract.mint(minterFour, _price - 1);
        vm.prank(minterFour);
        nftContract.mint(1);
        // minter one tries to mint over max amount
        vm.prank(minterOne);
        nftContract.mint(_mintAmount);
    }
}
