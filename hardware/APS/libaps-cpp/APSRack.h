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

	int get_num_devices() const;
	string get_deviceSerial(const int &) const;
	void enumerate_devices();
	int read_bitfile_version(const int &) const;

	int program_FPGA(const int &, const string &, const FPGASELECT &, const int &);

	int setup_DACs(const int &) const;

	int clear_channel_data(const int &);

	int run(const int &);
	int stop(const int &);
	int set_trigger_source(const int &, const int &);
	int get_trigger_source(const int &) const;

	int get_sampleRate(const int &) const;
	int set_sampleRate(const int &, const int &);

	int set_channel_offset(const int &, const int &, const float &);
	float get_channel_offset(const int &, const int &) const;
	int set_channel_scale(const int &, const int &, const float &);
	float get_channel_scale(const int &, const int &) const;
	int set_channel_enabled(const int &, const int &, const bool &);
	bool get_channel_enabled(const int &, const int &) const;

	int set_channel_trigDelay(const int &, const int &, const USHORT &);
	unsigned short get_channel_trigDelay(const int &, const int &);

	int set_trigger_interval(const int &, const double &);

	int get_running(const int &);

	int set_log(FILE *);
	int set_logging_level(const int &);

	//Pass through both short and float waveforms
	template <typename T>
	int set_waveform(const int & deviceID, const int & dac, const vector<T> & data){
		return APSs_[deviceID].set_waveform(dac, data);
	}

	int set_run_mode(const int &, const int &, const RUN_MODE &);
	int set_repeat_mode(const int &, const int &, const bool & mode);

	int add_LL_bank(const int &, const int &, const vector<USHORT> &, const vector<USHORT> &, const vector<USHORT> &, const vector<USHORT> &);
	int reset_LL_banks(const int &, const int &);

	int load_sequence_file(const int &, const string &);

	int save_state_files();
	int read_state_files();
	int save_bulk_state_file(string & );
	int read_bulk_state_file(string & );

	int raw_write(int, int, UCHAR*);
	int raw_read(int, FPGASELECT);

private:
	int numDevices_;
	vector<APS> APSs_;
	vector<string> deviceSerials_;
};


#endif /* APSRACK_H_ */
