/**********************************************
 * Module Name : libaps.c
 *
 * Author/Date : B.C. Donovan / 21-Oct-08
 *
 * Description : APS functions for libaps.dll
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
 *                       ZRL APS Example Code
 *
 * $Author: bdonovan $
 * $Date$
 * $Locker:  $
 * $Name:  $
 * $Revision$
 *

 *
 * Copyright (C) BBN Technologies Corp. 2008 - 2011
 **********************************************/


#include <strings.h>
#include "aps.h"
#include "libaps.h"
#include "fpga.h"
#include "ftd2xx.h"
#include "sha1.h"
#include "waveform.h"
#include "common.h"

#include <stdio.h>

extern gRegRead; // external global reg read value from common.c

#ifdef WIN32
#include <windows.h>

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

#ifdef WIN32
#define LIBFILE "ftd2xx.dll"
#elif __APPLE__
#define LIBFILE "libftd2xx.dylib"
#include <WinTypes.h>
#else
#define LIBFILE "libftd2xx.so"
#include <WinTypes.h>
#endif

FT_HANDLE usb_handles[MAX_APS_DEVICES];

waveform_t * waveforms[MAX_APS_DEVICES];

// global variables for function pointers
pFT_Open DLL_FT_Open;
pFT_Close DLL_FT_Close;
pFT_Write DLL_FT_Write;
pFT_Read DLL_FT_Read;
pFT_ListDevices DLL_FT_ListDevices;
pFT_SetBaudRate DLL_FT_SetBaudRate;
pFT_SetTimeouts DLL_FT_SetTimeouts;

char deviceSerials[64][MAX_APS_DEVICES];

#define DEBUG

FT_HANDLE device2handle(int device) {
	if (device > MAX_APS_DEVICES) {
		return 0;
	}
	return usb_handles[device];
}

EXPORT int APS_SetDebugLevel(int level) {
	if (level < 0) level = 0;
	setDebugLevel(level);
	return 0;
}

int APS_Init()
/*******************************************************************
 *
 * Function Name : APS_Init()
 *
 * Description : Initialize function points to ftd2xx.dll library
 *
 * Inputs : None
 *
 * Returns : 0 on success -1 if ftd2xx.dll is not found
 *
 * Error Conditions :
 *                             -1: ftd2xx.dll could not be loaded
 *
 * Unit Tested on:
 *
 * Unit Tested by:
 *
 ********************************************************************/
{
	/* Initialize function points to ftd2xx library  */

#if defined(DEBUG) && defined(BUILD_DLL)
	freopen("libaps.log","w", stderr);
#endif

#ifdef WIN32

	hdll = LoadLibrary("ftd2xx.dll");
	if ((uintptr_t)hdll <= HINSTANCE_ERROR) {
		dlog(DEBUG_INFO,"Error opening ftd2xx.dll library\n");
		return -1;
	}

#else
	hdll = dlopen(LIBFILE,RTLD_LAZY);
	if (hdll == 0) {
		dlog(DEBUG_INFO,"Error opening ftd2 library: %s\n",dlerror());
		return -1;
	}
#endif

	dlog(DEBUG_VERBOSE,"Library Loaded\n");


	DLL_FT_Open  = (pFT_Open) GetFunction(hdll,"FT_Open");
	DLL_FT_Close = (pFT_Close) GetFunction(hdll,"FT_Close");
	DLL_FT_Write = (pFT_Write) GetFunction(hdll,"FT_Write");
	DLL_FT_Read  = (pFT_Read) GetFunction(hdll,"FT_Read");
	DLL_FT_SetBaudRate = (pFT_SetBaudRate) GetFunction(hdll,"FT_SetBaudRate");

	DLL_FT_ListDevices = (pFT_ListDevices) GetFunction(hdll,"FT_ListDevices");
	DLL_FT_SetTimeouts = (pFT_SetTimeouts) GetFunction(hdll,"FT_SetTimeouts");

	// zero handles
	int cnt;
	for(cnt = 0; cnt < MAX_APS_DEVICES; cnt++) {
		usb_handles[cnt] = 0;
		waveforms[cnt] = 0;
	}

	return 0;
}

EXPORT int APS_Open(int device, int force)
/******************************************************************
 *
 * Function Name : APS_Open()
 *
 * Description : Opens FT2D devices
 *
 * Inputs : device - integer ID number starting at 0
 *
 * Returns : 0 on success FTD2 error code on failure
 *
 * Error Conditions :
 *
 * Unit Tested on:
 *
 * Unit Tested by:
 *
 ********************************************************************/

/*!
 * \brief Open APS Device
 * \param int device FTDI device index starting at 0
 */

{
	// Global FTDI Device usb_handle, must be set by call to FT_Open()
	FT_STATUS status;

	if (device > MAX_APS_DEVICES) {
		return -1;
	}

	// If the ftd2xx dll has not been loaded, loadit.
	if (!hdll) {
		if (APS_Init() != 0) {
			return -2;
		};
	}

	// allow a forced reopen of the device
	if (usb_handles[device] != 0 && force) {
		return 0;
	}

	usb_handles[device] = 0;
	status = DLL_FT_Open(device, &(usb_handles[device]));

	if (status == FT_OK) {
#ifdef DEBUG
		dlog(DEBUG_INFO,"FTD2 Open\n");
#endif
		status = DLL_FT_SetTimeouts(device2handle(device), APS_READTIMEOUT,APS_WRITETIMEOUT);
		if (status == FT_OK) {
			dlog(DEBUG_VERBOSE,"Set Timeouts OK\n");
		} else {
			dlog(DEBUG_INFO,"Set Timeouts Failed %i\n", status);
		}

	} else {
#ifdef DEBUG
		dlog(DEBUG_VERBOSE,"FTD_Open returned: %i\n", status);
#endif
		return -status;
	}

	return 0;
}

EXPORT int APS_OpenByID(int device)
/******************************************************************
 *
 * Function Name : APS_OpenByID()
 *
 * Description : Opens FT2D devices
 *
 * Inputs : device - integer ID number starting at 0
 *
 * Returns : 0 on success FTD2 error code on failure
 *
 * Error Conditions :
 *
 * Unit Tested on:
 *
 * Unit Tested by:
 *
 ********************************************************************/

/*!
 * \brief Open APS Device
 * \param int device FTDI device index starting at 0
 */

{
	// Global FTDI Device usb_handle, must be set by call to FT_Open()
	FT_STATUS status;

	int cnt, numdevices, found;
	char * serial;
	char testSerial[64];

	// If the ftd2xx dll has not been loaded, loadit.
	if (!hdll) {
		if (APS_Init() != 0) {
			return -2;
		};
	}

	serial = deviceSerials[device];
	numdevices = APS_NumDevices();

	if (device > numdevices) {
		return -1;
	}

	found = 0;
	for (cnt = 0; cnt < numdevices; cnt++) {
		DLL_FT_ListDevices(cnt, testSerial,FT_LIST_BY_INDEX|FT_OPEN_BY_SERIAL_NUMBER);
		if (strncmp(testSerial, serial, strlen(serial)) == 0) {
			found = 1;
			break;
		}
	}

	if (!found) {
		dlog(DEBUG_INFO,"Could not locate device ID: %i Serial %s\n",device, serial );
		printf("%i\n",status);
		return -1;
	}

	dlog(DEBUG_INFO,"Found device ID: %i Serial %s @ Index %i\n",device, serial,cnt );

	status = APS_Open(cnt, 0);
	if (status == FT_OK) {
		return cnt;
	} else {
		return status;
	}
}

EXPORT int APS_OpenBySerialNum(char * serialNum)
/******************************************************************
 *
 * Function Name : APS_OpenBySerialNum()
 *
 * Description : Opens FT2D devices
 *
 * Inputs : device - integer ID number starting at 0
 *
 * Returns : 0 on success FTD2 error code on failure
 *
 * Error Conditions :
 *
 * Unit Tested on:
 *
 * Unit Tested by:
 *
 ********************************************************************/

