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
	vector<unsigned short> offset_;
	vector<unsigned short> trigger_;
	vector<unsigned short> repeat_;
	vector<unsigned short> count_;



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
