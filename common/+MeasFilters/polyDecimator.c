#include "mex.h"
#include "ipps.h"

/*
 channelData = polyDecimator(measRecords, decimFactor)
 Implements a polyphase FIR filter to efficiently decimate the input signal by decimFactor.
*/

#define FILTERLENGTH 32

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

	float *measRecords, *channelData;
	mwSize numDims, recordLength, numSegments;
	const mwSize *inDims;
	mwSize *outDims;
	int decimFactor;
	IppsFIRState_32f *filterState;
	int size,len,height;
	double filterCoeff_d[FILTERLENGTH];
	float filterCoeff_f[FILTERLENGTH];
	IppStatus status;
	int stateSize;
	Ipp8u *filterBuffer;
	const float delayLine[FILTERLENGTH] = 0.0;
	int ct, segct;

	//Get the size of the input data
	//Expect recordLength x numSegments or recordLength x numWaveforms x numSegments X numRoundRobins
	//Can treat all of these as recordLength x N
	numDims = mxGetNumberOfDimensions(prhs[0]);
	inDims = mxGetDimensions(prhs[0]);
	recordLength = inDims[0];
	numSegments = 1;
	for (ct=1; ct < numDims; ct++) {
		numSegments *= inDims[ct];
	}

	//Pointer to measurment records
	measRecords = (float*)mxGetData(prhs[0]);
	decimFactor = (int)mxGetScalar(prhs[1]);

	//Apply a polyphase resampling filter to reduce the sampling rate
	//First design a crude low-pass filter 15-tap
	status = ippsFIRGenLowpass_64f(0.8*0.5/decimFactor, filterCoeff_d, FILTERLENGTH, ippWinBlackman, ippTrue);
	//TODO: error catch
	//Convert to single precision
	for (ct=0; ct<FILTERLENGTH; ct++){
		filterCoeff_f[ct] = (float) filterCoeff_d[ct];
	}
	//Get the size of the filter
	status = ippsFIRMRGetStateSize_32f(FILTERLENGTH, 1, decimFactor, &stateSize);
	//TODO: error catch
	filterBuffer = ippsMalloc_8u(stateSize*sizeof(Ipp8u));

	//Initialize the filter
	status = ippsFIRMRInit_32f(&filterState, filterCoeff_f, FILTERLENGTH, 1, 0.0, decimFactor, decimFactor-1, delayLine, filterBuffer);
	//TODO: error catch

	// prepare the output buffer
	outDims = malloc(numDims*sizeof(mwSize));
	for (ct = 0; ct < numDims; ++ct)
		outDims[ct] = inDims[ct];
	outDims[0] = floor(recordLength/decimFactor);
	plhs[0] = mxCreateNumericArray(numDims, outDims, mxSINGLE_CLASS, mxREAL);
	channelData = (float*)mxGetData(plhs[0]);

	//Apply the filter to each record
	for(segct=0; segct<numSegments; segct++){
		ippsFIR_32f(measRecords + segct*recordLength, channelData+segct*outDims[0], outDims[0], filterState);
		ippsFIRSetDlyLine_32f(filterState, delayLine);
	}
	
	ippsFree(filterBuffer);
	free(outDims);

}

