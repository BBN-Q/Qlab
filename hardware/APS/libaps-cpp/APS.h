/*
 * APS.h
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#ifndef APS_H_
#define APS_H_

#include "headings.h"

class Channel;

class APS {
public:
	APS();
	~APS();

	int read_Reg(ULONG, ULONG, ULONG, UCHAR *);
	int write_Reg();
	int program_FPGA(const string &);

private:
	int deviceID;
	string deviceSerial;
	vector<Channel> channels;



};

#endif /* APS_H_ */
