/*
 * X6Rack.h
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#include "headings.h"
#include "X6.h"

#ifndef X6RACK_H
#define X6RACK_H


class X6Rack {
public:
	X6Rack();
	~X6Rack();

	int init();
	int initX6(const int &);
	int connect(const int &);
	int disconnect(const int &);

	int get_num_devices() ;
	void enumerate_devices();
	int read_firmware_version(const int &) const;

	int acquire(const int &);
	int wait_for_acquisition(const int &, const int &);
	int stop(const int &);
	int transfer_waveform(const int &, const int &, short *, const size_t &);

	int set_trigger_source(const int &, const TRIGGERSOURCE &);
	TRIGGERSOURCE get_trigger_source(const int &) const;

	int set_digitizer_mode(const int &, const DIGITIZER_MODE &);
	DIGITIZER_MODE get_digitizer_mode(const int &) const;

	double get_sampleRate(const int &) const;
	int set_sampleRate(const int &, const double &);

	int set_averager_settings(const int &, const int &, const int &, const int &, const int &);

	int set_log(FILE *);
	int set_logging_level(const int &);

	// debug methods
	int raw_write(int, int, UCHAR*);
	int raw_read(int);
	
	int read_register(int, int, int);
	int write_register(int, int, int, int);

	// X6-1000M Test interface
	float get_logic_temperature(int, int);

private:
	X6Rack(const X6Rack&) = delete;
	X6Rack& operator=(const X6Rack&) = delete;
	X6 X6s_[MAX_NUM_DEVICES];
	int numDevices_ = 0;
};


#endif /* X6RACK_H */
