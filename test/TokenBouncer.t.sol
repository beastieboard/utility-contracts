
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;
pragma experimental ABIEncoderV2;


import "forge-std/Test.sol";
import "../src/AuthProxy.sol";
import "../src/TokenBouncer.sol";


contract Token is Test {
  address _owner;
  constructor(address owner) { _owner = owner; }
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public returns (bool) {
    assertEq(from, _owner);
    assertEq(to, address(0xABCD));
    return amount == 0xCDEF;
  }
}

contract TestTokenBouncer is Test {
  function test_tokenBouncer() public {

    Token token = new Token(address(this));

    AuthProxy proxy = new AuthProxy();
    TokenBouncer bouncer = new TokenBouncer(proxy);

    AuthProxy.Call[] memory calls = new AuthProxy.Call[](1);

    calls[0] = AuthProxy.Call(
      address(bouncer),
      abi.encodeCall(TokenBouncer.transfer, (IERC20(address(token)), address(0xABCD), 0xCDEF)),
      0
    );

    bytes[] memory outputs = proxy.proxy(calls);

    assertEq(outputs[0].length, 0);

    // Test failure case, wrong amount causes fail

    calls[0] = AuthProxy.Call(
      address(bouncer),
      abi.encodeCall(TokenBouncer.transfer, (IERC20(address(token)), address(0xABCD), 1)),
      0
    );

    vm.expectRevert(bytes(transferFromFailed));

    outputs = proxy.proxy(calls);
  }
}