{
	// Global FTDI Device usb_handle, must be set by call to FT_Open()
	FT_STATUS status;

	int cnt, numdevices, found;

	char testSerial[64];

	// If the ftd2xx dll has not been loaded, loadit.
	if (!hdll) {
		if (APS_Init() != 0) {
			return -2;
		};
	}

	numdevices = APS_NumDevices();

	found = 0;
	for (cnt = 0; cnt < numdevices; cnt++) {
		DLL_FT_ListDevices(cnt, testSerial,FT_LIST_BY_INDEX|FT_OPEN_BY_SERIAL_NUMBER);
		if (strncmp(testSerial, serialNum, strlen(serialNum)) == 0) {
			found = 1;
			break;
		}
	}

	if (!found) {
		dlog(DEBUG_INFO,"Could not locate device ID: Serial %s\n", serialNum );
		printf("%i\n",status);
		return -1;
	}

	dlog(DEBUG_INFO,"Found device ID: Serial %s @ Index %i\n", serialNum,cnt );

	status = APS_Open(cnt, 0);
	if (status == FT_OK) {
		return cnt;
	} else {
		return -status;
	}
}


EXPORT int APS_NumDevices()
/********************************************************************
 *
 * Function Name : APS_NumDevices()
 *
 * Description : Gets number of FTD2 devices available from the FTD2 library
 *
 * Inputs : None
 *
 * Returns : Number of devices
 *
 * Error Conditions :
 *
 * Unit Tested on:
 *
 * Unit Tested by:
 *
 ********************************************************************/
{
	if (!hdll) {
		if (APS_Init() != 0) {
			return -1;
		};
	}

	int numdevices;
	DLL_FT_ListDevices(&numdevices, NULL, FT_LIST_NUMBER_ONLY);
	return numdevices;
}

EXPORT int APS_PrintSerialNumbers()
{
	if (!hdll) {
		if (APS_Init() != 0) {
			return -1;
		}
	}

	int numdevices,cnt;
	char serial[64];
	numdevices = APS_NumDevices();
	printf("Found %i devices\n", numdevices);
	for (cnt = 0; cnt < numdevices; cnt++) {
		memset(serial, 0, 64 * sizeof(char));
		DLL_FT_ListDevices(cnt, serial,FT_LIST_BY_INDEX|FT_OPEN_BY_SERIAL_NUMBER);
		printf("Device %i Serial Num %s\n", cnt,serial );
	}
	//
	return 0;
}

EXPORT int APS_GetSerialNum(int device, char * buffer, int bufLen)
/*
* Return the serial number associated with a particular deviceID num
*/
{
	
	//Check we aren't asking for something beyond the number of devices
	if (device > APS_NumDevices()) {
		printf("Got here!\n");
		return -1;
	}
	
	//Initialize a temporary buffer of the right length and zero it out
	char tmpSerial[64];
	memset(tmpSerial, 0, 64 * sizeof(char));
	//Use the FTDI driver to get the serial number into the temporary buffer
	DLL_FT_ListDevices(device, tmpSerial, FT_LIST_BY_INDEX|FT_OPEN_BY_SERIAL_NUMBER);
	//Copy over the memory given of 64 bytes worth
	int copyBytes;
	copyBytes = (bufLen > 64) ? 64 : bufLen; 
	memcpy(buffer, tmpSerial, copyBytes);
	return 0;
}


EXPORT int APS_Close(int device)
/********************************************************************
 *
 * Function Name : APS_Close()
 *
 * Description : Closes FTD2 device
 *
 * Inputs : None
 *
 * Returns : 0
 *
 * Error Conditions :
 *
 * Unit Tested on:
 *
 * Unit Tested by:
 *
 ********************************************************************/
{
	if (!hdll) {
		if (APS_Init() != 0) {
			return -1;
		};
	}
	// Closes handle to FTD2 device

	dlog(DEBUG_INFO,"Closing: %i Handle %x\n", device, usb_handles[device]);

	DLL_FT_Close(usb_handles[device]);
	usb_handles[device] = 0;

	//WF_Destroy(waveforms[device]);

	return 0;
}



int APS_ReadReg
(
		int device,
		ULONG Command, // APS_FPGA_IO, APS_FPGA_ADDR, APS_CONF_DATA, APS_CONF_STAT, or APS_STATUS_CTRL
		ULONG Size,    // Transfer size, 0, 1, 2, or 3 for 1, 2, 4, or 8 bytes.  Ignored for Config cycles
		ULONG Sel,     // Select bits to drive FPGA selects for I/O or Config
		UCHAR *Data    // Buffer for read data
)
/********************************************************************
 *
 * Function Name : APS_ReadReg()
 *
 * Description : Read data from the register specified by the Command.
 *                         The number of bytes depends on the Size parameter
 *                         The values for the Command parameter are in aps.h
 *
 * Inputs :
 *               Command - APS_FPGA_IO, APS_FPGA_ADDR, APS_CONF_DATA, APS_CONF_STAT, or APS_STATUS_CTRL
 *              Size          - Transfer size, 0, 1, 2, or 3 for 1, 2, 4, or 8 bytes.  Ignored for Config cycles
 *              Sel,           - Select bits to drive FPGA selects for I/O or Config (1,2, or 3)
 *              *Data        - Buffer for read data
 *
 * Returns : 0 on success <0 on failure
 *
 * Error Conditions :
 *
 * Unit Tested on:
 *
 * Unit Tested by:
 *
 ********************************************************************/
{
	UCHAR Packet[256];
	ULONG Length,
	BytesRead,
	BytesWritten;
	FT_HANDLE usb_handle;
	FT_STATUS status;

	int repeats = 0;
	const int max_repeats = 5;

	usb_handle = device2handle(device);
	if (!usb_handle)
		return -1;

	switch(Command)
	{
	case APS_FPGA_IO:
		Length = 1<<Size;
		break;
	case APS_FPGA_ADDR:
	case APS_CONF_STAT:
	case APS_STATUS_CTRL:
		Length = 1;
		break;
	default:
		// Illegal command type
		return(0);
	}

	// Start all packets with a APS Command Byte with the R/W = 1 for read
	Packet[0] = 0x80 | Command | (Sel<<2) | Size;

	// Send the read command with the number of bytes specified in the Command Byte
	for (repeats = 0; repeats < max_repeats; repeats++) {
		if (repeats > 0) dlog(DEBUG_VERBOSE2,"Retry USB Write %i\n", repeats);
		status = DLL_FT_Write(usb_handle, Packet, 1, &BytesWritten);

		if (status != FT_OK || BytesWritten != 1) {
			dlog(DEBUG_VERBOSE2,"APS_ReadReg: Error writing to USB status %i bytes written %i / 1 repeats %i\n",
					status,BytesWritten, repeats);
			continue;
		}
		usleep(10);
		status = DLL_FT_Read(usb_handle, Data, Length, &BytesRead);
		if (repeats > 0) dlog(DEBUG_VERBOSE2,"Retry USB Read %i\n", repeats);
		if (status == FT_OK && BytesRead == Length) break;
	}
	if (status != FT_OK || BytesRead != Length) {
		dlog(DEBUG_VERBOSE,"APS_ReadReg: Error reading from USB! status %i bytes read %i / %i repeats = %i\n", status,BytesRead,Length,repeats);
	}



	return(BytesRead);
}

