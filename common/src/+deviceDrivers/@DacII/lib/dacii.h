/**********************************************
* Module Name : dacii.h
*
* Author/Date : B.C. Donovan / 21-Oct-08
*
* Description : Private dacii header for libdacii.dll
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
* $Date: 2011-01-21 16:35:11 -0500 (Fri, 21 Jan 2011) $
* $Locker:  $
* $Name:  $
* $Revision: 703 $
*
* $Log: dacii.h,v $
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


#ifdef WIN32
	#include "windows.h"
#endif

#ifdef __APPLE__
	#include "wintypes.h"
#endif

#ifdef __linux__
	#include "WinTypes.h"
#endif

// Functions and defines not exported by DLL

#include "ftd2xx.h"

#ifndef DACII_H
#define DACII_H

#define CBL_SERIAL_NUMS {"A6001ixW","A6001ixX"}

// Command byte CMD field values

#define DACII_FPGA_IO 0
#define DACII_FPGA_ADDR (1<<4)
#define DACII_DAC_SPI (2<<4)
#define DACII_PLL_SPI (3<<4)
#define DACII_VCXO_SPI (4<<4)
#define DACII_CONF_DATA (5<<4)
#define DACII_CONF_STAT (6<<4)
#define DACII_STATUS_CTRL (7<<4)
#define DACII_CMD (0x7<<4)

#define DACII_PGM01_BIT 1
#define DACII_PGM23_BIT 2
#define DACII_PGM_BITS (DACII_PGM01_BIT | DACII_PGM23_BIT)

#define DACII_FRST01_BIT 0x4
#define DACII_FRST23_BIT 0x8
#define DACII_FRST_BITS (DACII_FRST01_BIT | DACII_FRST23_BIT)

#define DACII_DONE01_BIT 0x10
#define DACII_DONE23_BIT 0x20
#define DACII_DONE_BITS (DACII_DONE01_BIT | DACII_DONE23_BIT)

#define DACII_INIT01_BIT 0x40
#define DACII_INIT23_BIT 0x80
#define DACII_INIT_BITS (DACII_INIT01_BIT | DACII_INIT23_BIT)

#define DACII_DRST01_BIT 0x4
#define DACII_DRST23_BIT 0x8
#define DACII_PRST_BIT 0x2
#define DACII_SYNC_BIT 0x2
#define DACII_OSCEN_BIT 0x10
#define DACII_STATUS_BIT 0x20
#define DACII_LOCK_BIT 0x40
#define DACII_DIRQ_BIT 0x80

#define FPGA1_PLL_CYCLES_ADDR 0x190
#define FPGA1_PLL_BYPASS_ADDR 0x191
#define FPGA1_ENABLE_ADDR	  0xF0

#define FPGA2_PLL_CYCLES_ADDR 0x196
#define FPGA2_PLL_BYPASS_ADDR 0x197
#define FPGA2_ENABLE_ADDR     0xF4

#define MAX_PHASE_TEST_CNT 10

typedef struct
{
  ULONG Address;
  UCHAR Data;
} DACII_SPI_REC;

FT_HANDLE device2handle(int device);

int DACII_ReadReg
(
  int device,
  ULONG Command, // DACII_FPGA_IO, DACII_FPGA_ADDR, DACII_CONF_DATA, DACII_CONF_STAT, or DACII_STATUS_CTRL
  ULONG Size,    // Transfer size, 0, 1, 2, or 3 for 1, 2, 4, or 8 bytes.  Ignored for Config cycles
  ULONG Sel,     // Select bits to drive FPGA selects for I/O or Config
  UCHAR *Data    // Data bytes to be written.  Must match length/transfer type
);

int DACII_WriteReg
(
  int device,
  ULONG Command, // DACII_FPGA_IO, DACII_FPGA_ADDR, DACII_CONF_DATA, DACII_CONF_STAT, or DACII_STATUS_CTRL
  ULONG Size,    // Transfer size, 0, 1, 2, or 3 for 1, 2, 4, or 8 bytes.  Ignored for Config cycles
  ULONG Sel,     // Select bits to drive FPGA selects for I/O or Config
  UCHAR *Data    // Data bytes to be written.  Must match length/transfer type
);

int DACII_WriteSPI
(
  int device,
  ULONG Command,   // DACII_DAC_SPI, DACII_PLL_SPI, or DACII_VCXO_SPI
  ULONG Address,   // SPI register address.  Ignored for VCXO since address embedded in the data
  UCHAR *Data      // Data bytes to be written.  1 for DAC, 1 for PLL, or 4 for VCXO.  LS Byte first.
);

int DACII_ReadSPI
(
  int device,
  ULONG Command,   // DACII_DAC_SPI, DACII_PLL_SPI, or DACII_VCXO_SPI
  ULONG Address,   // SPI register address.  Ignored for VCXO since address embedded in the data
  UCHAR *Data      // Destination for the returned data byte.  Only single byte reads supported.
);

int DACII_WriteBlock
(
  int device,
  ULONG Size,    // Transfer size bytes. 
  UCHAR *Data    // Data bytes to be written.  Must match length/transfer type
);

#endif // DACII_H
