/**********************************************
* Module Name : libdacii.h
*
* Author/Date : B.C. Donovan / 21-Oct-08
*
* Description : Public Header file for libdacii.dll
*
* Restrictions/Limitations :
*
*
* Change Descriptions :
*
* Classification : Unclassified
*
* References :
*
*
*    Modified    By    Reason
*    --------    --    ------
*                BCD
*
* CVS header info.
* ----------------
* $CVSfile$
* $Author: bdonovan $
* $Date$
* $Locker:  $
* $Name:  $
* $Revision$
*
* $Log: libdacii.h,v $
* Revision 1.7  2008/12/03 15:47:57  bdonovan
* Added support for multiple DAC boxes to libdacii. Updated dacii.m for new api.
*
* Revision 1.1  2008/10/23 20:41:35  bdonovan
* First version of CMD Builder GUI that uses C dll to communicate with DACII board.
*
* C library to communicate with board is in ./lib.
*
* Matlab code has been reorganized into classes. GUI is not edited with the guide command
* in matlab.
*
* Independent triggering of each of the 4 DACs has been confirmed for both software
*  and hardware triggering with cbl_dac2_r3beta.bit
*
*
* Copyright (C) BBN Technologies Corp. 2008
**********************************************/

#ifndef LIBDACII_H
#define LIBDACII_H

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

#define MAX_DACII_DEVICES 10

EXPORT int DACII_NumDevices();
EXPORT int DACII_GetSerialNumbers();
EXPORT int DACII_Open(int device);
EXPORT int DACII_OpenByCBLID(int device);
EXPORT int DACII_ListCBLSerials();
EXPORT int DACII_Close(int device);
EXPORT int DACII_OpenBySerialNum(char * serialNum);

EXPORT int DACII_LoadWaveform(int device, unsigned short *Data, int ByteCount, int offset, int dac);

EXPORT int DACII_LoadLinkList(int device, unsigned short *OffsetData, unsigned short *CountData,
		                                     unsigned short *TriggerData, unsigned short *RepeatData,
		                                     int length, int dac, int bank);

EXPORT int DACII_SetLinkListRepeat(int device, unsigned short repeat, int dac);

EXPORT int DACII_ProgramFpga(int device, BYTE *Data, int ByteCount, int Sel);
EXPORT int DACII_SetupPLL(int device);
EXPORT int DACII_SetupVCXO(int device);

EXPORT int DACII_TriggerDac(int device, int dac, int trigger_type);
EXPORT int DACII_PauseDac(int device, int dac);
EXPORT int DACII_DisableDac(int device, int dac);

EXPORT int DACII_TriggerFpga(int device, int dac, int trigger_type);
EXPORT int DACII_PauseFpga(int device, int dac);
EXPORT int DACII_DisableFpga(int device, int dac);

EXPORT int DACII_SetLinkListMode(int device, int enable, int mode, int dac);
EXPORT int DACII_SetPllFreq(int device, int dac, int freq);

EXPORT int DACII_ReadBitFileVersion(int device);
EXPORT void DACII_ReadLibraryVersion(void * buffer, int maxlen);
#endif
