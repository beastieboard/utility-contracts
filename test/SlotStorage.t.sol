
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;
pragma experimental ABIEncoderV2;


import "forge-std/Test.sol";
import "../src/SlotStorage.sol";


contract TestSlotStorage is Test {
  bytes32 slot = "test.storage";

  function test_basic() public {
    uint128 n = 3094850098214550198875587563;

    uint32 offset = 0;

    SlotStorage.set(slot, 128, 0, offset, n);
    assertEq(SlotStorage.get(slot, 128, 0, offset), n);

    offset = 1;

    SlotStorage.set(slot, 128, 0, offset, n);
    assertEq(SlotStorage.get(slot, 128, 0, offset), n);
  }
}

