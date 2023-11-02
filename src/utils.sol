// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.16;
pragma experimental ABIEncoderV2;


function getWordPart(uint size, uint i, uint word) pure returns (uint) {
  return (word >> (size * i)) & (2**size-1);
}

function setWordPart(uint size, uint i, uint word, uint part) pure returns (uint) {
  uint off = size * i;
  uint clear = ~ ((2**size-1) << off);
  return (word & clear) | (part << off);
}

