#include "mex.h"

typedef unsigned char uint8_t;

/*
 dataA, dataB = processBuffer(buffer, verticalScale)

 Compilation instructions:

 GCC
 mex COPTIMFLAGS="-O2 -DNDEBUG -ftree-vectorize -ftree-vectorizer-verbose=2 -ffast-math -msse2" processBuffer.c

 ICC
 mex COMPFLAGS="$COMPFLAGS /Qvec-report:2" processBuffer.c

 Clang
 mex COPTIMFLAGS="-O3 -DNDEBUG -ffast-math -Rpass=loop-vectorize -Rpass-analysis=loop-vectorize" processBuffer.c
 */

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
	uint8_t *buffer;
	mwSize bufferSize, i;
	mwSize dims[2];
	float verticalScale, dacScale;
	float *dataA, *dataB;
	// error check inputs and outputs
	if (nrhs != 2) {
		mexErrMsgIdAndTxt("AlazarATS9870:processBuffer:nrhs", "2 inputs required.");
	}
	if (nlhs != 2) {
		mexErrMsgIdAndTxt("AlazarATS9870:processBuffer:nlhs", "2 outputs required.");
	}

	buffer = (uint8_t *)mxGetData(prhs[0]);
	bufferSize = mxGetNumberOfElements(prhs[0]);
	verticalScale = mxGetScalar(prhs[1]);
	dacScale = 2.0*verticalScale/255.0;

	// prepare outputs
	dims[0] = 1;
	dims[1] = bufferSize/2;
	plhs[0] = mxCreateNumericArray(2, dims, mxSINGLE_CLASS, mxREAL);
	plhs[1] = mxCreateNumericArray(2, dims, mxSINGLE_CLASS, mxREAL);

	dataA = (float *)mxGetPr(plhs[0]);
	dataB = (float *)mxGetPr(plhs[1]);

	#pragma ivdep
	for (i=0; i < bufferSize/2; i++) {
		dataA[i] = (float)buffer[i];
	}

	#pragma ivdep
	for (i=0; i < bufferSize/2; i++) {
		dataB[i] = (float)buffer[i + bufferSize/2];
	}

	for (i=0; i < bufferSize/2; i++) {
		dataA[i] = dacScale * dataA[i] - verticalScale;
	}

	for (i=0; i < bufferSize/2; i++) {
		dataB[i] = dacScale * dataB[i] - verticalScale;
	}
}