int APS_WriteReg
(
		int device,
		ULONG Command, // APS_FPGA_IO, APS_FPGA_ADDR, APS_CONF_DATA, APS_CONF_STAT, or APS_STATUS_CTRL
		ULONG Size,    // Transfer size, 0, 1, 2, or 3 for 1, 2, 4, or 8 bytes.  Ignored for Config cycles
		ULONG Sel,     // Select bits to drive FPGA selects for I/O or Config
		UCHAR *Data    // Data bytes to be written.  Must match length/transfer type
)
/********************************************************************
 *
 * Function Name : APS_WriteReg()
 * Description :
 *                       Write data to the register specified by the Command.
 *                       The data is written in the size specified.
 *                       Configuration data writes are padded to be a multiple of the required 61 byte data length.
 *                       Note that you can use CONF_DATA cycles to write data to the post config FPGA as well.
 *                       It will just run bursts of 61 bytes.  This is the fastest way to transfer large blocks of data.
 *
 * Inputs :
 *                  Command - APS_FPGA_IO, APS_FPGA_ADDR, APS_CONF_DATA, APS_CONF_STAT, or APS_STATUS_CTRL
 *                  Size         - Transfer size, 0, 1, 2, or 3 for 1, 2, 4, or 8 bytes.  Ignored for Config cycles
 *                  Sel - Select bits to drive FPGA selects for I/O or Config
 *                  *Data  - Data bytes to be written.  Must match length/transfer type
 *
 * Returns : 0 on success <0 on failure
 *
 * Error Conditions :
 *
 * Unit Tested on:
 *
 * Unit Tested by:
 *
 ********************************************************************/
{
	UCHAR Packet[256];
	ULONG i,
	Length,
	BytesWritten;
	FT_HANDLE usb_handle;
	FT_STATUS status;

	int repeats;
	const int max_repeats = 5;
	usb_handle = device2handle(device);
	if (!usb_handle)
		return -1;

	switch(Command)
	{
	case APS_FPGA_IO:
		Length = 1<<Size;
		break;
	case APS_CONF_DATA:
		Length = 61;
		break;
	case APS_FPGA_ADDR:
	case APS_CONF_STAT:
	case APS_STATUS_CTRL:
		Length = 1;
		break;
	default:
		// Illegal command type
		return(0);
	}

	// Start all packets with a APS Command Byte with the R/W = 0 for write
	Packet[0] = Command | (Sel<<2) | Size;

	// Copy data bytes to output packet
	for(i = 0; i < Length; i++)
		Packet[i+1] = Data[i];

	for (repeats = 0; repeats < max_repeats; repeats++) {
		if (repeats > 0) dlog(DEBUG_VERBOSE2,"Repeat Write %i\n", repeats);
		status = DLL_FT_Write(usb_handle, Packet, Length+1, &BytesWritten);
		if (status == FT_OK) break;

	}

	if (status != FT_OK || BytesWritten != Length+1) {
		dlog(DEBUG_VERBOSE,"APS_WriteReg: Error writing to USB status %i bytes written %i / %i repeats %i\n",
				status,BytesWritten, Length+1, repeats);
	}



	// Adjust for command byte when returning bytes written
	return(BytesWritten - 1);
}

int APS_WriteBlock
(
		int device,
		ULONG Size,    // Transfer size bytes.
		UCHAR *Data    // Data bytes to be written.  Must match length/transfer type
)
/********************************************************************
 *
 * Function Name : APS_WriteReg()
 * Description :
 *                Write large block of data to FPGA. Assumes that the data has been preformatted for FPGAs.
 *
 * Inputs :
 *                  Size  - Number of Bytes
 *                  *Data  - Data bytes to be written.  Must match length/transfer type
 *
 * Returns : 0 on success <0 on failure
 *
 * Error Conditions :
 *
 * Unit Tested on:
 *
 * Unit Tested by:
 *
 ********************************************************************/
{
	ULONG BytesWritten;
	FT_HANDLE usb_handle;

	usb_handle = device2handle(device);
	if (!usb_handle)
		return -1;

	if(usb_handle)
		DLL_FT_Write(usb_handle, Data, Size, &BytesWritten);
	else
		return(0);

	// Adjust for command byte when returning bytes written
	return(BytesWritten);
}

int APS_WriteSPI
(
		int device,
		ULONG Command,   // APS_DAC_SPI, APS_PLL_SPI, or APS_VCXO_SPI
		ULONG Address,   // SPI register address.  Ignored for VCXO since address embedded in the data
		UCHAR *Data      // Data bytes to be written.  1 for DAC, 1 for PLL, or 4 for VCXO.  LS Byte first.
)
/********************************************************************
 *
 * Function Name : APS_WriteSPI()
 * Description :
 *      Write data to the selected chip via SPI.  The length of the data depends on the chip.
 *      The DAC requires 2 bytes, the PLL requires 3 bytes, and the VCXO requires 4 bytes.
 *      The format of the data bytes can be found in the data sheets for the chips.
 *      Note that the "data" defines an SPI command with R/W bit, a register address, and any write data.
 *      The values for the Command parameter are in aps.h
 *      Returns the number of bytes written
 *
 *      DAC Data Format for first byte: R/W N1 N0 A4 A3 A2 A1 A0
 *      RW = 0 for write, N = 00 for 1 byte transfer.  A = 5-bit register address
 *      Note that DAC channel specified by Address<6:5>, since only Address<4:0> select DAC registers.
 *
 *      PLL Data format for first two bytes: R/W W1 W0 A12 A11 A10 A9 A8 A7 A6 A5 A4 A3 A2 A1 A0
 *      RW = 0 for write, W = 00 for 1 byte transfer.  A = 13-bit register address
 *
 *      VCXO data format: 32-bit value, with the address embedded in D<1:0>.  Bytes stored MS byte first.
 *      Note that this is not the order of the bytes in a 32 bit integer on little-endian CPUs
 *
 * Inputs :
 *                Command -  APS_DAC_SPI, APS_PLL_SPI, or APS_VCXO_SPI
 *               Address    -  SPI register address.  Ignored for VCXO since address embedded in the data
 *                *Data      -  Data bytes to be written.  1 for DAC, 1 for PLL, or 4 for VCXO.  LS Byte first.
 *
 * Returns : 0 on success <0 on failure
 *
 * Error Conditions :
 *
 * Unit Tested on:
 *
 * Unit Tested by:
 *
 ********************************************************************/
{
	FT_STATUS status;
	UCHAR Buf[256],
	Packet[256];
	ULONG i,
	out,
	Length,
	BytesWritten;
	FT_HANDLE usb_handle;

	usb_handle = device2handle(device);
	if (!usb_handle)
		return -1;

	switch(Command & APS_CMD)
	{
	case APS_DAC_SPI:
		Buf[0] = Address & 0x1F;  // R/W = 0 for write, N = 00 for 1 Byte, A<4:0> = Address
		Buf[1] = Data[0];
		Command |= ((Address & 0x60)>>3);  // Take bits above register address as DAC channel select
		Length = 16;  // Number of bits to serialize
		break;
	case APS_PLL_SPI:
		Buf[0] = (Address>>8) & 0x1F;  // R/W = 0 for write, W = 00 for 1 Byte, A<12:8>
		Buf[1] = Address & 0xFF;  // A<7:0>
		Buf[2] = Data[0];
		Length = 24;  // Number of bits to serialize
		break;
	case APS_VCXO_SPI:
		// Copy out data bytes to be in MS Byte first order
		Buf[0] = Data[0];
		Buf[1] = Data[1];
		Buf[2] = Data[2];
		Buf[3] = Data[3];
		Length = 32;  // Number of bits to serialize
		break;
	default:
		// Ignore unsupported commands
		return(0);
	}

	// Start all packets with a APS Command Byte with the R/W= 0 for write
	// Note that command byte from DAC has the SEL bits for the desired DAC set
	Packet[0] = Command;

	// Serialize the data into bit 0 of the packet bytes
	for(i = 0, out = 1; i < Length; i++, out++)
		Packet[out] = (Buf[i/8]>>(7-(i%8))) & 1;

	if(usb_handle)
		status = DLL_FT_Write(usb_handle, Packet, Length+1, &BytesWritten);
	else
		return(0);

	return BytesWritten;
}




