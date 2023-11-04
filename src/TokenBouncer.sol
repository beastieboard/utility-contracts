import "lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "lib/solady/src/utils/SafeTransferLib.sol";
import "./AuthProxy.sol";


/*
 * This contract is a way to perform an authenticated ERC20 / ERC721 transfer
 * as part of a transaction that makes many calls (i.e., using ./AuthProxy.sol').
 *
 * It's neccesary, since we can't give authorizations to AuthProxy itself, since
 * it doesn't authenticate the user or have any idea what the hell it's doing.
 */

contract TokenBouncer {

  // AuthProxy address is immutably spliced into the contract code
  AuthProxy immutable AUTH_PROXY;

  // constructor
  constructor(AuthProxy authProxy) { AUTH_PROXY = authProxy; }

  // Get auth proxy
  function getAuthProxy() external view returns (AuthProxy) {
    return AUTH_PROXY;
  }

  // Proxy a transfer to an ERC20 contract where the caller has given
  // authorization to the TokenBouncer. Should also work for ERC721.
  //
  // Aware of AuthProxy so that the transaction can also make other calls.
  //
  function transfer(IERC20 token, address to, uint amount) external {

    // From is sender, but we check if it's coming from AuthProxy
    // This obviously depends on not being able to spoof the sender address
    // in AuthProxy.
    address from = msg.sender;
    if (from == address(AUTH_PROXY)) {
      from = AUTH_PROXY.getCaller();
    }

    SafeTransferLib.safeTransferFrom(address(token), from, to, amount);
  }
}

