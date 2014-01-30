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


EXPORT int init(const char *);

EXPORT int enumerate_devices();
EXPORT int get_numDevices();
EXPORT void get_deviceSerials(const char **);

EXPORT int connect_APS(const char *);
EXPORT int disconnect_APS(const char *);

EXPORT int reset(const char *, int);
EXPORT int initAPS(const char *, int);
EXPORT int get_bitfile_version(const char *);

EXPORT double get_uptime(const char *);

EXPORT int set_sampleRate(const char *, int);
EXPORT int get_sampleRate(const char *);

EXPORT int set_channel_offset(const char *, int, float);
EXPORT float get_channel_offset(const char *, int);
EXPORT int set_channel_scale(const char *, int, float);
EXPORT float get_channel_scale(const char *, int);
EXPORT int set_channel_enabled(const char *, int, int);
EXPORT int get_channel_enabled(const char *, int);

EXPORT int set_trigger_source(const char *, int);
EXPORT int get_trigger_source(const char *);
EXPORT int set_trigger_interval(const char *, double);
EXPORT double get_trigger_interval(const char *);

EXPORT int set_waveform_float(const char *, int, float*, int);
EXPORT int set_waveform_int(const char *, int, short*, int);

EXPORT int set_LL_data_IQ(const char *, int, int, unsigned short*, unsigned short*, unsigned short*, unsigned short*, unsigned short*);

EXPORT int set_run_mode(const char *, int, int);

EXPORT int load_sequence_file(const char *, const char*);

EXPORT int clear_channel_data(const char *);

EXPORT int run(const char *);
EXPORT int stop(const char *);

EXPORT int get_running(const char *);

EXPORT int set_log(const char *);
EXPORT int set_logging_level(int);

/* more debug methods */
//EXPORT int save_state_files();
//EXPORT int read_state_files();
//EXPORT int save_bulk_state_file();
//EXPORT int read_bulk_state_file();

EXPORT int raw_write(const char *, int, uint8_t*);
EXPORT int raw_read(const char *);
EXPORT int read_register(const char *, int);
EXPORT int program_FPGA(const char *, int);


#ifdef __cplusplus
}
#endif

#endif /* LIBAPS_H_ */