int APS_ReadSPI
(
		int device,
		ULONG Command,   // APS_DAC_SPI, APS_PLL_SPI, or APS_VCXO_SPI
		ULONG Address,   // SPI register address.  Ignored for VCXO since address embedded in the data
		UCHAR *Data      // Destination for the returned data byte.  Only single byte reads supported.
)
/********************************************************************
 *
 * Function Name : APS_ReadSPI
 *
 * Description :
 *   Read a byte from the specified SPI device
 *  Note that DAC channel specified by Address<6:5>, since only Address<4:0> select DAC registers.
 *
 * Inputs :
 *
 * Returns :
 *
 * Error Conditions :
 *
 * Unit Tested on:
 *
 * Unit Tested by:
 *
 ********************************************************************/
{
	UCHAR Buf[256],
	Packet[256];
	ULONG i,
	out,
	Length,
	BytesRead,
	BytesWritten;
	FT_HANDLE usb_handle;

	usb_handle = device2handle(device);
	if (!usb_handle)
		return -1;

	// Create a 1 byte read command at the specified address of the specified device
	// Note that the VCXO is not readable
	switch(Command & APS_CMD)
	{
	case APS_DAC_SPI:
		Buf[0] = 0x80 | (Address & 0x1F);  // R/W = 1 for read, N = 00 for 1 Byte, A<4:0> = Address
		Buf[1] = Data[0];
		Command |= ((Address & 0x60)>>3);  // Take bits above register address as DAC channel select
		Length = 16;  // Number of bits to serialize = 2 bytes * 8 bits/byte
		break;
	case APS_PLL_SPI:
		Buf[0] = 0x80 | ((Address>>8) & 0x1F);  // R/W = 1 for read, W = 00 for 1 Byte, A<12:8>
		Buf[1] = Address & 0xFF;  // A<7:0>
		Buf[2] = Data[0];
		Length = 24;  // Number of bits to serialize = 3 bytes * 8 bits/byte
		break;
	default:
		// Ignore unsupported commands
		return(0);
	}

	// Start all packets with a APS Command Byte with the R/W = 0 for write
	// Note that command byte from DAC has the SEL bits for the desired DAC set
	Packet[0] = Command;

	// Serialize the data into bit 0 of the packet bytes
	for(i = 0, out = 1; i < Length; i++, out++)
		Packet[out] = (Buf[i/8]>>(7-(i%8))) & 1;

	if(usb_handle)
	{
		// Write the SPI command.  This stores the last 8 SPI read bits in the I/O FPGA SerData register
		DLL_FT_Write(usb_handle, Packet, Length+1, &BytesWritten);

		Packet[0] |= 0x80;  // Convert the SPI write Command Byte into an SPI read Command Byte

		// Queue a read for the SerData from the previous SPI read command
		DLL_FT_Write(usb_handle, Packet, 1, &BytesWritten);

		// Read the one byte of serial data from the SerData register
		DLL_FT_Read(usb_handle, Data, 1, &BytesRead);

		return(BytesRead);
	}
	else
		return(0);

	return(BytesRead);
}


static const UCHAR BitReverse[256] =
{
		0x00, 0x80, 0x40, 0xC0, 0x20, 0xA0, 0x60, 0xE0, 0x10, 0x90, 0x50, 0xD0, 0x30, 0xB0, 0x70, 0xF0,
		0x08, 0x88, 0x48, 0xC8, 0x28, 0xA8, 0x68, 0xE8, 0x18, 0x98, 0x58, 0xD8, 0x38, 0xB8, 0x78, 0xF8,
		0x04, 0x84, 0x44, 0xC4, 0x24, 0xA4, 0x64, 0xE4, 0x14, 0x94, 0x54, 0xD4, 0x34, 0xB4, 0x74, 0xF4,
		0x0C, 0x8C, 0x4C, 0xCC, 0x2C, 0xAC, 0x6C, 0xEC, 0x1C, 0x9C, 0x5C, 0xDC, 0x3C, 0xBC, 0x7C, 0xFC,
		0x02, 0x82, 0x42, 0xC2, 0x22, 0xA2, 0x62, 0xE2, 0x12, 0x92, 0x52, 0xD2, 0x32, 0xB2, 0x72, 0xF2,
		0x0A, 0x8A, 0x4A, 0xCA, 0x2A, 0xAA, 0x6A, 0xEA, 0x1A, 0x9A, 0x5A, 0xDA, 0x3A, 0xBA, 0x7A, 0xFA,
		0x06, 0x86, 0x46, 0xC6, 0x26, 0xA6, 0x66, 0xE6, 0x16, 0x96, 0x56, 0xD6, 0x36, 0xB6, 0x76, 0xF6,
		0x0E, 0x8E, 0x4E, 0xCE, 0x2E, 0xAE, 0x6E, 0xEE, 0x1E, 0x9E, 0x5E, 0xDE, 0x3E, 0xBE, 0x7E, 0xFE,
		0x01, 0x81, 0x41, 0xC1, 0x21, 0xA1, 0x61, 0xE1, 0x11, 0x91, 0x51, 0xD1, 0x31, 0xB1, 0x71, 0xF1,
		0x09, 0x89, 0x49, 0xC9, 0x29, 0xA9, 0x69, 0xE9, 0x19, 0x99, 0x59, 0xD9, 0x39, 0xB9, 0x79, 0xF9,
		0x05, 0x85, 0x45, 0xC5, 0x25, 0xA5, 0x65, 0xE5, 0x15, 0x95, 0x55, 0xD5, 0x35, 0xB5, 0x75, 0xF5,
		0x0D, 0x8D, 0x4D, 0xCD, 0x2D, 0xAD, 0x6D, 0xED, 0x1D, 0x9D, 0x5D, 0xDD, 0x3D, 0xBD, 0x7D, 0xFD,
		0x03, 0x83, 0x43, 0xC3, 0x23, 0xA3, 0x63, 0xE3, 0x13, 0x93, 0x53, 0xD3, 0x33, 0xB3, 0x73, 0xF3,
		0x0B, 0x8B, 0x4B, 0xCB, 0x2B, 0xAB, 0x6B, 0xEB, 0x1B, 0x9B, 0x5B, 0xDB, 0x3B, 0xBB, 0x7B, 0xFB,
		0x07, 0x87, 0x47, 0xC7, 0x27, 0xA7, 0x67, 0xE7, 0x17, 0x97, 0x57, 0xD7, 0x37, 0xB7, 0x77, 0xF7,
		0x0F, 0x8F, 0x4F, 0xCF, 0x2F, 0xAF, 0x6F, 0xEF, 0x1F, 0x9F, 0x5F, 0xDF, 0x3F, 0xBF, 0x7F, 0xFF
};

// Program the FPGA(s) specified by the Sel parameter with the data stream
// passed in the Data array.  A total of ByteCount bytes are sent.
//

