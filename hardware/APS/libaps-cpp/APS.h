/*
 * APS.h
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#ifndef APS_H_
#define APS_H_

#include "headings.h"

class APS {
public:
	APS();
	virtual ~APS();

private:
	int deviceID;
	string deviceSerial;
	vector<Channel> channels;



};

#endif /* APS_H_ */
