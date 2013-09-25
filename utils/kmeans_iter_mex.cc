#include <memory.h>
#include "mex.h"
#include <float.h>

// One half iteration of k-means in which new centers are computed
// according to a center assignment vector.

// Inputs --------------------

#define mxX             prhs[0]  // A d*n matrix of data points (n d-dim points)
#define mxI             prhs[1]  // A n*1 vector encoding the
                                 // assignment of data points to
                                 // cluster centers. Each value should
                                 // be between 1 and h.
#define mxh             prhs[2]  // Number of cluster centers (h).

// Outputs --------------------

#define mxC             plhs[0]  // A d*h matrix of centers (h d-dim points)

void myAssert(int a, const char *b) {
  if (!a)
    mexErrMsgTxt(b);
}

void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
  int n, d, h;
  const float * X;
  const int * I;
  float * Cp, * nCp;
  
  if (nrhs != 3)
    mexErrMsgTxt("Thee input arguments expected.");
  if (nlhs != 1)
    mexErrMsgTxt("One output arguments expected.");
  
  if (!mxIsSingle(mxX) ||
      mxIsComplex(mxX) ||
      mxGetNumberOfDimensions(mxX) != 2)
    mexErrMsgTxt("First input argument should be a single "
                 "precision 2D matrix.");
  d = mxGetM(mxX);
  n = mxGetN(mxX);
  
  if (!mxIsInt32(mxI) ||
      mxIsComplex(mxI) ||
      mxGetM(mxI) != (unsigned int)n)
    mexErrMsgTxt("Second input argument must be an int "
                 "matrix compatible with first input.");
  myAssert(mxGetN(mxI) == 1, "Second input argument must be a column vector");

  X = (float*) mxGetPr(mxX);
  I = (int*) mxGetPr(mxI);
  h = (int)(*(double*)mxGetPr(mxh));

  mxC = mxCreateNumericMatrix (d, h, mxSINGLE_CLASS, mxREAL);
  Cp = (float*) mxGetPr(mxC);
  memset(Cp, 0, d * h * sizeof(float));

  // nCp represents a h-dim count vector counting number of data
  // points associated with any one of the centers.
  nCp = (float*) calloc(h, sizeof(float));  // calloc initializes to zero
  const float * px = X;
  for (int i = 0; i < n; i++, px += d) {
    int c = I[i] - 1;  // zero-based.
    myAssert(0 <= c && c < h, "Each value in the second input argument should"
                              " be between 1 and h.");
    nCp[c]++;
    float * pcxp = Cp + c * d;
    for (int k = 0; k < d; k++)
      pcxp[k] += px[k];
  }

  float * pcxp = Cp;
  for (int j = 0; j < h; j++, pcxp += d) {
    if (nCp[j])
      for (int k = 0; k < d; k++)
        pcxp[k] /= nCp[j];
  }
  free(nCp);
}
