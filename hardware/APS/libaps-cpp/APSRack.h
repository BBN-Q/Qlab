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

	map<string, int> serial2dev;

	int init();
	int initAPS(const int &, const string &, const bool &);
	int connect(const int &);
	int connect(const string &);
	int disconnect(const int &);
	int disconnect(const string &);

	int get_num_devices();
	void enumerate_devices();

	int program_FPGA(const int &, const string &, const int &, const int &);

	int get_sampleRate(const int &, const int &);
	int set_sampleRate(const int &, const int &, const int &, const bool &);

	template <typename T>
	int set_waveform(const int & deviceID, const int & channelNum, const vector<T> & data){
		return _APSs[deviceID]._channels[channelNum].set_waveform(data);
	}

	inline int set_LL_mode(const int & deviceID, const int & dac, const bool & enable, const bool & mode){
		//Pass through to APS method
		return _APSs[deviceID].set_LL_mode(dac, enable, mode);
	}


private:
	int _numDevices;
	vector<APS> _APSs;
	vector<string> _deviceSerials;
};

#endif /* APSRACK_H_ */
