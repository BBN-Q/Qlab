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
	if (nrhs != 3) {
		mexErrMsgIdAndTxt("AlazarATS9870:processBuffer:nrhs", "3 inputs required.");
	}
	if (nlhs != 2) {
		mexErrMsgIdAndTxt("AlazarATS9870:processBuffer:nlhs", "2 outputs required.");
	}

	buffer = (uint8_t *)mxGetData(prhs[0]);
	bufferSize = mxGetScalar(prhs[1]);
	verticalScale = mxGetScalar(prhs[2]);
	dacScale = 2.0*verticalScale/255.0;

	if (mxGetNumberOfElements(prhs[0])!= bufferSize) {
		mexErrMsgIdAndTxt("AlazarATS9870:processBuffer:bufferSize", "bufferSize does not match length of buffer.");
	}

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
