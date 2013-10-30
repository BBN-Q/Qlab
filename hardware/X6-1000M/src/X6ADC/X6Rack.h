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

	map<string, int> serial2dev;

	int init();
	int initX6(const int &);
	int connect(const int &);
	int connect(const string &);
	int disconnect(const int &);

	int get_num_devices() ;
	string get_deviceSerial(const int &) ;
	void enumerate_devices();
	void update_device_enumeration();
	int read_firmware_version(const int &) const;

	int acquire(const int &);
	int wait_for_acquisition(const int &);
	int stop(const int &);
	int transfer_waveform(const int, const int, unsigned short *);

	int set_trigger_source(const int &, const TRIGGERSOURCE &);
	TRIGGERSOURCE get_trigger_source(const int &) const;

	double get_sampleRate(const int &) const;
	int set_sampleRate(const int &, const int &);

	int set_log(FILE *);
	int set_logging_level(const int &);

	// debug methods
	int raw_write(int, int, UCHAR*);
	int raw_read(int, FPGASELECT);
	
	int read_register(int, int, int);
	int write_register(int, int, int, int);


	// X6-1000M Test interface
	float get_logic_temperature(int, int);

private:
	X6Rack(const X6Rack&) = delete;
	X6Rack& operator=(const X6Rack&) = delete;
	int numDevices_;
	vector<X6> X6s_;
	vector<string> deviceSerials_;
};


#endif /* X6RACK_H */
