/**********************************************
* Module Name : fpga.c
*
* Author/Date : B.C. Donovan / 21-Oct-08
*
* Description : Private fpga functions for libdacii.dll
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
* $Date: 2011-01-26 17:09:18 -0500 (Wed, 26 Jan 2011) $
* $Locker:  $
* $Name:  $
* $Revision: 706 $
*
* $Log: fpga.c,v $
* Revision 1.8  2008/12/03 15:47:57  bdonovan
* Added support for multiple DAC boxes to libdacii. Updated dacii.m for new api.
*
* Revision 1.7  2008/11/25 16:34:37  cbl
* Fixed link list off by bug.
*
* Revision 1.6  2008/11/24 23:54:03  bdonovan
* Added setting of OSCEN bit in status and control register to enable locking to 10
*  MHz reference.
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

// TODO: Write LoadLinkListELL

#ifdef WIN32
  #include <windows.h>
#endif

#include <stdio.h>
#include "dacii.h"
#include "fpga.h"
#include "libdacii.h"

#define DEBUG

#ifdef LOG_WRITE_FPGA
FILE * outfile = 0;
#endif

int gBitFileVersion = 0; // set default version to 0 as all valid version numbers are > 0
int gRegRead =  FPGA_ADDR_REGREAD; // register read address to or

int DACII_FormatForFPGA(BYTE * buffer, ULONG addr, ULONG data, UCHAR fpga)
{
	BYTE cmd;
	cmd = DACII_FPGA_IO | (fpga<<2) | 2;

	buffer[0] = cmd;
	buffer[1] = (addr >> 8) & LSB_MASK;
	buffer[2]  = addr & LSB_MASK;
	buffer[3]  = (data >> 8) & LSB_MASK;
	buffer[4]  = data & LSB_MASK;
	return 0;
}

int DACII_FormatForFPGA_ELL(BYTE * buffer, ULONG addr,
		                    ULONG offset, ULONG count,
		                    ULONG trigger, ULONG repeat, UCHAR fpga)
{
	BYTE cmd;

	cmd = DACII_FPGA_IO | (fpga<<2) | 2;

	buffer[0] = cmd;
	buffer[1] = (addr >> 8) & LSB_MASK;
	buffer[2]  = addr & LSB_MASK;

	buffer[3]  = (offset >> 8) & LSB_MASK;
	buffer[4]  = offset & LSB_MASK;

	buffer[5]  = (count >> 8) & LSB_MASK;
	buffer[6]  = count & LSB_MASK;

	buffer[7]  = (trigger >> 8) & LSB_MASK;
	buffer[8]  = trigger & LSB_MASK;

	buffer[9]  = (repeat >> 8) & LSB_MASK;
	buffer[10]  = repeat & LSB_MASK;
	return 0;
}

EXPORT int DACII_WriteFPGA(int device, ULONG addr, ULONG data, UCHAR fpga)
/********************************************************************
 *
 * Function Name : DACII_WriteFPGA()
 *
 * Description :  Writes data to FPGA. 16 bit numbers are unpacked to 2 bytes
 *
 * Inputs :
 *               Addr  - Address to write to
 *              Data   - Data to write
 *              FPGA - FPGA selection bit (1 or 2)
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
	UCHAR outdata[4];

	outdata[0] = (addr >> 8) & LSB_MASK;
	outdata[1] = addr & LSB_MASK;
	outdata[2] = (data >> 8) & LSB_MASK;
	outdata[3] = data & LSB_MASK;

	#ifdef DEBUG
	 fprintf(stderr,"Writting Addr 0x%x Data 0x%x\n", addr, data);
	 fflush(stderr);
	#endif

	DACII_WriteReg(device, DACII_FPGA_IO, 2, fpga, outdata);
}

EXPORT ULONG DACII_ReadFPGA(int device, ULONG addr, UCHAR fpga)
/********************************************************************
 *
 * Function Name : DACII_ReadFPGA()
 *
 * Description : Read data from FPGA
 *
 * Inputs : Addr  - Address to write to
 *              FPGA - FPGA selection bit (1 or 2)
 *
 * Returns : Data at address
 *
 * Error Conditions :
 *
 * Unit Tested on:
 *
 * Unit Tested by:
 *
 ********************************************************************/
{
	ULONG data;
	UCHAR read[2];

	read[0] = (addr >> 8) & LSB_MASK;
	read[1] = addr & LSB_MASK;

	DACII_WriteReg(device, DACII_FPGA_IO, 1, fpga, read);

	DACII_ReadReg(device, DACII_FPGA_IO, 1, fpga, read);

	data = (read[0] << 8) | read[1];


	#ifdef DEBUG
	fprintf(stderr,"Reading Addr 0x%x Data 0x%x\n", addr, data);
	fflush(stderr);
	#endif

	return data;
}

int dac2fpga(int dac)
/********************************************************************
 *
 * Function Name : dac2fpga()
 *
 * Description : Function to get FPGA ID from DAC ID. A
 *
 * Inputs :  dac id
 *
 * Returns : fpga id
 *
 * Error Conditions :
 *
 * Unit Tested on:
 *
 * Unit Tested by:
 *
 ********************************************************************/
{
	/* select FPGA based on DAC id number
	    DAC0 & DAC1 -> FPGA 1
	    DAC2 & DAC3 -> FPGA2
	    Added a special case: sending dac = -1 will trigger both FPGAs
	    at the same time.
	 */
	switch(dac) {
		case -1:
			return 3;
		case 0:
			// fall through
		case 1:
			return 1;
		case 2:
			// fall through
		case 3:
			return 2;
		default:
			return -1;
	}
}

