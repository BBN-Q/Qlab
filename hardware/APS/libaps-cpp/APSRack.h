/*
 * APSRack.h
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#ifndef APSRACK_H_
#define APSRACK_H_

#include "headings.h"

class APS;

class APSRack {
public:
	APSRack();
	virtual ~APSRack();

	int Init();
	int connect(const int &);
	int connect(const string &);
	int disconnect(const int &);
	int disconnect(const string &);

	int get_num_devices();
	void enumerate_devices();

private:
	vector<APS> _devices;
	int _numDevices;
	map<string, unsigned short> _serial2dev;
	vector<string> _deviceSerials;
	vector<FT_HANDLE> _deviceHandles;
};

#endif /* APSRACK_H_ */
