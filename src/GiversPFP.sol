// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract GiversPFP is ERC721Enumerable, Ownable, Pausable {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    string private baseURI;
    string private baseExtension = ".json";
    uint256 public price;
    uint256 public maxSupply = 1000;
    uint256 public maxMintAmount = 5;
    bool public revealed = false;
    bool public allowListOnly = true;
    string public notRevealedUri;
    IERC20 public paymentToken;
    mapping(address => bool) public allowList;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory notRevealedUri_,
        IERC20 paymentToken_,
        uint256 price_
    ) ERC721(name_, symbol_) {
        baseURI = baseURI_;
        notRevealedUri = notRevealedUri_;
        paymentToken = paymentToken_;
        price = price_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 mintAmount_) public whenNotPaused {
        uint256 supply = totalSupply();
        require(mintAmount_ > 0); // TODO: add appropriate error message
        require(mintAmount_ <= maxMintAmount); // TODO: add appropriate error message
        require(supply + mintAmount_ <= maxSupply); // TODO: add appropriate error message

        if (msg.sender != owner()) {
            require(!allowListOnly || allowList[msg.sender], "is not allowed to mint");
            paymentToken.safeTransferFrom(msg.sender, address(this), price * mintAmount_);
        }

        for (uint256 i = 1; i <= mintAmount_; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function setAllowListOnly(bool allowListOnly_) public onlyOwner {
        allowListOnly = allowListOnly_;
    }

    function _addToAllowList(address address_) internal {
        allowList[address_] = true;
    }

    function addToAllowList(address address_) public onlyOwner {
        allowList[address_] = true;
    }

    function addBatchToAllowList(address[] memory addresses_) public onlyOwner {
        for (uint256 i = 0; i < addresses_.length; i++) {
            _addToAllowList(addresses_[i]);
        }
    }

    function removeFromAllowList(address address_) public onlyOwner {
        allowList[address_] = false;
    }

    function walletOfOwner(address owner_) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(owner_);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner_, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory baseURI_ = _baseURI();
        return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, tokenId.toString(), baseExtension)) : "";
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setPrice(uint256 newPrice_) public onlyOwner {
        price = newPrice_;
    }

    function setPaymentToken(IERC20 paymentToken_) public onlyOwner {
        paymentToken = paymentToken_;
    }

    function setMaxMintAmount(uint256 maxMintAmount_) public onlyOwner {
        maxMintAmount = maxMintAmount_;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function setBaseExtension(string memory baseExtension_) public onlyOwner {
        baseExtension = baseExtension_;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw() public {
        uint256 tokenBalance = paymentToken.balanceOf(address(this));
        require(tokenBalance != 0, "no funds to withdraw!");
        paymentToken.transfer(owner(), tokenBalance);
    }
}
