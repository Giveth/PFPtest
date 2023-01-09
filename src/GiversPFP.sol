// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GiversPFP is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string baseURI;
    string public baseExtension = ".json";
    uint256 public price;
    uint256 public maxSupply = 1000;
    uint256 public maxMintAmount = 5;
    bool public paused = false;
    bool public revealed = false;
    bool public allowListOnly = true;
    string public notRevealedUri;
    IERC20 public paymentToken;
    mapping(address => bool) public onAllowList;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri,
        IERC20 _paymentToken,
        uint256 _price
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        paymentToken = IERC20(_paymentToken);
        price = _price;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint256 _mintAmount) public {
        uint256 supply = totalSupply();
        require(!paused);
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(supply + _mintAmount <= maxSupply);

        // UNCHECKED RETURN!!
        if (msg.sender != owner() && !allowListOnly) {
            paymentToken.transferFrom(msg.sender, address(this), price * _mintAmount);
        } else if ((msg.sender != owner() && allowListOnly)) {
            require(onAllowList[msg.sender] == true, "you are not on the allow list!");
            paymentToken.transferFrom(msg.sender, address(this), price  * _mintAmount);
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function toggleAllowList() public onlyOwner {
        if (!allowListOnly) {
            allowListOnly = true;
        } else {
            allowListOnly = false;
        }
    }

    function addToAllowList(address _address) public onlyOwner {
        onAllowList[_address] = true;
    }

    function addBatchToAllowList(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            onAllowList[_addresses[i]] = true;
        }
    }

    function removeFromAllowList(address _address) public onlyOwner {
        onAllowList[_address] = false;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    //only owner
    function reveal() public onlyOwner {
        revealed = true;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public {
        uint256 tokenBalance = paymentToken.balanceOf(address(this));
        require(tokenBalance != 0, "no funds to withdraw!");
        paymentToken.transfer(owner(), tokenBalance);
    }
}
