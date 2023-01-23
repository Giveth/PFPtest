// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import 'forge-std/Test.sol';
import 'ds-test/test.sol';
import '../contracts/GiversPFP.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract ERC20Mintable is ERC20, Ownable {
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }
}

contract TestGiversNFT is Test {
    string _initBaseURI = 'ipfs://QmTSadPfscgJMjti4SEaqiLuZ4rVg1wckrRSdo8hqG9M4U/';
    string _initNotRevealedUri = 'ipfs://QmfBaZYhkSnMp7W7rT4LhAphb7h9RhUpPQB8ERchndzyUr/hidden.json';
    string _name = 'testPFP';
    string _symbol = 'TEST';
    uint256 _price = 500;
    GiversPFP public nftContract;
    ERC20Mintable public paymentTokenContract;

    address internal owner = address(1);
    address internal minterOne = address(2);
    address internal minterTwo = address(3);
    address internal minterThree = address(4);
    address internal minterFour = address(5);

    function setUp() public {
        vm.startPrank(owner);
        paymentTokenContract = new ERC20Mintable("mitch token", "MITCH");
        nftContract = new GiversPFP(_name,  _symbol, _initNotRevealedUri, paymentTokenContract, _price);
        paymentTokenContract.mint(minterOne, 100000);
        paymentTokenContract.mint(minterTwo, 100000);
        paymentTokenContract.mint(minterThree, 100000);
        nftContract.setBaseURI(_initBaseURI);
        vm.stopPrank();
        vm.prank(minterOne);
        paymentTokenContract.approve(address(nftContract), 5000);
        vm.prank(minterTwo);
        paymentTokenContract.approve(address(nftContract), 5000);
        vm.prank(minterThree);
        paymentTokenContract.approve(address(nftContract), 5000);
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
        // call withdraw - cannot be called by anyone
        nftContract.withdraw();
        nftContract.withdraw();
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

    function testChangePaymentToken() public {
        // create new ERC20 token
        vm.startPrank(owner);
        ERC20Mintable altPaymentToken = new ERC20Mintable("another token", "ANTO");
        //mint new tokens
        altPaymentToken.mint(minterOne, 5000);
        nftContract.setAllowListOnly(false);
        // change payment token
        nftContract.withdrawAndChangePaymentToken(altPaymentToken);
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
        vm.expectRevert(abi.encodeWithSelector(GiversPFP.ExceedTotalSupplyLimit.selector, 1000));
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