EXPORT int DACII_LoadWaveform(int device, unsigned short *Data, int ByteCount, int offset,int dac)
/********************************************************************
 *
 * Function Name : DACII_LoadWaveform()
 *
 * Description : LoadsWaveform to FPGA
 *
 * Inputs : Data - pointer to waveform buffer
 *              ByteCount - length of waveform in bytes
 *              Dac - dac ID
 *
 * Returns : 0 on success < 0 on failure
 *
 * Error Conditions :
 *
 * Unit Tested on:
 *
 * Unit Tested by:
 *
 ********************************************************************/
{
	int dac_offset, dac_size, dac_write, dac_read, dac_mem_lock;
	int fpga;
	int cnt;
	char * dac_type;
	int cmd, addr, curData;

	#ifdef LOG_WAVEFORM
	FILE * logwaveform;
	#endif

	ULONG write_addr;
	ULONG data;
	ULONG wf_length;
	ULONG formated_length;
	
	BYTE * formatedData;
	BYTE * formatedDataIdx;

	if(gBitFileVersion < VERSION_ELL && ByteCount > K4 ) {
		fprintf(stderr,"[WARNING] Waveform length > 4K. Truncating waveform");
		fflush(stderr);
		ByteCount = K4;

	} else if(gBitFileVersion >= VERSION_ELL && ByteCount > K8 ) {
		fprintf(stderr,"[WARNING] Waveform length > 8K. Truncating waveform");
		fflush(stderr);
		ByteCount = K8;
	}

	wf_length = ByteCount / WF_MODULUS;

	#ifdef DEBUG
	if (ByteCount % WF_MODULUS != 0) {
		fprintf(stderr,"[WARNING] Waveform data needs to be padded");
		fflush(stderr);
	}
	#endif

	fpga = dac2fpga(dac);
	if (fpga < 0) {
		return -1;
	}

	#ifdef DEBUG
	fprintf(stderr,"Loading Waveform length %i into FPGA%i DAC%i \n", ByteCount, fpga, dac);
	fflush(stderr);
	#endif

	// setup register addressing based on DAC
	switch(dac) {
		case 0:
			// fall through
		case 2:
			dac_type   = ENVELOPE;
			dac_offset = FPGA_OFF_ENVOFF;
			dac_size   = FPGA_OFF_ENVSIZE;
			if (gBitFileVersion < VERSION_ELL) {
				dac_mem_lock = CSRMSK_ENVMEMLCK;
				dac_write = FPGA_ADDR_ENVWRITE;

			} else {
				dac_mem_lock = CSRMSK_ENVMEMLCK_ELL;
				dac_write =  FPGA_ADDR_ELL_ENVWRITE;
			}

			break;
		case 1:
			// fall through
		case 3:
			dac_type   = PHASE;
			dac_offset = FPGA_OFF_PHSOFF;
			dac_size   = FPGA_OFF_PHSSIZE;

			if (gBitFileVersion < VERSION_ELL) {
				dac_mem_lock = CSRMSK_PHSMEMLCK;
				dac_write = FPGA_ADDR_PHSWRITE;
			} else {
				dac_mem_lock = CSRMSK_PHSMEMLCK_ELL ;
				dac_write =  FPGA_ADDR_ELL_PHSWRITE;
			}
			break;
		default:
			return -2;
	}

	dac_read = gRegRead | dac_write;

	if (offset < 0 || offset > MAX_WF_OFFSET) {
		return -3;
	}

	// check to make sure that waveform will fit
	if ((offset + ByteCount) > MAX_WF_OFFSET) {
		return -4;
	}

	#ifdef DEBUG
	fprintf(stderr,"Clearing Control and Status Register ...\n");
	fflush(stderr);
	#endif

	DACII_WriteFPGA(device, FPGA_ADDR_REGWRITE | FPGA_OFF_CSR, 0x0, fpga);

	#ifdef DEBUG
	data = DACII_ReadFPGA(device, gRegRead | FPGA_OFF_CSR, fpga);
	fprintf(stderr,"CSR set to: %i\n", data);

	fprintf(stderr,"Initializing %s (%i) Offset and Size\n", dac_type, dac);
	fflush(stderr);
	#endif

	DACII_WriteFPGA(device, FPGA_ADDR_REGWRITE | dac_offset, offset, fpga);
	DACII_WriteFPGA(device, FPGA_ADDR_REGWRITE | dac_size,   wf_length, fpga);

	#ifdef DEBUG
	data = DACII_ReadFPGA(device, gRegRead | dac_offset, fpga);
	fprintf(stderr,"Offset set to: %i\n", data);

	data = DACII_ReadFPGA(device, gRegRead | dac_size, fpga);

	fprintf(stderr,"Size set to: %i\n", data);
	fflush(stderr);

	fprintf(stderr,"Loading %s (%i) Waveform ...\n", dac_type, dac);
	fflush(stderr);

	#endif

	#ifdef LOG_WAVEFORM
	logwaveform = fopen("waveform.out", "w");
	#endif

	// addjust start of writing by offset
	dac_write += offset;

	
	#define ADDRDATASIZE 5
	
	formated_length  = ADDRDATASIZE * ByteCount;  // Expanded length 1 byte command 2 bytes addr 2 bytes data per data sample
	formatedData = (BYTE *) malloc(formated_length);
	if (!formatedData)
		return -5;
	formatedDataIdx = formatedData;
	
	// Format data as would be expected for FPGA
	// This mimics the calls to DACII_WriteFPGA followed by DACII_WriteReg
	
	for(cnt = 0; cnt < ByteCount; cnt++) {
		DACII_FormatForFPGA(formatedDataIdx, dac_write + cnt, Data[cnt], fpga);
		formatedDataIdx += ADDRDATASIZE;
	}
	DACII_WriteBlock(device,formated_length, formatedData);
	free(formatedData);

  
  int error = 0;
  
  #if 0
  for(cnt = 0; cnt < ByteCount; cnt++) {
    data = DACII_ReadFPGA(device, dac_read + cnt, fpga);
    if (data != Data[cnt]) {
        fprintf(stderr,"Error reading back memory: cnt = %i expected 0x%x read 0x%x\n", cnt,Data[cnt], data);
        error = 1;
    }
  }

  if (!error) {
    fprintf(stderr,"Read back complete: no errors found\n");
  }
  #endif 
  
  
	#ifdef DEBUG
	fprintf(stderr,"LoadWaveform Done\n");
	#endif

	#ifdef LOG_WAVEFORM
	fclose(logwaveform);
	#endif

	#ifdef DEBUG
	data = DACII_ReadFPGA(device, gRegRead | FPGA_OFF_CSR, fpga);
	fprintf(stderr,"CSR set to: %i\n", data);
	fflush(stderr);
	#endif

	// make sure that link list mode is disabled by default
	DACII_SetLinkListMode(device, 0, 0, dac);

	// lock memory
	DACII_SetBit(device, fpga, FPGA_OFF_CSR, dac_mem_lock);

	return 0;
}

