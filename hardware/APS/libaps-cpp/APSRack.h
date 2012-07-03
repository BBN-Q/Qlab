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
	~APSRack();

	int Init();
	int connect(const int &);
	int connect(const string &);
	int disconnect(const int &);
	int disconnect(const string &);

	int get_num_devices();
	void enumerate_devices();

	int curDeviceID;

	int program_FPGA(const string &, const int &, const int &);

private:
	int _numDevices;
	vector<APS> _APSs;
	APS * _curAPS;
	map<string, int> _serial2dev;
	vector<string> _deviceSerials;
};

#endif /* APSRACK_H_ */
