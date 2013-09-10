/*
 * libaps.h
 *
 *  Created on: Jun 25, 2012
 *      Author: qlab
 */

#ifndef LIBAPS_H_
#define LIBAPS_H_

#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif


#ifdef __cplusplus
extern "C" {
#endif

enum APSErrorCode {
	APS_OK,
	APS_UNKNOWN_ERROR = -1,
	APS_FILE_ERROR = -2
};


EXPORT int init(char *);

EXPORT int get_numDevices();
EXPORT void get_deviceSerials(char *);

EXPORT int connect_APS(char *);
EXPORT int disconnect_APS(char *);

EXPORT int initAPS(char *, char*, int);
EXPORT int get_bitfile_version(char *);

EXPORT int set_sampleRate(char *, int);
EXPORT int get_sampleRate(char *);

EXPORT int set_channel_offset(char *, int, float);
EXPORT float get_channel_offset(char *, int);
EXPORT int set_channel_scale(char *, int, float);
EXPORT float get_channel_scale(char *, int);
EXPORT int set_channel_enabled(char *, int, int);
EXPORT int get_channel_enabled(char *, int);

EXPORT int set_trigger_source(char *, int);
EXPORT int get_trigger_source(char *);
EXPORT int set_trigger_interval(char *, double);
EXPORT double get_trigger_interval(char *);

EXPORT int set_waveform_float(char *, int, float*, int);
EXPORT int set_waveform_int(char *, int, short*, int);

EXPORT int set_LL_data_IQ(char *, int, int, unsigned short*, unsigned short*, unsigned short*, unsigned short*, unsigned short*);

EXPORT int set_run_mode(char *, int, int);

EXPORT int load_sequence_file(char *, const char*);

EXPORT int clear_channel_data(char *);

EXPORT int set_ethernet_active(char * , int);

EXPORT int run(char *);
EXPORT int stop(char *);

EXPORT int get_running(char *);

EXPORT int set_log(char *);
EXPORT int set_logging_level(int);

/* more debug methods */
//EXPORT int save_state_files();
//EXPORT int read_state_files();
//EXPORT int save_bulk_state_file();
//EXPORT int read_bulk_state_file();

EXPORT int raw_write(char *, int, uint8_t*);
EXPORT int raw_read(char *);
EXPORT int read_register(char *, int);
EXPORT int program_FPGA(char *, int);


#ifdef __cplusplus
}
#endif

#endif /* LIBAPS_H_ */
