/*
 * LinkList.h
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#include "headings.h"

#ifndef LLBANK_H_
#define LLBANK_H_


//An individual bank of a LL
class LLBank {
public:
	LLBank();
	LLBank(const vector<unsigned short> &, const vector<unsigned short> &, const vector<unsigned short> &, const vector<unsigned short> &);
	~LLBank();

	size_t length;

	vector<ULONG> get_packed_data();


private:
	vector<unsigned short> offset_;
	vector<unsigned short> count_;
	vector<unsigned short> repeat_;
	vector<unsigned short> trigger_;
	vector<UCHAR> packedBank_;
};

#endif /* LLBank_H_ */
