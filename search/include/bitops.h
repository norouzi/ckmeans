#ifndef BITOPTS_H__
#define BITOPTS_H__

#define popcntll __builtin_popcountll
#define popcnt __builtin_popcount

#include <stdio.h>
#include <math.h>
#include "types.h"

const int lookup [] = {0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4,
                       1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
                       1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
                       2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
                       1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
                       2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
                       2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
                       3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
                       1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
                       2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
                       2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
                       3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
                       2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
                       3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
                       3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
                       4, 5, 5, 6, 5, 6, 6, 7, 5, 6, 6, 7, 6, 7, 7, 8};

inline int match(UINT8*P, UINT8*Q, int codelb) {
  switch(codelb) {
  case 4: // 32 bit
    return popcnt(*(UINT32*)P ^ *(UINT32*)Q);
  case 8: // 64 bit
    return popcntll(((UINT64*)P)[0] ^ ((UINT64*)Q)[0]);
  case 16: // 128 bit
    return popcntll(((UINT64*)P)[0] ^ ((UINT64*)Q)[0]) \
      + popcntll(((UINT64*)P)[1] ^ ((UINT64*)Q)[1]);
  case 32: // 256 bit
    return popcntll(((UINT64*)P)[0] ^ ((UINT64*)Q)[0]) \
      + popcntll(((UINT64*)P)[1] ^ ((UINT64*)Q)[1]) \
      + popcntll(((UINT64*)P)[2] ^ ((UINT64*)Q)[2]) \
      + popcntll(((UINT64*)P)[3] ^ ((UINT64*)Q)[3]);
  case 64: // 512 bit
    return popcntll(((UINT64*)P)[0] ^ ((UINT64*)Q)[0]) \
      + popcntll(((UINT64*)P)[1] ^ ((UINT64*)Q)[1]) \
      + popcntll(((UINT64*)P)[2] ^ ((UINT64*)Q)[2]) \
      + popcntll(((UINT64*)P)[3] ^ ((UINT64*)Q)[3]) \
      + popcntll(((UINT64*)P)[4] ^ ((UINT64*)Q)[4]) \
      + popcntll(((UINT64*)P)[5] ^ ((UINT64*)Q)[5]) \
      + popcntll(((UINT64*)P)[6] ^ ((UINT64*)Q)[6]) \
      + popcntll(((UINT64*)P)[7] ^ ((UINT64*)Q)[7]);
  default:
    int output = 0;
    for (int i=0; i<codelb; i++) 
      output+= lookup[P[i] ^ Q[i]];
    return output;
  }
}

#endif  // BITOPTS_H__
