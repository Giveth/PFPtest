// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import 'forge-std/Script.sol';
import 'forge-std/console.sol';
import '../contracts/GiversPFP.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract deployPFP is Script {
    using SafeERC20 for IERC20;

    function run() external {
        // set constructor params
        uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
        vm.startBroadcast(deployerPrivateKey);
        string memory name = 'Givers Test Collection';
        string memory symbol = 'GIVRT';
        string memory notRevealedURI = 'ipfs://QmfBaZYhkSnMp7W7rT4LhAphb7h9RhUpPQB8ERchndzyUr/hidden.json';
        address paymentToken = 0xdc31Ee1784292379Fbb2964b3B9C4124D8F89C60;
        uint256 price = 50 ether;
        uint256 maxSupply = 300;
        uint16 maxMintAmount = 100;

        GiversPFP nftContract =
            new GiversPFP(name, symbol, notRevealedURI, maxSupply, IERC20(paymentToken),price, maxMintAmount);
        console.log('the address of the contract is', address(nftContract));
        console.log('the owner is ', nftContract.owner());
        console.log('the owner has ETH balance of ', nftContract.owner().balance);
    }
}
