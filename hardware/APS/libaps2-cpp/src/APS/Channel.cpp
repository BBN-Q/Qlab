/*
 * Channel.cpp
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#include "headings.h"
#include "Channel.h"

Channel::Channel() : number{-1}, offset_{0.0}, scale_{1.0}, enabled_{false}, waveform_(0), trigDelay_{0}{}

Channel::Channel( int number) : number{number}, offset_{0.0}, scale_{1.0}, enabled_{false}, waveform_(0), trigDelay_{0}{}

Channel::~Channel() {
	// TODO Auto-generated destructor stub
}

int Channel::set_enabled(const bool & enable){
	enabled_ = enable;
	return 0;
}

bool Channel::get_enabled() const{
	return enabled_;
}

int Channel::set_offset(const float & offset){
	offset_ = (offset>1.0) ? 1.0 : offset;
	offset_ = (offset<-1.0) ? -1.0 : offset;
	return 0;
}

float Channel::get_offset() const{
	return offset_;
}

int Channel::set_scale(const float & scale){
	scale_ = scale;
	return 0;
}

float Channel::get_scale() const{
	return scale_;
}


int Channel::set_waveform(const vector<float> & data) {
	//Check whether we need to resize the waveform vector
	if (data.size() > size_t(MAX_WF_LENGTH)){
		FILE_LOG(logERROR) << "Tried to update waveform to longer than max allowed: " << data.size();
		return -1;
	}

	//Copy over the waveform data
	//Waveform length must be a integer multiple of WF_MODULUS so resize to that
	waveform_.resize(size_t(WF_MODULUS*ceil(float(data.size())/WF_MODULUS)), 0);
	std::copy(data.begin(), data.end(), waveform_.begin());

	return 0;
}

int Channel::set_waveform(const vector<short> & data) {
	//Check whether we need to resize the waveform vector
	if (data.size() > size_t(MAX_WF_LENGTH)){
		FILE_LOG(logERROR) << "Tried to update waveform to longer than max allowed: " << data.size();
		return -1;
	}

	//Copy over the waveform data and convert to scaled floats
	//Waveform length must be a integer multiple of WF_MODULUS so resize to that
	waveform_.resize(size_t(WF_MODULUS*ceil(float(data.size())/WF_MODULUS)), 0);
	for(size_t ct=0; ct<data.size(); ct++){
		waveform_[ct] = float(data[ct])/MAX_WF_AMP;
	}
	return 0;
}

vector<short> Channel::prep_waveform() const{
	//Apply the scale,offset and covert to integer format
	vector<short> prepVec(waveform_.size());
	for(size_t ct=0; ct<prepVec.size(); ct++){
		prepVec[ct] = short(MAX_WF_AMP*(scale_*waveform_[ct]+offset_));
	}

	//Clip to the max and min values allowed
	if (*max_element(prepVec.begin(), prepVec.end()) > MAX_WF_AMP){
		FILE_LOG(logWARNING) << "Waveform element too positive; clipping to max";
		for(short & tmpVal : prepVec){
			if (tmpVal > MAX_WF_AMP) tmpVal = MAX_WF_AMP;
		}
	}
	if (*min_element(prepVec.begin(), prepVec.end()) < -MAX_WF_AMP){
		FILE_LOG(logWARNING) << "Waveform element too negative; clipping to max";
		for(short & tmpVal : prepVec){
			if (tmpVal < -MAX_WF_AMP) tmpVal = -MAX_WF_AMP;
		}
	}
	return prepVec;
}

int Channel::clear_data() {
	LLBank_.clear();
	waveform_.clear();
	return 0;
}

int Channel::write_state_to_hdf5(H5::H5File & H5StateFile, const string & rootStr){

	// write waveform data
	FILE_LOG(logDEBUG) << "Writing Waveform: " << rootStr + "/waveformLib";
	vector2h5array<float>(waveform_,  &H5StateFile, rootStr + "/waveformLib", rootStr + "/waveformLib",   H5::PredType::NATIVE_FLOAT);


	// add channel state information to root group
	H5::Group tmpGroup = H5StateFile.openGroup(rootStr);

	element2h5attribute<float>("offset",  offset_,    &tmpGroup, H5::PredType::NATIVE_FLOAT);
	element2h5attribute<float>("scale",   scale_,     &tmpGroup, H5::PredType::NATIVE_FLOAT);
	element2h5attribute<bool>("enabled",  enabled_,   &tmpGroup, H5::PredType::NATIVE_UINT);
	element2h5attribute<int>("trigDelay", trigDelay_, &tmpGroup, H5::PredType::NATIVE_INT);

	tmpGroup.close();

	//Save the linklist data

	// save number of banks to rootStr + /linkListData attribute "numBanks"
//	USHORT numBanks;
//	numBanks = banks_.size();//get number of banks from channel
//
//	// set attribute
//	FILE_LOG(logDEBUG) << "Creating Group: " << rootStr + "/linkListData";
//	tmpGroup = H5StateFile.createGroup(rootStr + "/linkListData");
//	element2h5attribute<USHORT>("numBanks",  numBanks, &tmpGroup,H5::PredType::NATIVE_UINT16);
//	tmpGroup.close();
//
//	std::ostringstream tmpStream;
//	//Now loop over the number of banks found and add the bank
//	for (USHORT bankct=0; bankct<numBanks; bankct++) {
//		tmpStream.str("");
//		tmpStream << rootStr << "/linkListData/bank" << bankct+1 ;
//		FILE_LOG(logDEBUG) << "Writing State Bank: " << bankct+1 << " from hdf5";
//		banks_[bankct].write_state_to_hdf5(H5StateFile, tmpStream.str() );
//	}
	return 0;
}

int Channel::read_state_from_hdf5(H5::H5File & H5StateFile, const string & rootStr){
	clear_data();
	// read waveform data
	waveform_ = h5array2vector<float>(&H5StateFile, rootStr + "/waveformLib",   H5::PredType::NATIVE_INT16);

	// load state information
	H5::Group tmpGroup = H5StateFile.openGroup(rootStr);
	offset_    = h5element2element<float>("offset",&tmpGroup, H5::PredType::NATIVE_FLOAT);
	scale_     = h5element2element<float>("scale",&tmpGroup, H5::PredType::NATIVE_FLOAT);
	enabled_   = h5element2element<bool>("enabled",&tmpGroup, H5::PredType::NATIVE_UINT);
	trigDelay_ = h5element2element<int>("trigDelay",&tmpGroup, H5::PredType::NATIVE_INT);

	//Load the linklist data
	//First figure our how many banks there are from the attribute
	tmpGroup = H5StateFile.openGroup(rootStr + "/linkListData");
	USHORT numBanks;
	numBanks = h5element2element<USHORT>("numBanks",&tmpGroup, H5::PredType::NATIVE_UINT16);
  tmpGroup.close();

	std::ostringstream tmpStream;
	//Now loop over the number of banks found and add the bank
	for (USHORT bankct=0; bankct<numBanks; bankct++){
		LLBank bank;
		tmpStream.str(rootStr);
		tmpStream << "/linkListData/bank" << bankct+1;
		FILE_LOG(logDEBUG) << "Reading State Bank: " << bankct+1 << " from hdf5";
		bank.read_state_from_hdf5( H5StateFile, tmpStream.str());
//		banks_.push_back(bank);
	}
	return 0;
}
