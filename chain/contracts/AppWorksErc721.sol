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
    /*=================================
   =            LIBRARIES            =
   =================================*/
    using MerkleProof for bytes32[];
    using Strings for uint256;
    using Counters for Counters.Counter;
    /*=================================
   =            MODIFIERS            =
   =================================*/
    modifier isOneTimeMintAmountValid(uint256 _mintAmount) {
        require(_mintAmount > maxMintPerTx, "Over max one time mint amount");
        _;
    }
    /**
     * @notice Check how many NFTs are available to be minted
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
     * @notice Check user has sufficient funds.
     * Solidity witll change ether to wei, so we don't have to multiply 10**18 ourselves
     */
    modifier isValueValid(uint256 _mintAmount) {
        require(msg.value >= price * _mintAmount, "Value is not enough");
        _;
    }
    /*=====================================
   =            CONFIGURABLES            =
   =====================================*/
    Counters.Counter private _nextTokenId;
    uint256 public price = 0.01 ether; // price for each token
    uint256 public constant maxSupply = 100;
    bool public mintActive = false;
    bool public earlyMintActive = false;
    bool public revealed = false; // reveal mystery box or not
    uint256 public earlyMintMaxBalance = 3;
    uint256 public ownerMaxBalance = 20;
    uint256 public userMaxBalance = 10;
    uint256 public maxMintPerTx = 5;
    /*================================
   =            DATASETS            =
   ================================*/
    string public baseURI;
    string public mysteryTokenURI; // mystery box image URL
    bytes32 public merkleRoot; // whitelist root
    mapping(address => uint256) public whiteListClaimed; // whitelist token amounts which already cliameded
    mapping(uint256 => string) private _tokenURIs;
    mapping(address => uint256) public balance;

    constructor() ERC721("AppWorks", "AW") {}

    /*=======================================
   =            PUBLIC FUNCTIONS            =
   =======================================*/
    /**
     * @notice return current total NFT being minted
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current();
    }

    /**
     * @notice See {IERC721Metadata-tokenURI}.
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
     * @notice Early mint function for people on the whitelist
     */
    function earlyMint(bytes32[] calldata _merkleProof, uint256 _mintAmount)
        public
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

    function mint(uint256 _mintAmount)
        public
        payable
        isMintAmountValid(_mintAmount)
        isValueValid(_mintAmount)
    {
        require(mintActive, "Current state is not available for Public Mint");
        _mintAndUpdateCounter(_mintAmount);
    }

    /*=======================================
   =            EXTERNAL FUNCTIONS            =
   =======================================*/

    /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/

    function setOwnerMaxBalance(uint256 _maxBalance) external onlyOwner {
        ownerMaxBalance = _maxBalance;
    }

    function setUserMaxBalance(uint256 _maxBalance) external onlyOwner {
        userMaxBalance = _maxBalance;
    }

    /**
     *  @notice set new merkle root
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice withdraw funds from the contract
     */
    function withdrawBalance() external onlyOwner {
        require(address(this).balance > 0, "Balance is 0");
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Withdraw failed");
    }

    /**
     * @notice set the mint price
     */
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function toggleMint() external onlyOwner {
        mintActive = !mintActive;
    }

    function toggleReveal() external onlyOwner {
        revealed = !revealed;
    }

    function toggleEarlyMint() external onlyOwner {
        earlyMintActive = !earlyMintActive;
    }

    // TODO: Let this contract can be upgradable, using openzepplin proxy library - week 10
    // TODO:  Try to modify blind box images by using proxy

    /*==========================================
   =            INTERNAL FUNCTIONS            =
   ==========================================*/
    function _mintAndUpdateCounter(uint256 _mintAmount) internal {
        uint256 tokenId = _nextTokenId.current();
        require(
            tokenId + _mintAmount < maxSupply,
            "Require amount is over total supply"
        );
        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(msg.sender, tokenId);
            tokenId++; // 一定不會超過 100，所以不會爆掉
        }
        _nextTokenId._value = tokenId;
        balance[msg.sender] += _mintAmount; // 一定不會超過 20
    }

    /**
     *  @notice return the NFT base URI
     *  ex: image base url...
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     *  @notice return mystry box image
     *  ex: mystry box image url...
     */
    function _mysteryTokenURI() public view returns (string memory) {
        return mysteryTokenURI;
    }
}
