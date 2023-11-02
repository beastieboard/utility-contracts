
import "forge-std/Test.sol";

import "../src/Provenance.sol";

contract TestProvenance is Test {
  function testProvenance() public {
    bytes32 salt = bytes32(uint(0x12345678));

    Mintee mintee = new Mintee{salt: salt}(salt);
    (bool ok, uint salt2) = verifyProvenanceWithSalt(address(this), address(mintee));

    assertEq(ok, true);
    assertEq(uint(salt), salt2);
  }

  function testProvenanceFailDifferentSalt() public {
    bytes32 salt = bytes32(uint(0x12345678));

    Mintee mintee = new Mintee{salt: salt}(bytes32(""));
    bool ok = verifyProvenance(address(this), address(mintee));

    assertEq(ok, false);
  }

  function testProvenanceFailDifferentCreator() public {
    bytes32 salt = bytes32(uint(0x12345678));

    Mintee mintee = new Mintee{salt: salt}(salt);
    bool ok = verifyProvenance(address(0x1234), address(mintee));

    assertEq(ok, false);
  }
}

contract Mintee is Provenance {
  constructor(bytes32 salt) Provenance(salt) {}
}
