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
	APS(int, string);
	~APS();

	int connect();
	int disconnect();

	int init(const string &, const bool &);

	int setup_VCXO();
	int setup_PLL();
	int program_FPGA(const string &, const UCHAR &, const int &);
	int read_bitfile_version(const UCHAR &);



	int set_sampleRate(const int &, const int &, const bool &);
	int get_sampleRate(const int & fpga);

	//The owning APSRack needs access to some private members
	friend class APSRack;

private:
	int _deviceID;
	string _deviceSerial;
	vector<Channel> _channels;
	FT_HANDLE _handle;
};

#endif /* APS_H_ */
