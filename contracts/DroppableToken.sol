pragma solidity 0.5.7;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

/**
 * @notice abstract
 */
contract DroppableToken is ERC20 {

    function setLockDropContract(address _lockDropContract) external;
    function dropTokens(address to, uint256 amount) external;
}