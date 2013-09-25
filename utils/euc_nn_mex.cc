#include <assert.h>
#include <math.h>
#include "mex.h"
#include <sys/time.h>

void mexFunction(int nlhs, mxArray* plhs[],
                 int nrhs, const mxArray* prhs[]) {
  if (nrhs != 2) 
    mexErrMsgTxt("There should be two input arguments.");
    
  if (nlhs != 2 && nlhs != 1)
    mexErrMsgTxt("There should be one or two output arguments.");

  int p = mxGetM(prhs[0]);
  int n = mxGetN(prhs[0]);
  int nq = mxGetN(prhs[1]);

  if (mxGetM(prhs[1]) != (unsigned int)p)
    mexErrMsgTxt("Dimensionality of the two input matrices are not "
                 "consistent.");
  
  if (mxGetClassID(prhs[0]) != mxSINGLE_CLASS 
      || mxGetClassID(prhs[1]) != mxSINGLE_CLASS )
    mexErrMsgTxt ("Only single precision matrices are supported."); 

  float * b = (float*) mxGetPr(prhs[0]);  /* database vectors */
  float * v = (float*) mxGetPr(prhs[1]);  /* query vectors */

  plhs[0] = mxCreateNumericMatrix(nq, 1, mxINT32_CLASS, mxREAL);
  int * ind = (int*) mxGetPr(plhs[0]);
  
  float * dis = NULL;
  if (nlhs >= 1) {
    plhs[1] = mxCreateNumericMatrix(nq, 1, mxSINGLE_CLASS, mxREAL);
    dis = (float*) mxGetPr(plhs[1]);
  }

  int j = 0;
#pragma omp parallel shared(j)
  {
#pragma omp for
    for (j = 0; j < nq; j++) {
      float * vj = v + j * p;  // vj points to the j-th query point.
      float min_dis = 1e10;
      int best_ind = -1;
      float * bi = b;  // bi points to the i-th data point.
      // The pointer changes with the for variable i.
      for (int i = 0; i < n; i++, bi += p) {
        float disi = 0;
        for (int k = 0; k < p; k++) {
          disi += (bi[k] - vj[k]) * (bi[k] - vj[k]);
        }
        if (disi < min_dis) {
          min_dis = disi;
          best_ind = i;
        }
      }
      if (nlhs >= 1)
        dis[j] = min_dis;
      ind[j] = best_ind + 1;  // one-based
      if (best_ind == -1)
        mexErrMsgTxt ("Something is wrong, ind is still -1.");
    }
  }
}
