
pragma solidity ^0.8.16;

import "./utils.sol";

/*
 * This is essentially packed array.
 */

library SlotStorage {
  function get(bytes32 storageSlot, uint size, uint224 ckey, uint32 offset)
    internal view returns (uint)
  {
    uint n = 256 / size;
    bytes32 key = keccak256(abi.encode(storageSlot, ckey, offset / n));

    uint word;
    assembly { word := sload(key) }

    return getWordPart(size, offset%n, word);
  }

  function set(bytes32 storageSlot, uint size, uint224 ckey, uint32 offset, uint val)
    internal returns (uint prev)
  {
    uint n = 256 / size;
    bytes32 key = keccak256(abi.encode(storageSlot, ckey, offset / n));

    uint word;
    assembly { word := sload(key) }

    prev = getWordPart(size, offset%n, word);
    word = setWordPart(size, offset%n, word, val);
    assembly { sstore(key, word) }
  }
}
