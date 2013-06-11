#include "mex.h"
#include "ipps.h"

/*
 channelData = polyDecimator(measRecords, decimFactor)
 Implements a polyphase FIR filter to efficiently decimate the input signal by decimFactor.
*/

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

	float *measRecords, *channelData;
	mwSize numDims, recordLength, numWaveforms, numSegments, numRoundRobins;
	const mwSize *inDims;
	mwSize *outDims;
	int decimFactor;
	IppsFIRState_32f *filterState;
	int size,len,height;
	double filterCoeff_d[16];
	float filterCoeff_f[16];
	IppStatus status;
	int stateSize;
	Ipp8u *filterBuffer;
	int ct, segct;

	//Get the size of the input data
	//Expect recordLength x numSegments or recordLength x numWaveforms x numSegments X numRoundRobins
	numDims = mxGetNumberOfDimensions(prhs[0]);
	inDims = mxGetDimensions(prhs[0]);
	recordLength = inDims[0];
	if (numDims == 2){
		numSegments = inDims[1];
	}
	else if (numDims == 4){
		numWaveforms = inDims[1];
		numSegments = inDims[2];
		numRoundRobins = inDims[3];
	}
	else{
		mexErrMsgIdAndTxt("AlazarATS9870:polyDecimator", "Expected a 2 or 4 dimensional measurement record  array.");
	}

	//Pointer to measurment records
	measRecords = (float*)mxGetData(prhs[0]);
	decimFactor = (int)mxGetScalar(prhs[1]);

	//Apply a polyphase resampling filter to reduce the sampling rate
	//First design a crude low-pass filter 15-tap
	status = ippsFIRGenLowpass_64f(0.8*0.5/decimFactor, filterCoeff_d, 16, ippWinBlackman, ippTrue);
	//TODO: error catch
	//Convert to single precision
	for (ct=0; ct<16; ct++){
		filterCoeff_f[ct] = (float) filterCoeff_d[ct];
	}
	//Get the size of the filter
	status = ippsFIRMRGetStateSize_32f(16, 1, decimFactor, &stateSize);
	//TODO: error catch
	filterBuffer = ippsMalloc_8u(stateSize*sizeof(Ipp8u));

	//Initialize the filter
	status = ippsFIRMRInit_32f(&filterState, filterCoeff_f, 16, 1, 0.0, decimFactor, decimFactor-1, NULL, filterBuffer);
	//TODO: error catch

	//Apply the filter
	outDims = malloc(numDims*sizeof(mwSize));
	for (ct = 0; ct < numDims; ++ct)
		outDims[ct] = inDims[ct];
	outDims[0] = recordLength/decimFactor;
	plhs[0] = mxCreateNumericArray(numDims, outDims, mxSINGLE_CLASS, mxREAL);
	channelData = (float*)mxGetData(plhs[0]);
	if (numDims == 2){
		for(segct=0; segct<numSegments; segct++){
			ippsFIR_32f(measRecords + segct*recordLength, channelData+segct*recordLength/decimFactor, outDims[0], filterState);
		}
	}
	
	ippsFree(filterBuffer);
	free(outDims);

}

