pragma solidity 0.5.7;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

import "./DroppableToken.sol";

contract COLToken is Ownable, DroppableToken {
    using SafeMath for uint256;

    uint8 public constant decimals = 18;
    string public constant name    = "COL";
    string public constant symbol  = "COL";

    uint256 public constant teamSupplyCap     = 40000000000; // 40 billions
    uint256 public constant lockDropSupplyCap = 20000000000; // 20 billions
    uint256 public constant stakingSupplyCap  = 140000000000; // 140 billions
    uint256 public constant totalSupplyCap    = 200000000000; // 200 billions

    uint256 public tokensDropped;
    address public lockDropContract;

    constructor() public { }

    function setLDContract(address _lockDropContract) external onlyOwner {
        require(_lockDropContract != address(0), "Wrong contract address value");
        lockDropContract = _lockDropContract;
    }

    function dropTokens(address to, uint256 amount) external {
        require(msg.sender == lockDropContract, "Called only by lock drop token");
        require(tokensDropped + amount <= lockDropSupplyCap, "Minting over lockdrop supply cap");

        _mint(to, amount);
    }

    function dropCap() external view returns (uint256) {
        return lockDropSupplyCap;
    }
}