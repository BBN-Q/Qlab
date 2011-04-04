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
#include "ftd2xx.h"
#include <stdio.h>

#ifdef WIN32
	#include <windows.h>

	// Function Pointer Types
	typedef FT_STATUS WINAPI (*pFT_Open)(int,FT_HANDLE *);
	typedef FT_STATUS WINAPI (*pFT_Close)(FT_HANDLE);
	typedef FT_STATUS WINAPI (*pFT_Write)(FT_HANDLE, LPVOID, DWORD, LPDWORD);
	typedef FT_STATUS WINAPI (*pFT_Read)(FT_HANDLE, LPVOID,DWORD, LPDWORD);
	typedef FT_STATUS WINAPI (*pFT_ListDevices)();
	typedef FT_STATUS WINAPI (*pFT_SetBaudRate)(FT_HANDLE, DWORD);
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
	void *hdll;

	#define GetFunction dlsym
#endif

#ifdef WIN32
	#define LIBFILE "ftd2xx.dll"
#elif __APPLE__
	#define LIBFILE "libftd2xx.dylib"
	#include <wintypes.h>
#else
	#define LIBFILE "libftd2xx.so"
	#include <WinTypes.h>
#endif


FT_HANDLE usb_handles[MAX_APS_DEVICES];

char *dac_devices[] = APS_SERIAL_NUMS;
#define MAX_DEVICES sizeof(dac_devices) / sizeof(char *)

// global variables for function pointers
pFT_Open DLL_FT_Open;
pFT_Close DLL_FT_Close;
pFT_Write DLL_FT_Write;
pFT_Read DLL_FT_Read;
pFT_ListDevices DLL_FT_ListDevices;
pFT_SetBaudRate DLL_FT_SetBaudRate;

int gDebugLevel = DEBUG_VERBOSE;

#define DEBUG

FT_HANDLE device2handle(int device) {
	if (device > MAX_APS_DEVICES) {
		return 0;
	}
	return usb_handles[device];
}

void dlog(int level, char * fmt, ...) {
  // wrap fprintf to force a flush after every write

  if (level > gDebugLevel) return;

  va_list args;
  va_start(args,fmt);
  vfprintf(stderr, fmt,args);
  fflush(stderr);
  va_end(args);
}

EXPORT int APS_SetDebugLevel(int level) {
    if (level < 0) level = 0;
    gDebugLevel = level;
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

	#ifdef DEBUG
		freopen("libaps.log","w", stderr);
	#endif

	#ifdef WIN32
		hdll = LoadLibrary("ftd2xx.dll");
		if ((int)hdll <= HINSTANCE_ERROR) {
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

	dlog(DEBUG_INFO,"Library Loaded\n");

	DLL_FT_Open  = (pFT_Open) GetFunction(hdll,"FT_Open");
	DLL_FT_Close = (pFT_Close) GetFunction(hdll,"FT_Close");
	DLL_FT_Write = (pFT_Write) GetFunction(hdll,"FT_Write");
	DLL_FT_Read  = (pFT_Read) GetFunction(hdll,"FT_Read");
	DLL_FT_SetBaudRate = (pFT_SetBaudRate) GetFunction(hdll,"FT_SetBaudRate");

	DLL_FT_ListDevices = (pFT_ListDevices) GetFunction(hdll,"FT_ListDevices");

	return 0;
}

EXPORT int APS_Open(int device)
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
	FT_HANDLE usb_device;

	if (device > MAX_APS_DEVICES) {
		return -1;
	}

	// If the ftd2xx dll has not been loaded, loadit.
	if (!hdll) {
		if (APS_Init() != 0) {
			return -2;
		};
	}

	usb_handles[device] = 0;
	status = DLL_FT_Open(device, &(usb_handles[device]));

	if (status == FT_OK) {
	#ifdef DEBUG
		dlog(DEBUG_INFO,"FTD2 Open\n");
	#endif
	} else {
	#ifdef DEBUG
		dlog(DEBUG_INFO,"FTD_Open returned: %i\n", status);
	#endif
		return -status;
	}

	/*
	dlog(DEBUG_INFO,"Setting baud rate to:%i\n", FT_BAUD_300);

	status = DLL_FT_SetBaudRate(usb_handles[device], FT_BAUD_300);
  if (status != FT_OK) {
    return -status;
  }
  */
  return 0;
}

