pragma solidity 0.5.7;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

import "./DroppableToken.sol";

contract LockDrop {
    using SafeMath for uint256;

    uint256 totalAmountOfDrop;
    uint256 lockEndTimestamp;
    uint256 dropStartTimeStamp;

    DroppableToken lockingToken;

    mapping (address => uint256) public lockedAmount;

    constructor(DroppableToken token) public {
        require(address(token) != address(0), "Wrong token address value");
        lockingToken = token;
        totalAmountOfDrop = lockingToken.dropCap();

        lockEndTimestamp = now + 24 hours;
        dropStartTimeStamp = lockEndTimestamp + 7 days;
    }

    function lock() external payable {
        require(lockEndTimestamp > now, "Locking lasts 24 hours from contract creation");
        require(msg.value > 0, "You should stake gt 0 amount of ETH");
        lockedAmount[msg.sender] = msg.value;
    }

    function claim() external {
        require(hasAmountToClaim(msg.sender), "You don't have tokens to claim");
        uint256 COLForClaimer = totalAmountOfDrop.div(
            address(this).balance.mul(lockedAmount[msg.sender])
        );
        lockedAmount[msg.sender] = 0;
        lockingToken.dropTokens(msg.sender, COLForClaimer);
    }

    function hasAmountToClaim(address claimer) internal view returns (bool) {
        if (lockedAmount[claimer] == 0) {
            return false;
        }
        return true;
    }
}