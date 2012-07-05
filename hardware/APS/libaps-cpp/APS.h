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

	inline int read_bitfile_version(const UCHAR & chipSelect){
		//Pass through to FPGA code
		return FPGA::read_bitFile_version(_handle, chipSelect);
	}

	inline int set_sampleRate(const int & fpga, const int & freq, const bool & testLock){
		//Pass through to the FPGA code
		return FPGA::set_PLL_freq(_handle, fpga, freq, testLock);
	}

	inline int get_sampleRate(const int & fpga){
		//Pass through to FPGA code
		return FPGA::get_PLL_freq(_handle, fpga);
	}

	template <typename T>
    inline int set_waveform(const int & dac, const vector<T> & data){
		_channels[dac].set_waveform(data);
		FPGA::write_waveform(_handle, dac, _channels[dac].prep_waveform());
	}

	inline int set_LL_mode(const int & dac , const bool & enable, const bool & mode){
		//Pass through to FPGA code
		return FPGA::set_LL_mode(_handle, dac, enable, mode);
	}

	//The owning APSRack needs access to some private members
	friend class APSRack;

private:
	int _deviceID;
	string _deviceSerial;
	vector<Channel> _channels;
	FT_HANDLE _handle;

};

#endif /* APS_H_ */