int DACII_SetBit(int device, int fpga, int addr, int mask)
/********************************************************************
 *
 * Function Name : DACII_SetBit()
 *
 * Description : Sets Bit in FPGA register
 *
 * Inputs : FPGA - FPGA ID
 *              ADDR - Register Address
 *              MASK - bit mask
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
	int current_state;
	current_state = DACII_ReadFPGA(device, gRegRead | addr, fpga);
	#ifdef DEBUG
	fprintf(stderr,"Current State: 0x%x Writing 0x%x\n", current_state, current_state | mask);
	fflush(stderr);
	#endif
	DACII_WriteFPGA(device, FPGA_ADDR_REGWRITE | addr, current_state | mask, fpga);
}

int DACII_ClearBit(int device, int fpga, int addr, int mask)
/********************************************************************
 *
 * Function Name : DACII_ClearBit()
 *
 * Description : Clears Bit in FPGA register
 *
 * Inputs : FPGA - FPGA ID
 *              ADDR - Register Address
 *              MASK - bit mask
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
	int current_state;
	current_state = DACII_ReadFPGA(device, gRegRead | addr, fpga);
	#ifdef debug
	fprintf(stderr,"Current State: 0x%x Writing 0x%x\n", current_state, current_state & ~mask);
	fflush(stderr);
	#endif
	DACII_WriteFPGA(device, FPGA_ADDR_REGWRITE | addr, current_state & ~mask, fpga);
}


EXPORT int DACII_TriggerDac(int device, int dac, int trigger_type)
/********************************************************************
 *
 * Function Name : DACII_TriggerDac()
 *
 * Description : Triggers DAC
 *
 * Inputs : dac - dac id
 *               trigger_type  - 1 software 2 hardware
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
	int fpga;
	char * dac_type;
	int dac_sm_enable, dac_sw_led, dac_trig_src, dac_sw_trig, dac_sm_reset;
	int current_state;

	#ifdef DEBUG
	fprintf(stderr,"Trigger DAC%i type %i \n", dac, trigger_type);
	fflush(stderr);
	#endif

	fpga = dac2fpga(dac);
	if (fpga < 0) {
		return -1;
	}

	// setup register addressing based on DAC
	switch(dac) {
		case 0:
			// fall through
		case 2:
			dac_type      = ENVELOPE;
			dac_sw_led    = TRIGLEDMSK_SWLED0;
			dac_sw_trig   = TRIGLEDMSK_ENVSWTRIG;
			if (gBitFileVersion < VERSION_ELL) {
				dac_sm_enable = CSRMSK_ENVSMEN;
				dac_trig_src  = CSRMSK_ENVTRIGSRC ;
				dac_sm_reset  = CSRMSK_ENVSMRST;
			} else {
				dac_sm_enable = CSRMSK_ENVSMEN_ELL;
				dac_trig_src  = CSRMSK_ENVTRIGSRC_ELL;
				dac_sm_reset  = CSRMSK_ENVSMRST_ELL;
			}


			break;
		case 1:
			// fall through
		case 3:
			dac_type      = PHASE;
			dac_sw_led    = TRIGLEDMSK_SWLED1;
			dac_sw_trig   = TRIGLEDMSK_PHSSWTRIG;
			if (gBitFileVersion < VERSION_ELL) {
				dac_sm_enable = CSRMSK_PHSSMEN;
				dac_trig_src  = CSRMSK_PHSTRIGSRC ;
				dac_sm_reset  = CSRMSK_PHSSMRST;
			} else {
				dac_sm_enable = CSRMSK_PHSSMEN_ELL;
				dac_trig_src  = CSRMSK_PHSTRIGSRC_ELL;
				dac_sm_reset  = CSRMSK_PHSSMRST_ELL;
			}
			break;
		default:
			return -2;
	}

	DACII_ClearBit(device, fpga,FPGA_OFF_CSR, dac_sm_reset);

	#ifdef DEBUG
	fprintf(stderr, "Enable %s State Machine ... \n", dac_type);
	fflush(stderr);
	#endif

	DACII_SetBit(device, fpga,FPGA_OFF_CSR, dac_sm_enable);

	#ifdef DEBUG
	fprintf(stderr,"Current CSR: %x TRIGLED %i\n",
		 DACII_ReadFPGA(device, gRegRead | FPGA_OFF_CSR, fpga),
		 DACII_ReadFPGA(device, gRegRead | FPGA_OFF_TRIGLED, fpga)
		);
	fflush(stderr);
	#endif

	if (trigger_type == SOFTWARE_TRIGGER) {
		#ifdef DEBUG
		fprintf(stderr, "Trigger %s State Machine ... \n", dac_type);
		#endif
		DACII_ClearBit(device, fpga, FPGA_OFF_CSR, dac_trig_src);
	    DACII_SetBit(device, fpga, FPGA_OFF_TRIGLED, dac_sw_trig);

	} else if (trigger_type == HARDWARE_TRIGGER) {

		DACII_ClearBit(device, fpga, FPGA_OFF_TRIGLED, dac_sw_trig);

		#ifdef DEBUG
		fprintf(stderr,"Setting HW Trigger ... \n");
		#endif
		DACII_SetBit(device, fpga, FPGA_OFF_CSR, dac_trig_src);

	} else {
		#ifdef DEBUG
		fprintf(stderr, "Invalid Trigger Type\n");
		#endif
		return -1;
	}


	return 0;
}

EXPORT int DACII_PauseDac(int device, int dac)
/********************************************************************
 *
 * Function Name : DACII_PauseDac()
 *
 * Description :  Pauses DAC
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
	int fpga;
	char * dac_type;
	int dac_sw_trig, dac_trig_src, dac_sm_reset, dac_sm_enable, current_state;

	fpga = dac2fpga(dac);
	if (fpga < 0) {
		return -1;
	}

	#ifdef DEBUG
	fprintf(stderr,"Pause FPGA%i DAC%i\n", fpga, dac);
	fflush(stderr);
	#endif

	switch(dac) {
		case 0:
			// fall through
		case 2:
			dac_type      = ENVELOPE;
			dac_sw_trig   = TRIGLEDMSK_ENVSWTRIG;
			if (gBitFileVersion < VERSION_ELL) {
				dac_trig_src  = CSRMSK_ENVTRIGSRC ;
				dac_sm_reset  = CSRMSK_ENVSMRST;
				dac_sm_enable = CSRMSK_ENVSMEN;
			} else {
				dac_trig_src  = CSRMSK_ENVTRIGSRC_ELL;
				dac_sm_reset  = CSRMSK_ENVSMRST_ELL;
				dac_sm_enable = CSRMSK_ENVSMEN_ELL;
			}


			break;
		case 1:
			// fall through
		case 3:
			dac_type      = PHASE;
			dac_sw_trig   = TRIGLEDMSK_PHSSWTRIG;
			if (gBitFileVersion < VERSION_ELL) {
						dac_trig_src  = CSRMSK_PHSTRIGSRC ;
						dac_sm_reset  = CSRMSK_PHSSMRST;
						dac_sm_enable = CSRMSK_PHSSMEN;
			} else {
				dac_trig_src  = CSRMSK_PHSTRIGSRC_ELL;
				dac_sm_reset  = CSRMSK_PHSSMRST_ELL;
				dac_sm_enable = CSRMSK_PHSSMEN_ELL;
			}
			break;
		default:
			return -2;
	}

	DACII_ClearBit(device, fpga,FPGA_OFF_TRIGLED, dac_sw_trig);
	DACII_ClearBit(device, fpga,FPGA_OFF_CSR, dac_sm_enable);
	return 0;
}

EXPORT int DACII_DisableDac(int device, int dac)
/********************************************************************
 *
 * Function Name : DACII_DisableDac()
 *
 * Description : Disables DAC
 *
 * Inputs : dac - dac ID
 *
 * Returns : 0  on success
 *
 * Error Conditions :
 *
 * Unit Tested on:
 *
 * Unit Tested by:
 *
 ********************************************************************/
{

	int fpga;
	char *dac_type;
	int dac_sm_reset, dac_offset, dac_sm_enable, current_state, dac_sw_trig;

	fpga = dac2fpga(dac);
	if (fpga < 0) {
		return -1;
	}

	#ifdef DEBUG
	fprintf(stderr,"Disable FPGA%i DAC%i\n", fpga, dac);
	fflush(stderr);
	#endif

	switch(dac) {
		case 0:
			// fall through
		case 2:
			dac_type      = ENVELOPE;
			dac_offset    = FPGA_OFF_ENVOFF;
			dac_sw_trig   = TRIGLEDMSK_ENVSWTRIG;
			if (gBitFileVersion < VERSION_ELL) {
				dac_sm_reset  = CSRMSK_ENVSMRST;
				dac_sm_enable = CSRMSK_ENVSMEN ;
			} else {
				dac_sm_reset  = CSRMSK_ENVSMRST_ELL;
				dac_sm_enable = CSRMSK_ENVSMEN_ELL;
			}

			break;
		case 1:
			// fall through
		case 3:
			dac_type      = PHASE;
			dac_offset    = FPGA_OFF_PHSOFF;
			dac_sw_trig   = TRIGLEDMSK_PHSSWTRIG;
			if (gBitFileVersion < VERSION_ELL) {
				dac_sm_reset  = CSRMSK_PHSSMRST;
				dac_sm_enable = CSRMSK_PHSSMEN ;
			} else {
				dac_sm_reset  = CSRMSK_PHSSMRST_ELL;
				dac_sm_enable = CSRMSK_PHSSMEN_ELL;
			}

			break;
		default:
			return -2;
	}

	#ifdef DEBUG
	fprintf(stderr, "Disable %s State Machine ... \n", dac_type);
	#endif


	DACII_ClearBit(device, fpga,FPGA_OFF_TRIGLED, dac_sw_trig);
	DACII_ClearBit(device, fpga,FPGA_OFF_CSR, dac_sm_enable);


	#ifdef DEBUG
	fprintf(stderr, "Reset %s State Machine ... \n", dac_type);
	fflush(stderr);
	#endif

	DACII_SetBit(device, fpga,FPGA_OFF_CSR, dac_sm_reset);
	return 0;
}


