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

    event RevealArt();
    event ChangedURI(string oldURI, string newURI);
    event ChangedBasedExtension(string oldExtension, string newExtension);

    function setUp() public {
        vm.startPrank(owner);
        paymentTokenContract = new ERC20Mintable("mitch token", "MITCH");
        nftContract = new GiversPFP(_name,  _symbol, _initNotRevealedUri, _maxSupply, paymentTokenContract, _price);
        paymentTokenContract.mint(minterOne, 100000);
        nftContract.setAllowListOnly(false);
        vm.stopPrank();
        vm.startPrank(minterOne);
        paymentTokenContract.approve(address(nftContract), 5000);
        nftContract.mint(3);
        vm.stopPrank();
    }

    function testReveal() public {
        // check token metadata matches hidden URI before reveal is called (final art is hidden)
        assertEq(_initNotRevealedUri, nftContract.tokenURI(1));
        vm.startPrank(owner);
        // reveal art - enter in URI - test metadata target has changed
        vm.expectEmit(true, true, true, true, address(nftContract));
        emit ChangedURI('', 'testing/');
        vm.expectEmit(true, true, true, true, address(nftContract));
        emit RevealArt();
        nftContract.reveal('testing/');
        assertEq(nftContract.tokenURI(1), 'testing/1.json');
    }

    function testMetadataCounter() public {
        vm.startPrank(owner);
        // reveal art - enter in URI - test that 3 tokens minted in setup have the correct metadata targets
        nftContract.reveal('testing/');
        assertEq(nftContract.tokenURI(1), 'testing/1.json');
        assertEq(nftContract.tokenURI(2), 'testing/2.json');
        assertEq(nftContract.tokenURI(3), 'testing/3.json');
    }

    function testSetURI() public {
        vm.startPrank(owner);
        // reveal art - enter in URI
        nftContract.reveal('testing/');
        // change URI again with setBaseURI
        vm.expectEmit(true, true, true, true, address(nftContract));
        emit ChangedURI('testing/', 'anotherTest/');
        nftContract.setBaseURI('anotherTest/');
        // should match baseURI now that art has been revealed
        assertEq(nftContract.tokenURI(1), 'anotherTest/1.json');
        vm.stopPrank();
    }

    function testWalletOfOwner() public {
        // test walletOfOwner gives correct token IDs
        uint256[] memory owners = nftContract.walletOfOwner(minterOne);
        assertEq(owners[0], 1);
        assertEq(owners[1], 2);
        assertEq(owners[2], 3);
    }

    function testSetBaseExtension() public {
        vm.startPrank(owner);
        nftContract.reveal('testing/');
        vm.expectEmit(true, true, true, true, address(nftContract));
        emit ChangedBasedExtension('.json', '.txt');
        nftContract.setBaseExtension('.txt');
        assertEq(nftContract.tokenURI(1), 'testing/1.txt');
    }
}
