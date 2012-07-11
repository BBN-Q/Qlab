/*
 * LinkList.cpp
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#include "LLBank.h"


LLBank::LLBank() : length{0}, offset_(0), trigger_(0), repeat_(0), count_(0) {
	// TODO Auto-generated constructor stub

}

LLBank::LLBank(const vector<unsigned short> & offset, const vector<unsigned short> & count, const vector<unsigned short> & repeat, const vector<unsigned short> & trigger) :
		offset_(offset), count_(count), repeat_(repeat), trigger_(trigger), length(offset.size()){};

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