int LoadLinkList_V5(int device, unsigned short *OffsetData, unsigned short *CountData,
		            int length, int dac)
/********************************************************************
 *
 * Function Name : DACII_LoadLinkList()
 *
 * Description : Loads LinkList to FPGA
 *
 * Inputs :
*              OffsetData - pointer to link list offsets
*              CountData - pointer to link list counts
*              length - length of link list
*              Dac - dac ID
*
* Returns : 0 on success < 0 on failure
*
* Error Conditions :
*
* Unit Tested on:
*
* Unit Tested by:
*
********************************************************************/
{
	int dac_shift, dac_write_offset, dac_write_cnt;
	int fpga;
	int cnt;
	char * dac_type;
	int ctrl_reg;

	ULONG write_addr;
	ULONG data;
	ULONG wf_length;

	BYTE * formatedData;
	BYTE * formatedDataIdx;
	int formated_length;

	fpga = dac2fpga(dac);
	if (fpga < 0) {
		return -1;
	}

	#ifdef DEBUG
	fprintf(stderr,"Loading LinkList length %i into FPGA%i DAC%i \n", length, fpga, dac);
	fflush(stderr);
	#endif

	// setup register addressing based on DAC
	switch(dac) {
		case 0:
			// fall through
		case 2:
			dac_type   			= ENVELOPE;
			dac_shift 			= LL_SIZE_ENVSHIFT;
			dac_write_offset 	= FPGA_ADDR_ENVLLOFF_WRITE;
			dac_write_cnt 		= FPGA_ADDR_ENVLLCNT_WRITE;
			break;
		case 1:
			// fall through
		case 3:
			dac_type   			= PHASE;
			dac_shift 			= LL_SIZE_PHSSHIFT;
			dac_write_offset 	= FPGA_ADDR_PHSLLOFF_WRITE;
			dac_write_cnt 		= FPGA_ADDR_PHSLLCNT_WRITE;
			break;
		default:
			return -2;
	}

	if ( length > MAX_LL_LENGTH)  {
		return -3;
	}

	// load current cntrl reg
	ctrl_reg = DACII_ReadFPGA(device, gRegRead | FPGA_OFF_LLCTRL, fpga);

#ifdef DEBUG
	fprintf(stderr,"Current Link List Control Reg: 0x%x\n", ctrl_reg);
	fflush(stderr);
#endif

	// zero current dac settings
	ctrl_reg &= ~(0xFF << dac_shift);

#ifdef DEBUG
	fprintf(stderr,"Zeroed Link List Control Reg: 0x%x\n", ctrl_reg);
	fflush(stderr);
#endif

	//set link list size
	ctrl_reg |= (length << dac_shift);

	//length = length - 1;

	#ifdef DEBUG
	fprintf(stderr,"Writing Link List Control Reg: 0x%x\n", ctrl_reg);
	fflush(stderr);
	#endif

	// write control reg
	DACII_WriteFPGA(device, FPGA_ADDR_REGWRITE | FPGA_OFF_LLCTRL, ctrl_reg, fpga);

	// load current cntrl reg
	ctrl_reg = DACII_ReadFPGA(device, gRegRead | FPGA_OFF_LLCTRL, fpga);

#ifdef DEBUG
	fprintf(stderr,"Written Link List Control Reg: 0x%x\n", ctrl_reg);
	fflush(stderr);
#endif

	#ifdef DEBUG
	fprintf(stderr,"Loading Link List %s DAC%i...\n", dac_type, dac);
	fflush(stderr);
	#endif

	// Expanded length 1 byte command 2 bytes addr 2 bytes data per data sample
	// * 2 from two entries offset and count
	formated_length  = ADDRDATASIZE * 2 * length;
	formatedData = (BYTE *) malloc(formated_length);
	if (!formatedData)
		return -5;
	formatedDataIdx = formatedData;

	// Format data as would be expected for FPGA
	// This mimics the calls to DACII_WriteFPGA followed by DACII_WriteReg

	for(cnt = 0; cnt < length; cnt++) {
		DACII_FormatForFPGA(formatedDataIdx, dac_write_offset + cnt,OffsetData[cnt], fpga );
		formatedDataIdx += ADDRDATASIZE;
		DACII_FormatForFPGA(formatedDataIdx, dac_write_cnt + cnt, CountData[cnt], fpga );
		formatedDataIdx += ADDRDATASIZE;
	}
	DACII_WriteBlock(device,formated_length, formatedData);
	free(formatedData);

	#ifdef DEBUG
	fprintf(stderr,"Done\n");
	fflush(stderr);
	#endif

	return 0;
}

