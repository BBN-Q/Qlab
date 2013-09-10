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

	int init(const string &);
	int initAPS(const int &, const string &, const bool &);
	int connect(const int &);
	int connect(const string &);
	int disconnect(const int &);
	int disconnect(const string &);

	int get_num_devices() ;
	string get_deviceSerial(const int &) ;
	void enumerate_devices();
	void update_device_enumeration();
	int get_bitfile_version(const int &);

	int program_FPGA(const int &, const int &);
	int load_bitfile(const int &, const string &, const int &);

	int setup_DACs(const int &);

	int clear_channel_data(const int &);

	int run(const int &);
	int stop(const int &);
	int set_trigger_source(const int &, const TRIGGERSOURCE &);
	TRIGGERSOURCE get_trigger_source(const int &);
	int set_trigger_interval(const int &, const double &);
	double get_trigger_interval(const int &);

	int get_sampleRate(const int &);
	int set_sampleRate(const int &, const int &);

	int set_channel_offset(const int &, const int &, const float &);
	float get_channel_offset(const int &, const int &) const;
	int set_channel_scale(const int &, const int &, const float &);
	float get_channel_scale(const int &, const int &) const;
	int set_channel_enabled(const int &, const int &, const bool &);
	bool get_channel_enabled(const int &, const int &) const;

	int get_running(const int &);

	int set_log(FILE *);
	int set_logging_level(const int &);

	//Pass through both short and float waveforms
	template <typename T>
	int set_waveform(const int & deviceID, const int & dac, const vector<T> & data){
		return APSs_[deviceID].set_waveform(dac, data);
	}

	int set_run_mode(const int &, const int &, const RUN_MODE &);

	int set_LL_data(const int &, const int &, const WordVec &, const WordVec &, const WordVec &, const WordVec &, const WordVec &);
	int set_LL_data(const int &, const int &, const WordVec &, const WordVec &, const WordVec &, const WordVec &);

	int load_sequence_file(const int &, const string &);

	int save_state_files();
	int read_state_files();
	int save_bulk_state_file(string & );
	int read_bulk_state_file(string & );

	int raw_write(int, int, uint8_t*);
	int raw_read(int);
	int read_register(int, int);

private:
	APSRack(const APSRack&) = delete;
	APSRack& operator=(const APSRack&) = delete;
	int numDevices_;
	vector<APS2> APSs_;
	vector<string> deviceSerials_;
	APSEthernet & socket_ = APSEthernet::get_instance(); 
};


#endif /* APSRACK_H_ */
