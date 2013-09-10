/*
 * APSRack.h
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

 
#ifndef APSRACK_H_
#define APSRACK_H_

#include "headings.h"
#include "APS2.h"

class APSRack {
public:
	APSRack();
	~APSRack();

	int init(const string &);
	int initAPS(const string &, const string &, const bool &);
	int connect(const string &);
	int disconnect(const string &);

	int get_num_devices() ;
	void enumerate_devices();
	int get_bitfile_version(const string &);

	int program_FPGA(const string &, const int &);
	int load_bitfile(const string &, const string &, const int &);

	int setup_DACs(const string &);

	int clear_channel_data(const string &);

	int run(const string &);
	int stop(const string &);
	int set_trigger_source(const string &, const TRIGGERSOURCE &);
	TRIGGERSOURCE get_trigger_source(const string &);
	int set_trigger_interval(const string &, const double &);
	double get_trigger_interval(const string &);

	int get_sampleRate(const string &);
	int set_sampleRate(const string &, const int &);

	int set_channel_offset(const string &, const int &, const float &);
	float get_channel_offset(const string &, const int &) ;
	int set_channel_scale(const string &, const int &, const float &);
	float get_channel_scale(const string &, const int &) ;
	int set_channel_enabled(const string &, const int &, const bool &);
	bool get_channel_enabled(const string &, const int &) ;

	int get_running(const string &);

	int set_log(FILE *);
	int set_logging_level(const int &);

	//Pass through both short and float waveforms
	template <typename T>
	int set_waveform(const string & deviceSerial, const int & dac, const vector<T> & data){
		return APSs_[deviceSerial].set_waveform(dac, data);
	}

	int set_run_mode(const string &, const int &, const RUN_MODE &);

	int set_LL_data(const string &, const int &, const WordVec &, const WordVec &, const WordVec &, const WordVec &, const WordVec &);
	int set_LL_data(const string &, const int &, const WordVec &, const WordVec &, const WordVec &, const WordVec &);

	int load_sequence_file(const string &, const string &);

	int save_state_files();
	int read_state_files();
	int save_bulk_state_file(string & );
	int read_bulk_state_file(string & );

	int raw_write(const string &, int, uint8_t*);
	int raw_read(const string &);
	int read_register(const string &, int);

private:
	APSRack(const APSRack&) = delete;
	APSRack& operator=(const APSRack&) = delete;
	int numDevices_;
	map<string, APS2> APSs_;
	set<string> deviceSerials_;
};


#endif /* APSRACK_H_ */
