#include "types.h"

#ifndef LINSCAN_H__
#define LINSCAN_H__

void linscan_hamm_query(UINT32 *counter, UINT32 *res, UINT8 *codes,
                        UINT8 *queries, int N, UINT32 NQ, int B,
                        unsigned int K, int dim1codes, int dim1queries);

void linscan_aqd_query(REAL *dists, UINT32 *res, UINT8 *codes, REAL *centers,
                       REAL *queries, int N, UINT32 NQ, int B, int K,
                       int dim1codes, int dim1queries, int subdim);

#endif  // LINSCAN_H__
