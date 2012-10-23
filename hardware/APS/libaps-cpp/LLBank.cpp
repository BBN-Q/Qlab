/*
 * LinkList.cpp
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#include "LLBank.h"

LLBank::LLBank() : length{0}, addr_(0), count_(0), repeat_(0),trigger1_(0), trigger2_(0) {
	// TODO Auto-generated constructor stub
}

LLBank::LLBank(const WordVec & addr, const WordVec & count, const WordVec & trigger, const WordVec & repeat) :
		length(addr.size()), IQMode(false), addr_(addr), count_(count), repeat_(repeat), trigger1_(trigger){
	init_data();
};

LLBank::LLBank(const WordVec & addr, const WordVec & count, const WordVec & trigger1, const WordVec & trigger2, const WordVec & repeat) :
		length(addr.size()), IQMode(true), addr_(addr), count_(count), repeat_(repeat), trigger1_(trigger1), trigger2_(trigger2){
	init_data();
};

LLBank::~LLBank() {
	// TODO Auto-generated destructor stub
}

void LLBank::clear(){
	length = 0;
	addr_.clear();
	count_.clear();
	repeat_.clear();
	trigger1_.clear();
	trigger2_.clear();
	packedData_.clear();
	miniLLStartIdx.clear();
	miniLLLengths.clear();

}

WordVec LLBank::get_packed_data(const size_t & startIdx, const size_t & stopIdx){
	//Pull out packed data starting at startIdx but not inclusive of stopIdx
	WordVec vecOut;
	//If we are in IQ mode then we have an extra word for every entry
	int lengthMult = IQMode ? 5 : 4;
	//Handle wrapping around the top of the LL data
	if (stopIdx < startIdx){
		vecOut.assign(packedData_.begin()+lengthMult*startIdx, packedData_.end());
		vecOut.insert(vecOut.end(), packedData_.begin(), packedData_.begin()+lengthMult*stopIdx);
	}
	else{
		vecOut.assign(packedData_.begin()+lengthMult*startIdx, packedData_.begin()+lengthMult*stopIdx);
	}
	return vecOut;
}

int LLBank::write_state_to_hdf5(H5::H5File & H5StateFile, const string & rootStr){
	H5::Group chanGroup = H5StateFile.openGroup(rootStr);
	H5::DataType dt = H5::PredType::NATIVE_UINT16;
	USHORT tmpLength = static_cast<USHORT>(length);
	element2h5attribute<USHORT>("length", tmpLength, &chanGroup, dt);
	chanGroup.close();
	vector2h5array<USHORT>(addr_,  &H5StateFile, "addr",  rootStr + "/addr",  dt);
	vector2h5array<USHORT>(count_,   &H5StateFile, "count",   rootStr + "/count",   dt);
	vector2h5array<USHORT>(repeat_,  &H5StateFile, "repeat",  rootStr + "/repeat",  dt);
	vector2h5array<USHORT>(trigger1_, &H5StateFile, "trigger1", rootStr + "/trigger1", dt);
	if (IQMode){
		vector2h5array<USHORT>(trigger2_, &H5StateFile, "trigger2", rootStr + "/trigger2", dt);
	}
	return 0;
}

int LLBank::read_state_from_hdf5(H5::H5File & H5StateFile, const string & rootStr){
	H5::Group chanGroup = H5StateFile.openGroup(rootStr);
	H5::DataType dt = H5::PredType::NATIVE_UINT16;
	length = h5element2element<USHORT>("length", &chanGroup, dt);
	chanGroup.close();
	addr_  = h5array2vector<USHORT>(&H5StateFile, rootStr + "/addr",  dt);
	count_   = h5array2vector<USHORT>(&H5StateFile, rootStr + "/count",   dt);
	trigger1_ = h5array2vector<USHORT>(&H5StateFile, rootStr + "/trigger1", dt);
	repeat_  = h5array2vector<USHORT>(&H5StateFile, rootStr + "/repeat",  dt);
	if(IQMode){
		trigger2_ = h5array2vector<USHORT>(&H5StateFile, rootStr + "/trigger2", dt);
	}

	init_data();
	return 0;
}

void LLBank::init_data(){

	//Sort out the length of the mini LL's and their start points
	//Go through the LL entries and calculate lengths and start points of each miniLL
	miniLLLengths.clear();
	miniLLStartIdx.clear();
	const USHORT startMiniLLMask = (1 << 15);
	const USHORT endMiniLLMask = (1 << 14);
	size_t lengthCt = 0;
	for(size_t ct = 0; ct < length; ct++){
		// flags are stored in repeat vector
		USHORT curWord = repeat_[ct];
		if (curWord & startMiniLLMask){
			miniLLStartIdx.push_back(ct);
			lengthCt = 0;
		}
		lengthCt++;
		if (curWord & endMiniLLMask){
			miniLLLengths.push_back(lengthCt);
		}
	}
	numMiniLLs = miniLLLengths.size();

	//Now pack the data for writing to the device
	packedData_.clear();
	size_t expectedLength = IQMode ? 5*length : 4*length;
	packedData_.reserve(expectedLength);

	for(size_t ct=0; ct<length; ct++){
		packedData_.push_back(addr_[ct]);
		packedData_.push_back(count_[ct]);
		packedData_.push_back(trigger1_[ct]);
		if (IQMode){
			packedData_.push_back(trigger2_[ct]);
		}
		packedData_.push_back(repeat_[ct]);
	}
}
