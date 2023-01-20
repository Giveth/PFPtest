// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Givers PFP Collection by Giveth minter contract
/// @notice modified from Hashlips NFT art engine contracts - https://github.com/HashLips/hashlips_nft_contract
/// @notice This contract contains features for an allow list, art reveal/metadata management and payment for NFTs with ERC20 tokens
contract GiversPFP is ERC721Enumerable, Ownable, Pausable {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    event Withdraw(address address_, uint256 amount_);
    event ChangedURI(string oldURI_, string newURI_);
    event UpdateAllowList(string updatedType_, address address_);
    event RevealArt();
    event UpdatedPrice(uint256 oldPrice_, uint256 newPrice_);
    event UpdatedPaymentToken(address oldPaymentToken_, address newPaymentToken_);
    event UpdatedMaxMint(uint8 mintAmount_);
    event UpdatedMaxSupply(uint256 maxSupply_);

    string private baseURI;
    string private baseExtension = ".json";
    uint256 public price;
    uint256 public maxSupply = 1000;
    string public notRevealedUri;
    mapping(address => bool) public allowList;
    IERC20 public paymentToken;
    uint8 public maxMintAmount = 5;
    bool public revealed = false;
    bool public allowListOnly = true;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory notRevealedUri_,
        IERC20 paymentToken_,
        uint256 price_
    ) ERC721(name_, symbol_) {
        notRevealedUri = notRevealedUri_;
        paymentToken = paymentToken_;
        price = price_;
    }

    /// @notice the ipfs CID hash of where the nft metadata is stored
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @notice This function will mint multiple NFT tokens to an address
    /// @notice charges a final price calculcated by the # of NFTs to mint * the base price per NFT
    /// @param mintAmount_ the amount of NFTs you wish to mint, cannot exceed the maxMintAmount variable
    function mint(uint256 mintAmount_) external whenNotPaused {
        uint256 supply = totalSupply();
        require(mintAmount_ > 0, "must mint at least 1 token.");
        require(mintAmount_ <= maxMintAmount, "cannot mint more than the maximum amount in one tx.");
        require(supply + mintAmount_ <= maxSupply, "cannot exceed the maximum supply of tokens");

        if (msg.sender != owner()) {
            require(!allowListOnly || allowList[msg.sender], "address is not on the allow list to mint!");
            paymentToken.safeTransferFrom(msg.sender, address(this), price * mintAmount_);
            // check w/ amin how to check return from safetransfer calls
            // require(success, "payment transaction has failed! Try again");
        }

        for (uint256 i = 1; i <= mintAmount_; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    /// @notice function use to toggle on and off the allow list, when the allow list is on (true) only users on the allow list can call the mint() function
    /// @param allowListOnly_ controls to set the allow list on (true) or off (false)
    function setAllowListOnly(bool allowListOnly_) external onlyOwner {
        allowListOnly = allowListOnly_;
    }

    /// @notice internal function to add a given address to the allow list, allowing it to call mint when allow list is on
    /// @param address_ the address you wish to add to the allow list
    function _addToAllowList(address address_) internal {
        allowList[address_] = true;
        emit UpdateAllowList("add", address_);
    }

    /// @notice add a given address to the allow list, allowing it to call mint when allow list is on
    /// @param address_ the address you wish to add to the allow list
    function addToAllowList(address address_) external onlyOwner {
        allowList[address_] = true;
        emit UpdateAllowList("add", address_);
    }

    /// @notice adds an array of specified addresses to the allow list, allowing them to call mint when allow list is on
    /// @param addresses_ an array of the addresses you wish to add to the allow list
    function addBatchToAllowList(address[] memory addresses_) external onlyOwner {
        for (uint256 i = 0; i < addresses_.length; i++) {
            _addToAllowList(addresses_[i]);
            emit UpdateAllowList("add", addresses_[i]);
        }
    }

    /// @notice removes an address from the allow list, preventing them from calling mint when allow list is on
    /// @param address_ the address you wish to remove from the allow list
    function removeFromAllowList(address address_) external onlyOwner {
        allowList[address_] = false;
        emit UpdateAllowList("remove", address_);
    }

    /// @notice shows which NFT IDs are owned by a specific address
    /// @param owner_ the address you wish to check for which NFT IDs they own.
    function walletOfOwner(address owner_) external view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(owner_);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i = 0; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner_, i);
        }
        return tokenIds;
    }

    /// @notice displays the ipfs link to where the metadata is stored for a specific NFT ID
    /// @param tokenId the NFT ID of which you wish to get the ipfs CID hash for
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory baseURI_ = _baseURI();
        return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, tokenId.toString(), baseExtension)) : "";
    }

    /// @notice change the ipfs CID hash of where the nft metadata is stored. effectively can change the metadata of all nfts
    /// @param baseURI_ the ipfs CID you wish to change the base URI to
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _setBaseURI(baseURI_);
    }

    /// @notice internal function to change the ipfs CID hash of where the nft metadata is stored. effectively can change the metadata of all nfts
    /// @param baseURI_ the ipfs CID you wish to change the base URI to
    function _setBaseURI(string memory baseURI_) internal {
        string memory oldURI = baseURI;
        baseURI = baseURI_;
        emit ChangedURI(oldURI, baseURI);
    }

    /// @notice changes the metadata for all nfts from the base "hidden" image and nft metadata to the final unique artwork and metadata for the collection
    /// @param baseURI_ the ipfs CID where the final metadata is stored
    function reveal(string memory baseURI_) external onlyOwner {
        _setBaseURI(baseURI_);
        revealed = true;
        emit RevealArt();
    }

    /// @notice changes the price per NFT in the specified ERC20 token
    /// @param newPrice_ the new price to pay per NFT minted
    function setPrice(uint256 newPrice_) external onlyOwner {
        uint256 oldPrice = price;
        price = newPrice_;
        emit UpdatedPrice(oldPrice, price);
    }

    /// @notice changes the ERC20 token accepted to pay for NFTs to mint
    /// @param paymentToken_ the address of a compatible ERC20 token to accept as payments
    /// @dev make sure to change where the approve method is called before mint() to match the new token after calling this function
    function setPaymentToken(IERC20 paymentToken_) external onlyOwner {
        address oldPaymentToken = address(paymentToken);
        paymentToken = paymentToken_;
        emit UpdatedPaymentToken(oldPaymentToken, address(paymentToken));
    }

    /// @notice change the maximum amount of NFTs of this collection that can be minted in on tx with mint()
    /// @param maxMintAmount_ the new maximum of NFTs that can be minted in one tx (max 256)
    function setMaxMintAmount(uint8 maxMintAmount_) external onlyOwner {
        // Uint8 type max amount is 255
        // require(maxMintAmount_ <= 255, "beyond safe amount to mint at once");
        maxMintAmount = maxMintAmount_;
        emit UpdatedMaxMint(maxMintAmount);
    }

    /// @notice change the maximum supply of the NFT collection - used to extend the collection if there is more art available
    /// @param maxSupply_ the new max supply of the nft collection
    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
        emit UpdatedMaxSupply(maxSupply_);
    }

    /// @notice changes the base filename extension for the ipfs stored metadata (not images), by default this should be .json
    /// @param baseExtension_ the new filename extension for nft metadata
    function setBaseExtension(string memory baseExtension_) external onlyOwner {
        baseExtension = baseExtension_;
    }

    /// @notice pauses the contract, preventing any functions from being called
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice unpauses the contract, allowing functions to be called
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice withdraws all payment token funds held by this contract to the contract owner address
    function withdraw() external onlyOwner {
        uint256 tokenBalance = paymentToken.balanceOf(address(this));
        require(tokenBalance != 0, "no funds to withdraw!");
        paymentToken.safeTransfer(owner(), tokenBalance);
        emit Withdraw(owner(), tokenBalance);
    }
}
