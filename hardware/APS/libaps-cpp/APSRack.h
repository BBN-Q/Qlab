/*
 * APSRack.h
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#ifndef APSRACK_H_
#define APSRACK_H_

#include "headings.h"

class APSRack {
public:
	APSRack();
	virtual ~APSRack();

	int Init();
	int connect(int);
	int connect(string);

	int GetNumDevices();
	vector<string> GetDeviceSerials();

private:
	vector<APS> _devices;
	int _numDevices;
	APSLogger _logger;

};

#endif /* APSRACK_H_ */
