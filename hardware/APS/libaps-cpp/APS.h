/*
 * APS.h
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#include "headings.h"

#ifndef APS_H_
#define APS_H_

class APS {
public:
	APS();
	APS(int, string);
	~APS();

	int connect();
	int disconnect();

	int init(const string &, const bool &);

	int setup_VCXO() const;
	int setup_PLL() const;
	int setup_DACs() const;

	int program_FPGA(const string &, const FPGASELECT &, const int &) const;
	int read_bitFile_version(const FPGASELECT &) const;

	int set_sampleRate(const FPGASELECT &, const int &, const bool &);
	int get_sampleRate(const FPGASELECT & fpga) const;

	int set_channel_enabled(const int &, const bool &);
	bool get_channel_enabled(const int &) const;
	int set_channel_offset(const int &, const float &);
	float get_channel_offset(const int &) const;
	int set_channel_scale(const int &, const float &);
	float get_channel_scale(const int &) const;
	int set_offset_register(const int &, const float &);

	template <typename T>
	int set_waveform(const int & dac, const vector<T> & data){
		channels_[dac].set_waveform(data);
		return write_waveform(dac, channels_[dac].prep_waveform());
	}

	int set_LL_mode(const int &, const bool &, const bool &);
	int add_LL_bank(const int & dac, const vector<unsigned short> & offset, const vector<unsigned short> & count, const vector<unsigned short> & repeat, const vector<unsigned short> & trigger);


	int load_sequence_file(const string &);

	int run();
	int stop();

	//The owning APSRack needs access to some private members
	friend class APSRack;

private:
	int deviceID_;
	string deviceSerial_;
	FT_HANDLE handle_;
	vector<Channel> channels_;
	map<FPGASELECT, CheckSum> checksums_;
	int triggerSource_;
	vector<UCHAR> writeQueue_;
	thread * bankBouncerThread_;
	bool running_ = false;


	int write(const FPGASELECT &, const ULONG &, const ULONG &, const bool & queue = false);

	template <typename T>
	int write(const FPGASELECT & fpga, ULONG addr, const vector<T> & data, const bool & queue=false){
		for(const T tmpData : data){
			write(fpga, addr++, ULONG(tmpData), queue);
		}
		return 0;
	}

	int flush();
	int reset_status_ctrl();
	int clear_status_ctrl();

	int setup_PLL();
	int set_PLL_freq(const FPGASELECT &, const int &, const bool &);
	int test_PLL_sync(const FPGASELECT &, const int &);
	int read_PLL_status(const FPGASELECT & fpga, const int & regAddr = FPGA_ADDR_REGREAD | FPGA_OFF_VERSION, const vector<int> & pllLockBits = {PLL_02_LOCK_BIT, PLL_13_LOCK_BIT, REFERENCE_PLL_LOCK_BIT});
	int get_PLL_freq(const FPGASELECT &) const;

	int setup_VCXO();

	int setup_DAC(const int &) const;

	int trigger(const FPGASELECT &);
	int disable(const FPGASELECT &);

	int reset_checksums(const FPGASELECT &);
	bool verify_checksums(const FPGASELECT &);

	int write_waveform(const int &, const vector<short> &);

	int write_LL_data(const int &, const int &, const int &);

	int stream_LL_data();
	int read_LL_status(const int &);
};

inline FPGASELECT dac2fpga(const int & dac)
{
	/* select FPGA based on DAC id number
	    DAC0 & DAC1 -> FPGA 0
	    DAC2 & DAC3 -> FPGA 1
	    Added a special case: sending dac = -1 will trigger both FPGAs
	    at the same time.
	 */
	switch(dac) {
		case -1:
			return ALL_FPGAS;
		case 0:
		case 1:
			return FPGA1;
		case 2:
		case 3:
			return FPGA2;
		default:
			return INVALID_FPGA;
	}
}

#endif /* APS_H_ */
