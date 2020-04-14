pragma solidity 0.5.7;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";

import "./DroppableToken.sol";

contract LockDrop {

    uint256 createdWhen;

    DroppableToken lockingToken;

    mapping (address => uint256) public lockedAmount;

    constructor(DroppableToken token) public {
        require(address(token) != address(0), "Wrong token address value");
        lockingToken = token;
        createdWhen = now;
    }

    function lock() external payable {
        // restrictions?
        lockedAmount[msg.sender] = msg.value;
    }

    function claim() external {
        uint256 COLForClaimer = 20000000000/(address(this).balance * lockedAmount[msg.sender]);
        lockedAmount[msg.sender] = 0;
        lockingToken.dropTokens(msg.sender, COLForClaimer);
    }
}