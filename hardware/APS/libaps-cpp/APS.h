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
	int program_FPGA(const string &, const UCHAR &, const int &);
	int read_bitfile_version(const UCHAR &);

	//The owning APSRack needs access to some private members
	friend class APSRack;

private:
	int _deviceID;
	string _deviceSerial;
	vector<Channel> _channels;
	FT_HANDLE _handle;
};

#endif /* APS_H_ */
