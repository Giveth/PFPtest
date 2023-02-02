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
    uint16 _royaltyFee = 100;
    GiversPFP public nftContract;
    ERC20Mintable public paymentTokenContract;

    function setUp() public {
        vm.startPrank(address(0));
        paymentTokenContract = new ERC20Mintable("mitch token", "MITCH");
        nftContract = new GiversPFP(_name,  _symbol, _initNotRevealedUri, _maxSupply, paymentTokenContract, _price);
        nftContract.setBaseURI(_initBaseURI);
        nftContract.setAllowListOnly(false);
        paymentTokenContract.mint(address(1), 10000000);
        vm.stopPrank();
    }

    function testSetDefaultRoyalty() public {
        vm.prank(address(0));
        nftContract.setRoyaltyDefault(address(1), _royaltyFee);
        vm.startPrank(address(1));
        paymentTokenContract.approve(address(nftContract), 100000);
        nftContract.mint(3);
        address royaltyRecevier;
        uint256 royaltlyPercentage;
        (royaltyRecevier, royaltlyPercentage) = nftContract.royaltyInfo(1, 1000);
        assertEq(royaltyRecevier, address(1));
        assertEq(royaltlyPercentage, 10);
    }
}
