/*
 * X6.h
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#include "headings.h"
#include "X6_1000.h"

#ifndef X6_H_
#define X6_H_

class X6 {

// TODO find correct location for error codes and consolidate
enum X6ErrorCode {
	X6_OK,
	X6_UNKNOWN_ERROR = -1,
	X6_BUFFER_OVERFLOW = -2,
	X6_NOT_IMPLEMENTED_ERROR = -3,
	X6_INVALID_CHANNEL = -4
};


public:
	//Constructors
	X6();
	X6(int);
	//Move-ctor
	X6(X6&&);

	~X6();

	int connect();
	int disconnect();
	int init();

	int read_firmware_version() const;

	int acquire();
	int wait_for_acquisition(const int &);
	int trigger();
	int stop();
	int transfer_waveform(const int &, unsigned short *, const size_t &);

	int set_sampleRate(const double &);
	double get_sampleRate() const;

	int set_trigger_source(const TRIGGERSOURCE &);
	TRIGGERSOURCE get_trigger_source() const;

	int set_digitzer_mode(const int &, const DIGITIZER_MODE &);
	DIGITIZER_MODE get_digitzer_mode();

	int write_register(const uint32_t &, const uint32_t &, const uint32_t &);
	uint32_t read_register(const uint32_t &, const uint32_t &);

	float get_logic_temperature(int method);

	//The owning X6Rack needs access to some private members
	// friend class X6Rack;

private:
	bool isOpen_ = false;

	//Since the X6 contains non-copyable mutexes and atomic members then explicitly prevent copying
	X6(const X6&) = delete;
	X6& operator=(const X6&) = delete;

	int deviceID_;
	X6_1000 handle_; 
	int samplingRate_;
/*
	vector<UCHAR> writeQueue_;
	vector<size_t> offsetQueue_;

	int write(const unsigned int & addr, const USHORT & data, const bool & queue = false);
	int write(const unsigned int & addr, const vector<USHORT> & data, const bool & queue = false);

	int flush();
*/
};

#endif /* X6_H_ */
