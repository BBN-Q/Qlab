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
public:
	// TODO find correct location for error codes and consolidate
	enum X6ErrorCode {
		X6_OK,
		X6_UNKNOWN_ERROR = -1,
		X6_BUFFER_OVERFLOW = -2,
		X6_NOT_IMPLEMENTED_ERROR = -3,
		X6_INVALID_CHANNEL = -4,
		X6_FILE_ERROR = -5,
		X6_INVALID_DEVICEID = -6,
		X6_TIMEOUT = -7
	};

	X6();
	~X6();

	int connect(const int &);
	int disconnect();
	int init();

	int read_firmware_version() const;

	int acquire();
	int wait_for_acquisition(const int &);
	int stop();
	int transfer_waveform(const int &, short *, const size_t &);

	int set_sampleRate(const double &);
	double get_sampleRate() const;

	int set_averager_settings(const int &, const int &, const int &, const int &);

	int set_trigger_source(const TRIGGERSOURCE &);
	TRIGGERSOURCE get_trigger_source() const;

	int set_digitizer_mode(const DIGITIZER_MODE &);
	DIGITIZER_MODE get_digitizer_mode() const;

	int write_register(const uint32_t &, const uint32_t &, const uint32_t &);
	uint32_t read_register(const uint32_t &, const uint32_t &) const;

	float get_logic_temperature(int method);

private:
	bool isOpen_ = false;

	//Since the X6 contains non-copyable mutexes and atomic members then explicitly prevent copying
	X6(const X6&) = delete;
	X6& operator=(const X6&) = delete;

	int deviceID_;
	X6_1000 handle_;

	int samplingRate_;

	// averager settings
	int recordLength_;
	int numSegments_;
	int waveforms_;
	int roundRobins_;
};

#endif /* X6_H_ */