int LoadLinkList_ELL(int device, unsigned short *OffsetData, unsigned short *CountData,
		             unsigned short *TriggerData, unsigned short *RepeatData,
		             int length, int dac, int bank)
/********************************************************************
 *
 * Function Name : LoadLinkList()
 *
 * Description : Loads LinkList to FPGA Enhanced Link List Mode
 *
 * Inputs :
*              OffsetData - pointer to link list offsets
*              CountData - pointer to link list counts
*              length - length of link list
*              Dac - dac ID
*
* Returns : 0 on success < 0 on failure
*
* Error Conditions :
*
* Unit Tested on:
*
* Unit Tested by:
*
********************************************************************/
{
	int dac_write;
	int dac_ctrl_reg, dac_rpt_reg;
	int fpga;
	int cnt;
	char * dac_type;
	int ctrl_reg;

	ULONG write_addr;
	ULONG data;
	ULONG wf_length;

	BYTE * formatedData;
	BYTE * formatedDataIdx;
	int formated_length;

	fpga = dac2fpga(dac);
	if (fpga < 0) {
		return -1;
	}

	if (gBitFileVersion < VERSION_ELL) {
		fprintf(stderr,"ERROR => Hardware Version: %i does not support ELL mode.\n", gBitFileVersion);
		fflush(stderr);
		return -1;
	}

	#ifdef DEBUG
	fprintf(stderr,"Loading LinkList length %i into FPGA%i DAC%i \n", length, fpga, dac);
	fflush(stderr);
	#endif

	// setup register addressing based on DAC
	switch(dac) {
		case 0:
			// fall through
		case 2:
			dac_type = ENVELOPE;
			if (bank == 0) {
				dac_write = FPGA_ADDR_ELL_ENVLL_A_WRITE;
				dac_ctrl_reg = FGPA_OFF_ELL_ENVLL_A_CTRL;
			} else {
				dac_write = FPGA_ADDR_ELL_ENVLL_B_WRITE;
				dac_ctrl_reg = FGPA_OFF_ELL_ENVLL_B_CTRL;
			}
			dac_rpt_reg  = FGPA_OFF_ELL_ENVLL_REPEAT;
			break;
		case 1:
			// fall through
		case 3:
			dac_type = PHASE;
			if (bank == 0) {
				dac_write    = FPGA_ADDR_ELL_PHSLL_A_WRITE;
				dac_ctrl_reg = FGPA_OFF_ELL_PHSLL_A_CTRL;
			} else {
				dac_write = FPGA_ADDR_ELL_PHSLL_B_WRITE;
				dac_ctrl_reg = FGPA_OFF_ELL_PHSLL_B_CTRL;
			}
			dac_rpt_reg  = FGPA_OFF_ELL_PHSLL_REPEAT;
			break;
		default:
			return -2;
	}

	if ( length > MAX_LL_LENGTH_ELL)  {
		return -3;
	}

	// load current cntrl reg
	ctrl_reg = DACII_ReadFPGA(device, gRegRead | dac_ctrl_reg, fpga);

#ifdef DEBUG
	fprintf(stderr,"ELL: Current Link List Control Reg: 0x%x\n", ctrl_reg);
	fflush(stderr);
#endif

	// zero current dac settings
	ctrl_reg &= ~0xFF;

#ifdef DEBUG
	fprintf(stderr,"Zeroed Link List Control Reg: 0x%x\n", ctrl_reg);
	fflush(stderr);
#endif

	//set link list size
	// ELL Mode does not require shift due to different control registers
	ctrl_reg |= length;

	//length = length - 1;

	#ifdef DEBUG
	fprintf(stderr,"Writing Link List Control Reg: 0x%x\n", ctrl_reg);
	fflush(stderr);
	#endif

	// write control reg
	DACII_WriteFPGA(device, FPGA_ADDR_REGWRITE | dac_ctrl_reg, ctrl_reg, fpga);

	// load current cntrl reg
	ctrl_reg = DACII_ReadFPGA(device, gRegRead | dac_ctrl_reg, fpga);

#ifdef DEBUG
	fprintf(stderr,"Written Link List Control Reg: 0x%x\n", ctrl_reg);
	fflush(stderr);
#endif

	#ifdef DEBUG
	fprintf(stderr,"Loading Link List %s DAC%i...\n", dac_type, dac);
	fflush(stderr);
	#endif


	// ADDRDATASIZE_ELL 1 cmd 2 addr 2 offset 2 count 2 trigger 2 repeat
#define ADDRDATASIZE_ELL 11
	formated_length  = ADDRDATASIZE_ELL * length;  // Expanded length 1 byte command 2 bytes addr 2 bytes data per data sample
	formatedData = (BYTE *) malloc(formated_length);
	if (!formatedData)
		return -5;
	formatedDataIdx = formatedData;

	// Format data as would be expected for FPGA
	// This mimics the calls to DACII_WriteFPGA followed by DACII_WriteReg

	for(cnt = 0; cnt < length; cnt++) {
		DACII_FormatForFPGA_ELL(formatedDataIdx, dac_write + cnt,
								OffsetData[cnt], CountData[cnt],
								TriggerData[cnt], RepeatData[cnt],
								fpga );
		formatedDataIdx += ADDRDATASIZE_ELL;
	}
	DACII_WriteBlock(device,formated_length, formatedData);
	free(formatedData);

	// zero repeat register
	DACII_WriteFPGA(device, FPGA_ADDR_REGWRITE | dac_rpt_reg, 0, fpga);

	#ifdef DEBUG
	fprintf(stderr,"Done\n");
	fflush(stderr);
	#endif

	return 0;
}