EXPORT int APS_ProgramFpga(int device, BYTE *Data, int ByteCount, int Sel, int expectedVersion)
{
	/********************************************************************
	 *
	 * Function Name : APS_ProgramFpga
	 *
	 * Description :
	 *
	 * Inputs :
	 *
	 * Returns :
	 *
	 * Error Conditions :
	 *
	 * Unit Tested on:
	 *
	 * Unit Tested by:
	 *
	 ********************************************************************/

	UCHAR PgmMask,
	InitMask,
	DoneMask,
	RstMask,
	ReadByte,
	WriteByte,
	LastBuf[64];
	int i, j, version;

	// To configure the FPGAs, you initialize them, send the byte stream, and
	// then wait for the DONE flag to be asserted.

	// Note that FPGAs can be programmed with the same image by setting Sel = 3.
	// However, the pinouts of the connections to the DAC are different for the two
	// FPGAs.  Unless there is a post-configuration modification of the DAC output
	// mapping, a different image must be written to each FPGA.

	// Create bit masks matching Config Status Register bits for the active FPGAs ...


#ifdef OUTPUTBITFILE
	test = fopen("data.out","wt");
#endif

	dlog(DEBUG_INFO, "Starting ProgramFPGA Device: %i Sel: %i ... \n", device, Sel);

	// Create masks
	PgmMask = 0;
	if(Sel & 1) PgmMask |= APS_PGM01_BIT;
	if(Sel & 2) PgmMask |= APS_PGM23_BIT;

	InitMask = 0;
	if(Sel & 1) InitMask |= APS_INIT01_BIT;
	if(Sel & 2) InitMask |= APS_INIT23_BIT;

	DoneMask = 0;
	if(Sel & 1) DoneMask |= APS_DONE01_BIT;
	if(Sel & 2) DoneMask |= APS_DONE23_BIT;

	RstMask = 0;
	if(Sel & 1) RstMask |= APS_FRST01_BIT;
	if(Sel & 2) RstMask |= APS_FRST23_BIT;

	const int maxAttemptCnt = 3; // max retries is something fails along the way
	int numBytesProgrammed;

	int ok = 0; // flag to indicate test worked

	/*
	 * Programming order:
	 *
	 * 1) clear PGM and RESET
	 * 2) issue status READ and verify init bits are low
	 * 3) set PGM and RESET high
	 * 4) verify init bits are HIGH
	 * 5) write program
	 * 6) test done bits
	 */

	for(i = 0, ok = 0; i < maxAttemptCnt && ok == 0; i++) {
		dlog(DEBUG_VERBOSE, "Attempt: %i \n", i);
		// Read the Status to get state of RESETN for unused channel
		if(APS_ReadReg(device, APS_CONF_STAT, 1, 0, &ReadByte) != 1) return(-1);
		dlog(DEBUG_VERBOSE, "Read 1: %02X \n", ReadByte);

		// Clear Program and Reset Masks
		WriteByte = ~PgmMask & ~RstMask & 0xF;
		dlog(DEBUG_VERBOSE, "Write 1: %02X \n", WriteByte);
		if(APS_WriteReg(device,  APS_CONF_STAT, 1, 0, &WriteByte) != 1)	return(-2);

		// Read the Status to see that INITN is asserted in response to PROGRAMN
		if(APS_ReadReg(device, APS_CONF_STAT, 1, 0, &ReadByte) != 1) return(-3);
		dlog(DEBUG_VERBOSE, "Read 2: %02X \n", ReadByte);

		// verify Init bits are cleared
		if((ReadByte & InitMask) == 0) ok = 1;
	}

	if (!ok) return -4;

	for(i = 0, ok = 0; i < maxAttemptCnt && ok == 0; i++) {
		dlog(DEBUG_VERBOSE, "Attempt: %i \n", i+1);
		// Set Program and Reset Bits
		WriteByte = (PgmMask | RstMask) & 0xF;
		dlog(DEBUG_VERBOSE, "Write 2: %02X \n", WriteByte);
		if(APS_WriteReg(device, APS_CONF_STAT, 1, 0, &WriteByte) != 1)	return(-5);

		// sleep to allow init to take place
		// if the sleep is left out the next test might fail
		usleep(1000);

		// Read the Status to see that INITN is deasserted in response to PROGRAMN deassertion
		if(APS_ReadReg(device, APS_CONF_STAT, 1, 0, &ReadByte) != 1) return(-6);
		dlog(DEBUG_VERBOSE, "Read 3: %02X \n", ReadByte);

		// verify Init Mask is high
		if((ReadByte & InitMask) == InitMask) ok = 1;
	}

	if (!ok) return -7;

	// Bit reverse the data
	for(i = 0; i < ByteCount; i++)
		Data[i] = BitReverse[Data[i]];

#define BLOCKSIZE 61

	//original loading code (did not use driver to buffer memory) (took 7.25 secs to load)
	// current must use original code as buffered version does not appear to work with
	// hardware (may be a hardware limitation)

	// At this point, the selected FPGA is ready to receive configuration bytes.
	// Write out all of the bytes in groups of 61 bytes, since that is the most that
	// can be written in a single USB packet.

	for(i = 0; i < ByteCount; i += BLOCKSIZE)
		// Write a full buffer if not at the end of the input data

		if(i + BLOCKSIZE < ByteCount) {
#ifdef OUTPUTBITFILE
			for(cnt = 0; cnt < BLOCKSIZE; cnt++)
				fprintf(test,"%031 ", Data[i+cnt]);
			fprintf(test,"\n");
#endif
			if(APS_WriteReg(device, APS_CONF_DATA, 0, Sel, Data+i) != BLOCKSIZE)  // Defaults to 61 bytes for CONF_DATA
				return(-8);
		} else {

			// Create a zero padded final buffer
			for(j = 0; j < BLOCKSIZE; j++)
				if(j + i < ByteCount)
					LastBuf[j] = Data[i+j];
				else
					LastBuf[j] = 0;

#ifdef OUTPUTBITFILE
			for(cnt = 0; cnt < BLOCKSIZE; cnt++)
				fprintf(test,"%03i ", LastBuf[cnt]);
#endif

			// Write out the last buffer
			if(APS_WriteReg(device, APS_CONF_DATA, 0, Sel, LastBuf) != BLOCKSIZE)  // Defaults to 61 bytes for CONF_DATA
				return(-9);
		}

#ifdef OUTPUTBITFILE
	fprintf(test,"\n");
	fclose(test);
#endif

	numBytesProgrammed = i + j;

	// check done bits
	for(i = 0, ok = 0; i < maxAttemptCnt && !ok; i++) {
		if(APS_ReadReg(device, APS_CONF_STAT, 1, 0, &ReadByte) != 1) return(-3);
		dlog(DEBUG_VERBOSE, "Read 4: %02X (looking for %02X HIGH)\n", ReadByte, DoneMask);
		if ((ReadByte & DoneMask) == DoneMask) ok = 1;
		usleep(1000); // if done has not set wait a bit
	}

	//if (!ok) return -10;
	if (!ok) {
		dlog(DEBUG_INFO, "WARNING: FPGAs did not set DONE bits after programming, attempting to continue.\n");
	}

	dlog(DEBUG_VERBOSE, "Done programming\n");
	
	// wait 10ms for FPGA to deal with the bitfile data
	usleep(10000);

	// Read Bit File Version
	for (i = 0, ok = 0; i < maxAttemptCnt && !ok; i++) {
		if (Sel == 3) {
			version = APS_ReadBitFileVersion(device);
		} else {
			version = APS_ReadFpgaBitFileVersion(device, Sel);
		}
		if (version == expectedVersion) ok = 1;
		usleep(1000); // if doesn't match, wait a bit and try again
	}
	
	if (!ok) return -11;

	// Return the number of data bytes written
	return numBytesProgrammed;
}



// Setup modified for 300 MHz FPGA clock rate
APS_SPI_REC PllSetup[] =
{
		0x0,  0x99,  // Use SDO, Long instruction mode
		0x10, 0x7C,  // Enable PLL , set charge pump to 4.8ma
		0x11, 0x5,   // Set reference divider R to 5 to divide 125 MHz reference to 25 MHz
		0x14, 0x06,  // Set B counter to 6
		0x16, 0x5,   // Set P prescaler to 16 and enable B counter (N = P*B = 96 to divide 2400 MHz to 25 MHz)
		0x17, 0x4,   // Selects readback of N divider on STATUS bit in Status/Control register
		0x18, 0x60,  // Calibrate VCO with 2 divider, set lock detect count to 255, set high range
		0x1A, 0x2D,  // Selects readback of PLL Lock status on LOCK bit in Status/Control register
		0x1C, 0x7,   // Enable differential reference, enable REF1/REF2 power, disable reference switching
		0xF0, 0x00,  // Enable un-inverted 400mv clock on OUT0
		0xF1, 0x00,  // Enable un-inverted 400mv clock on OUT1
		0xF2, 0x00,  // Enable un-inverted 400mv clock on OUT2
		0xF3, 0x00,  // Enable un-inverted 400mv clock on OUT3
		0xF4, 0x00,  // Enable un-inverted 400mv clock on OUT4
		0xF5, 0x00,  // Enable un-inverted 400mv clock on OUT5
		0x190, 0x00, //	No division on channel 0
		0x191, 0x80, //	Bypass 0 divider
		0x193, 0x11, //	(2 high, 2 low = 1.2 GHz / 4 = 300 MHz = Reference 300 MHz)
		0x196, 0x00, //	No division on channel 2
		0x197, 0x80, //   Bypass 2 divider
		0x1E0, 0x0,  // Set VCO post divide to 2
		0x1E1, 0x2,  // Select VCO as clock source for VCO divider
		0x232, 0x1,  // Set bit 0 to 1 to simultaneously update all registers with pending writes.
		0x18, 0x71,  // Initiate Calibration.  Must be followed by Update Registers Command
		0x232, 0x1,   // Set bit 0 to 1 to simultaneously update all registers with pending writes.
		0x18, 0x70,  // Clear calibration flag so that next set generates 0 to 1.
		0x232, 0x1   // Set bit 0 to 1 to simultaneously update all registers with pending writes.
};

