// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import 'forge-std/Test.sol';
import 'ds-test/test.sol';
import '../contracts/GiversPFPRoyalties.sol';
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
    GiversPFP public nftContract;
    ERC20Mintable public paymentTokenContract;

    address internal owner = address(1);
    address internal minterOne = address(2);
    address internal minterTwo = address(3);
    address internal minterThree = address(4);
    address internal minterFour = address(5);

    event AllowListAdded(address indexed account);
    event AllowListRemoved(address indexed account);

    function setUp() public {
        vm.startPrank(owner);
        paymentTokenContract = new ERC20Mintable("mitch token", "MITCH");
        nftContract = new GiversPFP(_name,  _symbol, _initNotRevealedUri, _maxSupply, paymentTokenContract, _price);
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

    function testFailAllowListMint() public {
        // test trying to mint not being on allow list
        vm.prank(minterOne);
        nftContract.mint(1);
    }

    function testAllowListMint() public {
        vm.startPrank(owner);
        // test minting 1 token from owner - should not cost tokens
        nftContract.mint(1);

        // allow minter one to mint tokens
        vm.expectEmit(true, true, true, true, address(nftContract));
        emit AllowListAdded(minterOne);
        nftContract.addToAllowList(minterOne);

        // mint 1 token to minterOne check contract balance
        vm.stopPrank();
        vm.startPrank(minterOne);

        nftContract.mint(1);
        assertEq(paymentTokenContract.balanceOf(address(nftContract)), _price);
        // mint 3 tokens to minterThree check contract balance
        nftContract.mint(3);
        assertEq(paymentTokenContract.balanceOf(address(nftContract)), _price * 4);
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

        vm.expectEmit(true, true, true, true, address(nftContract));
        emit AllowListAdded(minterOne);
        vm.expectEmit(true, true, true, true, address(nftContract));
        emit AllowListAdded(minterTwo);
        vm.expectEmit(true, true, true, true, address(nftContract));
        emit AllowListAdded(minterThree);

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

        vm.startPrank(minterFour);
        vm.expectRevert(abi.encodeWithSelector(GiversPFP.NotInAllowList.selector, minterFour));
        nftContract.mint(1);
    }

    function testRemoveAllowList() public {
        assertFalse(nftContract.allowList(minterOne));
        vm.prank(owner);
        nftContract.addToAllowList(minterOne);
        assertTrue(nftContract.allowList(minterOne));
        // remove from allow list
        vm.prank(owner);
        vm.expectEmit(true, true, true, true, address(nftContract));
        emit AllowListRemoved(minterOne);

        nftContract.removeFromAllowList(minterOne);
        assertFalse(nftContract.allowList(minterOne));

        // attempt to mint while not on allow list
        vm.startPrank(minterOne);
        vm.expectRevert(abi.encodeWithSelector(GiversPFP.NotInAllowList.selector, minterOne));
        nftContract.mint(1);
    }
}