EXPORT int DACII_LoadLinkList(int device,
		                          unsigned short *OffsetData, unsigned short *CountData,
		                          unsigned short *TriggerData, unsigned short *RepeatData,
		                          int length, int dac, int bank)
{

	if (gBitFileVersion < VERSION_ELL) {
		return LoadLinkList_V5(device, OffsetData, CountData, length, dac);
	} else {
		return LoadLinkList_ELL(device, OffsetData, CountData, TriggerData, RepeatData,
				         length, dac, bank);
	}

}

EXPORT int DACII_SetLinkListRepeat(int device, unsigned short repeat, int dac) {
	int dac_rpt_reg;
	int fpga;
	int cnt;
	char * dac_type;

	fpga = dac2fpga(dac);
	if (fpga < 0) {
		return -1;
	}

	if (gBitFileVersion < VERSION_ELL) {
		fprintf(stderr,"ERROR => Hardware Version: %i does not support ELL mode.\n", gBitFileVersion);
		fflush(stderr);
		return -1;
	}

	// setup register addressing based on DAC
	switch(dac) {
		case 0:
			// fall through
		case 2:
			dac_type = ENVELOPE;
			dac_rpt_reg  = FGPA_OFF_ELL_ENVLL_REPEAT;
			break;
		case 1:
			// fall through
		case 3:
			dac_type = PHASE;
			dac_rpt_reg  = FGPA_OFF_ELL_PHSLL_REPEAT;
			break;
		default:
			return -2;
	}
	// zero repeat register
	DACII_WriteFPGA(device, FPGA_ADDR_REGWRITE | dac_rpt_reg, repeat, fpga);

	fprintf(stderr,"SET: FPGA: %i Dac: %s Repeat Count: %i\n", fpga, dac_type, repeat);
	fflush(stderr);
	return 0;
}

