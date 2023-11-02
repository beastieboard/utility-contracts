
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.16;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Create2.sol";

//
// The Bucket is simply another address that forwards calls from an owner,
// so it can be used to store balances.
//
// Not using Ownable since we dont want the events
// 

// this code cant change. if it does, addr recovery breaks for old buckets. This is also
// true across compiler versions.
contract Bucket {

  address immutable _owner;

  constructor() {
    _owner = msg.sender;
  }

  function forward(address target, bytes memory data) public returns (bytes memory) {
    require(msg.sender == _owner, 'unauthorized');

    (bool ok, bytes memory rdata) = target.call(data);

    if (!ok) {
      if (rdata.length == 0) revert();
      assembly {
        revert(add(32, rdata), mload(rdata))
      }
    }

    return rdata;
  }
}

/*
 * Create / recover a bucket from a key.
 * Again, this breaks if the contract bytecode changes.
 */
function jitBucket(bytes32 key) returns (Bucket) {
  address a = Create2.computeAddress(key, keccak256(type(Bucket).creationCode));
  uint s;
  assembly { s := extcodesize(a) }
  if (s == 0) {
    Bucket b = new Bucket{salt: key}();
    require(address(b) == a, "Bucket address mismatch");
  }
  return Bucket(a);
}
