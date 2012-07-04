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

EXPORT int Init();

EXPORT int connect_by_ID(int);

EXPORT int connect_by_Serial(char *);

EXPORT int disconnect();

EXPORT int program_FPGA(char *, int, int);

#ifdef __cplusplus
}
#endif

#endif /* LIBAPS_H_ */