EXPORT int DACII_SetLinkListMode(int device, int enable, int mode, int dac)
/********************************************************************
 *
 * Function Name : DACII_LoadLinkList()
 *
 * Description : Loads LinkList to FPGA
 *
 * Inputs :
*              enable -  enable link list 1 = enabled 0 = disabled
*              mode - 1 = DC mode 0 = waveform mode
*              dac - dac ID
*
* Returns : 0 on success < 0 on failure
*
* Error Conditions :
*
* Unit Tested on:
*
* Unit Tested by:
*
********************************************************************/
{
	int fpga;
	int dac_enable_mask, dac_mode_mask, ctrl_reg;
	char *dac_type;

	fpga = dac2fpga(dac);
	if (fpga < 0) {
		return -1;
	}

	// setup register addressing based on DAC
	switch(dac) {
		case 0:
			// fall through
		case 2:
			dac_type   		= ENVELOPE;
			dac_enable_mask = LLMSK_ENVENABLE;
			dac_mode_mask 	= LLMSK_ENVMODE;

			break;
		case 1:
			// fall through
		case 3:
			dac_type   		= PHASE;
			dac_enable_mask = LLMSK_PHSENABLE;
			dac_mode_mask 	= LLMSK_PHSMODE;
			break;
		default:
			return -2;
	}

	if (enable < 0 && enable > 1) {
		return -3;
	}

	if (mode < 0 && mode > 1) {
		return -4;
	}

	#ifdef DEBUG
	fprintf(stderr, "Setting Link List Enable ==> FPGA: %i DAC: %i Enable: %i\n", fpga, dac, enable);
	#endif

	// load current cntrl reg
	ctrl_reg = DACII_ReadFPGA(device, gRegRead | FPGA_OFF_LLCTRL, fpga);

	fprintf(stderr,"Current Link List Control Reg: 0x%x\n", ctrl_reg);
	fflush(stderr);

	if (enable) {
		DACII_SetBit(device, fpga, FPGA_OFF_LLCTRL, dac_enable_mask);
	} else {
		DACII_ClearBit(device, fpga, FPGA_OFF_LLCTRL, dac_enable_mask);
	}

	#ifdef DEBUG
	fprintf(stderr, "Setting Link List Mode ==> FPGA: %i DAC: %i Mode: %i\n", fpga, dac, mode);
	#endif

	if (mode) {
		DACII_SetBit(device, fpga, FPGA_OFF_LLCTRL, dac_mode_mask);
	} else {
		DACII_ClearBit(device, fpga, FPGA_OFF_LLCTRL, dac_mode_mask);
	}

	#ifdef debug
	fflush(stderr);
	#endif
	return 0;
}

