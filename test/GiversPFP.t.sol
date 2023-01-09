// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/Test.sol";
import "ds-test/test.sol";
import "../src/GiversPFP.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mintable is ERC20, Ownable {
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }
}

contract TestGiversNFT is Test {
    string _initBaseURI = "ipfs://QmTSadPfscgJMjti4SEaqiLuZ4rVg1wckrRSdo8hqG9M4U/";
    string _initNotRevealedUri = "ipfs://QmfBaZYhkSnMp7W7rT4LhAphb7h9RhUpPQB8ERchndzyUr/hidden.json";
    string _name = "testPFP";
    string _symbol = "TEST";
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
        nftContract = new GiversPFP(_name,  _symbol, _initBaseURI, _initNotRevealedUri, paymentTokenContract, _price);
        paymentTokenContract.mint(minterOne, 100000);
        paymentTokenContract.mint(minterTwo, 100000);
        paymentTokenContract.mint(minterThree, 100000);
        vm.stopPrank();
        vm.prank(minterOne);
        paymentTokenContract.approve(address(nftContract), 5000);
        vm.prank(minterTwo);
        paymentTokenContract.approve(address(nftContract), 5000);
        vm.prank(minterThree);
        paymentTokenContract.approve(address(nftContract), 5000);

    }

    function testFailAllowListMint(uint32 mintAmount) public {
        // test trying to mint not being on allow list
        vm.prank(minterOne);
        nftContract.mint(1);
        uint256 contractBalance = paymentTokenContract.balanceOf(address(nftContract));
        console.log(contractBalance);
        // add to allow list - test minting over max amount
        vm.prank(owner);
        nftContract.addToAllowList(minterOne);
        vm.prank(minterOne);
        nftContract.mint(mintAmount);
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
        vm.expectRevert("you are not on the allow list!");
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
        nftContract.toggleAllowList();
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
        nftContract.toggleAllowList();
        // minter four has no payment tokens
        vm.startPrank(minterFour);
        paymentTokenContract.approve(address(nftContract), _price);
        nftContract.mint(1);
        vm.stopPrank();
        // minter four has tokens, but less than minting price
        vm.prank(owner);
        paymentTokenContract.mint(minterFour,_price - 1);
        vm.prank(minterFour);
        nftContract.mint(1);
        // minter one tries to mint over max amount
        vm.prank(minterOne);
        nftContract.mint(_mintAmount);
    }

    function testWithdraw() public {
        // turn off allow list
        vm.prank(owner);
        nftContract.toggleAllowList();
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
        nftContract.withdraw();
        // ensure owner address receives funds, nft contract is emptied
        assertEq(paymentTokenContract.balanceOf(owner), _price * 9);
        assertEq(paymentTokenContract.balanceOf(address(nftContract)), 0);
    }

    function testFailWithdraw() public {
                // turn off allow list
        vm.prank(owner);
        nftContract.toggleAllowList();
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