// Write the PLL setup
EXPORT int APS_SetupPLL(int device)
{

	int i;
	dlog(DEBUG_INFO,"Setting up PLL\n");

	// Disable DDRs
	int ddr_mask = CSRMSK_ENVDDR_ELL | CSRMSK_PHSDDR_ELL;
	APS_ClearBit(device, 3, FPGA_OFF_CSR, ddr_mask);

	for(i = 0; i <  sizeof(PllSetup)/sizeof(APS_SPI_REC); i++) {
		APS_WriteSPI(device, APS_PLL_SPI, PllSetup[i].Address, &PllSetup[i].Data);
	}

	// Enable DDRs
	APS_SetBit(device, 3, FPGA_OFF_CSR, ddr_mask);

	return 0;
}


APS_SPI_REC PllFinish[] =
{
		0x18, 0x71,  // Initiate Calibration.  Must be followed by Update Registers Command
		0x232, 0x1,   // Set bit 0 to 1 to simultaneously update all registers with pending writes.
		0x18, 0x70,  // Clear calibration flag so that next set generates 0 to 1.
		0x232, 0x1   // Set bit 0 to 1 to simultaneously update all registers with pending writes.
};




EXPORT int APS_SetPllFreq(int device, int dac, int freq, int testLock)
{

	static int fpgaFrequencies[2] = {1200,1200};

	ULONG pll_cycles_addr, pll_bypass_addr;
	UCHAR pll_cycles_val, pll_bypass_val;

	UCHAR WriteByte;
	int fpga;
	int sync_status;
	int numSyncChannels;

	dlog(DEBUG_INFO, "Setting PLL DAC: %i Freq: %i\n", dac, freq);

	fpga = dac2fpga(dac);
	if (fpga < 0) {
		return -1;
	}

	switch(dac) {
	case 0:
		// fall through
	case 1:
		pll_cycles_addr = FPGA1_PLL_CYCLES_ADDR;
		pll_bypass_addr = FPGA1_PLL_BYPASS_ADDR;
		break;
	case 2:
		// fall through
	case 3:
		pll_cycles_addr = FPGA2_PLL_CYCLES_ADDR;
		pll_bypass_addr = FPGA2_PLL_BYPASS_ADDR;
		break;
	default:
		return -1;
	}

	switch(freq) {
	case 40:
		pll_cycles_val = 0xEE; // 15 high / 15 low (divide by 30)
		break;
	case 50:
		pll_cycles_val = 0xBB; // 12 high / 12 low (divide by 24)
		break;
	case 100:
		pll_cycles_val = 0x55; // 6 high / 6 low (divide by 12)
		break;
	case 200:
		pll_cycles_val = 0x22; // 3 high / 3 low (divide by 6)
		break;
	case 300:
		pll_cycles_val = 0x11; // 2 high /2 low (divide by 4)
		break;
	case 600:
		pll_cycles_val = 0x00; // 1 high / 1 low (divide by 2)
		break;
	case 1200:
		pll_cycles_val = 0x00; // value ignored, set bypass below
		break;
	default:
		return -2;
	}

	// bypass divider if freq == 1200
	if (freq == 1200) {
		pll_bypass_val = 0x80;
	} else {
		pll_bypass_val = 0x00;
	}

	dlog(DEBUG_VERBOSE, "Setting PLL cycles addr: 0x%x val: 0x%x\n", pll_cycles_addr, pll_cycles_val);
	dlog(DEBUG_VERBOSE, "Setting PLL bypass addr: 0x%x val: 0x%x\n", pll_bypass_addr, pll_bypass_val);

	// fpga = 1 or 2 save frequency for later comparison to decide to use
	// 4 channel sync or 2 channel sync
	fpgaFrequencies[fpga - 1] = freq;

	// Disable DDRs
	int ddr_mask = CSRMSK_ENVDDR_ELL | CSRMSK_PHSDDR_ELL;
	APS_ClearBit(device, fpga, FPGA_OFF_CSR, ddr_mask);

	// Disable oscillator by clearing APS_STATUS_CTRL register
	WriteByte = 0;
	if(APS_WriteReg(device,APS_STATUS_CTRL, 1, 0, &WriteByte) != 1)
		return(-4);

	APS_WriteSPI(device, APS_PLL_SPI, pll_cycles_addr, &pll_cycles_val);
	APS_WriteSPI(device, APS_PLL_SPI, pll_bypass_addr, &pll_bypass_val);

	int i;
	for(i = 0; i <  sizeof(PllFinish)/sizeof(APS_SPI_REC); i++) {
		APS_WriteSPI(device, APS_PLL_SPI, PllFinish[i].Address, &PllFinish[i].Data);
	}

	// Enable Oscillator
	WriteByte = APS_OSCEN_BIT;
	if(APS_WriteReg(device, APS_STATUS_CTRL, 1, 0, &WriteByte) != 1)
		return(-4);

	// Enable DDRs
	APS_SetBit(device, fpga, FPGA_OFF_CSR, ddr_mask);

	sync_status = 0;

	if (testLock) {
		// We have reset the global oscillator, so should sync both FPGAs, but the current
		// test only works for channels running at 1.2 GHz
		numSyncChannels = (fpgaFrequencies[0] == 1200 && fpgaFrequencies[1] == 1200) ? 4 : 2;
		if (numSyncChannels == 4) {
			APS_TestPllSync(device, 0, numSyncChannels);
			sync_status = APS_TestPllSync(device, 2, numSyncChannels);
		}
		else if (fpgaFrequencies[fpga] == 1200)
			sync_status = APS_TestPllSync(device, dac, numSyncChannels);
	}

	return sync_status;
}

EXPORT int APS_GetPllFreq(int device, int dac) {
	// Poll APS PLL chip to determine current frequency

	ULONG pll_cycles_addr, pll_bypass_addr;
	UCHAR pll_cycles_val, pll_bypass_val;

	int fpga;
	int freq;

	dlog(DEBUG_VERBOSE, "Getting PLL DAC: %i\n", dac);

	fpga = dac2fpga(dac);
	if (fpga < 0) {
		return -1;
	}

	switch(dac) {
	case 0:
		// fall through
	case 1:
		pll_cycles_addr = FPGA1_PLL_CYCLES_ADDR;
		pll_bypass_addr = FPGA1_PLL_BYPASS_ADDR;
		break;
	case 2:
		// fall through
	case 3:
		pll_cycles_addr = FPGA2_PLL_CYCLES_ADDR;
		pll_bypass_addr = FPGA2_PLL_BYPASS_ADDR;
		break;
	default:
		return -1;
	}

	APS_ReadSPI(device, APS_PLL_SPI, pll_cycles_addr, &pll_cycles_val);
	APS_ReadSPI(device, APS_PLL_SPI, pll_bypass_addr, &pll_bypass_val);

	if (pll_bypass_val == 0x80 && pll_cycles_val == 0x00)
		return 1200;
	// select frequency based on pll cycles setting
	// the values here should match the reverse lookup in APS_SetPllFreq

	switch(pll_cycles_val) {
		case 0xEE: freq = 40;  break;
		case 0xBB: freq = 50;  break;
		case 0x55: freq = 100; break;
		case 0x22: freq = 200; break;
		case 0x11: freq = 300; break;
		case 0x00: freq = 600; break;
		default:
			return -2;
	}

	dlog(DEBUG_VERBOSE, "PLL DAC: %i Freq: %i\n", dac, freq);

	return freq;
}

