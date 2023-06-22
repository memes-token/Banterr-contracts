// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import './PostNFT.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title [Banterr] - Post NFT Factory
 * @author Pwned (https://github.com/Pwnedev)
 */
contract PostNFTFactory is Context, Ownable {

    bool private _isCreationPaused; // If true, creation of new Post NFT's is paused

    mapping(string => address) public postNFTAddressMap; // Mapping to store the postId to PostNFT address

    address public postNFTPublicKey; // Address of the PostNFT Public Key

    string public tokenURIBase; // Base URI for the tokenURI of the PostNFT and Awards

    /**
     * @dev Emitted when calling `createPostNFT` successfully creates a new PostNFT
     */
    event NewPostNFT(address indexed postNFTAddress, string postHash, string postId, uint8 supply, address indexed minter);

    /**
     * @dev Emitted when a PostNFT token is transferred
     */
    event PostNFTTransfer(address indexed postNFTAddress, string postId, address indexed from, address indexed to, uint256 tokenId);

    /**
     * @dev Emitted when a PostNFT token is removed from the map
     */
    event RemovePostNFT(string postId);

    constructor(address _postNFTPublicKey, string memory _tokenURIBase) Ownable() {
        postNFTPublicKey = _postNFTPublicKey;
        tokenURIBase = _tokenURIBase;
    }

    /**
     * @notice Pauses creation of new NFT's if not paused
     */
    function pauseCreation() external onlyOwner() {
        require(_isCreationPaused != true, "Creation is already paused");
        _isCreationPaused = true;
    }

    /**
     * @notice Unpauses creation of new NFT's if paused
     */
    function unpauseCreation() external onlyOwner() {
        require(_isCreationPaused != false, "Creation is already unpaused");
        _isCreationPaused = false;
    }

    /**
     * @notice Sets the PostNFT public key
     */
    function setPublicKey(address _postNFTPublicKey) external onlyOwner() {
        postNFTPublicKey = _postNFTPublicKey;
    }

    /**
     * @notice Sets the tokenURI base used for PostNFTs and Awards
     */
    function setTokenURIBase(string memory _tokenURIBase) external onlyOwner() {
        tokenURIBase = _tokenURIBase;
    }

    /**
     * @notice Removes a PostNFT address from the map
     * @param postId The ID of the PostNFT to be removed
     * Only used if the PostNFTFactory's private key was compromised and an invalid PostNFT was created with it
     */
    function removePostNFTAddress(string memory postId) external onlyOwner() {
        require(postNFTAddressMap[postId] != address(0), "PostNFT with the given postId does not exist.");

        delete postNFTAddressMap[postId];

        emit RemovePostNFT(postId);
    }

    /**
     * @notice Emits a PostNFTTransfer event
     */
    function emitPostNFTTransferEvent(string memory postId, address from, address to, uint256 tokenId) external {
        require(postNFTAddressMap[postId] == _msgSender(), "Unauthorized");

        emit PostNFTTransfer(_msgSender(), postId, from, to, tokenId);
    }

    /**
     * @notice Creates new Post NFT and mints given `supply` to the caller address
     * @param postHash Post NFT's IPFS Image Hash
     * @param postId Post NFT's ID
     * @param supply Total Supply or "Number of Copies" of given post
     * @param v v part of the signature
     * @param r r part of the signature
     * @param s s part of the signature
     */
    function createPostNFT(string memory postHash, string memory postId, uint8 supply, uint8 v, bytes32 r, bytes32 s) public {
        require(_isCreationPaused == false, "Creation of new Post NFT's is paused. This may be due to a security issue or migration, contact the developers for more info.");
        require(supply >= 1, "Supply must be between 1 and 10.");
        require(supply <= 10, "Supply must be between 1 and 10.");
        require(postNFTAddressMap[postId] == address(0), "PostNFT with the given postId was already minted.");

        bytes32 messageHash = keccak256(abi.encodePacked(postHash, postId, supply, _msgSender()));
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        address signer = ecrecover(prefixedHash, v, r, s);

        require(signer == postNFTPublicKey, "Unauthorized");

        PostNFT newPostNFT = new PostNFT(postHash, postId, supply, _msgSender());

        postNFTAddressMap[postId] = address(newPostNFT);

        emit NewPostNFT(address(newPostNFT), postHash, postId, supply, _msgSender());
    }

    /**
     * @notice Returns true if creation of new NFT's is paused, false otherwise
     */
    function isCreationPaused() external view returns(bool) {
        return _isCreationPaused;
    }

    /**
     * @notice Returns the PostNFT address for given `postId` and `postHash`
     */
    function getPostNFTAddress(string memory postId) external view returns(address) {
        return postNFTAddressMap[postId];
    }
}