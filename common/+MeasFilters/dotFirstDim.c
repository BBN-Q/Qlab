#include "mex.h"

/*
 out = dotFirstDim(bufferA, bufferB)
 bufferA assumed to be N-D, where N > 1
 bufferB assumed to be 1D with length matching size(bufferA,1)
 returns the dot product along the first dimension

 Compilation instructions:

 GCC
 mex COPTIMFLAGS="-O2 -DNDEBUG -ftree-vectorize -ftree-vectorizer-verbose=2 -ffast-math -msse2" dotFirstDim.c

 ICC
 mex COMPFLAGS="$COMPFLAGS /Qvec-report:2" dotFirstDim.c

 Clang
 mex COPTIMFLAGS="-O3 -DNDEBUG -ffast-math -Rpass=loop-vectorize -Rpass-analysis=loop-vectorize" dotFirstDim.c
 */

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
	float *bufferAr, *bufferAi, *bufferBr, *bufferBi;
	mwSize sA, sB, i, j, k, numDims;
	const mwSize *dims;
	mwSize *outDims;
	mxComplexity outType;
	float *outr, *outi, tmpr, tmpi;
	// error check inputs and outputs
	if (nrhs != 2) {
		mexErrMsgIdAndTxt("dotFirstDim:nrhs", "2 inputs required.");
	}
	if (nlhs != 1) {
		mexErrMsgIdAndTxt("dotFirstDim:nlhs", "1 output required.");
	}

	bufferAr = (float *)mxGetData(prhs[0]);
	bufferAi = (float *)mxGetImagData(prhs[0]);
	sA = mxGetNumberOfElements(prhs[0]);
	dims = mxGetDimensions(prhs[0]);
	numDims = mxGetNumberOfDimensions(prhs[0]);

	bufferBr = (float *)mxGetData(prhs[1]);
	bufferBi = (float *)mxGetImagData(prhs[1]);
	sB = mxGetNumberOfElements(prhs[1]);

	if (sA % sB != 0) mexErrMsgIdAndTxt("dotFirstDim:mismatch", "Dimension mismatch.");
	if (!mxIsSingle(prhs[0]) || !mxIsSingle(prhs[1])) {
		mexErrMsgIdAndTxt("dotFirstDim:type", "dotFirstDim only works on single-precision (float) inputs");
	}

	// prepare output buffer
	outDims = mxMalloc(numDims);
	outDims[0] = 1;
	#pragma novector
	for (i = 1; i < numDims; i++)
		outDims[i] = dims[i];

	outType = (mxIsComplex(prhs[0]) || mxIsComplex(prhs[1])) ? mxCOMPLEX : mxREAL;
	plhs[0] = mxCreateNumericArray(numDims, outDims, mxSINGLE_CLASS, outType);
	outr = (float *)mxGetPr(plhs[0]);
	outi = (float *)mxGetPi(plhs[0]);

	if (mxIsComplex(prhs[0]) && mxIsComplex(prhs[1])) {
		for (i = 0, k = 0; i < sA; i += sB, k++) {
			tmpr = 0.0;
			tmpi = 0.0;
			for (j = 0; j < sB; j++) {
				tmpr += bufferAr[i+j] * bufferBr[j] - bufferAi[i+j] * bufferBi[j];
				tmpi += bufferAr[i+j] * bufferBi[j] + bufferAi[i+j] * bufferBr[j];
			}
			outr[k] = tmpr;
			outi[k] = tmpi;
		}
	} else if (mxIsComplex(prhs[0])) { // only bufferA is complex
		for (i = 0, k = 0; i < sA; i += sB, k++) {
			tmpr = 0.0;
			tmpi = 0.0;
			for (j = 0; j < sB; j++) {
				tmpr += bufferAr[i+j] * bufferBr[j];
				tmpi += bufferAi[i+j] * bufferBr[j];
			}
			outr[k] = tmpr;
			outi[k] = tmpi;
		}
	} else if (mxIsComplex(prhs[1])) { // only bufferB is complex
		for (i = 0, k = 0; i < sA; i += sB, k++) {
			tmpr = 0.0;
			tmpi = 0.0;
			for (j = 0; j < sB; j++) {
				tmpr += bufferAr[i+j] * bufferBr[j];
				tmpi += bufferAr[i+j] * bufferBi[j];
			}
			outr[k] = tmpr;
			outi[k] = tmpi;
		}
	} else { // both A and B are real
		for (i = 0, k = 0; i < sA; i += sB, k++) {
			tmpr = 0.0;
			for (j = 0; j < sB; j++) {
				tmpr += bufferAr[i+j] * bufferBr[j];
			}
			outr[k] = tmpr;
		}
	}
	mxFree(outDims);
}