/*
	APS_TestPllSync synchronized the phases of the DAC clocks with the following procedure:
	1) Make sure all PLLs have locked.
	2) Test for sync of 600 MHz clocks from DACs. They must be in sync with each other
    and in sync with the 300 MHz reference. If they are out of sync with each other, 
	  the 300 MHz DDR PLLs in the FPGA will come up 90 or 270 degrees out of phase.
	  This has a test signature of the global XOR bit set roughly half the time. If they
    are in sync but out of phase with the reference, then both DDR PLLs will be 90/270
    degrees out of phase with the reference (it is sufficient to test only one DDR PLL)
		- If either of these conditions exist, disable and re-enable the PLL output to one
    of the DACs connected to the FPGA. Reset the FPGA PLLs, wait for lock, then loop.
	3) Test channel 0/2 PLL against reference PLL. Reset until in phase.
	4) Test channel 1/3 PLL against reference PLL. Reset until in phase.
	5) Verify that sync worked by testing 0/2 XOR 1/3 (global phase).
 */
EXPORT int APS_TestPllSync(int device, int dac, int numSyncChannels) {

	// Test for DAC clock phase match
	int inSync, globalSync;
	int test_cnt, cnt, pll, xor_flag_cnt, xor_flag_cnt2, xor_flag_cnt3;
	int dac02_reset, dac13_reset;
	int pll_unlock;

	int fpga;
	int pll_bit;
	UINT pll_reg_value;
	UINT pll_reset_addr, pll_reset_bit, pll_enable_addr, pll_enable_addr2;

	pll_reset_addr = FPGA_PLL_RESET_ADDR;
	pll_reset_bit   = CSRMSK_PHSPLLRST_ELL | CSRMSK_ENVPLLRST_ELL;

	fpga = dac2fpga(dac);
	if (fpga < 0) {
		return -1;
	}

	dlog(DEBUG_INFO,"Running channel sync test on FPGA%i\n", fpga);

	switch(dac) {
	case 0:
		// fall through
	case 1:
		pll_enable_addr = DAC0_ENABLE_ADDR;
		pll_enable_addr2 = DAC1_ENABLE_ADDR;
		break;
	case 2:
		// fall through
	case 3:
		pll_enable_addr = DAC2_ENABLE_ADDR;
		pll_enable_addr2 = DAC3_ENABLE_ADDR;
		break;
	default:
		return -1;
	}

	// Disable DDRs
	int ddr_mask = CSRMSK_ENVDDR_ELL | CSRMSK_PHSDDR_ELL;
	APS_ClearBit(device, fpga, FPGA_OFF_CSR, ddr_mask);

	// test for PLL lock
	inSync = 0;
	for (test_cnt = 0; test_cnt < 20; test_cnt++) {
		if (APS_ReadPllStatus(device, fpga) == 0) {
			inSync = 1;
			break;
		}
		// clear PLL reset bits
		pll_reg_value = APS_ReadFPGA(device, gRegRead | pll_reset_addr, fpga);
		APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | pll_reset_addr, pll_reg_value & ~pll_reset_bit, fpga);
	}

	if (!inSync) {
		dlog(DEBUG_INFO,"Reference PLL failed to lock\n");
		return -5;
	}

	inSync = 0;
	globalSync = 0;

	int PLL_XOR_TEST[3] = {PLL_02_XOR_BIT, PLL_13_XOR_BIT,PLL_GLOBAL_XOR_BIT};
	int PLL_LOCK_TEST[3] = {PLL_02_LOCK_BIT, PLL_13_LOCK_BIT, REFERENCE_PLL_LOCK_BIT};
	int PLL_RESET[3] = {CSRMSK_ENVPLLRST_ELL, CSRMSK_PHSPLLRST_ELL, 0};
	char * pllStr;

	// start by testing for a global or channel XOR count near 50%, which indicates
	// that DAC 600 MHz clocks have come up out of phase.
	dlog(DEBUG_INFO,"Testing for DAC clock phase sync\n");
	for (test_cnt = 0; test_cnt < MAX_PHASE_TEST_CNT; test_cnt++) {
		xor_flag_cnt = 0;
		xor_flag_cnt2 = 0;
		xor_flag_cnt3 = 0;
		dac02_reset = 0;
		dac13_reset = 0;

		for(cnt = 0; cnt < 20; cnt++) {
			pll_bit = APS_ReadFPGA(device, FPGA_ADDR_SYNC_REGREAD | FPGA_OFF_VERSION, fpga);
			xor_flag_cnt += (pll_bit >> PLL_GLOBAL_XOR_BIT) & 0x1;
			xor_flag_cnt2 += (pll_bit >> PLL_02_XOR_BIT) & 0x1;
			xor_flag_cnt3 += (pll_bit >> PLL_13_XOR_BIT) & 0x1;
		}

		// due to clock skews, need to accept a range of counts as "0" and "1"
		if ( (xor_flag_cnt < 5 || xor_flag_cnt > 15) &&
				(xor_flag_cnt2 < 5 || xor_flag_cnt2 > 15) &&
				(xor_flag_cnt3 < 5 || xor_flag_cnt3 > 15) ) {
			// 300 MHz clocks on FPGA are either 0 or 180 degrees out of phase, so 600 MHz clocks
			// from DAC must be in phase. Move on.
			dlog(DEBUG_VERBOSE,"DAC clocks in phase with reference (XOR counts %i and %i and %i)\n", xor_flag_cnt, xor_flag_cnt2, xor_flag_cnt3);
			break;
		}
		else {
			// 600 MHz clocks out of phase, reset DAC clocks that are 90/270 degrees out of phase with reference
			dlog(DEBUG_VERBOSE,"DAC clocks out of phase; resetting (XOR counts %i and %i and %i)\n", xor_flag_cnt, xor_flag_cnt2, xor_flag_cnt3);
			UCHAR WriteByte = 0x2; //disable clock outputs
			if (xor_flag_cnt2 >= 5 || xor_flag_cnt2 <= 15) {
				dac02_reset = 1;
				APS_WriteSPI(device, APS_PLL_SPI, pll_enable_addr, &WriteByte);
			}
			if (xor_flag_cnt3 >= 5 || xor_flag_cnt3 <= 15) {
				dac13_reset = 1;
				APS_WriteSPI(device, APS_PLL_SPI, pll_enable_addr2, &WriteByte);
			}
			APS_UpdatePllReg(device);
			WriteByte = 0x0; // enable clock outputs
			if (dac02_reset)
				APS_WriteSPI(device, APS_PLL_SPI, pll_enable_addr, &WriteByte);
			if (dac13_reset)
				APS_WriteSPI(device, APS_PLL_SPI, pll_enable_addr2, &WriteByte);
			APS_UpdatePllReg(device);

			// reset FPGA PLLs
			pll_reg_value = APS_ReadFPGA(device, gRegRead | pll_reset_addr, fpga);
			// Write PLL with bits set
			APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | pll_reset_addr, pll_reg_value | pll_reset_bit, fpga);
			// Clear reset bits
			APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | pll_reset_addr, pll_reg_value & ~pll_reset_bit, fpga);

			// wait for lock
			inSync =  0;
			for(cnt = 0; cnt < 20; cnt++) {
				if (APS_ReadPllStatus(device, fpga) == 0) {
					inSync = 1;
					break;
				}
			}
			if (!inSync) {
				dlog(DEBUG_INFO,"PLLs did not re-sync after reset\n");
				return -7;
			}
		}
	}

	for (pll = 0; pll < 3; pll++) {

		switch (pll) {
		case 0: pllStr = "02"; break;
		case 1: pllStr = "13"; break;
		case 2: pllStr = "Global"; break;
		}

		dlog(DEBUG_INFO,"Testing channel %s\n", pllStr);
		for (test_cnt = 0; test_cnt < MAX_PHASE_TEST_CNT; test_cnt++) {
			xor_flag_cnt = 0;

			for(cnt = 0; cnt < 10; cnt++) {
				pll_bit = APS_ReadFPGA(device, FPGA_ADDR_SYNC_REGREAD | FPGA_OFF_VERSION, fpga);
				xor_flag_cnt += (pll_bit >> PLL_XOR_TEST[pll]) & 0x1;
			}

			// here we are just looking for in-phase or 180 degrees out of phase, so we accept a large
			// range around "0"
			if (xor_flag_cnt < 5) {
				globalSync = 1;
				break; // passed, move on to next channel
			} else {
				// PLLs out of sync, reset
				dlog(DEBUG_INFO,"Channel %s PLL not in sync resetting (XOR count %i)\n", pllStr, xor_flag_cnt);

				globalSync = 0;

				if (pll == 2) { // global pll compare did not sync
					dlog(DEBUG_INFO,"Error could not sync PLLs\n");
					return -6;
				}

				// Read PLL reg
				pll_reg_value = APS_ReadFPGA(device, gRegRead | pll_reset_addr, fpga);
				// Write PLL with bit set
				APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | pll_reset_addr, pll_reg_value | PLL_RESET[pll], fpga);
				// Write original value (making sure to clear the PLL reset bit)
				APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | pll_reset_addr, pll_reg_value & ~PLL_RESET[pll], fpga);

				// wait for lock
				inSync =  0;
				for(cnt = 0; cnt < 20; cnt++) {
					pll_bit = APS_ReadFPGA(device, gRegRead | FPGA_OFF_VERSION, fpga);
					pll_unlock = (pll_bit >> PLL_LOCK_TEST[pll]) & 0x1;
					if (!pll_unlock) {
						inSync = 1;
						break;
					}
				}
				if (!inSync) {
					dlog(DEBUG_INFO,"PLL %s did not re-sync after reset\n", pllStr);
					return -7;
				}
			}
		}
	}

	// Enable DDRs
	APS_SetBit(device, fpga, FPGA_OFF_CSR, ddr_mask);

	if (!globalSync) {
		dlog(DEBUG_INFO,"Warning: PLLs are not in sync\n");
		return -8;
	}
	dlog(DEBUG_INFO,"Sync test complete\n");
	return 0;
}