EXPORT int DACII_TriggerFpga(int device, int dac, int trigger_type)
/********************************************************************
 *
 * Function Name : DACII_TriggerFPGA()
 *
 * Description : Triggers Both DACs on FPGA at the same time
 *
 * Inputs : dac - dac id
 *               trigger_type  - 1 software 2 hardware
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
	int fpga;
	char * dac_type;
	int dac_sm_enable, dac_sw_led, dac_trig_src, dac_sw_trig, dac_sm_reset;
	int current_state;

	#ifdef DEBUG
	fprintf(stderr,"Trigger FPGA DAC%i type %i \n", dac, trigger_type);
	fflush(stderr);
	#endif

	fpga = dac2fpga(dac);
	if (fpga < 0) {
		return -1;
	}

	// setup register addressing based on DAC
	// strictly speaking the switch is not needed
	// but it is here to maintain a similar structure
	// to TriggerDAC and validate the input value of
	// the variable dac
	switch(dac) {
		case 0:
			// fall through
		case 1:
			// fall through
		case 2:
			// fall through
		case 3:
			dac_type      = BOTH_DACS;
			dac_sw_led    = TRIGLEDMSK_SWLED0 | TRIGLEDMSK_SWLED1;
			dac_sw_trig   = TRIGLEDMSK_ENVSWTRIG | TRIGLEDMSK_PHSSWTRIG;
			if (gBitFileVersion < VERSION_ELL) {
				dac_sm_enable = CSRMSK_ENVSMEN | CSRMSK_PHSSMEN;
				dac_trig_src  = CSRMSK_ENVTRIGSRC | CSRMSK_PHSTRIGSRC;
				dac_sm_reset  = CSRMSK_ENVSMRST | CSRMSK_PHSSMRST;
			} else {
				dac_sm_enable = CSRMSK_ENVSMEN_ELL | CSRMSK_PHSSMEN_ELL ;
				dac_trig_src  = CSRMSK_ENVTRIGSRC_ELL | CSRMSK_PHSTRIGSRC_ELL;
				dac_sm_reset  = CSRMSK_ENVSMRST_ELL | CSRMSK_PHSSMRST_ELL ;
			}

			break;
		default:
			return -2;
	}

	DACII_ClearBit(device, fpga,FPGA_OFF_CSR, dac_sm_reset);

	#ifdef DEBUG
	fprintf(stderr, "Enable %s State Machine ... \n", dac_type);
	fflush(stderr);
	#endif

	DACII_SetBit(device, fpga,FPGA_OFF_CSR, dac_sm_enable);

	#ifdef DEBUG
	fprintf(stderr,"Current CSR: %x TRIGLED %i\n",
		 DACII_ReadFPGA(device, gRegRead | FPGA_OFF_CSR, fpga),
		 DACII_ReadFPGA(device, gRegRead | FPGA_OFF_TRIGLED, fpga)
		);
	fflush(stderr);
	#endif

	if (trigger_type == SOFTWARE_TRIGGER) {
		#ifdef DEBUG
		fprintf(stderr, "Trigger %s State Machine ... \n", dac_type);
		#endif
		DACII_ClearBit(device, fpga, FPGA_OFF_CSR, dac_trig_src);
	    DACII_SetBit(device, fpga, FPGA_OFF_TRIGLED, dac_sw_trig);

	} else if (trigger_type == HARDWARE_TRIGGER) {

		DACII_ClearBit(device, fpga, FPGA_OFF_TRIGLED, dac_sw_trig);

		#ifdef DEBUG
		fprintf(stderr,"Setting HW Trigger ... \n");
		#endif
		DACII_SetBit(device, fpga, FPGA_OFF_CSR, dac_trig_src);

	} else {
		#ifdef DEBUG
		fprintf(stderr, "Invalid Trigger Type\n");
		#endif
		return -1;
	}


	return 0;
}

EXPORT int DACII_PauseFpga(int device, int dac)
/********************************************************************
 *
 * Function Name : DACII_PauseFPGA()
 *
 * Description :  Pauses both DACs on a signal FPGA
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
	int fpga;
	char * dac_type;
	int dac_sw_trig, dac_trig_src, dac_sm_reset, dac_sm_enable, current_state;

	fpga = dac2fpga(dac);
	if (fpga < 0) {
		return -1;
	}

	#ifdef DEBUG
	fprintf(stderr,"Pause FPGA%i DAC%i\n", fpga, dac);
	fflush(stderr);
	#endif

	switch(dac) {
		case 0:
			// fall through
		case 1:
			// fall through
		case 2:
			// fall through
		case 3:
			dac_type      = BOTH_DACS;
			dac_sw_trig   = TRIGLEDMSK_ENVSWTRIG | TRIGLEDMSK_PHSSWTRIG;

			if (gBitFileVersion < VERSION_ELL) {
				dac_trig_src  = CSRMSK_ENVTRIGSRC | CSRMSK_PHSTRIGSRC;
				dac_sm_reset  = CSRMSK_ENVSMRST | CSRMSK_PHSSMRST;
				dac_sm_enable = CSRMSK_ENVSMEN | CSRMSK_PHSSMEN;
			} else {
				dac_trig_src  = CSRMSK_ENVTRIGSRC_ELL | CSRMSK_PHSTRIGSRC_ELL ;
				dac_sm_reset  = CSRMSK_ENVSMRST_ELL | CSRMSK_PHSSMRST_ELL;
				dac_sm_enable = CSRMSK_ENVSMEN_ELL | CSRMSK_PHSSMEN_ELL;
			}


			break;
		default:
			return -2;
	}

	DACII_ClearBit(device, fpga,FPGA_OFF_TRIGLED, dac_sw_trig);
	DACII_ClearBit(device, fpga,FPGA_OFF_CSR, dac_sm_enable);
	return 0;
}

EXPORT int DACII_DisableFpga(int device, int dac)
/********************************************************************
 *
 * Function Name : DACII_DisableFPGA()
 *
 * Description : Disables both DACs on a singal FPGA
 *
 * Inputs : dac - dac ID
 *
 * Returns : 0  on success
 *
 * Error Conditions :
 *
 * Unit Tested on:
 *
 * Unit Tested by:
 *
 ********************************************************************/
{

	int fpga;
	char *dac_type;
	int dac_sm_reset, dac_sm_enable, current_state, dac_sw_trig;

	fpga = dac2fpga(dac);
	if (fpga < 0) {
		return -1;
	}

	#ifdef DEBUG
	fprintf(stderr,"Disable FPGA%i DAC%i\n", fpga, dac);
	fflush(stderr);
	#endif

	switch(dac) {
		case 0:
			// fall through
		case 1:
			// fall through
		case 2:
			// fall through
		case 3:
			dac_type      = BOTH_DACS;
			dac_sw_trig   = TRIGLEDMSK_ENVSWTRIG | TRIGLEDMSK_PHSSWTRIG;

			if ( gBitFileVersion < VERSION_ELL) {
				dac_sm_reset  = CSRMSK_ENVSMRST | CSRMSK_PHSSMRST;
				dac_sm_enable = CSRMSK_ENVSMEN | CSRMSK_PHSSMEN;
			} else {
				dac_sm_reset  = CSRMSK_ENVSMRST_ELL | CSRMSK_PHSSMRST_ELL;
				dac_sm_enable = CSRMSK_ENVSMEN_ELL | CSRMSK_PHSSMEN_ELL;
			}

			break;
		default:
			return -2;
	}

	#ifdef DEBUG
	fprintf(stderr, "Disable %s State Machine ... \n", dac_type);
	#endif


	DACII_ClearBit(device, fpga,FPGA_OFF_TRIGLED, dac_sw_trig);
	DACII_ClearBit(device, fpga,FPGA_OFF_CSR, dac_sm_enable);


	#ifdef DEBUG
	fprintf(stderr, "Reset %s State Machine ... \n", dac_type);
	fflush(stderr);
	#endif

	DACII_SetBit(device, fpga,FPGA_OFF_CSR, dac_sm_reset);
	return 0;
}



EXPORT int DACII_ReadBitFileVersion(int device) {
	// Reads version information from device
	// Location to read version from moved between r 0x5 and 0x10
	// so we read assuming r 0x5 and then try the location for r 0x10
	int version;
	int fpga = 1;

	version = DACII_ReadFPGA(device, FPGA_ADDR_REGREAD | FPGA_OFF_VERSION, fpga);

	if (version == -1) { // tried to read invalid address
		version = DACII_ReadFPGA(device, FPGA_ADDR_ELL_REGREAD | FPGA_OFF_VERSION, fpga);
	}
	fprintf(stderr, "Found BitFile Version %i\n", version);
	fflush(stderr);
	gBitFileVersion = version;
	gRegRead = (version >= VERSION_ELL) ? FPGA_ADDR_ELL_REGREAD : FPGA_ADDR_REGREAD;
	return version;
}
