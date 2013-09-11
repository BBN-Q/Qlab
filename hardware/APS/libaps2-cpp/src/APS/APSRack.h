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

	void enumerate_devices();
	int get_num_devices() ;

	int set_log(FILE *);
	int set_logging_level(const int &);

	int save_state_files();
	int read_state_files();
	int save_bulk_state_file(string & );
	int read_bulk_state_file(string & );

	int raw_write(const string &, int, uint8_t*);
	int raw_read(const string &);
	int read_register(const string &, int);

	map<string, APS2> APSs;
	size_t numDevices;
	set<string> deviceSerials;

private:
	APSRack(const APSRack&) = delete;
	APSRack& operator=(const APSRack&) = delete;
};


#endif /* APSRACK_H_ */
