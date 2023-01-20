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

contract GiversPFPTest is Test {
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

    function setUp() public virtual {
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
}
