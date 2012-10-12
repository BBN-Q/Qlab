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
		length(addr.size()), IQMode(false), addr_(addr), count_(count), repeat_(repeat), trigger1_(trigger){};

LLBank::LLBank(const WordVec & addr, const WordVec & count, const WordVec & trigger1, const WordVec & trigger2, const WordVec & repeat) :
		length(addr.size()), IQMode(true), addr_(addr), count_(count), repeat_(repeat), trigger1_(trigger1), trigger2_(trigger2){};

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

}

WordVec LLBank::get_packed_data(const size_t & startIdx, const size_t & stopIdx){
	WordVec vecOut;
	int lengthMult = IQMode ? 5 : 4;
	vecOut.assign(packedData_.begin()+lengthMult*startIdx, packedData_.begin()+lengthMult*stopIdx-1);
	return vecOut;
}

int LLBank::write_state_to_hdf5(H5::H5File & H5StateFile, const string & rootStr){
	H5::DataType dt = H5::PredType::NATIVE_UINT16;
	vector2h5array<USHORT>(addr_,  &H5StateFile, "offset",  rootStr + "/offset",  dt);
	vector2h5array<USHORT>(count_,   &H5StateFile, "count",   rootStr + "/count",   dt);
	vector2h5array<USHORT>(repeat_,  &H5StateFile, "repeat",  rootStr + "/repeat",  dt);
	vector2h5array<USHORT>(trigger1_, &H5StateFile, "trigger", rootStr + "/trigger1", dt);
	if (IQMode){
		vector2h5array<USHORT>(trigger2_, &H5StateFile, "trigger", rootStr + "/trigger2", dt);
	}
	return 0;
}

int LLBank::read_state_from_hdf5(H5::H5File & H5StateFile, const string & rootStr){
	H5::DataType dt = H5::PredType::NATIVE_UINT16;
	addr_  = h5array2vector<USHORT>(&H5StateFile, rootStr + "/offset",  dt);
	count_   = h5array2vector<USHORT>(&H5StateFile, rootStr + "/count",   dt);
	trigger1_ = h5array2vector<USHORT>(&H5StateFile, rootStr + "/trigger1", dt);
	repeat_  = h5array2vector<USHORT>(&H5StateFile, rootStr + "/repeat",  dt);
	if(IQMode){
		trigger2_ = h5array2vector<USHORT>(&H5StateFile, rootStr + "/trigger1", dt);
	}

	return 0;
}

void LLBank::pack_data(){

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
