/*
 * LinkList.h
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#include "headings.h"

#ifndef LINKLIST_H_
#define LINKLIST_H_


//An individual bank of a LL
class LLBank {
public:
	LLBank();
	~LLBank();

private:
	size_t _length;

};

//A collection of LL banks
class LinkList {
public:
	LinkList();
	~LinkList();

private:
	size_t _numBanks;
	vector<LLBank> _banks;
};

#endif /* LINKLIST_H_ */
