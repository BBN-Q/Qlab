#include "mex.h"

typedef unsigned char uint8_t;

/*
 dataA, dataB = processBuffer(buffer, bufferSize, verticalScale)
 */

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
	uint8_t *buffer;
	mwSize bufferSize, i;
	double verticalScale, dacScale;
	double *dataA, *dataB;
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
	plhs[0] = mxCreateDoubleMatrix(1, bufferSize/2, mxREAL);
	plhs[1] = mxCreateDoubleMatrix(1, bufferSize/2, mxREAL);

	dataA = mxGetPr(plhs[0]);
	dataB = mxGetPr(plhs[1]);

	for (i=0; i < bufferSize/2; i++) {
		dataA[i] = dacScale*(double)buffer[i] - verticalScale;
		dataB[i] = dacScale*(double)buffer[i + bufferSize/2] - verticalScale;
	}
}
