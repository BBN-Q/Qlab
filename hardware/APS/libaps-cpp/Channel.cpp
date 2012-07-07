/*
 * Channel.cpp
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#include "Channel.h"

Channel::Channel() : number(-1), _offset(0.0), _scale(1.0) {}

Channel::Channel( int number) : number(number), _offset(0.0), _scale(0.0){}

Channel::~Channel() {
	// TODO Auto-generated destructor stub
}

int Channel::set_waveform(const vector<float> & data) {
	//Check whether we need to resize the waveform vector
	if (data.size() > size_t(MAX_WFLENGTH)){
		FILE_LOG(logERROR) << "Tried to update waveform to longer than max allowed: " << data.size();
		return -1;
	}

	//Copy over the waveform data
	//Waveform length must be a integer multiple of WF_MODULUS so resize to that
	_waveform.resize(size_t(WF_MODULUS*ceil(data.size()/WF_MODULUS)), 0);
	std::copy(data.begin(), data.end(), _waveform.begin());

	return 0;
}

int Channel::set_waveform(const vector<short> & data) {
	FILE_LOG(logDEBUG2) << "End of data vector: " << *(data.end()-1);
	//Check whether we need to resize the waveform vector
	if (data.size() > size_t(MAX_WFLENGTH)){
		FILE_LOG(logERROR) << "Tried to update waveform to longer than max allowed: " << data.size();
		return -1;
	}

	//Copy over the waveform data and convert to scaled floats
	//Waveform length must be a integer multiple of WF_MODULUS so resize to that
	_waveform.resize(size_t(WF_MODULUS*ceil(data.size()/WF_MODULUS)), 0);
	for(size_t ct=0; ct<data.size(); ct++){
		_waveform[ct] = float(data[ct]/MAX_WFAMP);
	}
	return 0;
}

vector<short> Channel::prep_waveform(){
	//Apply the scale,offset and covert to integer format
	vector<short> prepVec(_waveform.size());
	for(size_t ct=0; ct<prepVec.size(); ct++){
		prepVec[ct] = short(MAX_WFAMP*(_scale*_waveform[ct]+_offset));
	}

	//Clip to the max and min values allowed
	if (*max_element(prepVec.begin(), prepVec.end()) > MAX_WFAMP){
		FILE_LOG(logWARNING) << "Waveform element too positive; clipping to max";
		for(short & tmpVal : prepVec){
			if (tmpVal > MAX_WFAMP) tmpVal = MAX_WFAMP;
		}
	}
	if (*min_element(prepVec.begin(), prepVec.end()) < -MAX_WFAMP){
		FILE_LOG(logWARNING) << "Waveform element too negative; clipping to max";
		for(short & tmpVal : prepVec){
			if (tmpVal < -MAX_WFAMP) tmpVal = -MAX_WFAMP;
		}
	}
	return prepVec;
}
