/*
 * libaps.h
 *
 *  Created on: Jun 25, 2012
 *      Author: qlab
 */

#ifndef LIBX6ADC_H
#define LIBX6ADC_H

#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

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


EXPORT int init();
EXPORT int connect_by_ID(int);
EXPORT int disconnect(int);
EXPORT int get_num_devices();

EXPORT int initX6(int);
EXPORT int read_firmware_version(int);

EXPORT int set_digitizer_mode(int, int);
EXPORT int get_digitizer_mode(int);

EXPORT int set_sampleRate(int, double);
EXPORT double get_sampleRate(int);

EXPORT int set_trigger_source(int, int);
EXPORT int get_trigger_source(int);

EXPORT int set_reference_source(int, int);
EXPORT int get_reference_source(int);

EXPORT int set_averager_settings(int, int, int, int, int);

EXPORT int acquire(int);
EXPORT int wait_for_acquisition(int, int);
EXPORT int stop(int);
EXPORT int transfer_waveform(int, int, short *, unsigned int);

EXPORT int set_log(char *);
int update_log(FILE * pFile);
EXPORT int set_logging_level(int);

/* debug methods */
EXPORT int read_register(int, int, int);
EXPORT int write_register(int, int, int, int);

// II X6-1000M Test Interface
EXPORT float get_logic_temperature(int,int);

#ifdef __cplusplus
}
#endif

#endif /* LIBX6ADC_H */
