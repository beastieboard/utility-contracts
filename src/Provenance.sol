
// see: https://ssadler.substack.com/p/contract-provenance-verification-175

interface IProvenance {
  function getProvenanceData() external returns (uint salt, bytes32 codeHash);
}

contract Provenance is IProvenance {
  bytes32 immutable _salt;
  bytes32 immutable _codeHash;

  constructor(bytes32 salt) {
    _salt = salt;
    _codeHash = _deployGetCodeHash();
  }

  function _deployGetCodeHash() internal pure returns (bytes32 codeHash) {
    // The code hash that is used in the create2 address preimage is the hash of
    // all of the creation code, which we can access using codecopy.
    assembly {
      let code := mload(0x40)
      codecopy(code, 0, codesize())
      codeHash := keccak256(code, codesize())
    }
  }

  function getProvenanceData() override external view returns (uint salt, bytes32 codeHash) {
    return (uint(_salt), _codeHash);
  }
}

/*
 * In order to verify legitimate proxy as cheaply as possible, and in a (relatively)
 * non revokable way, it is done cryptographically; each proxy has hardcoded it's
 * salt and creation code hash, so together with the address of the minting contract,
 * the address can be recreated and verified.
 */
function verifyProvenanceWithSalt(address creator, address target) view returns (bool ok, uint salt) {
  /// @solidity memory-safe-assembly
  assembly {
    let ptr := mload(0x40)
    mstore(ptr, creator)

    mstore(0, hex"2f00ef5c") // cast sig "getProvenanceData()"
    pop(staticcall(1000, target, 0, 4, add(ptr, 0x20), 64))

    salt := mload(add(ptr, 0x20))

    let start := add(ptr, 0x0b)
    mstore8(start, 0xff)
    let computed := keccak256(start, 85)
    computed := and(computed, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
    ok := eq(computed, target)
  }
}

function verifyProvenance(address creator, address target) view returns (bool) {
  (bool ok,) = verifyProvenanceWithSalt(creator, target);
  return ok;
}
