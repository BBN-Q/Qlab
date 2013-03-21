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


EXPORT int init();

EXPORT int get_numDevices();
EXPORT void get_deviceSerial(int, char *);

EXPORT int connect_by_ID(int);
EXPORT int connect_by_serial(char *);

EXPORT int disconnect_by_ID(int);
EXPORT int disconnect_by_serial(char *);

EXPORT int serial2ID(char *);

EXPORT int initAPS(int, char*, int);
EXPORT int read_bitfile_version(int);

EXPORT int set_sampleRate(int, int);
EXPORT double get_sampleRate(int);

EXPORT int set_channel_offset(int, int, float);
EXPORT float get_channel_offset(int, int);
EXPORT int set_channel_scale(int, int, float);
EXPORT float get_channel_scale(int, int);
EXPORT int set_channel_enabled(int, int, int);
EXPORT int get_channel_enabled(int, int);

EXPORT int set_trigger_source(int, int);
EXPORT int get_trigger_source(int);
EXPORT int set_trigger_interval(int, double);
EXPORT double get_trigger_interval(int);

EXPORT int set_miniLL_repeat(int, unsigned short);

EXPORT int set_waveform_float(int, int, float*, int);
EXPORT int set_waveform_int(int, int, short*, int);

EXPORT int set_LL_data_IQ(int, int, int, unsigned short*, unsigned short*, unsigned short*, unsigned short*, unsigned short*);

EXPORT int set_run_mode(int, int, int);
EXPORT int set_repeat_mode(int, int, int);

EXPORT int load_sequence_file(int, const char*);

EXPORT int clear_channel_data(int);

EXPORT int run(int);
EXPORT int stop(int);

EXPORT int get_running(int);

EXPORT int set_log(char *);
EXPORT int set_logging_level(int);

/* more debug methods */
EXPORT int save_state_files();
EXPORT int read_state_files();
EXPORT int save_bulk_state_file();
EXPORT int read_bulk_state_file();

EXPORT int raw_write(int, int, unsigned char*);
EXPORT int raw_read(int, int);
EXPORT int read_register(int, int, int);
EXPORT int program_FPGA(int, char*, int, int);

// II X6-1000M Test Interface
EXPORT float get_logic_temperature(int);
EXPORT int enable_test_generator(int,int,float);
EXPORT int disable_test_generator(int);

EXPORT void set_malibu_threading_enable(bool);

#ifdef __cplusplus
}
#endif

#endif /* LIBAPS_H_ */
