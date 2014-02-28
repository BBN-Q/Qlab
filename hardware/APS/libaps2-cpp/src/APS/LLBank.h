/*
 * LinkList.h
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#include "headings.h"

#ifndef LLBANK_H_
#define LLBANK_H_


//An individual bank of a LL for a single channel
class LLBank {
public:
	LLBank();
	LLBank(const WordVec &, const WordVec &, const WordVec &, const WordVec &);
	LLBank(const WordVec &, const WordVec &, const WordVec &, const WordVec &, const WordVec &);
	~LLBank();

	void clear();

	size_t length;
	bool IQMode;
	size_t numMiniLLs;
	WordVec miniLLLengths;
	WordVec miniLLStartIdx;

	WordVec get_packed_data(const size_t &, const size_t &);

	int write_state_to_hdf5(  H5::H5File & , const string & );
	int read_state_from_hdf5( H5::H5File & , const string & );


private:
	WordVec addr_;
	WordVec count_;
	WordVec repeat_;
	WordVec trigger1_;
	WordVec trigger2_;
	WordVec packedData_;
	void init_data();
};

#endif /* LLBANK_H_ */
