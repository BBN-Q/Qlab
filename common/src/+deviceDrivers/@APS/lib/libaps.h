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

#if defined(WIN32) || defined(_WIN32)
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
		#define EXPORT //* EXE import */
	#endif
#else
	#define EXPORT
#endif

#define MAX_APS_DEVICES 10


EXPORT int APS_NumDevices();
EXPORT int APS_GetSerialNum(int device, char * buffer, int bufLen);
EXPORT int APS_PrintSerialNumbers();
EXPORT int APS_Open(int device, int force);
EXPORT int APS_OpenByID(int device);
EXPORT int APS_Close(int device);
EXPORT int APS_OpenBySerialNum(char * serialNum);

EXPORT int APS_LoadWaveform(int device, short *Data, int ByteCount, int offset, int dac,
                            int validate, int useSlowWrite);

EXPORT int APS_LoadLinkList(int device, unsigned short *OffsetData, unsigned short *CountData,
		                                     unsigned short *TriggerData, unsigned short *RepeatData,
		                                     int length, int dac, int bank, int validate);

EXPORT int APS_SetLinkListRepeat(int device, unsigned short repeat, int dac);

EXPORT int APS_ProgramFpga(int device, BYTE *Data, int ByteCount, int Sel, int expectedVersion);
EXPORT int APS_SetupPLL(int device);
EXPORT int APS_SetupVCXO(int device);

EXPORT int APS_IsRunning(int device);

EXPORT int APS_TriggerDac(int device, int dac, int trigger_type);
EXPORT int APS_PauseDac(int device, int dac);
EXPORT int APS_DisableDac(int device, int dac);

EXPORT int APS_TriggerFpga(int device, int dac, int trigger_type);
EXPORT int APS_PauseFpga(int device, int dac);
EXPORT int APS_DisableFpga(int device, int dac);

EXPORT int APS_SetLinkListMode(int device, int enable, int mode, int dac);
EXPORT int APS_SetPllFreq(int device, int dac, int freq, int testLock);
EXPORT int APS_GetPllFreq(int device, int dac);
EXPORT int APS_TestPllSync(int device, int dac, int numSyncChannels);
EXPORT int APS_ReadPllStatus(int device, int fpga);

EXPORT int  APS_ReadBitFileVersion(int device);
EXPORT void APS_ReadLibraryVersion(void * buffer, int maxlen);
EXPORT int  APS_ReadAllRegisters(int device, int fpga);
EXPORT int  APS_TestWaveformMemory(int device, int dac, int byteCount);
EXPORT int  APS_SetDebugLevel(int level);
EXPORT int  APS_ReadLinkListStatus(int device, int dac);

EXPORT void APS_HashPulse(unsigned short *pulse, int len, void * hashStr, int maxlen );
EXPORT int  APS_ClearLinkListELL(int device,int dac, int bank);

EXPORT int   APS_SetChannelOffset(int device, int dac, short offset);
EXPORT short APS_ReadChannelOffset(int device, int dac);

EXPORT UCHAR APS_ReadStatusCtrl(int device);
EXPORT int   APS_ResetStatusCtrl(int device);
EXPORT int   APS_ClearStatusCtrl(int device);
EXPORT int   APS_RegWriteTest(int device, int addr);

// Waveform related functions

EXPORT int   APS_SetWaveform(int device, int channel, float * data, int length);
EXPORT int   APS_SetWaveformOffset(int device, int channel, float offset);
EXPORT float APS_GetWaveformOffset(int device, int channel);
EXPORT int   APS_SetWaveformScale(int device, int channel, float scale);
EXPORT float APS_GetWaveformScale(int device, int channel);
EXPORT int   APS_LoadStoredWaveform(int device, int channel);
EXPORT int   APS_LoadAllWaveforms(int device);
EXPORT int   APS_SetLinkList(int device, int channel,
                           unsigned short *OffsetData, unsigned short *CountData,
                           unsigned short *TriggerData, unsigned short *RepeatData,
                           int length, int bank);
EXPORT int APS_SaveWaveformCache(int device, char * filename);
EXPORT int APS_LoadWaveformCache(int device, char * filename);
#endif
