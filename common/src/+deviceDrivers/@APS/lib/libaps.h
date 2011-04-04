/**********************************************
* Module Name : libaps.h
*
* Author/Date : B.C. Donovan / 21-Oct-08
*
* Description : Public Header file for libaps.dll
*
* Restrictions/Limitations :
*
*
* Change Descriptions :
*
* References :
*
*
*
* Copyright (C) BBN Technologies Corp. 2008 - 2011
**********************************************/

#ifndef LIBAPS_H
#define LIBAPS_H

// test for the LCC compilier used by Matlab on windows
// this needs to be done since the OS can not be passed
// from windows
#ifdef __lcc__
    #define WINDOWS
#endif

#ifdef WIN32
	#include "windows.h"
#elif __APPLE__
	#include "wintypes.h"
#else
	#include "WinTypes.h"
#endif

// Public functions exported by DLL
#ifdef WIN32
	#ifdef BUILD_DLL
		#define EXPORT __declspec(dllexport) /* DLL export */
	#else
		#define EXPORT __declspec(dllimport) /* EXE import */
	#endif
#else
	#define EXPORT
#endif

#define MAX_APS_DEVICES 10

EXPORT int APS_NumDevices();
EXPORT int APS_GetSerialNumbers();
EXPORT int APS_Open(int device);
EXPORT int APS_OpenByID(int device);
EXPORT int APS_ListSerials();
EXPORT int APS_Close(int device);
EXPORT int APS_OpenBySerialNum(char * serialNum);

EXPORT int APS_LoadWaveform(int device, unsigned short *Data, int ByteCount, int offset, int dac,
                            int validate, int useSlowWrite);

EXPORT int APS_LoadLinkList(int device, unsigned short *OffsetData, unsigned short *CountData,
		                                     unsigned short *TriggerData, unsigned short *RepeatData,
		                                     int length, int dac, int bank, int validate);

EXPORT int APS_SetLinkListRepeat(int device, unsigned short repeat, int dac);

EXPORT int APS_ProgramFpga(int device, BYTE *Data, int ByteCount, int Sel);
EXPORT int APS_SetupPLL(int device);
EXPORT int APS_SetupVCXO(int device);

EXPORT int APS_TriggerDac(int device, int dac, int trigger_type);
EXPORT int APS_PauseDac(int device, int dac);
EXPORT int APS_DisableDac(int device, int dac);

EXPORT int APS_TriggerFpga(int device, int dac, int trigger_type);
EXPORT int APS_PauseFpga(int device, int dac);
EXPORT int APS_DisableFpga(int device, int dac);

EXPORT int APS_SetLinkListMode(int device, int enable, int mode, int dac);
EXPORT int APS_SetPllFreq(int device, int dac, int freq);

EXPORT int APS_ReadBitFileVersion(int device);
EXPORT void APS_ReadLibraryVersion(void * buffer, int maxlen);
EXPORT int APS_ReadAllRegisters(int device);
EXPORT int APS_TestWaveformMemory(int device, int dac, int byteCount);
EXPORT int APS_SetDebugLevel(int level);

#endif
