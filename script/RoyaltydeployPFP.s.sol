// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import 'forge-std/Script.sol';
import 'forge-std/console.sol';
import '../contracts/GiversPFPRoyalties.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract deployPFPRoyalties is Script {
    using SafeERC20 for IERC20;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
        vm.startBroadcast(deployerPrivateKey);
        string memory name = 'Givers Test Collection';
        string memory symbol = 'GIVRT';
        string memory notRevealedURI = 'ipfs://QmfBaZYhkSnMp7W7rT4LhAphb7h9RhUpPQB8ERchndzyUr/hidden.json';
        address paymentToken = 0xdc31Ee1784292379Fbb2964b3B9C4124D8F89C60;
        uint256 price = 50 ether;
        uint256 maxSupply = 300;
        uint16 maxMintAmount = 100;

        //param mint initial supply for Giveth
        // I think this is the best launch plan - mint 10 for Giveth at the start then use mintTo to issue PFPs piecemeal during our promotional events
        // ETH Denver, myNFT etc... after 10 we still have another 90 earmarked outside the public mint for a later time.
        address exampleGivethDAO = address(2);

        GiversPFP nftContract =
            new GiversPFP(name, symbol, notRevealedURI, maxSupply, IERC20(paymentToken),price, maxMintAmount);
        nftContract.mintTo(10, exampleGivethDAO);
        nftContract.setRoyaltyDefault(exampleGivethDAO, 1000);

        console.log('the address of the contract is', address(nftContract));
        console.log('the owner is ', nftContract.owner());
        console.log('the owner has ETH balance of ', nftContract.owner().balance);
    }
}
