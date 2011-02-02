/**********************************************
* Module Name : fpga.h
*
* Author/Date : B.C. Donovan / 21-Oct-08
*
* Description : Private fpda header for libdacii.dll
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
*   LinkListMemoryMapChanges.xls by Scott Stafford
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
* $Log: fpga.h,v $
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

#ifndef FPGA_H
#define FPGA_H

#define VERSION_ELL 0x10

#define K4 4096
#define K8 8192

#define LSB_MASK 0xFF;

#define ENV 0
#define PHS 1

// Version 5 Memory Map

#define FPGA_ADDR_REGWRITE 	0x0000
#define FPGA_ADDR_REGREAD 	0x1000
#define FPGA_ADDR_ENVWRITE  0x2000
#define FPGA_ADDR_ENVREAD 	0x3000
#define FPGA_ADDR_PHSWRITE  0x4000
#define FPGA_ADDR_PHSREAD 	0x5000

#define FPGA_ADDR_ENVLLOFF_WRITE 0xA000
#define FPGA_ADDR_ENVLLOFF_READ  0xA800
#define FPGA_ADDR_ENVLLCNT_WRITE 0xB000
#define FPGA_ADDR_ENVLLCNT_READ  0xB800

#define FPGA_ADDR_PHSLLOFF_WRITE 0xC000
#define FPGA_ADDR_PHSLLOFF_READ  0xC800
#define FPGA_ADDR_PHSLLCNT_WRITE 0xD000
#define FPGA_ADDR_PHSLLCNT_READ  0xD800

// Version 0x10 ELL Memory Map Additions

#define FPGA_ADDR_ELL_REGREAD   0x8000

#define FPGA_ADDR_ELL_ENVWRITE  0x1000
#define FPGA_ADDR_ELL_PHSWRITE  0x4000

#define FPGA_ADDR_ELL_ENVLL_A_WRITE 0x3000
#define FPGA_ADDR_ELL_ENVLL_B_WRITE 0x3800

#define FPGA_ADDR_ELL_PHSLL_A_WRITE 0x6000
#define FPGA_ADDR_ELL_PHSLL_B_WRITE 0x6800

// Register Locations

#define FPGA_OFF_CSR 		0x0
#define FPGA_OFF_TRIGLED 	0x1
#define FPGA_OFF_ENVOFF 	0x2
#define FPGA_OFF_ENVSIZE 	0x3
#define FPGA_OFF_PHSOFF 	0x4
#define FPGA_OFF_PHSSIZE 	0x5
#define FPGA_OFF_VERSION	0x6
#define FPGA_OFF_LLCTRL		0x7

// Version 0x10 Additional Registers

#define FGPA_OFF_ELL_ENVLL_A_CTRL 0x7  // A Control Register
#define FGPA_OFF_ELL_ENVLL_B_CTRL 0x8  // B Control Register
#define FGPA_OFF_ELL_ENVLL_REPEAT 0x9  // Repeat Count
#define FGPA_OFF_ELL_PHSLL_A_CTRL 0xA  // A Control Register
#define FGPA_OFF_ELL_PHSLL_B_CTRL 0xB  // B Control Register
#define FGPA_OFF_ELL_PHSLL_REPEAT 0xC  // Repeat Count

#define LL_SIZE_PHSSHIFT	8
#define LL_SIZE_ENVSHIFT	0

#define LLMSK_PHSENABLE		0x4000
#define LLMSK_PHSMODE		0x8000
#define LLMSK_ENVENABLE		0x40
#define LLMSK_ENVMODE		0x80

#define CSRMSK_ENVMEMRST 	0x1
#define CSRMSK_ENVSMRST 	0x2
#define CSRMSK_ENVSMEN 		0x4
#define CSRMSK_ENVMEMLCK 	0x8
#define CSRMSK_ENVTRIGSRC 	0x10
#define CSRMSK_PHSMEMRST 	0x20
#define CSRMSK_PHSSMRST 	0x40
#define CSRMSK_PHSSMEN 		0x80
#define CSRMSK_PHSMEMLCK 	0x100
#define CSRMSK_PHSTRIGSRC 	0x200

// Version 0x10 Register Masks

#define CSRMSK_ENVMEMRST_ELL 	0x1
#define CSRMSK_ENVSMRST_ELL 	0x2
#define CSRMSK_ENVSMEN_ELL		0x4
#define CSRMSK_ENVMEMLCK_ELL 	0x8
#define CSRMSK_ENVTRIGSRC_ELL 	0x10
#define CSRMSK_ENVOUTMODE_ELL  	0x20
#define CSRMSK_ENVLLMODE_ELL  	0x40
#define CSRMSK_ENVLLSTATUS_ELL 	0x80

#define CSRMSK_PHSMEMRST_ELL 	0x100
#define CSRMSK_PHSSMRST_ELL 	0x200
#define CSRMSK_PHSSMEN_ELL		0x400
#define CSRMSK_PHSMEMLCK_ELL 	0x800
#define CSRMSK_PHSTRIGSRC_ELL 	0x1000
#define CSRMSK_PHSOUTMODE_ELL  	0x2000
#define CSRMSK_PHSLLMODE_ELL  	0x4000
#define CSRMSK_PHSLLSTATUS_ELL 	0x8000

#define TRIGLEDMSK_ENVSWTRIG 	0x1
#define TRIGLEDMSK_PHSSWTRIG 	0x2
#define TRIGLEDMSK_SWLED0 		0x4
#define TRIGLEDMSK_SWLED1 		0x8

#define MAX_WF_LEN_SAMPLES 4092
#define MAX_WF_AMP_SAMPLES 8192
#define WF_MODULUS		   4
#define MAX_WF_OFFSET	0xFFF
#define MAX_LL_LENGTH	64
#define MAX_LL_LENGTH_ELL 512

#define SOFTWARE_TRIGGER 1
#define HARDWARE_TRIGGER 2

#define ENVELOPE "Envelope"
#define PHASE    "Phase"
#define BOTH_DACS "Envelope & Phase"

#define ELL_ENTRY_LENGTH 4

int DACII_WriteFPGA(int device, ULONG addr, ULONG data, UCHAR fpga);
ULONG DACII_ReadFPGA(int device,ULONG addr, UCHAR fpga);
int dac2fpga(int dac);

#endif
