/*
 * APSRack.h
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#include "headings.h"

#ifndef APSRACK_H_
#define APSRACK_H_


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

	int program_FPGA(const int &, const string &, const FPGASELECT &, const int &);

	int setup_DACs(const int &) const;

	int trigger_FPGA_debug(const int &, const FPGASELECT &);
	int disable_FPGA_debug(const int &, const FPGASELECT &);
	int set_trigger_source(const int &, const int &);

	int get_sampleRate(const int &, const FPGASELECT &) const;
	int set_sampleRate(const int &, const FPGASELECT &, const int &, const bool &);

	int set_channel_offset(const int &, const int &, const float &);
	float get_channel_offset(const int &, const int &) const;
	int set_channel_scale(const int &, const int &, const float &);
	float get_channel_scale(const int &, const int &) const;
	int set_channel_enabled(const int &, const int &, const bool &);
	bool get_channel_enabled(const int &, const int &) const;

	int set_log(FILE *);

	//Pass through both short and float waveforms
	template <typename T>
	int set_waveform(const int & deviceID, const int & dac, const vector<T> & data){
		return APSs_[deviceID].set_waveform(dac, data);
	}

	int set_LL_mode(const int & deviceID, const int & dac, const bool & enable, const bool & mode);
	int add_LL_bank(const int &, const int &, const int &, const vector<USHORT> &, const vector<USHORT>, const vector<USHORT>, const vector<USHORT>);
	int reset_LL_banks(const int &, const int &);

	int load_sequence_file(const int &, const string &);

private:
	int numDevices_;
	vector<APS> APSs_;
	vector<string> deviceSerials_;
};


#endif /* APSRACK_H_ */
