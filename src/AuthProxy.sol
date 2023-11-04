
pragma solidity ^0.8.16;

/*
 * This contract is designed to help a user perform multiple
 * authenticated calls to different contracts in one transaction.
 *
 * In order for applications to authenticate a user calling via this contract,
 * they use the getCaller method, which will return the original msg.sender.
 *
 * Security of this contract depends on not being able to spoof the sender address.
 * It is easy to verify that the sender address is set, once, to msg.sender,
 * near the start of the proxy entry point.
 *
 */

contract AuthProxy {

  // Caller and App (call target) are stored "in memory"
  address _user;
  address _app;

  struct Call {
    address target;
    bytes callData;
    uint copyWords;
  }

  function proxy(Call[] memory calls) external returns (bytes[] memory) {

    require(uint160(_user) <= 1, "auth in use");

    // Set the user so that downstream calls can find the original caller
    _user = msg.sender;

    // Create the outputs array
    bytes[] memory outputs = new bytes[](calls.length);

    for (uint i=0; i<calls.length; i++) {
      runCall(calls[i], i, outputs);
    }

    // Setting to 1 instead of clearing makes usage cheaper overall
    // since the next call will modify rather than allocate (5000 vs 20000 gas)
    // (while waiting for TSTORE)
    _user = _app = address(1);

    return outputs;
  }

  /*
   * Run a call
   */
  function runCall(Call memory call, uint i, bytes[] memory outputs) internal {

    // Check if target refers to a previous output
    address target = call.target;
    if (uint160(target) < i) {
      bytes memory output = outputs[uint160(target)];
      require(output.length > 0, "AuthProxy: replacement target is empty");
      target = abi.decode(output, (address));
    }

    if (call.copyWords > 0) {
      runCopyWords(call, i, outputs);
    }

    _app = target;

    (bool ok, bytes memory rdata) = target.call(call.callData);

    if (!ok) {
      assembly { revert(add(rdata, 32), mload(rdata)) }
    }

    outputs[i] = rdata;
  }

  /*
   * Optionally append arguments (data returned from previous calls) to calldata.
   *
   * Note, that this may not compose in the presence of dynamically sized types.
   */
  function runCopyWords(Call memory call, uint i, bytes[] memory outputs) internal pure {

    bytes memory callData = call.callData;
    uint copyWords = call.copyWords;

    uint r = callData.length % 32;
    require(r == 0 || r == 4, "unknown calldata format");

    while (copyWords > 0) {
      uint destWord = copyWords & 31;
      copyWords >>= 5;
      uint sourceWord = copyWords & 31;
      copyWords >>= 5;
      uint resultIndex = copyWords & 63;
      copyWords >>= 6;

      require(resultIndex < i, "proxyAuth invalid arg index");
      bytes memory output = outputs[resultIndex];

      require(sourceWord * 32 + 32 <= output.length, "proxyAuth invalid arg offset");
      // TODO: require target offset sanity

      assembly {
        mstore(
          add(add(callData, add(r, 32)), mul(destWord, 32)),
          mload(add(add(output, 32), mul(sourceWord, 32)))
        )
      }
    }
  }

  /*
   * Allow callee (and only callee) to get the original caller
   */
  function getCaller() external view returns (address) {
    return msg.sender == _app ? _user : address(0);
  }
}

abstract contract AuthProxyClient {

  function getAuthProxy() internal virtual returns (AuthProxy);

  function getAuthedSender() internal returns (address) {
    AuthProxy proxy = getAuthProxy();

    if (msg.sender == address(proxy)) {
      return proxy.getCaller();
    }

    return msg.sender;
  }
}
