// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "hardhat/console.sol";

// 📜 ERC721 Library
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// 📜 Auth Library for varify ownership
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
import "@openzeppelin/contracts/access/Ownable.sol";

// 📜 Counter Library for calculate tokenId
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol
import "@openzeppelin/contracts/utils/Counters.sol";

// 📜 Merkle Tree Library for implement whitelist
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MerkleProof.sol
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract AppWorks is ERC721, Ownable {
    using MerkleProof for bytes32[];
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _nextTokenId;
    // token 多少錢
    uint256 public price = 0.01 ether;
    // 總供應量
    uint256 public constant maxSupply = 100;
    // 公開販售
    bool public mintActive = false;
    // 事前販售
    bool public earlyMintActive = false;
    // 盲盒揭露

    bool public revealed = false;
    // 回傳 JSON 存放 NFT 在區塊鏈外的資訊
    string public baseURI;
    string public mysteryTokenURI;

    bytes32 public merkleRoot;
    mapping(address => uint256) public whiteListClaimed;
    uint public earlyMintMaxBalance = 3;

    mapping(uint256 => string) private _tokenURIs;
    mapping(address => uint256) public balance;

    uint public ownerMaxBalance = 20;
    uint public userMaxBalance = 10;
    uint256 public maxMintAmountOneTime = 5;

    constructor() ERC721("AppWorks", "AW") {}

    modifier isOneTimeMintAmountValid(uint256 _mintAmount) {
        require(
            _mintAmount > maxMintAmountOneTime,
            "Over max one time mint amount"
        );
        _;
    }

    /**
     * @dev Check how many NFTs are available to be minted
     *  Set mint per user limit to 10 and owner limit to 20 - Week 8
     */
    modifier isMintAmountValid(uint256 _mintAmount) {
        uint256 totalBalance = balance[msg.sender] += _mintAmount;
        require(
            totalBalance <=
                (owner() == msg.sender ? ownerMaxBalance : userMaxBalance),
            "Token quentity is out of range"
        );
        _;
    }

    /**
     * @dev Check user has sufficient funds
     * Solidity 底層會自己把 ether 轉 wei 計算，不用再轉
     */
    modifier isValueValid(uint256 _mintAmount) {
        require(msg.value >= price * _mintAmount, "Value is not enough");
        _;
    }

    function mint(uint256 _mintAmount)
        public
        payable
        isMintAmountValid(_mintAmount)
        isValueValid(_mintAmount)
    {
        require(mintActive, "Current state is not available for Public Mint");
       _mintAndUpdateCounter(_mintAmount);
    }

    function _mintAndUpdateCounter(uint256 _mintAmount) internal{
        uint256 tokenId = _nextTokenId.current();
        require(
            tokenId + _mintAmount < maxSupply,
            "Require amount is over total supply"
        );
        for (uint i = 0; i < _mintAmount; i++) {
            _safeMint(msg.sender, tokenId);
            tokenId++; // 一定不會超過 100，所以不會爆掉
        }
        _nextTokenId._value = tokenId;
        balance[msg.sender] += _mintAmount; // 一定不會超過 20
    }

    /**
     * @dev Early mint function for people on the whitelist - week 9
     */
    function earlyMint(bytes32[] calldata _merkleProof, uint256 _mintAmount)
        external
        payable
        isMintAmountValid(_mintAmount)
        isValueValid(_mintAmount)
    {
        require(
            earlyMintActive,
            "Current state is not available for Early Mint."
        );
        require(
            whiteListClaimed[msg.sender] + _mintAmount < earlyMintMaxBalance,
            "Amount run out of early lint quota"
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            _merkleProof.verify(merkleRoot, leaf),
            "Incorrect proof, current user is not in the whitelist"
        );
        _mintAndUpdateCounter(_mintAmount);
    }

    /**
     * @dev Function to return current total NFT being minted - week 8
     * NFT 總供應量
     */
    function totalSupply() public view returns (uint) {
        return _nextTokenId.current();
    }

    // 提領餘額
    // Implement withdrawBalance() Function to withdraw funds from the contract - week 8
    function withdrawBalance() external onlyOwner {
        require(address(this).balance > 0, "Balance is 0");
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Withdraw failed");
    }

    // 設定價格
    // Implement setPrice(price) Function to set the mint price - week 8
    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }

    // 決定能不能開採
    // Implement toggleMint() Function to toggle the public mint available or not - week 8
    function toggleMint() external onlyOwner {
        mintActive = !mintActive;
    }

    // Implement toggleReveal() Function to toggle the blind box is revealed - week 9
    function toggleReveal() external onlyOwner {
        revealed = !revealed;
    }

    // Implement setBaseURI(newBaseURI) Function to set BaseURI - week 9
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        if (revealed) {
            string memory baseURI = _baseURI();
            return
                bytes(baseURI).length > 0
                    ? string(
                        abi.encodePacked(baseURI, tokenId.toString(), ".json")
                    )
                    : "";
        } else {
            return mysteryTokenURI;
        }
    }

    /**
     *  @dev Function to return the NFT base URI
     *  ex: image url...
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _mysteryTokenURI() public view returns (string memory) {
        return mysteryTokenURI;
    }

    function setOwnerMaxBalance(uint256 _maxBalance) public onlyOwner {
        ownerMaxBalance = _maxBalance;
    }

    function setUserMaxBalance(uint256 _maxBalance) public onlyOwner {
        userMaxBalance = _maxBalance;
    }

    /**
     *  @dev Implement toggleEarlyMint() Function to toggle the early mint available or not - week 9
     */
    function toggleEarlyMint() public onlyOwner {
        earlyMintActive = !earlyMintActive;
    }

    /**
     *  @dev Implement setMerkleRoot(merkleRoot) Function to set new merkle root - week 9
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
    // Let this contract can be upgradable, using openzepplin proxy library - week 10
    // Try to modify blind box images by using proxy
}
