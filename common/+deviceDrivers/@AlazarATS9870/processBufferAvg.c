#include "mex.h"

typedef unsigned char uint8_t;

/*
 dataA, dataB = processBufferSum(buffer, bufferDims, verticalScale)

 Compilation instructions:

 GCC
 mex COPTIMFLAGS="-O2 -DNDEBUG -ftree-vectorize -ftree-vectorizer-verbose=2 -ffast-math -msse2" processBufferAvg.c

 ICC
 mex COMPFLAGS="$COMPFLAGS /Qvec-report:2" processBufferAvg.c

 Clang
 mex COPTIMFLAGS="-O3 -DNDEBUG -ffast-math -Rpass=loop-vectorize -Rpass-analysis=loop-vectorize" processBufferAvg.c
 */

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
	uint8_t *buffer;
	mwSize bufferSize, checkSize, ni, i, nj, j, nk, k, nl, l;
	mwSize dims[2];
	double *bufferDims;
	float verticalScale, dacScale;
	int sum;
	float *dataA, *dataB;
	// error check inputs and outputs
	if (nrhs != 3) {
		mexErrMsgIdAndTxt("AlazarATS9870:processBuffer:nrhs", "3 inputs required.");
	}
	if (nlhs != 2) {
		mexErrMsgIdAndTxt("AlazarATS9870:processBuffer:nlhs", "2 outputs required.");
	}

	buffer = (uint8_t *)mxGetData(prhs[0]);
	bufferSize = mxGetNumberOfElements(prhs[0]);
	bufferDims = mxGetPr(prhs[1]);
	if (mxGetNumberOfElements(prhs[1]) != 4) {
		mexErrMsgIdAndTxt("AlazarATS9870:processBuffer:bufferDims", "Expected a 4 element bufferDims vector.");
	}
	// compute product of bufferDims
	ni = bufferDims[0];
	nj = bufferDims[1];
	nk = bufferDims[2];
	nl = bufferDims[3];
	checkSize = ni*nj*nk*nl;
	if (2*checkSize != bufferSize) {
		mexErrMsgIdAndTxt("AlazarATS9870:processBuffer:bufferSize", "length(buffer) and 2*prod(bufferDims) do not match.");
	}

	verticalScale = mxGetScalar(prhs[2]);
	dacScale = 2.0*verticalScale/255.0;

	// prepare outputs
	dims[0] = ni;
	dims[1] = nk;
	plhs[0] = mxCreateNumericArray(2, dims, mxSINGLE_CLASS, mxREAL);
	plhs[1] = mxCreateNumericArray(2, dims, mxSINGLE_CLASS, mxREAL);

	dataA = (float *)mxGetPr(plhs[0]);
	dataB = (float *)mxGetPr(plhs[1]);

	// copy and sum along the 2nd and 4th dimension
	for (l=0; l < nl; l++) {
		for (k=0; k < nk; k++) {
			for (j=0; j < nj; j++) {
				for (i=0; i < ni; i++) {
					dataA[i + k*ni] += (float)buffer[i + j*ni + k*ni*nj + l*ni*nj*nk];
					dataB[i + k*ni] += (float)buffer[i + j*ni + k*ni*nj + l*ni*nj*nk + bufferSize/2];
				}
			}
		}
	}

	dacScale /= nj*nl; // include averaging denominator in scale

	for (i=0; i < ni*nk; i++) {
		dataA[i] = dacScale * dataA[i] - verticalScale;
	}

	for (i=0; i < ni*nk; i++) {
		dataB[i] = dacScale * dataB[i] - verticalScale;
	}
}
