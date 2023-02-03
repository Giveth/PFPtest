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
    uint256 _maxSupply = 300;
    uint16 maxMintAmount = 5;

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
        nftContract =
            new GiversPFP(_name,  _symbol, _initNotRevealedUri, _maxSupply, paymentTokenContract, _price, maxMintAmount);
        // turn off allow list - allow open minting
        nftContract.setAllowListOnly(false);
        // mint payment tokens for test accts one, two and three
        paymentTokenContract.mint(minterOne, 100000);
        paymentTokenContract.mint(minterTwo, 100000);
        paymentTokenContract.mint(minterThree, 100000);
        nftContract.setBaseURI(_initBaseURI);
        vm.stopPrank();
        // approve payments to nft contract
        vm.prank(minterOne);
        paymentTokenContract.approve(address(nftContract), 5000);
        vm.prank(minterTwo);
        paymentTokenContract.approve(address(nftContract), 5000);
        vm.prank(minterThree);
        paymentTokenContract.approve(address(nftContract), 5000);
    }

    function testOpenMint() public {
        // mint a pfp
        assertEq(paymentTokenContract.balanceOf(address(nftContract)), 0);
        vm.prank(minterOne);
        nftContract.mint(1);
        assertEq(paymentTokenContract.balanceOf(address(nftContract)), _price);
        // mint 3 more pfps
        vm.prank(minterTwo);
        nftContract.mint(3);
        // check balance of contract after minting 4 total pfps
        assertEq(paymentTokenContract.balanceOf(address(nftContract)), _price * 4);
    }

    function testFailOpenMint() public {
        // minter four has no payment tokens
        vm.startPrank(minterFour);
        paymentTokenContract.approve(address(nftContract), _price);
        nftContract.mint(1);
    }

    function testFailNotEnoughFunds() public {
        // minter four has tokens, but less than minting price
        vm.prank(owner);
        paymentTokenContract.mint(minterFour, _price - 1);
        vm.startPrank(minterFour);
        paymentTokenContract.approve(address(nftContract), _price);
        nftContract.mint(1);
    }

    function testFailMintOverMax() public {
        // minter four tries to mint over max amount
        vm.prank(owner);
        paymentTokenContract.mint(minterFour, 1000000000);
        vm.startPrank(minterFour);
        paymentTokenContract.approve(address(nftContract), 1000000000);
        nftContract.mint(nftContract.maxMintAmount() + 1);
    }
}
