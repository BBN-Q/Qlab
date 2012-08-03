/*
 * LinkList.cpp
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#include "LLBank.h"


LLBank::LLBank() : length{0}, offset_(0), count_(0), repeat_(0),trigger_(0) {
	// TODO Auto-generated constructor stub

}

LLBank::LLBank(const vector<unsigned short> & offset, const vector<unsigned short> & count, const vector<unsigned short> & repeat, const vector<unsigned short> & trigger) :
		length(offset.size()), offset_(offset), count_(count), repeat_(repeat), trigger_(trigger){};

LLBank::~LLBank() {
	// TODO Auto-generated destructor stub
}


vector<ULONG> LLBank::get_packed_data(){
	vector<ULONG> vecOut;

	vecOut.reserve(4*length);

	for(size_t ct=0; ct<length; ct++){
		vecOut.push_back(offset_[ct]);
		vecOut.push_back(count_[ct]);
		vecOut.push_back(trigger_[ct]);
		vecOut.push_back(repeat_[ct]);
	}
	return vecOut;
}

int LLBank::write_state_to_hdf5(H5::H5File & H5StateFile, const string & rootStr){
	H5::DataType dt = H5::PredType::NATIVE_UINT16;
	vector2h5array<USHORT>(offset_,  &H5StateFile, "offset",  rootStr + "/offset",  dt);
	vector2h5array<USHORT>(count_,   &H5StateFile, "count",   rootStr + "/count",   dt);
	vector2h5array<USHORT>(repeat_,  &H5StateFile, "repeat",  rootStr + "/repeat",  dt);
	vector2h5array<USHORT>(trigger_, &H5StateFile, "trigger", rootStr + "/trigger", dt);
	return 0;
}

int LLBank::read_state_from_hdf5(H5::H5File & H5StateFile, const string & rootStr){
	H5::DataType dt = H5::PredType::NATIVE_UINT16;
	offset_  = h5array2vector<USHORT>(&H5StateFile, rootStr + "/offset",  dt);
	count_   = h5array2vector<USHORT>(&H5StateFile, rootStr + "/count",   dt);
	repeat_  = h5array2vector<USHORT>(&H5StateFile, rootStr + "/repeat",  dt);
	trigger_ = h5array2vector<USHORT>(&H5StateFile, rootStr + "/trigger", dt);
	return 0;
}