EXPORT int APS_ListSerials()
{
	int max_serials;
	int cnt;

	max_serials = MAX_DEVICES;

	printf("This Library knows the following serial numbers\n");
	for (cnt = 0; cnt < max_serials; cnt++) {
		printf("ID: %i Serial: %s\n", cnt, dac_devices[cnt]);
	}
	return 0;
}

EXPORT int APS_GetSerials(char * buf, int maxlen, int device)
{
	if (device > MAX_DEVICES) {
		return -1;
	}
	snprintf(buf,maxlen,"%s",dac_devices[device] );
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
	FT_HANDLE usb_device;
	int device_idx;
	int cnt, numdevices, found;
	char * serial;
	char testSerial[64];

	if (device > MAX_DEVICES) {
		return -1;
	}

	// If the ftd2xx dll has not been loaded, loadit.
	if (!hdll) {
		if (APS_Init() != 0) {
			return -2;
		};
	}

	serial = dac_devices[device];
	numdevices = APS_NumDevices();

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

	status = APS_Open(cnt);
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
	FT_HANDLE usb_device;
	int device_idx;
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

	status = APS_Open(cnt);
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

EXPORT int APS_GetSerialNumbers()
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
  UCHAR CmdByte,
        Buf[256],
        pbuf[256],
        Packet[256];
  ULONG i,
        out,
        Length,
        WriteData,
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
		status = DLL_FT_Write(usb_handle, Packet, 1, &BytesWritten);
		if (status == FT_OK) break;
	}

	if (status != FT_OK || BytesWritten != 1) {
		dlog(DEBUG_INFO,"Error writing to USB status %i bytes written %i / 1 repeats %i\n",
				status,BytesWritten, repeats);
	}

	// Read the specified number of bytes into the Data array
	for (repeats = 0; repeats < max_repeats ; repeats++) {
		status = DLL_FT_Read(usb_handle, Data, Length, &BytesRead);
		if (repeats > 0) dlog(DEBUG_INFO,"Retry USB Read %i\n", repeats);
		if (status == FT_OK) break;
	}
	if (status != FT_OK || BytesRead != Length) {
		dlog(DEBUG_INFO,"Error reading from USB! status %i bytes read %i / %i repeats = %i\n", status,BytesRead,Length,repeats);
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
  UCHAR CmdByte,
        Buf[256],
        pbuf[256],
        Packet[256];
  ULONG i,
        out,
        Length,
        WriteData,
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
		  status = DLL_FT_Write(usb_handle, Packet, Length+1, &BytesWritten);
	  	if (status == FT_OK) break;
	  	dlog(DEBUG_INFO,"Repeat Write\n");
	  }

	  if (status != FT_OK || BytesWritten != Length+1) {
	  	dlog(DEBUG_INFO,"Error writing to USB status %i bytes written %i / %i repeats %i\n",
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
  UCHAR CmdByte,
        Buf[256],
        pbuf[256],
        Packet[256];
  ULONG i,
        out,
        Length,
        WriteData,
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
  UCHAR CmdByte,
        Buf[256],
        pbuf[256],
        Packet[256];
  ULONG i,
        out,
        Length,
        WriteData,
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

EXPORT int APS_ProgramFpga(int device, BYTE *Data, int ByteCount, int Sel)
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
  char pbuf[256];
  int i, j,cnt;

  FILE * test;

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

  dlog(DEBUG_VERBOSE, "Starting ProgramFPGA Device: %i Sel: %i ... \n", device, Sel);

  // Create active low mask bits for PROGRAMN field
  PgmMask = APS_PGM_BITS;
  if(Sel & 1) PgmMask &= ~APS_PGM01_BIT;
  if(Sel & 2) PgmMask &= ~APS_PGM23_BIT;

  // Create mask bits for valid INITN readback bits
  InitMask = 0;
  if(Sel & 1) InitMask |= APS_INIT01_BIT;
  if(Sel & 2) InitMask |= APS_INIT23_BIT;

  // Create active high mask bits for DONE field
  DoneMask = 0;
  if(Sel & 1) DoneMask |= APS_DONE01_BIT;
  if(Sel & 2) DoneMask |= APS_DONE23_BIT;

  // Read the Status to get state of RESETN for unused channel
  if(APS_ReadReg(device, APS_CONF_STAT, 1, 0, &ReadByte) != 1)
    return(-1);

  // Create active high mask bits for RESETN field
  // Force state of programmed chip reset to 1, leave the other alone
  RstMask = APS_FRST_BITS & ReadByte;
  if(Sel & 1) RstMask |= APS_FRST01_BIT;
  if(Sel & 2) RstMask |= APS_FRST23_BIT;

  //WriteByte = APS_OSCEN_BIT;
  //if(APS_WriteReg(device, APS_STATUS_CTRL, 1, 0, &WriteByte) != 1)
  // return(-5);

  // Assert PROGRAMN and deassert RESETN for the selected FPGA(s).  Leave all other bits low.
  WriteByte = PgmMask | RstMask;
  if(APS_WriteReg(device,  APS_CONF_STAT, 1, 0, &WriteByte) != 1)
    return(-2);

  // Read the Status to see that INITN is asserted in response to PROGRAMN
  if(APS_ReadReg(device, APS_CONF_STAT, 1, 0, &ReadByte) != 1)
    return(-3);

  if((ReadByte & InitMask) != 0)
    return(-4);

  // Deassert PROGRAMN for all FPGA(s).
  WriteByte |= APS_PGM_BITS;
  if(APS_WriteReg(device, APS_CONF_STAT, 1, 0, &WriteByte) != 1)
    return(-5);

  // Read the Status to see that INITN is deasserted in response to PROGRAMN deassertion
  if(APS_ReadReg(device, APS_CONF_STAT, 1, 0, &ReadByte) != 1)
    return(-6);

  if((ReadByte & InitMask) == 0)
    return(-7);

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
	
    if(i + BLOCKSIZE < ByteCount)
    {
      #ifdef OUTPUTBITFILE
      for(cnt = 0; cnt < BLOCKSIZE; cnt++)
		  fprintf(test,"%031 ", Data[i+cnt]);
	  fprintf(test,"\n");
	  #endif
      if(APS_WriteReg(device, APS_CONF_DATA, 0, Sel, Data+i) != BLOCKSIZE)  // Defaults to 61 bytes for CONF_DATA
        return(-8);
    }
    else
    {
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
      if(APS_WriteReg(device, APS_CONF_DATA, 0, Sel, LastBuf) != 61)  // Defaults to 61 bytes for CONF_DATA
        return(-9);

	#ifdef OUTPUTBITFILE
	  fprintf(test,"\n");
	  fclose(test);
	#endif


	    dlog(DEBUG_VERBOSE, "Done\n");


      // Read Bit File Version
      APS_ReadBitFileVersion(device);

	  // Return the number of data bytes written
      return(i+j);
    }
	// We do not expect to get to this point but rather be returned in the for
	// loop above. If we get here it is an error.

	dlog(DEBUG_VERBOSE,"Error\n");

	return 0;
}



// Setup modified for low clock rate
APS_SPI_REC PllSetup[] =
{
  0x0,  0x99,  // Use SDO, Long instruction mode
  0x10, 0x7C,  // Enable PLL , set charge pump to 4.8ma
  0x11, 0x5,   // Set reference divider R to 5 to divide 125 MHz reference to 25 MHz
  0x14, 0x06,  // Set B divider to 6 to divide 1200 MHz to 25 MHz
  0x16, 0x5,   // Set P divider to 16 and enable B counter
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
  0x190, 0x55, //	6 high, 6 low = channel 0 divide by 12
  0x191, 0x00, //	Clear divider 0 bypass
  0x193, 0x22, //	3 high, 3 low = channel 1 divide by 6
  0x196, 0x55, //	6 high, 6 low = channel 2 divide by 12
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
  dlog(DEBUG_INFO,"Setting PLL\n");

  for(i = 0; i <  sizeof(PllSetup)/sizeof(APS_SPI_REC); i++) {
     APS_WriteSPI(device, APS_PLL_SPI, PllSetup[i].Address, &PllSetup[i].Data);
  }
  return 0;
}


APS_SPI_REC PllFinish[] =
{
  0x18, 0x71,  // Initiate Calibration.  Must be followed by Update Registers Command
  0x232, 0x1,   // Set bit 0 to 1 to simultaneously update all registers with pending writes.
  0x18, 0x70,  // Clear calibration flag so that next set generates 0 to 1.
  0x232, 0x1   // Set bit 0 to 1 to simultaneously update all registers with pending writes.
};

EXPORT int APS_SetPllFreq(int device, int dac, int freq)
{
  ULONG pll_cycles_addr, pll_bypass_addr;
  UCHAR pll_cycles_val, pll_bypass_val;
  UCHAR pll_output_enable, pll_enable_addr;
  UCHAR ReadByte,WriteByte;
  int cnt, xor_flag_cnt;
  int fpga;
  int sync_status;

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
		pll_enable_addr = FPGA1_ENABLE_ADDR;
		break;
	case 2:
		// fall through
	case 3:
		pll_cycles_addr = FPGA2_PLL_CYCLES_ADDR;
		pll_bypass_addr = FPGA2_PLL_BYPASS_ADDR;
		pll_enable_addr = FPGA2_ENABLE_ADDR;
	  break;
	default:
	  return -1;
  }

  switch(freq) {
	case 40:
		pll_cycles_val = 0xEE; //  6 high / 6 low (divide by 12)
		break;
	case 100:
		pll_cycles_val = 0x55; //  4 high / 2 low (divide by 6)
		break;
	case 300:
		pll_cycles_val = 0x11; // 1 high /1 low (divide by 2)
		break;
	case 600:				   // implicit divide by 2 if divider is not bypassed
		// fall through
	case 1200:
		pll_cycles_val = 0x00;
	  break;
	default:
	  return -2;
  }

  // by pass divider if freq == 1200
  if (freq == 1200) {
	pll_bypass_val = 0x80;
  } else {
	pll_bypass_val = 0x00;
  }

  dlog(DEBUG_INFO, "Setting PLL cycles addr: 0x%x val: 0x%x\n", pll_cycles_addr, pll_cycles_val);
  dlog(DEBUG_INFO, "Setting PLL bypass addr: 0x%x val: 0x%x\n", pll_bypass_addr, pll_bypass_val);

  WriteByte = 0;
  if(APS_WriteReg(device,APS_STATUS_CTRL, 1, 0, &WriteByte) != 1)
    return(-4);

  APS_WriteSPI(device, APS_PLL_SPI, pll_cycles_addr, &pll_cycles_val);
  APS_WriteSPI(device, APS_PLL_SPI, pll_bypass_addr, &pll_bypass_val);

  int i;
  for(i = 0; i <  sizeof(PllFinish)/sizeof(APS_SPI_REC); i++) {
     APS_WriteSPI(device, APS_PLL_SPI, PllFinish[i].Address, &PllFinish[i].Data);
  }

  //Enable Oscillator
  WriteByte = APS_OSCEN_BIT;
  if(APS_WriteReg(device, APS_STATUS_CTRL, 1, 0, &WriteByte) != 1)
    return(-4);

  sync_status = 0;

 /* // Test for PLL Lock

  APS_ReadReg(device, APS_STATUS_CTRL, 1, 0, &ReadByte);
  if (ReadByte && APS_LOCK_BIT != APS_LOCK_BIT) {
    // We do not have a PLL Lock
	sync_status |= 2;
  }
*/
  // Test for DAC clock phase match
  /*

  sync_status |= 4;
  test_cnt = 0;
  while (test_cnt < MAX_PHASE_TEST_CNT) {
	  test_cnt++;
	  xor_flag_cnt = 0;
	  for(cnt = 0; cnt < 10; cnt++) {
		xor_flag_cnt += APS_ReadFPGA(gRegRead | FPGA_OFF_VERSION, fpga);
	  }

	  if (xor_flag_cnt > 5) {
		// DAC outputs are out of sync
		// disable output of clock to DAC
		pll_output_enable = 0x2;
		APS_WriteSPI(APS_PLL_SPI, pll_enable_addr, &pll_output_enable);
		// re-enable otput of clock to DAC
		pll_output_enable = 0x0;
		APS_WriteSPI(APS_PLL_SPI, pll_enable_addr, &pll_output_enable);
	  } else {
	    sync_status = sync_status & ~4;
	    break;
	  }

  }
  */

  return sync_status;
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
	snprintf(buffer, maxlen, "Libaps $Revision$");
}