int APS_ReadPllStatus(int device, int fpga) {
	int pll_1_unlock, pll_2_unlock, pll_3_unlock;
	int pll_bit;

	if (fpga < 0 || fpga > 2) {
		return -1;
	}

	pll_bit = APS_ReadFPGA(device, gRegRead | FPGA_OFF_VERSION, fpga);
	pll_1_unlock = (pll_bit >> PLL_02_LOCK_BIT) & 0x1;
	pll_2_unlock = (pll_bit >> PLL_13_LOCK_BIT) & 0x1;
	pll_3_unlock = (pll_bit >> REFERENCE_PLL_LOCK_BIT) & 0x1;
	// lock bit == 1 means not-locked
	if (!pll_1_unlock && !pll_2_unlock && !pll_3_unlock) {
		//dlog(DEBUG_INFO,"PLLs locked on FPGA%i\n", fpga);
		return 0;
	}
	//return -1;
	return pll_bit;
}

void APS_UpdatePllReg(int device)
{
	APS_SPI_REC UpdateCmd = { 0x232, 0x1 };
	APS_WriteSPI(device, APS_PLL_SPI, UpdateCmd.Address, &UpdateCmd.Data);
}


// Register 00 VCXO value, MS Byte First
UCHAR Reg00Bytes[4] =
{
		0x8, 0x60, 0x0, 0x4
};

// Register 01 VCXO value, MS Byte First
UCHAR Reg01Bytes[4] =
{
		0x64, 0x91, 0x0, 0x61
};

// Write the standard VCXO setup
EXPORT int APS_SetupVCXO(int device)
{

	dlog(DEBUG_INFO, "Setting up VCX0\n");

	APS_WriteSPI(device, APS_VCXO_SPI, 0, Reg00Bytes);
	APS_WriteSPI(device, APS_VCXO_SPI, 0, Reg01Bytes);
	return 0;
}

EXPORT void APS_ReadLibraryVersion(void *buffer, int maxlen) {
	snprintf(buffer, maxlen, "Libaps $Revision - GIT $");
}

EXPORT void APS_HashPulse(unsigned short *pulse, int len, void * hashStr, int maxlen ){
	SHA1Context_t sha;
	uint8_t HASH[20];
	//freopen("libaps.log","w+", stderr);
	//dlog(DEBUG_VERBOSE,"Start sha %i len pulse str len %i\n", len, maxlen);
	sha1_init(&sha);
	sha1_update(&sha,(uint8_t*)pulse,len);
	sha1_finish(&sha,HASH);
	snprintf(hashStr,maxlen, "%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
			HASH[0],HASH[1],HASH[2],HASH[3],HASH[4],HASH[5],HASH[6],HASH[7],HASH[8],HASH[9],HASH[10],
			HASH[11],HASH[12],HASH[13],HASH[14],HASH[15],HASH[16],HASH[17],HASH[18],HASH[19]);
	//dlog(DEBUG_VERBOSE,"HASH %s\n",(char*) hashStr);
}


EXPORT int APS_SetWaveform(int device, int channel, float * data, int length) {
	waveform_t * wfArray;
	wfArray = waveforms[device];
	if (!wfArray) return -1;

	return WF_SetWaveform(wfArray, channel, data, length);
}

EXPORT int APS_SetWaveformOffset(int device, int channel, float offset) {
	waveform_t * wfArray;
	wfArray = waveforms[device];
	if (!wfArray) return -1;

	// TODO: set DAC offset value

	WF_SetOffset(wfArray,channel,offset);
	return 0;
}

EXPORT float APS_GetWaveformOffset(int device, int channel) {
	waveform_t * wfArray;
	wfArray = waveforms[device];
	if (!wfArray) return -1;
	return WF_GetOffset(wfArray,channel);
}

EXPORT int APS_SetWaveformScale(int device, int channel, float scale) {
	waveform_t * wfArray;
	wfArray = waveforms[device];
	if (!wfArray) return -1;
	WF_SetScale(wfArray,channel,scale);
	return 0;
}

EXPORT float APS_GetWaveformScale(int device, int channel){
	waveform_t * wfArray;
	wfArray = waveforms[device];
	if (!wfArray) return -1;
	return WF_GetScale(wfArray,channel);
}


EXPORT int APS_LoadStoredWaveform(int device, int channel) {
	waveform_t * wfArray;
	wfArray = waveforms[device];
	if (!wfArray) return -1;
	uint16_t *dataPtr;
	uint16_t length;

	if (!WF_GetIsLoaded(wfArray,channel)) {
		dataPtr = WF_GetDataPtr(wfArray, channel);
		length = WF_GetLength(wfArray, channel);
		APS_LoadWaveform(device, dataPtr, length, 0 ,channel - 1, 0, 0);
		WF_SetIsLoaded(wfArray,  channel,1);
	}
	return 0;
}

EXPORT int APS_SetLinkList(int device, int channel,
		unsigned short *OffsetData, unsigned short *CountData,
		unsigned short *TriggerData, unsigned short *RepeatData,
		int length, int bank) {
	// initial error checking

	waveform_t * wfArray;
	wfArray = waveforms[device];
	if (!wfArray) return -1;


	if (!OffsetData || ! CountData || !TriggerData || !RepeatData)
		return -2; // require every data type
	if (bank < 0 || bank > 1)
		return -3; // bank must be 0 or 1 (A or B)

	return WF_SetLinkList(wfArray, channel,
			OffsetData,CountData, TriggerData, RepeatData,
			length, bank);

}


