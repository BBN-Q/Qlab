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
EXPORT int get_sampleRate(int);

EXPORT int set_channel_offset(int, int, float);
EXPORT float get_channel_offset(int, int);
EXPORT int set_channel_scale(int, int, float);
EXPORT float get_channel_scale(int, int);
EXPORT int set_channel_enabled(int, int, int);
EXPORT int get_channel_enabled(int, int);
EXPORT int set_channel_trigDelay(int, int, unsigned short);
EXPORT unsigned short get_channel_trigDelay(int, int);

EXPORT int set_trigger_source(int, int);
EXPORT int get_trigger_source(int);

EXPORT int set_waveform_float(int, int, float*, int);
EXPORT int set_waveform_int(int, int, short*, int);

EXPORT int add_LL_bank(int, int, int, unsigned short*, unsigned short*, unsigned short*, unsigned short*);
EXPORT int reset_LL_banks(int, int);

EXPORT int set_run_mode(int, int, int);
EXPORT int set_repeat_mode(int, int, int);

EXPORT int load_sequence_file(int, char*);

EXPORT int clear_channel_data(int);

EXPORT int run(int);
EXPORT int stop(int);
EXPORT int trigger_FPGA_debug(int, int);
EXPORT int disable_FPGA_debug(int, int);

EXPORT int get_running(int);

EXPORT int set_log(char *);
EXPORT int set_logging_level(int);

EXPORT int save_state_files();
EXPORT int read_state_files();
EXPORT int save_bulk_state_file();
EXPORT int read_bulk_state_file();


#ifdef __cplusplus
}
#endif

#endif /* LIBAPS_H_ */
