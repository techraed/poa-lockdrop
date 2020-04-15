pragma solidity 0.5.7;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

import "./COLToken.sol";

contract LockDrop {
    using SafeMath for uint256;

    uint256 lockDeadline;
    uint256 dropStartTimeStamp;
    uint256 totalAmountOfTokenDrop;
    uint256 totalLockedWei;

    COLToken lockingToken;

    mapping (address => uint256) public lockedAmounts;

    constructor(COLToken token) public {
        require(address(token) != address(0), "Wrong token address value");
        lockingToken = token;
        totalAmountOfTokenDrop = lockingToken.lockDropSupplyCap();

        lockDeadline = now + 24 hours;
        dropStartTimeStamp = lockDeadline + 7 days;
    }

    function lock() external payable {
        require(lockDeadline > now, "Locking lasts 24 hours from contract creation");
        require(msg.value > 0, "You should stake gt 0 amount of ETH");

        lockedAmounts[msg.sender] = lockedAmounts[msg.sender].add(msg.value);
        totalLockedWei = totalLockedWei.add(msg.value);
    }

    function claim() external {
        require(dropStartTimeStamp <= now, "Drop hasn't been started yet");
        require(hasAmountToClaim(msg.sender), "You don't have tokens to claim");

        (uint256 tokensForClaimer, uint256 ETHForClaimer) = getClaimersAssetValues(msg.sender);
        lockedAmounts[msg.sender] = 0;

        lockingToken.dropTokens(msg.sender, tokensForClaimer);
        require(msg.sender.send(ETHForClaimer), "Eth transfer failed");
    }

    function hasAmountToClaim(address claimer) internal view returns (bool) {
        if (lockedAmounts[claimer] == 0) {
            return false;
        }
        return true;
    }

    function getClaimersAssetValues(address claimer) internal view returns (uint256, uint256) {
        uint256 tokensForClaimer = (totalAmountOfTokenDrop.mul(10**36)).div(
            totalLockedWei.mul(lockedAmounts[claimer])
        );
        return (tokensForClaimer, lockedAmounts[claimer]);
    }
}