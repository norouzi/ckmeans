// A mex wrapper around linscan_aqd_query to call asymmetric quantizer
// distance (AQD) k-nearest neighbor search from within matlab.
//
// NOTE: the output indices are one-based.

#include <algorithm>
#include "linscan.h"
#include <math.h>
#include <mex.h>
#include <stdio.h>
#include "types.h"

// Inputs --------------------

#define mxcodes         prhs[0]  // A matrix of data points against
                                 // which nearest neighbors search is
                                 // performed.
#define mxqueries       prhs[1]  // A matrix of query points for the
                                 // search.
#define mxN             prhs[2]  // Number of data points to use in
                                 // search.
#define mxB             prhs[3]  // Number of bits per code.
#define mxK             prhs[4]  // Number of kNN results to return.
#define mxcenters       prhs[5]

// Outputs --------------------

#define mxres           plhs[0]
#define mxdists         plhs[1]

void myAssert(int a, const char *b) {
  if (!a)
    mexErrMsgTxt(b);
}

void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray*prhs[])
{
  if (nrhs != 6)
    mexErrMsgTxt("Wrong number of inputs\n");
  if (nlhs != 2)
    mexErrMsgTxt("Wrong number of outputs\n");
    
  UINT32 N = (UINT32) *(mxGetPr(mxN));
  int B = (int) *(mxGetPr(mxB));
  int K = (int) *(mxGetPr(mxK));
	
  UINT8 *codes = (UINT8*) mxGetPr(mxcodes);
  double *queries = (double*) mxGetPr(mxqueries);
  double *centers = (double*) mxGetPr(mxcenters);
	
  int NQ = mxGetN(mxqueries);
  int dim1codes = mxGetM(mxcodes);
  int dim1queries = mxGetM(mxqueries);
  int subdim = mxGetM(mxcenters);

  myAssert(mxIsDouble(mxcenters), "centers is not double");
  myAssert(mxIsDouble(mxqueries), "queries is not double");
  myAssert(mxIsUint8(mxcodes), "codes is not uit8");
  myAssert(mxGetN(mxcodes) >= N, "number of codes < N");
  myAssert(dim1codes >= B / 8, "dim1codes < B/8");
  myAssert(dim1queries >= B / 8, "dim1queries < B/8");
  myAssert(B % 8 == 0, "mod(B, 8) != 0.");
  myAssert(dim1queries >= subdim * (B / 8),
           "dim1queries < subdim*B/8.");
  myAssert(mxGetDimensions(mxcenters)[1] == 256,
           "number of centers != 256.");
  myAssert(mxGetDimensions(mxcenters)[2] == B / 8,
           "3rd dim of centers is not B/8.");

  mxdists = mxCreateNumericMatrix(K, NQ, mxDOUBLE_CLASS, mxREAL);
  double *dists = (double *) mxGetPr(mxdists);
	
  mxres = mxCreateNumericMatrix(K, NQ, mxUINT32_CLASS, mxREAL);
  UINT32 *res = (UINT32 *) mxGetPr(mxres);

  linscan_aqd_query(dists, res, codes, centers, queries, N, NQ, B, K,
                    dim1codes, dim1queries, subdim);
  // Make the indices one-based.
  for (int i = 0; i < K * NQ; i++)
    res[i] = res[i] + 1;
}
