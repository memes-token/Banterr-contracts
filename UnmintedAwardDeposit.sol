// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import './MemesToken.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title [Banterr] - Unminted post award $MEMES token deposit contract
 * @author Pwned (https://github.com/Pwnedev)
 */
contract UnmintedAwardDeposit is Context, Ownable {
  MemesToken private _memesToken;

  address public _publicKey;
  bool private _isWithdrawPaused;
  mapping(address => bool) public _withdrawalClaimed;
  
  /**
   * @dev Emitted when a user withdraws their $MEMES tokens
   */
  event Withdraw(address indexed caller, uint256 amount);

  constructor(address memesAddress, address publicKey) Ownable() {
    _memesToken = MemesToken(payable(memesAddress));
    _publicKey = publicKey;
  }

  function withdraw(uint256 amount, uint8 v, bytes32 r, bytes32 s) public {
    require(_isWithdrawPaused == false, "Withdrawal is paused");
    require(_withdrawalClaimed[_msgSender()] == false, "Withdrawal already claimed");

    bytes32 messageHash = keccak256(abi.encodePacked(amount, _msgSender()));
    bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    address signer = ecrecover(prefixedHash, v, r, s);

    require(signer == _publicKey, "Unauthorized");

    _withdrawalClaimed[_msgSender()] = true;

    _memesToken.transfer(_msgSender(), amount);

    emit Withdraw(_msgSender(), amount);
  }

  /**
   * @notice Adds an address to the withdrawal claimed mapping
   */
  function addAddressToWithdrawalClaimed(address user) external onlyOwner() {
    require(_withdrawalClaimed[user] != true, "Address is already set as withdrawal claimed");
    _withdrawalClaimed[user] = true;
  }

  /**
   * @notice Sets the award unminted post public key
   */
  function setPublicKey(address newPublicKey) external onlyOwner() {
    _publicKey = newPublicKey;
  }

  /**
   * @notice Pauses withdrawal of $MEMES tokens if unpaused
   */
  function pauseWithdrawal() external onlyOwner() {
    require(_isWithdrawPaused != true, "Withdrawal is already paused");
    _isWithdrawPaused = true;
  }

  /**
   * @notice Unpauses withdrawal of $MEMES tokens if paused
   */
  function unpauseWithdrawal() external onlyOwner() {
    require(_isWithdrawPaused != false, "Withdrawal is already unpaused");
    _isWithdrawPaused = false;
  }

  /**
   * @dev Function to withdraw "ERC20" tokens from contract
   */
  function withdrawERC20(IERC20 _token) external onlyOwner() {
    uint256 balance = _token.balanceOf(address(this));
    _token.transfer(owner(), balance);
  }

  /**
   * @dev Function to withdraw "ETH" from contract
   */
  function withdrawETH() external onlyOwner() {
    uint256 balance = address(this).balance;
    payable(owner()).transfer(balance);
  }
}