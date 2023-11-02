
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;
pragma experimental ABIEncoderV2;


import "forge-std/Test.sol";
import "../src/AuthProxy.sol";


contract TestAuthProxyGeneral is Test {

  function test_sender() public {
    AuthProxy.Call[] memory calls = new AuthProxy.Call[](2);

    calls[0] = AuthProxy.Call(
      address(this),
      abi.encodeCall(TestAuthProxyGeneral.foo, (110)),
      0
    );

    calls[1] = AuthProxy.Call(
      address(this),
      abi.encodeWithSelector(TestAuthProxyGeneral.bar.selector, 220, 0),
      1
    );

    AuthProxy proxy = new AuthProxy();

    bytes[] memory outputs = proxy.proxy(calls);

    assertEq(abi.decode(outputs[0], (uint)), 330);
    assertEq(abi.decode(outputs[1], (uint)), 440);
  }

  function foo(uint n) external returns (uint) {
    assertEq(AuthProxy(msg.sender).getCaller(), address(this));
    assertEq(n, 110);
    return 330;
  }

  function bar(uint m, uint n) external returns (uint) {
    assertEq(m, 220);
    assertEq(n, 330);
    return 440;
  }
}

contract Bar {
  function bar() external pure returns (uint) {
    return 33;
  }
}

contract TestAuthProxyConstructTarget is Test {

  function test_authProxyConstructTarget() public {

    AuthProxy.Call[] memory calls = new AuthProxy.Call[](2);

    calls[0] = AuthProxy.Call(
      address(this),
      abi.encodeCall(TestAuthProxyConstructTarget.foo, ()),
      0
    );

    calls[1] = AuthProxy.Call(
      address(0),
      abi.encodeWithSelector(Bar.bar.selector),
      0
    );

    AuthProxy proxy = new AuthProxy();

    bytes[] memory outputs = proxy.proxy(calls);

    assertEq(abi.decode(outputs[1], (uint)), 33);
  }

  function foo() external returns (Bar, uint) {
    // append a uint just to check it handles it
    return (new Bar(), 1);
  }
}

