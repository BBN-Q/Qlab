/**********************************************
* Module Name : aps.h
*
* Author/Date : B.C. Donovan / 21-Oct-08
*
* Description : Private aps header for libaps.dll
*
* Restrictions/Limitations :
*
*
* Copyright (C) BBN Technologies Corp. 2008 - 2011
**********************************************/


#ifdef WIN32
	#include "windows.h"
#endif

#ifdef __APPLE__
	#include "WinTypes.h"
#endif

#ifdef __linux__
	#include "WinTypes.h"
#endif

// Functions and defines not exported by DLL

#include "ftd2xx.h"

#ifndef APS_H
#define APS_H

#define APS_SERIAL_NUMS {"A6001ixW","A6001ixX"}

// Command byte CMD field values

#define APS_FPGA_IO 0
#define APS_FPGA_ADDR (1<<4)
#define APS_DAC_SPI (2<<4)
#define APS_PLL_SPI (3<<4)
#define APS_VCXO_SPI (4<<4)
#define APS_CONF_DATA (5<<4)
#define APS_CONF_STAT (6<<4)
#define APS_STATUS_CTRL (7<<4)
#define APS_CMD (0x7<<4)

#define APS_PGM01_BIT 1
#define APS_PGM23_BIT 2
#define APS_PGM_BITS (APS_PGM01_BIT | APS_PGM23_BIT)

#define APS_FRST01_BIT 0x4
#define APS_FRST23_BIT 0x8
#define APS_FRST_BITS (APS_FRST01_BIT | APS_FRST23_BIT)

#define APS_DONE01_BIT 0x10
#define APS_DONE23_BIT 0x20
#define APS_DONE_BITS (APS_DONE01_BIT | APS_DONE23_BIT)

#define APS_INIT01_BIT 0x40
#define APS_INIT23_BIT 0x80
#define APS_INIT_BITS (APS_INIT01_BIT | APS_INIT23_BIT)

#define APS_DRST01_BIT 0x4
#define APS_DRST23_BIT 0x8
#define APS_PRST_BIT 0x2
#define APS_SYNC_BIT 0x1
#define APS_OSCEN_BIT 0x10
#define APS_STATUS_BIT 0x20
#define APS_LOCK_BIT 0x40
#define APS_DIRQ_BIT 0x80

#define FPGA1_PLL_CYCLES_ADDR 0x190
#define FPGA1_PLL_BYPASS_ADDR 0x191
#define DAC0_ENABLE_ADDR	  0xF0
#define DAC1_ENABLE_ADDR	  0xF1
#define FGPA1_PLL_ADDR		  0xF2

#define FPGA2_PLL_CYCLES_ADDR 0x196
#define FPGA2_PLL_BYPASS_ADDR 0x197
#define DAC2_ENABLE_ADDR     0xF5
#define DAC3_ENABLE_ADDR     0xF4
#define FGPA2_PLL_ADDR		 0xF3

#define FPGA_PLL_RESET_ADDR 0x0
#define FPGA1_PLL_RESET_BIT 0x2
#define FPGA2_PLL_RESET_BIT 0x200

#define MAX_PHASE_TEST_CNT 25

typedef struct
{
  ULONG Address;
  UCHAR Data;
} APS_SPI_REC;

FT_HANDLE device2handle(int device);

int APS_ReadReg
(
  int device,
  ULONG Command, // APS_FPGA_IO, APS_FPGA_ADDR, APS_CONF_DATA, APS_CONF_STAT, or APS_STATUS_CTRL
  ULONG Size,    // Transfer size, 0, 1, 2, or 3 for 1, 2, 4, or 8 bytes.  Ignored for Config cycles
  ULONG Sel,     // Select bits to drive FPGA selects for I/O or Config
  UCHAR *Data    // Data bytes to be written.  Must match length/transfer type
);

int APS_WriteReg
(
  int device,
  ULONG Command, // APS_FPGA_IO, APS_FPGA_ADDR, APS_CONF_DATA, APS_CONF_STAT, or APS_STATUS_CTRL
  ULONG Size,    // Transfer size, 0, 1, 2, or 3 for 1, 2, 4, or 8 bytes.  Ignored for Config cycles
  ULONG Sel,     // Select bits to drive FPGA selects for I/O or Config
  UCHAR *Data    // Data bytes to be written.  Must match length/transfer type
);

int APS_WriteSPI
(
  int device,
  ULONG Command,   // APS_DAC_SPI, APS_PLL_SPI, or APS_VCXO_SPI
  ULONG Address,   // SPI register address.  Ignored for VCXO since address embedded in the data
  UCHAR *Data      // Data bytes to be written.  1 for DAC, 1 for PLL, or 4 for VCXO.  LS Byte first.
);

int APS_ReadSPI
(
  int device,
  ULONG Command,   // APS_DAC_SPI, APS_PLL_SPI, or APS_VCXO_SPI
  ULONG Address,   // SPI register address.  Ignored for VCXO since address embedded in the data
  UCHAR *Data      // Destination for the returned data byte.  Only single byte reads supported.
);

int APS_WriteBlock
(
  int device,
  ULONG Size,    // Transfer size bytes. 
  UCHAR *Data    // Data bytes to be written.  Must match length/transfer type
);

void APS_UpdatePllReg(int device);

#endif // APS_H
