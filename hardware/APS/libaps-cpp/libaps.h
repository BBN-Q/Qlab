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
#include <stdbool.h>
#endif


#ifdef __cplusplus
extern "C" {
#endif

EXPORT int init();

EXPORT int connect_by_ID(int);

EXPORT int connect_by_serial(char *);

EXPORT int disconnect_by_ID(int);

EXPORT int disconnect_by_serial(char *);

EXPORT int serial2ID(char *);

EXPORT int initAPS(int, char*, int);

EXPORT int program_FPGA(int, char *, int, int);

EXPORT int set_sampleRate(int, int, int, int);

EXPORT int get_sampleRate(int, int);


#ifdef __cplusplus
}
#endif

#endif /* LIBAPS_H_ */
