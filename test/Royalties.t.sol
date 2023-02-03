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
    // denominator number is hardcoded in ERC2981 contract
    uint96 _feeDenominator = 10000;
    uint16 maxMintAmount = 5;

    GiversPFP public nftContract;
    ERC20Mintable public paymentTokenContract;

    function setUp() public {
        vm.startPrank(address(0));
        paymentTokenContract = new ERC20Mintable("mitch token", "MITCH");
        nftContract = new GiversPFP(_name,  _symbol, _initNotRevealedUri, _maxSupply, paymentTokenContract, _price, maxMintAmount);
        nftContract.setBaseURI(_initBaseURI);
        nftContract.setAllowListOnly(false);
        
        paymentTokenContract.mint(address(1), 10000000);
        vm.stopPrank();
    }

    function testSetDefaultRoyalty(uint192 salePrice) public {
        // set default royalty for all tokens 
        uint96 _royaltyNumerator = 10000;
        vm.prank(address(0));
        nftContract.setRoyaltyDefault(address(1), _royaltyNumerator);
        vm.startPrank(address(1));
        // mint some tokens
        paymentTokenContract.approve(address(nftContract), 100000);
        nftContract.mint(3);

        // define royalty variables and expected logic - deal with floating numbers
        address royaltyRecevier;
        uint256 actualFee;
        uint256 feePercentage = ((_royaltyNumerator * 10) / _feeDenominator);
        uint256 expectedFee = (feePercentage * salePrice) / 10;

        // get royalty info for token 1 
        (royaltyRecevier, actualFee) = nftContract.royaltyInfo(1, salePrice);
        console.log("fee percentage", feePercentage);
        console.log("expected Fee", expectedFee);
        console.log("actual Fee", actualFee);

        // compare actual and expected royalty fees
        assertEq(royaltyRecevier, address(1));
        assertEq(expectedFee, actualFee);
    }

    function testSetTokenRoyalty(uint192 salePrice) public {
        // set up royalty price for tokenID 2 
        uint96 tokenRoyalty = 3000;
        vm.prank(address(0));
        nftContract.setTokenRoyalty(2, address(1), tokenRoyalty);
        // mint some tokens
        vm.startPrank(address(1));
        paymentTokenContract.approve(address(nftContract), 100000);
        nftContract.mint(3);
        
        // define royalty variables and expected logic - deal with floating numbers
        uint256 tokenFeePercentage = ((tokenRoyalty * 10) / _feeDenominator);
        address royaltyRecevier;
        uint256 actualFee;
        uint256 expectedFee = (tokenFeePercentage * salePrice) / 10;

        // get royalty info for tokenID 2 
        (royaltyRecevier, actualFee) = nftContract.royaltyInfo(2, salePrice);
        console.log("token fee percentage", tokenFeePercentage);
        console.log("expected Fee", expectedFee);
        console.log("actual Fee", actualFee);
        // compare actual and expected royalty fees
        assertEq(royaltyRecevier, address(1));
        assertEq(actualFee, expectedFee);
    }
}
