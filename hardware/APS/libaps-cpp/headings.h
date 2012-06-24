/*
 * headings.h
 *
 * Bring all the includes and constants together in one file
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */


// INCLUDES
#ifndef HEADINGS_H_
#define HEADINGS_H_

#include <string>
#include <vector>
using std::vector;
using std::string;

#include <dlfcn.h>


#include "Channel.h"
#include "APS.h"
#include "Waveform.h"
#include "LinkList.h"


//CONSTANTS

#define MAX_APS_CHANNELS 4
#define MAX_APS_BANKS 2

#define APS_WAVEFORM_UNIT_LENGTH 4

#define MAX_WAVEFORM_LENGTH 8192

#define NUM_BITS 13

#define MAX_WF_VALUE (pow(2,NUM_BITS)-1)




//FTDI
#include "ftd2xx.h"
#ifdef WIN32
#include <windows.h>
#define LIBFILE "ftd2xx.dll"


// Function Pointer Types
typedef FT_STATUS WINAPI (*pFT_Open)(int,FT_HANDLE *);
typedef FT_STATUS WINAPI (*pFT_Close)(FT_HANDLE);
typedef FT_STATUS WINAPI (*pFT_Write)(FT_HANDLE, LPVOID, DWORD, LPDWORD);
typedef FT_STATUS WINAPI (*pFT_Read)(FT_HANDLE, LPVOID,DWORD, LPDWORD);
typedef FT_STATUS WINAPI (*pFT_ListDevices)();
typedef FT_STATUS WINAPI (*pFT_SetBaudRate)(FT_HANDLE, DWORD);
typedef FT_STATUS WINAPI (*pFT_SetTimeouts)(FT_HANDLE, DWORD,DWORD);
HANDLE hdll = 0;

#define GetFunction GetProcAddress
#else
#include <dlfcn.h>
#define LIBFILE "libftd2xx.so"
#include "WinTypes.h"

typedef int (*pFT_Open)(int,FT_HANDLE *);
typedef int (*pFT_Close)(FT_HANDLE);
typedef int (*pFT_Write)(FT_HANDLE, LPVOID, DWORD, LPDWORD);
typedef int (*pFT_Read)(FT_HANDLE, LPVOID,DWORD, LPDWORD);
typedef int (*pFT_ListDevices)();
typedef int (*pFT_SetBaudRate)(FT_HANDLE, DWORD);
typedef int (*pFT_SetTimeouts)(FT_HANDLE, DWORD,DWORD);
void *hdll;

#define GetFunction dlsym
#endif




#endif /* HEADINGS_H_ */
