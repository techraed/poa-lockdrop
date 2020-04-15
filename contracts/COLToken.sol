pragma solidity 0.5.7;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract COLToken is Ownable, ERC20 {
    using SafeMath for uint256;

    enum MintReason {TEAM, LOCKDROP, STAKING}

    string public constant name    = "COL";
    string public constant symbol  = "COL";
    uint8 public constant decimals = 18;

    uint256 public constant teamSupplyCap     =  40000000000; // 40 billions
    uint256 public constant lockDropSupplyCap =  20000000000; // 20 billions
    uint256 public constant stakingSupplyCap  = 140000000000; // 140 billions
    uint256 public constant totalSupplyCap    = 200000000000; // 200 billions

    uint256 public tokensDropped;
    address public lockDropContract;

    uint256 public tokensSend2Team;
    uint256 public tokensStaked;

    constructor() public { }

    function setLDContract(address _lockDropContract) external onlyOwner {
        require(_lockDropContract != address(0), "Wrong contract address value");
        lockDropContract = _lockDropContract;
    }

    function dropTokens(address to, uint256 amount) external {
        require(msg.sender == lockDropContract, "Called only by lock drop token");
        require(checkMintIsValid(MintReason.LOCKDROP, amount), "Minting over lockdrop supply cap");

        tokensDropped = tokensDropped.add(amount);
        _mint(to, amount);
    }

    function checkMintIsValid(MintReason reason, uint256 amount) internal view returns (bool) {
        if (reason == MintReason.TEAM) {
            return tokensSend2Team.add(amount) <= teamSupplyCap;
        }

        if (reason == MintReason.LOCKDROP) {
            return tokensDropped.add(amount) <= lockDropSupplyCap;
        }

        if (reason == MintReason.STAKING) {
            return tokensStaked.add(amount) <= stakingSupplyCap;
        }
        return false;
    }
}