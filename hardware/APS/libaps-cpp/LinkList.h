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
	size_t length_;

};

//A collection of LL banks
class LinkList {
public:
	LinkList();
	~LinkList();

private:
	size_t numBanks_;
	vector<LLBank> banks_;
};

#endif /* LINKLIST_H_ */
