pragma solidity 0.5.7;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

import "./LockDrop.sol";

contract COLToken is Ownable, ERC20 {
    using SafeMath for uint256;

    enum MintReason {TEAM, LOCKDROP, STAKING}

    string public constant name    = "COL";
    string public constant symbol  = "COL";
    uint8 public constant decimals = 18;

    // Total supply cap - 200 billions;
    uint256 public constant teamSupply     =  40000000000; // 40 billions
    uint256 public constant lockDropSupply =  20000000000; // 20 billions
    uint256 public constant stakingSupply  = 140000000000; // 140 billions

    uint256 public tokensDropped;
    LockDrop public lockDropContract;

    uint256 public tokensSend2Team;
    address public teamMultisig;

    uint256 public tokensStaked;
    address public stakingMultisig;

    constructor(address teamMultisig_, address stakingMultisig_) public {
        teamMultisig = teamMultisig_;
        stakingMultisig = stakingMultisig_;

        _mint(teamMultisig, teamSupply);
        _mint(stakingMultisig, stakingSupply);
    }

    function beginLockDrop() external onlyOwner {
        lockDropContract = new LockDrop(COLToken(this), lockDropSupply);
        _mint(address(lockDropContract), lockDropSupply);
    }
}