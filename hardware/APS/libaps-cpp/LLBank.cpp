/*
 * LinkList.cpp
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#include "LinkList.h"

LinkList::LinkList() : numBanks_(0) {
	// TODO Auto-generated constructor stub

}

LinkList::~LinkList() {
	// TODO Auto-generated destructor stub
}

LLBank::LLBank() : length_{0}, offset_(0), trigger_(0), repeat_(0), count_(0) {
	// TODO Auto-generated constructor stub

}

LLBank::~LLBank() {
	// TODO Auto-generated destructor stub
}
