/**********************************************
* Module Name : fpga.c
*
* Author/Date : B.C. Donovan / 21-Oct-08
*
* Description : Private fpga functions for libaps.dll
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
* $Author: bdonovan $
* $Date$
* $Locker:  $
* $Name:  $
* $Revision$
*
* Copyright (C) BBN Technologies Corp. 2008- 2011
**********************************************/

#ifdef WIN32
  #include <windows.h>
#endif

#include <stdio.h>
#include <unistd.h>
#include "aps.h"
#include "fpga.h"
#include "libaps.h"
#include "common.h"

#ifdef LOG_WRITE_FPGA
FILE * outfile = 0;
#endif

int gBitFileVersion = 0; // set default version to 0 as all valid version numbers are > 0
int gRegRead =  FPGA_ADDR_REGREAD; // register read address to or
WORD gCheckSum[MAX_APS_DEVICES][2] = {0}; // checksum for data written to each fpga
WORD gAddrCheckSum[MAX_APS_DEVICES][2] = {0}; // checksum for addresses written to each fpga

int APS_FormatForFPGA(BYTE * buffer, ULONG addr, ULONG data, UCHAR fpga)
{
	BYTE cmd;
	cmd = APS_FPGA_IO | (fpga<<2) | 2;

	buffer[0] = cmd;
	buffer[1] = (addr >> 8) & LSB_MASK;
	buffer[2]  = addr & LSB_MASK;
	buffer[3]  = (data >> 8) & LSB_MASK;
	buffer[4]  = data & LSB_MASK;
	return 0;
}

int APS_FormatForFPGA_ELL(BYTE * buffer, ULONG addr,
		                    ULONG offset, ULONG count,
		                    ULONG trigger, ULONG repeat, UCHAR fpga)
{
	BYTE cmd;

	cmd = APS_FPGA_IO | (fpga<<2) | 2;

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

EXPORT int APS_WriteFPGA(int device, ULONG addr, ULONG data, UCHAR fpga)
/********************************************************************
 *
 * Function Name : APS_WriteFPGA()
 *
 * Description :  Writes data to FPGA. 16 bit numbers are unpacked to 2 bytes
 *
 * Inputs :
 *               Addr  - Address to write to
 *              Data   - Data to write
 *              FPGA - FPGA selection bit (1 or 2, 3 = both)
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

	// address checksum is defined as (bits 0-11: addr, 12-14: cmd, 15: 0)
	// since the cmd is always = 000, we can mimic this by settings bits 12-15 to zero
	if (fpga == 3) {
		gAddrCheckSum[device][0] += addr & 0xFFF;
		gCheckSum[device][0] += data;
		gAddrCheckSum[device][1] += addr & 0xFFF;
		gCheckSum[device][1] += data;
	} else {
		gAddrCheckSum[device][fpga - 1] += addr & 0xFFF;
		gCheckSum[device][fpga - 1] += data;
	}

	dlog(DEBUG_VERBOSE2,"Writting Addr 0x%x Data 0x%x\n", addr, data);

	APS_WriteReg(device, APS_FPGA_IO, 2, fpga, outdata);
}

EXPORT int APS_CompareCheckSum(int device, int fpga) {
	// returns true (1) if both the address and data checksums match, otherwise returns 0
	unsigned int data_checksum, addr_checksum;
	if (fpga < 0 || fpga == 3) {
		return -1;
	}
	data_checksum = APS_ReadFPGA(device, gRegRead | FPGA_OFF_DATA_CHECKSUM, fpga);
	addr_checksum = APS_ReadFPGA(device, gRegRead | FPGA_OFF_ADDR_CHECKSUM, fpga);
	
	int success = ((data_checksum == gCheckSum[device][fpga - 1]) &&
		(addr_checksum == gAddrCheckSum[device][fpga-1]));
	
	dlog(DEBUG_INFO, "Checksum Addr: 0x%x (0x%x), Data: 0x%x (0x%x), Success: %d\n", addr_checksum, gAddrCheckSum[device][fpga-1], data_checksum, gCheckSum[device][fpga-1], success);
	
	return success;
}

EXPORT UINT APS_ResetCheckSum(int device, int fpga) {
	gCheckSum[device][fpga-1] = 0;
	gAddrCheckSum[device][fpga-1] = 0;
	// write to registers to clear them
	APS_WriteFPGA(device, FPGA_OFF_DATA_CHECKSUM, 0, fpga);
	APS_WriteFPGA(device, FPGA_OFF_ADDR_CHECKSUM, 0, fpga);
}

EXPORT UINT APS_ResetAllCheckSum() {
	int i;
	for (i = 0; i < MAX_APS_DEVICES; i++) {
		gCheckSum[i][0] = 0;
		gCheckSum[i][1] = 0;
		gAddrCheckSum[i][0] = 0;
		gAddrCheckSum[i][1] = 0;
	}
}


EXPORT ULONG APS_ReadFPGA(int device, ULONG addr, UCHAR fpga)
/********************************************************************
 *
 * Function Name : APS_ReadFPGA()
 *
 * Description : Read data from FPGA
 *
 * Inputs : Addr  - Address to write to
 *              FPGA - FPGA selection bit (1 or 2)
 *
 * Returns : Data at address
 *
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
  
	if (fpga == 3) {
		// can only read from one FPGA at a time, assume we want data from FPGA 1
		fpga = 1;
	}

	read[0] = (addr >> 8) & LSB_MASK;
	read[1] = addr & LSB_MASK;

	APS_WriteReg(device, APS_FPGA_IO, 1, fpga, read);

	read[0] = 0xBA;
	read[1] = 0xD0;

	APS_ReadReg(device, APS_FPGA_IO, 1, fpga, read);

	data = (read[0] << 8) | read[1];

	dlog(DEBUG_VERBOSE2,"Reading Addr 0x%x Data 0x%x\n", addr, data);

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

EXPORT int APS_LoadWaveform(int device, short *Data,
		                      int nbrSamples, int offset, int dac,
		                      int validate, int useSlowWrite)
/********************************************************************
 *
 * Function Name : APS_LoadWaveform()
 *
 * Description : LoadsWaveform to FPGA
 *
 * Inputs : Data - pointer to waveform buffer
 *              nbrSamples - length of waveform in samples
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

	#ifdef LOG_WAVEFORM
	FILE * logwaveform;
	#endif

	ULONG data;
	ULONG wf_length;
	ULONG max_wf_length;
	ULONG formated_length;
	
	BYTE * formatedData;
	BYTE * formatedDataIdx;

	if(gBitFileVersion < VERSION_ELL) {
		max_wf_length = K4;
	} else {
		max_wf_length = K8;
	}

	if(nbrSamples > max_wf_length ) {
		dlog(DEBUG_INFO,"[WARNING] Waveform length > Maximum. Truncating waveform");
		nbrSamples = max_wf_length;
	}

	// waveform length used by FPGA must be an integer multiple of WF_MODULUS
	wf_length = nbrSamples / WF_MODULUS - 1;


	if (nbrSamples % WF_MODULUS != 0) {
		dlog(DEBUG_VERBOSE,"[WARNING] Waveform data needs to be padded");
	}

	fpga = dac2fpga(dac);
	if (fpga < 0) {
		return -1;
	}

	dlog(DEBUG_INFO,"Loading Waveform length %i into FPGA%i DAC%i \n", nbrSamples, fpga, dac);

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

	if (offset < 0 || offset > max_wf_length) {
		return -3;
	}

	// check to make sure that waveform will fit
	if ((offset + nbrSamples) > max_wf_length) {
		return -4;
	}

	dlog(DEBUG_VERBOSE,"Initialize Control and Status Register to initial state\n");
	// State machines should be reset and DDRs enabled
	int csr_init = CSRMSK_ENVSMRST_ELL | CSRMSK_ENVDDR_ELL | CSRMSK_PHSSMRST_ELL | CSRMSK_PHSDDR_ELL;

	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | FPGA_OFF_CSR, csr_init, fpga);

	if (getDebugLevel() >= DEBUG_VERBOSE) {
		data = APS_ReadFPGA(device, gRegRead | FPGA_OFF_CSR, fpga);
		dlog(DEBUG_VERBOSE,"CSR set to: 0x%x\n", data);
		dlog(DEBUG_VERBOSE,"Initializing %s (%i) Offset and Size\n", dac_type, dac);
	}

	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | dac_offset, offset, fpga);
	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | dac_size, wf_length, fpga);

	if (getDebugLevel() >= DEBUG_VERBOSE) {
		data = APS_ReadFPGA(device, gRegRead | dac_offset, fpga);
		dlog(DEBUG_VERBOSE,"Offset set to: %i\n", data);

		data = APS_ReadFPGA(device, gRegRead | dac_size, fpga);
		dlog(DEBUG_VERBOSE,"Size set to: %i\n", data);
		dlog(DEBUG_VERBOSE,"Loading %s (%i) Waveform at 0x%x ...\n", dac_type, dac, dac_write);
	}

	int error = 0;

	#ifdef LOG_WAVEFORM
	logwaveform = fopen("waveform.out", "w");
	#endif

	// Adjust start of writing by offset
	dac_write += offset;

	#define ADDRDATASIZE 5
	
	// clear checksums
	APS_ResetCheckSum(device, fpga);

	// slow write of data one sample at a time
	UCHAR dummyRead[2];
	if (useSlowWrite != 0) {
		dlog(DEBUG_VERBOSE,"Using slow write\n");

		for(cnt = 0; cnt < nbrSamples; cnt++) {
			APS_WriteFPGA(device, dac_write + cnt, Data[cnt], fpga);
			if (cnt % 4 == 0 && cnt != 0) {
				// dummy read to slow down the cpld
				APS_ReadReg(device, APS_FPGA_IO, 1, fpga, dummyRead);
			}
		}
	} else {

	// faster buffered write

	formated_length	 = ADDRDATASIZE * nbrSamples;  // Expanded length = 1 byte command + 2 bytes addr + 2 bytes data per sample
	formatedData = (BYTE *) malloc(formated_length);
	if (!formatedData)
		return -5;
	formatedDataIdx = formatedData;

	// Format data as would be expected for FPGA
	// This mimics the calls to APS_WriteFPGA followed by APS_WriteReg

	WORD addr;
	for(cnt = 0; cnt < nbrSamples; cnt++) {
		APS_FormatForFPGA(formatedDataIdx, dac_write + cnt, Data[cnt], fpga);
		formatedDataIdx += ADDRDATASIZE;
		// address checksum is defined as (bits 0-11: addr, 12-14: cmd, 15: 0)
		// since the cmd is always = 000, we can mimic this by settings bits 12-15 to zero
		addr = dac_write + cnt;
		addr &= 0xFFF;
		gAddrCheckSum[device][fpga-1] += addr;
		gCheckSum[device][fpga-1] += Data[cnt];
	}
	APS_WriteBlock(device, formated_length, formatedData);
	free(formatedData);
	}
	
	// always verify the checksum
	data = APS_CompareCheckSum(device, fpga);
	if (!data) {
		dlog(DEBUG_INFO, "APS_LoadWaveform ERROR: Checksum does not match\n");
	}
	
	// this section does a word by word comparison of the written data
	if (validate != 0) {
		dlog(DEBUG_VERBOSE,"Validating Waveform\n");
		
		for(cnt = 0; cnt < nbrSamples; cnt++) {
			data = APS_ReadFPGA(device, dac_read + cnt, fpga);
			if (data != Data[cnt]) {
				dlog(DEBUG_VERBOSE,"Error reading back memory: cnt = %i expected 0x%x read 0x%x\n", cnt,Data[cnt], data);
				error = 1;
			}
		}
		
		if (!error) {
			dlog(DEBUG_VERBOSE,"Read back complete: no errors found\n");
		}
	}
  
	dlog(DEBUG_VERBOSE,"LoadWaveform Done\n");

	#ifdef LOG_WAVEFORM
	fclose(logwaveform);
	#endif

	if (getDebugLevel() >= DEBUG_VERBOSE) {
	    data = APS_ReadFPGA(device, gRegRead | FPGA_OFF_CSR, fpga);
	    dlog(DEBUG_VERBOSE,"CSR set to: 0x%x\n", data);
	}

	// make sure that link list mode is disabled by default
	APS_SetLinkListMode(device, 0, 0, dac);

	// lock memory
	//APS_SetBit(device, fpga, FPGA_OFF_CSR, dac_mem_lock);

	return 0;
}

int APS_SetBit(int device, int fpga, int addr, int mask)
/********************************************************************
 *
 * Function Name : APS_SetBit()
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
	int current_state, current_state2;
  if (fpga == 3) { // read the two FPGAs serially
    current_state = APS_ReadFPGA(device, gRegRead | addr, 1);
    current_state2 = APS_ReadFPGA(device, gRegRead | addr, 2);
    if (current_state != current_state2) {
      // note the mismatch in the log file but continue on using FPGA1's data
      dlog(DEBUG_VERBOSE,"APS_SetBit: FPGA registers don't match. Addr: 0x%x FPGA1: 0x%x FPGA2: 0x%x\n", addr, current_state, current_state2);
    }
  } else {
    current_state = APS_ReadFPGA(device, gRegRead | addr, fpga);
  }

	dlog(DEBUG_VERBOSE2,"Addr: 0x%x Current State: 0x%x Mask: 0x%x Writing 0x%x\n",
	     addr, current_state, mask, current_state | mask);

	usleep(100);
	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | addr, current_state | mask, fpga);
  
  if (getDebugLevel() >= DEBUG_VERBOSE2) {
    // verify write
    usleep(100);
    if (fpga == 3) {
      current_state = APS_ReadFPGA(device, gRegRead | addr, 1);
      current_state2 = APS_ReadFPGA(device, gRegRead | addr, 2);
      dlog(DEBUG_VERBOSE2,"Addr: 0x%x FPGA1: 0x%x FPGA2 0x%x\n", addr, current_state, current_state2);
    } else {
      current_state = APS_ReadFPGA(device, gRegRead | addr, fpga);
    }
	if ((current_state & mask) == 0)
		dlog(DEBUG_VERBOSE,"ERROR: APS_SetBit data does not match\n");
  }
}

int APS_ClearBit(int device, int fpga, int addr, int mask)
/********************************************************************
 *
 * Function Name : APS_ClearBit()
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
	int current_state, current_state2;
	if (fpga == 3) { // read the two FPGAs serially
		current_state = APS_ReadFPGA(device, gRegRead | addr, 1);
		current_state2 = APS_ReadFPGA(device, gRegRead | addr, 2);
		if (current_state != current_state2) {
			// note the mismatch in the log file but continue on using FPGA1's data
			dlog(DEBUG_VERBOSE,"APS_ClearBit: FPGA registers don't match. Addr: 0x%x FPGA1: 0x%x FPGA2: 0x%x\n", addr, current_state, current_state2);
		}
	} else {
		current_state = APS_ReadFPGA(device, gRegRead | addr, fpga);
	}
	dlog(DEBUG_VERBOSE2,"Addr: 0x%x Current State: 0x%x Writing 0x%x\n", addr, current_state, current_state & ~mask);

	usleep(100);
	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | addr, current_state & ~mask, fpga);
  
	if (getDebugLevel() >= DEBUG_VERBOSE2) {
		// verify write
		usleep(100);
		if (fpga == 3) {
		  current_state = APS_ReadFPGA(device, gRegRead | addr, 1);
		  current_state2 = APS_ReadFPGA(device, gRegRead | addr, 2);
		  dlog(DEBUG_VERBOSE2,"Addr: 0x%x FPGA1: 0x%x FPGA2 0x%x\n", addr, current_state, current_state2);
		} else {
		  current_state = APS_ReadFPGA(device, gRegRead | addr, fpga);
		}
	}
}


EXPORT int APS_TriggerDac(int device, int dac, int trigger_type)
/********************************************************************
 *
 * Function Name : APS_TriggerDac()
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


	dlog(DEBUG_INFO,"Trigger DAC%i type %i \n", dac, trigger_type);

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
				dac_sm_enable = CSRMSK_ENVDDR_ELL;
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
				dac_sm_enable = CSRMSK_PHSDDR_ELL;
				dac_trig_src  = CSRMSK_PHSTRIGSRC_ELL;
				dac_sm_reset  = CSRMSK_PHSSMRST_ELL;
			}
			break;
		default:
			return -2;
	}

	dlog(DEBUG_VERBOSE,"Current CSR: %x TRIGLED: %x\n",
		 APS_ReadFPGA(device, gRegRead | FPGA_OFF_CSR, fpga),
		 APS_ReadFPGA(device, gRegRead | FPGA_OFF_TRIGLED, fpga)
		);

	if (trigger_type == SOFTWARE_TRIGGER) {
		dlog(DEBUG_VERBOSE, "Trigger %s State Machine ... \n", dac_type);

		APS_ClearBit(device, fpga, FPGA_OFF_CSR, dac_trig_src);
	  APS_SetBit(device, fpga, FPGA_OFF_TRIGLED, dac_sw_trig);

	} else if (trigger_type == HARDWARE_TRIGGER) {

		APS_ClearBit(device, fpga, FPGA_OFF_TRIGLED, dac_sw_trig);

		dlog(DEBUG_VERBOSE,"Setting HW Trigger ... \n");

		APS_SetBit(device, fpga, FPGA_OFF_CSR, dac_trig_src);

	} else {
	  dlog(DEBUG_VERBOSE, "Invalid Trigger Type\n");
		return -1;
	}

  dlog(DEBUG_VERBOSE,"Enable %s State Machine ... \n", dac_type);
  
  APS_ClearBit(device, fpga,FPGA_OFF_CSR, dac_sm_reset);
	//APS_SetBit(device, fpga,FPGA_OFF_CSR, dac_sm_enable);

	return 0;
}

EXPORT int APS_PauseDac(int device, int dac)
/********************************************************************
 *
 * Function Name : APS_PauseDac()
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
	int dac_sw_trig, dac_trig_src, dac_sm_reset, dac_sm_enable;

	fpga = dac2fpga(dac);
	if (fpga < 0) {
		return -1;
	}

	dlog(DEBUG_INFO,"Pause FPGA%i DAC%i\n", fpga, dac);

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
				dac_sm_enable = CSRMSK_ENVDDR_ELL;
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
				dac_sm_enable = CSRMSK_PHSDDR_ELL;
			}
			break;
		default:
			return -2;
	}

	APS_ClearBit(device, fpga,FPGA_OFF_TRIGLED, dac_sw_trig);
	APS_ClearBit(device, fpga,FPGA_OFF_CSR, dac_sm_enable);
	return 0;
}

EXPORT int APS_DisableDac(int device, int dac)
/********************************************************************
 *
 * Function Name : APS_DisableDac()
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
	int dac_sm_reset, dac_offset, dac_sm_enable, dac_sw_trig;

	fpga = dac2fpga(dac);
	if (fpga < 0) {
		return -1;
	}

  dlog(DEBUG_INFO,"Disable FPGA%i DAC%i\n", fpga, dac);

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
				dac_sm_enable = CSRMSK_ENVDDR_ELL;
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
				dac_sm_enable = CSRMSK_PHSDDR_ELL;
			}

			break;
		default:
			return -2;
	}


	//dlog(DEBUG_VERBOSE,"Disable %s State Machine ... \n", dac_type);

	APS_ClearBit(device, fpga,FPGA_OFF_TRIGLED, dac_sw_trig);
	//APS_ClearBit(device, fpga,FPGA_OFF_CSR, dac_sm_enable);

	dlog(DEBUG_VERBOSE, "Reset %s State Machine ... \n", dac_type);

	APS_SetBit(device, fpga,FPGA_OFF_CSR, dac_sm_reset);
	return 0;
}


int LoadLinkList_V5(int device, unsigned short *OffsetData, unsigned short *CountData,
		            int length, int dac)
/********************************************************************
 *
 * Function Name : APS_LoadLinkList()
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

	BYTE * formatedData;
	BYTE * formatedDataIdx;
	int formated_length;

	fpga = dac2fpga(dac);
	if (fpga < 0) {
		return -1;
	}

	dlog(DEBUG_INFO,"Loading LinkList length %i into FPGA%i DAC%i \n", length, fpga, dac);

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
	ctrl_reg = APS_ReadFPGA(device, gRegRead | FPGA_OFF_LLCTRL, fpga);

  dlog(DEBUG_VERBOSE,"Current Link List Control Reg: 0x%x\n", ctrl_reg);

	// zero current dac settings
	ctrl_reg &= ~(0xFF << dac_shift);

  dlog(DEBUG_VERBOSE,"Zeroed Link List Control Reg: 0x%x\n", ctrl_reg);

	//set link list size
	ctrl_reg |= (length << dac_shift);

	//length = length - 1;

	dlog(DEBUG_VERBOSE,"Writing Link List Control Reg: 0x%x\n", ctrl_reg);

	// write control reg
	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | FPGA_OFF_LLCTRL, ctrl_reg, fpga);

	// load current ctrl reg
	ctrl_reg = APS_ReadFPGA(device, gRegRead | FPGA_OFF_LLCTRL, fpga);

	dlog(DEBUG_VERBOSE,"Written Link List Control Reg: 0x%x\n", ctrl_reg);
  dlog(DEBUG_VERBOSE,"Loading Link List %s DAC%i...\n", dac_type, dac);

	// Expanded length 1 byte command 2 bytes addr 2 bytes data per data sample
	// * 2 from two entries offset and count
	formated_length  = ADDRDATASIZE * 2 * length;
	formatedData = (BYTE *) malloc(formated_length);
	if (!formatedData)
		return -5;
	formatedDataIdx = formatedData;

	// Format data as would be expected for FPGA
	// This mimics the calls to APS_WriteFPGA followed by APS_WriteReg

	for(cnt = 0; cnt < length; cnt++) {
		APS_FormatForFPGA(formatedDataIdx, dac_write_offset + cnt,OffsetData[cnt], fpga );
		formatedDataIdx += ADDRDATASIZE;
		APS_FormatForFPGA(formatedDataIdx, dac_write_cnt + cnt, CountData[cnt], fpga );
		formatedDataIdx += ADDRDATASIZE;
	}
	APS_WriteBlock(device,formated_length, formatedData);
	free(formatedData);

	dlog(DEBUG_VERBOSE,"Done\n");

	return 0;
}

int LoadLinkList_ELL(int device, unsigned short *OffsetData, unsigned short *CountData,
		             unsigned short *TriggerData, unsigned short *RepeatData,
		             int length, int dac, int bank, int validate)
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
	int ctrl_reg, ctrl_reg_read;
	int readVal;

	/*
	int lastEntryAddress;

	ULONG write_addr;
	ULONG wf_length;

	BYTE * formatedData;
	BYTE * formatedDataIdx;
	 */

	fpga = dac2fpga(dac);
	if (fpga < 0) {
		return -1;
	}

	dlog(DEBUG_VERBOSE,"Load Link List ELL\n");

	if (gBitFileVersion < VERSION_ELL) {
		dlog(DEBUG_INFO,"ERROR => Hardware Version: %i does not support ELL mode.\n", gBitFileVersion);
		return -1;
	}

	const char * banks[] = {"A","B"};
	dlog(DEBUG_INFO,"Loading LinkList length %i into FPGA%i DAC%i Bank %s\n",
	    length, fpga, dac, banks[bank]);

	// setup register addressing based on DAC
	switch(dac) {
		case 0:
			// fall through
		case 2:
			dac_type = ENVELOPE;
			if (bank == 0) {
				dac_write = FPGA_ADDR_ELL_ENVLL_A_WRITE;
				dac_ctrl_reg = FPGA_OFF_ELL_ENVLL_A_CTRL;
			} else {
				dac_write = FPGA_ADDR_ELL_ENVLL_B_WRITE;
				dac_ctrl_reg = FPGA_OFF_ELL_ENVLL_B_CTRL;
			}
			dac_rpt_reg  = FPGA_OFF_ELL_ENVLL_REPEAT;
			break;
		case 1:
			// fall through
		case 3:
			dac_type = PHASE;
			if (bank == 0) {
				dac_write    = FPGA_ADDR_ELL_PHSLL_A_WRITE;
				dac_ctrl_reg = FPGA_OFF_ELL_PHSLL_A_CTRL;
			} else {
				dac_write = FPGA_ADDR_ELL_PHSLL_B_WRITE;
				dac_ctrl_reg = FPGA_OFF_ELL_PHSLL_B_CTRL;
			}
			dac_rpt_reg  = FPGA_OFF_ELL_PHSLL_REPEAT;
			break;
		default:
			return -2;
	}

	if ( length > MAX_LL_LENGTH_ELL)  {
		return -3;
	}

	// load current cntrl reg
	ctrl_reg = APS_ReadFPGA(device, gRegRead | dac_ctrl_reg, fpga);

	dlog(DEBUG_VERBOSE,"ELL: Current Link List Control Reg: 0x%x\n", ctrl_reg);

	//set link list size
	// ELL Mode does not require shift due to different control registers
	ctrl_reg = (length-1) & 0x3FFF;

	// if bank is Bank B need to add based 0x200 to length
	if (bank == 1) {
		ctrl_reg = ctrl_reg + 0x200;  // Link List B offset is 0x200 (on DAC side)
	}

	dlog(DEBUG_VERBOSE,"Writing Link List Control Reg: 0x%x = 0x%x\n", dac_ctrl_reg,ctrl_reg);

	// write control reg
	APS_WriteFPGA(device, dac_ctrl_reg, ctrl_reg, fpga);

	// load current ctrl reg
	ctrl_reg_read = APS_ReadFPGA(device, gRegRead | dac_ctrl_reg, fpga);

	dlog(DEBUG_VERBOSE,"Loaded Link List %s DAC%i... Ctrl Reg = 0x%x\n", dac_type, dac, ctrl_reg_read);

	if (ctrl_reg_read != ctrl_reg) {
		dlog(DEBUG_VERBOSE, "WARNING: LinkList Control Reg Did Not Write Correctly\n");
	}

#if 1
  for(cnt = 0; cnt < length; cnt++) {
    dlog(DEBUG_VERBOSE,"Writting LL Entry: %3i => Addr: 0x%X Count: %i: Repeat %i\n",
        cnt,dac_write + 4*cnt,  CountData[cnt], RepeatData[cnt]);
    dlog(DEBUG_VERBOSE,"                          TriggerMode: %i TriggerCount %i\n",
        TriggerData[cnt] >> 14,
        TriggerData[cnt] & 0x3FFF);

    dlog(DEBUG_VERBOSE,"                          Offset: 0x%x Address: 0x%x TA: %i Z: %i T:% i LS: %i LE: %i\n",
        OffsetData[cnt],
        OffsetData[cnt] & 0x7FF,
        (OffsetData[cnt] & 0x8000) == 0x8000,
        (OffsetData[cnt] & 0x4000) == 0x4000,
        (OffsetData[cnt] & 0x2000) == 0x2000,
        (OffsetData[cnt] & 0x1000) == 0x1000,
        (OffsetData[cnt] & 0x800) == 0x800);

    APS_WriteFPGA(device, dac_write + 4*cnt  , OffsetData[cnt], fpga);
    dlog(DEBUG_VERBOSE,"LL Addr: 0x%X Offset  Value 0x%X\n",dac_write + 4*cnt, OffsetData[cnt]);

    APS_WriteFPGA(device, dac_write + 4*cnt+1, CountData[cnt], fpga);
    dlog(DEBUG_VERBOSE,"LL Addr: 0x%X Count   Value 0x%X\n",dac_write + 4*cnt+1, CountData[cnt]);

    APS_WriteFPGA(device, dac_write + 4*cnt+2, TriggerData[cnt], fpga);
    dlog(DEBUG_VERBOSE,"LL Addr: 0x%X Trigger Value 0x%X\n",dac_write + 4*cnt+2, TriggerData[cnt]);

    APS_WriteFPGA(device, dac_write + 4*cnt+3, RepeatData[cnt], fpga);
    dlog(DEBUG_VERBOSE,"LL Addr: 0x%X Repeat  Value 0x%X\n",dac_write + 4*cnt+3, RepeatData[cnt]);

    if (validate) {
      readVal = APS_ReadFPGA(device, gRegRead | dac_write + 4*cnt  ,  fpga) ;
      if (readVal != OffsetData[cnt])
         dlog(DEBUG_INFO,"Error writing offset 0x%X != 0x%X \n", readVal, OffsetData[cnt]);

      readVal = APS_ReadFPGA(device, gRegRead | dac_write + 4*cnt+1  ,  fpga) ;
      if (readVal != CountData[cnt])
        dlog(DEBUG_INFO,"Error writing count 0x%X != 0x%X \n", readVal, CountData[cnt]);

      readVal = APS_ReadFPGA(device, gRegRead | dac_write + 4*cnt+2  ,  fpga) ;
      if (readVal != TriggerData[cnt])
        dlog(DEBUG_INFO,"Error writing trigger 0x%X != 0x%X \n", readVal, TriggerData[cnt]);

      readVal = APS_ReadFPGA(device, gRegRead | dac_write + 4*cnt+3  ,  fpga) ;
      if (readVal != RepeatData[cnt])
        dlog(DEBUG_INFO,"Error writing repeat 0x%X != 0x%X \n", readVal, RepeatData[cnt]);
    }

  }

#else
	// ADDRDATASIZE_ELL 1 cmd 2 addr 2 offset 2 count 2 trigger 2 repeat
#define ADDRDATASIZE_ELL 11
	formated_length  = ADDRDATASIZE_ELL * length;  // Expanded length 1 byte command 2 bytes addr 2 bytes data per data sample
	formatedData = (BYTE *) malloc(formated_length);
	if (!formatedData)
		return -5;
	formatedDataIdx = formatedData;

	// Format data as would be expected for FPGA
	// This mimics the calls to APS_WriteFPGA followed by APS_WriteReg

	for(cnt = 0; cnt < length; cnt++) {
		APS_FormatForFPGA_ELL(formatedDataIdx, dac_write + cnt,
								OffsetData[cnt], CountData[cnt],
								TriggerData[cnt], RepeatData[cnt],
								fpga );
		formatedDataIdx += ADDRDATASIZE_ELL;
	}
	APS_WriteBlock(device,formated_length, formatedData);
	free(formatedData);
#endif

	// zero repeat register
	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | dac_rpt_reg, 0, fpga);

	dlog(DEBUG_VERBOSE,"Done\n");
	return 0;
}

EXPORT int APS_LoadLinkList(int device,
		                          unsigned short *OffsetData, unsigned short *CountData,
		                          unsigned short *TriggerData, unsigned short *RepeatData,
		                          int length, int dac, int bank, int validate)
{
  dlog(DEBUG_VERBOSE,"APS_LoadLinkList\n");
	if (gBitFileVersion < VERSION_ELL) {
		return LoadLinkList_V5(device, OffsetData, CountData, length, dac);
	} else {
		return LoadLinkList_ELL(device, OffsetData, CountData, TriggerData, RepeatData,
				         length, dac, bank, validate);
	}
}

EXPORT int APS_ClearLinkListELL(int device,int dac, int bank)
{
  dlog(DEBUG_VERBOSE,"APS_ClearLinkList\n");
  int dac_write;
    int dac_ctrl_reg, dac_rpt_reg;
    int fpga;
    int ctrl_reg;
    char * dac_type;

    fpga = dac2fpga(dac);
    if (fpga < 0) {
      return -1;
    }

    dlog(DEBUG_VERBOSE,"Load Link List ELL\n");

    if (gBitFileVersion < VERSION_ELL) {
      dlog(DEBUG_INFO,"ERROR => Hardware Version: %i does not support ELL mode.\n", gBitFileVersion);
      return -1;
    }

    const char * banks[] = {"A","B"};
    dlog(DEBUG_INFO,"Clearing LinkList FPGA%i DAC%i Bank %s\n", fpga, dac, banks[bank]);

    // setup register addressing based on DAC
    switch(dac) {
      case 0:
        // fall through
      case 2:
        dac_type = ENVELOPE;
        if (bank == 0) {
          dac_write = FPGA_ADDR_ELL_ENVLL_A_WRITE;
          dac_ctrl_reg = FPGA_OFF_ELL_ENVLL_A_CTRL;
        } else {
          dac_write = FPGA_ADDR_ELL_ENVLL_B_WRITE;
          dac_ctrl_reg = FPGA_OFF_ELL_ENVLL_B_CTRL;
        }
        dac_rpt_reg  = FPGA_OFF_ELL_ENVLL_REPEAT;
        break;
      case 1:
        // fall through
      case 3:
        dac_type = PHASE;
        if (bank == 0) {
          dac_write    = FPGA_ADDR_ELL_PHSLL_A_WRITE;
          dac_ctrl_reg = FPGA_OFF_ELL_PHSLL_A_CTRL;
        } else {
          dac_write = FPGA_ADDR_ELL_PHSLL_B_WRITE;
          dac_ctrl_reg = FPGA_OFF_ELL_PHSLL_B_CTRL;
        }
        dac_rpt_reg  = FPGA_OFF_ELL_PHSLL_REPEAT;
        break;
      default:
        return -2;
    }

    //set link list size
    // for zero length to clear Link List
    ctrl_reg = 0;

    // if bank is Bank B need to add based 0x200 to length
    // for the mgth
    //if (bank == 1) {
    // ctrl_reg = ctrl_reg + 0x200;  // Link List B offset is 0x200 (on DAC side)
    //}

    dlog(DEBUG_VERBOSE,"Writing Link List Control Reg: 0x%x = 0x%x\n", dac_ctrl_reg,ctrl_reg);

    // write control reg
    APS_WriteFPGA(device, dac_ctrl_reg, ctrl_reg, fpga);

    // zero repeat register
    APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | dac_rpt_reg, 0, fpga);

    dlog(DEBUG_VERBOSE,"Done\n");
    return 0;

}

EXPORT int APS_SetLinkListRepeat(int device, unsigned short repeat, int dac) {
	int dac_rpt_reg;
	int fpga;

	char * dac_type;

	fpga = dac2fpga(dac);
	if (fpga < 0) {
		return -1;
	}

	if (gBitFileVersion < VERSION_ELL) {
		dlog(DEBUG_INFO,"ERROR => Hardware Version: %i does not support ELL mode.\n", gBitFileVersion);
		return -1;
	}

	// setup register addressing based on DAC
	switch(dac) {
		case 0:
			// fall through
		case 2:
			dac_type = ENVELOPE;
			dac_rpt_reg  = FPGA_OFF_ELL_ENVLL_REPEAT;
			break;
		case 1:
			// fall through
		case 3:
			dac_type = PHASE;
			dac_rpt_reg  = FPGA_OFF_ELL_PHSLL_REPEAT;
			break;
		default:
			return -2;
	}
	// zero repeat register
	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | dac_rpt_reg, repeat, fpga);

	dlog(DEBUG_INFO,"SET LinkList Repeat FPGA: %i Dac: %s Repeat Count: %i Addr: 0x%X\n", fpga, dac_type, repeat, FPGA_ADDR_REGWRITE | dac_rpt_reg);

	return 0;
}

int SetLinkListMode_V5(int device, int enable, int mode, int dac)
/********************************************************************
 *
 * Function Name : APS_LoadLinkList()
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

	dlog(DEBUG_INFO, "Setting Link List Enable ==> FPGA: %i DAC: %i Enable: %i\n", fpga, dac, enable);

	// load current cntrl reg
	ctrl_reg = APS_ReadFPGA(device, gRegRead | FPGA_OFF_LLCTRL, fpga);

  dlog(DEBUG_VERBOSE,"Current Link List Control Reg: 0x%x\n", ctrl_reg);


	if (enable) {
		APS_SetBit(device, fpga, FPGA_OFF_LLCTRL, dac_enable_mask);
	} else {
		APS_ClearBit(device, fpga, FPGA_OFF_LLCTRL, dac_enable_mask);
	}

	dlog(DEBUG_INFO, "Setting Link List Mode ==> FPGA: %i DAC: %i Mode: %i\n", fpga, dac, mode);

	if (mode) {
		APS_SetBit(device, fpga, FPGA_OFF_LLCTRL, dac_mode_mask);
	} else {
		APS_ClearBit(device, fpga, FPGA_OFF_LLCTRL, dac_mode_mask);
	}

	return 0;
}

int SetLinkListMode_ELL(int device, int enable, int mode, int dac)
/********************************************************************
 *
 * Function Name : APS_LoadLinkList()
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
      dac_type      = ENVELOPE;
      dac_enable_mask = CSRMSK_ENVOUTMODE_ELL;
      dac_mode_mask   = CSRMSK_ENVLLMODE_ELL;

      break;
    case 1:
      // fall through
    case 3:
      dac_type      = PHASE;
      dac_enable_mask = CSRMSK_PHSOUTMODE_ELL;
      dac_mode_mask   = CSRMSK_PHSLLMODE_ELL;
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

  dlog(DEBUG_INFO, "Setting Link List Enable ==> FPGA: %i DAC: %i Enable: %i\n", fpga, dac, enable);

  // load current cntrl reg
  ctrl_reg = APS_ReadFPGA(device, gRegRead | FPGA_OFF_CSR, fpga);

  dlog(DEBUG_VERBOSE,"Current CSR: 0x%x\n", ctrl_reg);


  if (enable) {
    // set bit to turn on link list mode
    APS_SetBit(device, fpga, FPGA_OFF_CSR, dac_enable_mask);
  } else {
    APS_ClearBit(device, fpga, FPGA_OFF_CSR, dac_enable_mask);
  }

  dlog(DEBUG_INFO, "Setting Link List Mode ==> FPGA: %i DAC: %i Mode: %i\n", fpga, dac, mode);

  if (mode) {
    APS_SetBit(device, fpga, FPGA_OFF_CSR, dac_mode_mask);
  } else {
    APS_ClearBit(device, fpga, FPGA_OFF_CSR, dac_mode_mask);
  }

  return 0;
}

EXPORT int APS_SetLinkListMode(int device, int enable, int mode, int dac) {
    // may be able to merge functions back together
    dlog(DEBUG_VERBOSE,"APS_SetLinkListMode\n");
    if (gBitFileVersion < VERSION_ELL) {
      return SetLinkListMode_V5( device, enable, mode, dac);
    } else {
      return SetLinkListMode_ELL(device, enable, mode, dac);
    }
}

EXPORT int APS_TriggerFpga(int device, int dac, int trigger_type)
/********************************************************************
 *
 * Function Name : APS_TriggerFPGA()
 *
 * Description : Triggers Both DACs on FPGA at the same time. We do all operations
 * serially except the last one, to try to avoid simultaneous write errors.
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

  fpga = dac2fpga(dac);
  dlog(DEBUG_INFO,"Trigger FPGA%i type %i \n", fpga, trigger_type);
	if (fpga < 0) {
		return -1;
	}

	// setup register addressing based on DAC
	// strictly speaking the switch is not needed
	// but it is here to maintain a similar structure
	// to TriggerDAC and validate the input value of
	// the variable dac
	switch(dac) {
	  case -1:
	    // fall through
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

			dac_trig_src  = CSRMSK_ENVTRIGSRC_ELL | CSRMSK_PHSTRIGSRC_ELL;
			dac_sm_reset  = CSRMSK_ENVSMRST_ELL | CSRMSK_PHSSMRST_ELL;

			break;
		default:
			return -2;
	}

	if (fpga == 3) {
		dlog(DEBUG_VERBOSE,"FPGA1 Current CSR: 0x%x TRIGLED: 0x%x\n",
		     APS_ReadFPGA(device, gRegRead | FPGA_OFF_CSR, 1),
		     APS_ReadFPGA(device, gRegRead | FPGA_OFF_TRIGLED, 1)
		);
		dlog(DEBUG_VERBOSE,"FPGA2 Current CSR: 0x%x TRIGLED: 0x%x\n",
		     APS_ReadFPGA(device, gRegRead | FPGA_OFF_CSR, 2),
		     APS_ReadFPGA(device, gRegRead | FPGA_OFF_TRIGLED, 2)
		);
	} else {
		dlog(DEBUG_VERBOSE,"FPGA%d Current CSR: 0x%x TRIGLED: 0x%x\n",
		     fpga,
		     APS_ReadFPGA(device, gRegRead | FPGA_OFF_CSR, fpga),
		     APS_ReadFPGA(device, gRegRead | FPGA_OFF_TRIGLED, fpga)
		);
	}

	if (trigger_type == SOFTWARE_TRIGGER) {
		dlog(DEBUG_VERBOSE, "Setting SW Trigger ... \n", dac_type);

		if (fpga == 3) {
			APS_ClearBit(device, 1, FPGA_OFF_CSR, dac_trig_src);
			APS_SetBit(device, 1, FPGA_OFF_TRIGLED, dac_sw_trig);
			APS_ClearBit(device, 2, FPGA_OFF_CSR, dac_trig_src);
			APS_SetBit(device, 2, FPGA_OFF_TRIGLED, dac_sw_trig);
		} else {
			APS_ClearBit(device, fpga, FPGA_OFF_CSR, dac_trig_src);
			APS_SetBit(device, fpga, FPGA_OFF_TRIGLED, dac_sw_trig);
		}

	} else if (trigger_type == HARDWARE_TRIGGER) {
		dlog(DEBUG_VERBOSE,"Setting HW Trigger ... \n");
		
		if (fpga == 3) {
			APS_ClearBit(device, 1, FPGA_OFF_TRIGLED, dac_sw_trig);
			APS_SetBit(device, 1, FPGA_OFF_CSR, dac_trig_src);
			APS_ClearBit(device, 2, FPGA_OFF_TRIGLED, dac_sw_trig);
			APS_SetBit(device, 2, FPGA_OFF_CSR, dac_trig_src);
		} else {
			APS_ClearBit(device, fpga, FPGA_OFF_TRIGLED, dac_sw_trig);
			APS_SetBit(device, fpga, FPGA_OFF_CSR, dac_trig_src);
		}

	} else {
		dlog(DEBUG_VERBOSE, "Invalid Trigger Type\n");
		return -1;
	}

	if (getDebugLevel() >= DEBUG_VERBOSE) {
		dlog(DEBUG_VERBOSE,"New CSR: 0x%x TRIGLED 0x%x\n",
		 APS_ReadFPGA(device, gRegRead | FPGA_OFF_CSR, fpga),
		 APS_ReadFPGA(device, gRegRead | FPGA_OFF_TRIGLED, fpga)
	    );
	}

	dlog(DEBUG_VERBOSE,"Enable %s State Machine ... \n", dac_type);

	// do this last operation simultaneously, if necessary
	APS_ClearBit(device, fpga, FPGA_OFF_CSR, dac_sm_reset);

	return 0;
}

EXPORT int APS_PauseFpga(int device, int dac)
/********************************************************************
 *
 * Function Name : APS_PauseFPGA()
 *
 * Description :  Disables DDR output to DACs and turns off software triggering
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
	int dac_sw_trig, dac_sm_reset, dac_sm_enable;

	fpga = dac2fpga(dac);
	if (fpga < 0) {
		return -1;
	}

	dlog(DEBUG_INFO,"Pause FPGA%i DAC%i\n", fpga, dac);

	switch(dac) {
	  case -1:
	    // fall through
		case 0:
			// fall through
		case 1:
			// fall through
		case 2:
			// fall through
		case 3:
			dac_sw_trig   = TRIGLEDMSK_ENVSWTRIG | TRIGLEDMSK_PHSSWTRIG;

			if (gBitFileVersion < VERSION_ELL) {
				dac_sm_reset  = CSRMSK_ENVSMRST | CSRMSK_PHSSMRST;
				dac_sm_enable = CSRMSK_ENVSMEN | CSRMSK_PHSSMEN;
			} else {
				dac_sm_reset  = CSRMSK_ENVSMRST_ELL | CSRMSK_PHSSMRST_ELL;
				dac_sm_enable = CSRMSK_ENVDDR_ELL | CSRMSK_PHSDDR_ELL;
			}

			break;
		default:
			return -2;
	}

	APS_ClearBit(device, fpga,FPGA_OFF_TRIGLED, dac_sw_trig);
	APS_ClearBit(device, fpga,FPGA_OFF_CSR, dac_sm_enable);
	return 0;
}

EXPORT int APS_DisableFpga(int device, int dac)
/********************************************************************
 *
 * Function Name : APS_DisableFPGA()
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
	int dac_sm_reset, dac_sm_enable, dac_sw_trig;

	fpga = dac2fpga(dac);
	if (fpga < 0) {
		return -1;
	}

	dlog(DEBUG_INFO,"Disable FPGA%i DAC%i\n", fpga, dac);

	switch(dac) {
	  case -1 :
	    // fall through
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
				dac_sm_enable = CSRMSK_ENVDDR_ELL | CSRMSK_PHSDDR_ELL;
			}

			break;
		default:
			return -2;
	}

	if (fpga == 3) {
		APS_ClearBit(device, 1, FPGA_OFF_TRIGLED, dac_sw_trig);
		APS_ClearBit(device, 2, FPGA_OFF_TRIGLED, dac_sw_trig);
	} else {
		APS_ClearBit(device, fpga, FPGA_OFF_TRIGLED, dac_sw_trig);
	}

	dlog(DEBUG_VERBOSE,"Reset %s State Machine ... \n", dac_type);

	if (fpga == 3) {
		APS_SetBit(device, 1, FPGA_OFF_CSR, dac_sm_reset);
		APS_SetBit(device, 2, FPGA_OFF_CSR, dac_sm_reset);
	} else {
		APS_SetBit(device, fpga, FPGA_OFF_CSR, dac_sm_reset);
	}
	return 0;
}



EXPORT int APS_ReadBitFileVersion(int device) {
	// read bit file version and return if the same, otherwise return an error (-1)
	int version1, version2;
	version1 = APS_ReadFpgaBitFileVersion(device, 1);
	version2 = APS_ReadFpgaBitFileVersion(device, 2);
	dlog(DEBUG_VERBOSE, "Bitfile versions FPGA1: 0x%x, FPGA2: 0x%x\n", version1, version2);
	
	if (version1 == version2) {
		gBitFileVersion = version1;
		gRegRead = (version1 >= VERSION_ELL) ? FPGA_ADDR_ELL_REGREAD : FPGA_ADDR_REGREAD;
		dlog(DEBUG_VERBOSE, "gRegRead set to: 0x%x\n", gRegRead );
		return version1;
	} else {
		dlog(DEBUG_INFO, "Bitfile versions do not match, FPGA1: 0x%x, FPGA2: 0x%x\n", version1, version2);
		return -1;
	}
}

int APS_ReadFpgaBitFileVersion(int device, int fpga) {
	// Reads version information from register 0x8006
	int version;

	version = APS_ReadFPGA(device, FPGA_ADDR_ELL_REGREAD | FPGA_OFF_VERSION, fpga);
	version = version & 0x1FF; // First 9 bits hold version
	
	return version;
}

EXPORT int APS_ReadAllRegisters(int device, int fpga) {
	int cnt;
	int val;
	static int readCnt = 0;
	int expected_values[] = {-1,-1,0,-1,0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,0xdead,-1,-1,0,0};

	dlog(DEBUG_VERBOSE,"====== Register Read %3i ======\n", readCnt++);

	for(cnt = 0; cnt < 20; cnt++) {
		val = APS_ReadFPGA(device, gRegRead | cnt, fpga);

		if ((expected_values[cnt] != -1) && (expected_values[cnt] != val)) {
			dlog(DEBUG_VERBOSE,"Error reading 0x%x: expected 0x%x read 0x%x\n",  gRegRead | cnt, expected_values[cnt], val);
		}
		// register values will be dumped to log by APS_ReadFPGA
	}
	return 0;
}

EXPORT int APS_TestWaveformMemory(int device, int dac, int nbrSamples) {
	int dac_offset, dac_size, dac_write, dac_read, dac_mem_lock;
	int fpga;
	int cnt;
	char * dac_type;

	#ifdef LOG_WAVEFORM
	FILE * logwaveform;
	#endif

	ULONG data;
	ULONG wf_length;


	if(gBitFileVersion < VERSION_ELL && nbrSamples > K4 ) {
		dlog(DEBUG_INFO,"[WARNING] Waveform length > 4K. Truncating waveform\n");
		nbrSamples = K4;

	} else if(gBitFileVersion >= VERSION_ELL && nbrSamples > K8 ) {
		dlog(DEBUG_INFO,"[WARNING] Waveform length > 8K. Truncating waveform\n");
		nbrSamples = K8;
	}

	wf_length = nbrSamples / WF_MODULUS;


	if (nbrSamples % WF_MODULUS != 0) {
		dlog(DEBUG_VERBOSE,"[WARNING] Waveform data needs to be padded");
	}


	fpga = dac2fpga(dac);
	if (fpga < 0) {
		return -1;
	}

	dlog(DEBUG_VERBOSE,"Testing device %i dac %i fpga %i\n",device,dac, fpga);

	dlog(DEBUG_VERBOSE,"Loading Waveform length %i into FPGA%i DAC%i \n", nbrSamples, fpga, dac);

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

  dlog(DEBUG_VERBOSE,"Clearing Control and Status Register ...\n");

	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | FPGA_OFF_CSR, 0x0, fpga);

	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | dac_offset, 0x0, fpga);
	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | dac_size,   wf_length, fpga);

	int num_errors = 0;
	int ok, attempt;
	int out;

	for(cnt = 0; cnt < nbrSamples; cnt++) {

		if (cnt % 100 == 0) {
			dlog(DEBUG_VERBOSE,"Writing to addr: 0x%x\n", dac_write+cnt);
		}
		ok = 0;
		attempt = 0;
		while(!ok) {
			out = ((cnt & 0xFF) << 8) | ((cnt & 0xFF00) >> 8);
			APS_WriteFPGA(device,dac_write+cnt , out, fpga);
			data = APS_ReadFPGA(device, dac_read + cnt, fpga);
			if (data != out) {
				attempt++;
				if (attempt == 1)
					dlog(DEBUG_VERBOSE,"Error reading 0x%x (0x%x): expected 0x%x read ", dac_read + cnt,  dac_write + cnt,out);
				dlog(DEBUG_VERBOSE,"0x%x ", data);
				num_errors = num_errors + 1;
			} else {
				ok = 1;
			}
		}
		if (attempt)
			dlog(DEBUG_VERBOSE, "bad attempts %i\n", attempt);
	}

	int round;
	for(round = 0; round < 1; round++) {
		//dlog(DEBUG_VERBOSE,"======== %i =========\n", round);
		for(cnt = 0; cnt < nbrSamples; cnt++) {
			if (cnt % 100 == 0) {
				dlog(DEBUG_VERBOSE,"Reading from addr: 0x%x\n", dac_read+cnt);
			}

			ok = 0;
			attempt = 0;
			out = ((cnt & 0xFF) << 8) | ((cnt & 0xFF00) >> 8);
			while (!ok) {
				data = APS_ReadFPGA(device, dac_read + cnt, fpga);
				if (data != out) {
					attempt++;
					if (attempt == 1)
						dlog(DEBUG_VERBOSE,"Error reading 0x%x: expected 0x%x read ", dac_read + cnt,out);
					dlog(DEBUG_VERBOSE,"0x%x ", data);
					num_errors = num_errors + 1;
				} else {
					ok = 1;
				}
			}
			if (attempt)
				dlog(DEBUG_VERBOSE,"bad attempts %i\n", attempt);
		}
	}
	dlog(DEBUG_VERBOSE,"Total Number of Errors: %i\n",num_errors);

	return 0;
}

EXPORT int APS_ReadLinkListStatus(int device, int dac) {
  int csr, link_list_status;
  int fpga;

  int val;
  int status;
  char * dac_type;

  fpga = dac2fpga(dac);
  if (fpga < 0) {
    return -1;
  }

  if (gBitFileVersion < VERSION_ELL) {
    dlog(DEBUG_INFO,"ERROR => Hardware Version: %i does not support ELL mode.\n", gBitFileVersion);
    return -1;
  }

  csr = FPGA_OFF_CSR;

  // setup register addressing based on DAC
  switch(dac) {
    case 0:
      // fall through
    case 2:
      dac_type = ENVELOPE;
      link_list_status  = CSRMSK_ENVLLSTATUS_ELL;
      break;
    case 1:
      // fall through
    case 3:
      dac_type = PHASE;
      link_list_status  = CSRMSK_PHSLLSTATUS_ELL;
      break;
    default:
      return -2;
  }
  // read CSR
  val = APS_ReadFPGA(device, gRegRead | csr, fpga);
  status = (val & link_list_status) == link_list_status;

  dlog(DEBUG_VERBOSE,"CSR = 0x%x LL Status = %i\n", val,status);

  return status;
}

EXPORT int APS_IsRunning(int device)
/********************************************************************
 *
 * Function Name : APS_IsRunning()
 *
 * Description : Returns 1 if APS is running 0 otherwise
 *
 * Inputs : device device id
 *
 * APS is running if any of the channels are enabled
 *
 ********************************************************************/
{
  int csrReg1, csrReg2;
  int dac_sm_enable;
  int running;
  // load current cntrl reg
  csrReg1 = APS_ReadFPGA(device, gRegRead | FPGA_OFF_CSR, 1);
  csrReg2 = APS_ReadFPGA(device, gRegRead | FPGA_OFF_CSR, 2);

  // these bits need to be cleared for the channels to be running
  dac_sm_enable = CSRMSK_ENVSMRST_ELL | CSRMSK_PHSSMRST_ELL;

  // test for output disabled on each channel
  csrReg1 &= dac_sm_enable;
  csrReg2 &= dac_sm_enable;

  // or each channel together to determine if the aps is running
  running = ~csrReg1 | ~csrReg2;
  if (running)
    running = 1;  // return 1 if running otherwise return 0;

  return running;
}

EXPORT int APS_SetChannelOffset(int device, int dac, short offset)
/* APS_SetChannelOffset
 * Write the zero register for the associated channel
 * offset - signed 14-bit value (-8192, 8192) representing the channel offset
 */
{
  int fpga, zero_register_addr;
  
  fpga = dac2fpga(dac);
  if (fpga < 0) {
    return -1;
  }
  
  switch (dac) {
    case 0:
      // fall through
    case 2:
      zero_register_addr = FPGA_OFF_DAC02_ZERO;
      break;
    case 1:
      // fall through
    case 3:
      zero_register_addr = FPGA_OFF_DAC13_ZERO;
      break;
    default:
      return -2;
  }
  
  // clip the offset value to the allowed range
  if (offset > 8191)
    offset = 8191;
  if (offset < -8191)
    offset = -8191;
  dlog(DEBUG_INFO, "Setting DAC%i zero register to %i\n", dac, offset);
  
  APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | zero_register_addr, offset, fpga);
  return 0;
}

EXPORT short APS_ReadChannelOffset(int device, int dac)
/* APS_SetChannelOffset
 * Read the zero register for the associated channel
 */
{
  int fpga, zero_register_addr;
  
  fpga = dac2fpga(dac);
  if (fpga < 0) {
    return -1;
  }
  
  switch (dac) {
    case 0:
      // fall through
    case 2:
      zero_register_addr = FPGA_OFF_DAC02_ZERO;
      break;
    case 1:
      // fall through
    case 3:
      zero_register_addr = FPGA_OFF_DAC13_ZERO;
      break;
    default:
      return -2;
  }
  
  return APS_ReadFPGA(device, gRegRead | zero_register_addr, fpga);
}

EXPORT UCHAR APS_ReadStatusCtrl(int device)
{
	UCHAR ReadByte;
	APS_ReadReg(device, APS_STATUS_CTRL, 0, 0, &ReadByte);
	return ReadByte;
}

// sets Status/CTRL register to default state when running (OSCEN enabled)
EXPORT int APS_ResetStatusCtrl(int device)
{
	UCHAR WriteByte = APS_OSCEN_BIT;
	return APS_WriteReg(device, APS_STATUS_CTRL, 0, 0, &WriteByte);
}

// clears Status/CTRL register. This is the required state to program the VCXO and PLL
EXPORT int APS_ClearStatusCtrl(int device)
{
	UCHAR WriteByte = APS_OSCEN_BIT;
	return APS_WriteReg(device, APS_STATUS_CTRL, 0, 0, &WriteByte);
}

EXPORT int APS_RegWriteTest(int device, int addr)
{
	int current_state, current_state2;
	int i, data;
	// test writes
	// write to FPGAs one at a time
	dlog(DEBUG_INFO, "WRITE TEST to addr: 0x%x\nIndividual writes\n", addr);
	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | addr, 0xffff, 1);
	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | addr, 0xffff, 2);
	usleep(100);
	current_state = APS_ReadFPGA(device, gRegRead | addr, 1);
	current_state2 = APS_ReadFPGA(device, gRegRead | addr, 2);
	dlog(DEBUG_INFO,"0xffff FPGA1: 0x%x FPGA2 0x%x\n", current_state, current_state2);
	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | addr, 0xaaaa, 1);
	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | addr, 0xaaaa, 2);
	usleep(100);
	current_state = APS_ReadFPGA(device, gRegRead | addr, 1);
	current_state2 = APS_ReadFPGA(device, gRegRead | addr, 2);
	dlog(DEBUG_INFO,"0xaaaa FPGA1: 0x%x FPGA2 0x%x\n", current_state, current_state2);
	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | addr, 0x5555, 1);
	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | addr, 0x5555, 2);
	usleep(100);
	current_state = APS_ReadFPGA(device, gRegRead | addr, 1);
	current_state2 = APS_ReadFPGA(device, gRegRead | addr, 2);
	dlog(DEBUG_INFO,"0x5555 FPGA1: 0x%x FPGA2 0x%x\n", current_state, current_state2);
	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | addr, 0x0000, 1);
	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | addr, 0x0000, 2);
	usleep(100);
	current_state = APS_ReadFPGA(device, gRegRead | addr, 1);
	current_state2 = APS_ReadFPGA(device, gRegRead | addr, 2);
	dlog(DEBUG_INFO,"0x0000 FPGA1: 0x%x FPGA2 0x%x\n", current_state, current_state2);
	dlog(DEBUG_INFO,"Simultaneous writes\n");
	// simultaneous writes of single HIGH bits
	for (i = 0; i < 16; i++) {
		data = 1 << i;
		APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | addr, data, 3);
		current_state = APS_ReadFPGA(device, gRegRead | addr, 1);
		current_state2 = APS_ReadFPGA(device, gRegRead | addr, 2);
		dlog(DEBUG_INFO,"0x%4x FPGA1: 0x%x FPGA2 0x%x\n", data, current_state, current_state2);
	}
	// simultaneous writes with multiple HIGH bits
	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | addr, 0xaaaa, 3);
	current_state = APS_ReadFPGA(device, gRegRead | addr, 1);
	current_state2 = APS_ReadFPGA(device, gRegRead | addr, 2);
	dlog(DEBUG_INFO,"0xaaaa FPGA1: 0x%x FPGA2 0x%x\n", current_state, current_state2);
	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | addr, 0x5555, 3);
	current_state = APS_ReadFPGA(device, gRegRead | addr, 1);
	current_state2 = APS_ReadFPGA(device, gRegRead | addr, 2);
	dlog(DEBUG_INFO,"0x5555 FPGA1: 0x%x FPGA2 0x%x\n", current_state, current_state2);
	
	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | addr, 0x00ff, 3);
	current_state = APS_ReadFPGA(device, gRegRead | addr, 1);
	current_state2 = APS_ReadFPGA(device, gRegRead | addr, 2);
	dlog(DEBUG_INFO,"0x00ff FPGA1: 0x%x FPGA2 0x%x\n", current_state, current_state2);
	usleep(100);
	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | addr, 0xff00, 3);
	usleep(100);
	current_state = APS_ReadFPGA(device, gRegRead | addr, 1);
	current_state2 = APS_ReadFPGA(device, gRegRead | addr, 2);
	dlog(DEBUG_INFO,"0xff00 FPGA1: 0x%x FPGA2 0x%x\n", current_state, current_state2);
	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | addr, 0xffff, 3);
	usleep(100);
	current_state = APS_ReadFPGA(device, gRegRead | addr, 1);
	current_state2 = APS_ReadFPGA(device, gRegRead | addr, 2);
	dlog(DEBUG_INFO,"0xffff FPGA1: 0x%x FPGA2 0x%x\n", current_state, current_state2);
	usleep(100);
	usleep(100);
	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | addr, 0x0000, 3);
	usleep(100);
	current_state = APS_ReadFPGA(device, gRegRead | addr, 1);
	current_state2 = APS_ReadFPGA(device, gRegRead | addr, 2);
	dlog(DEBUG_INFO,"0x0000 FPGA1: 0x%x FPGA2 0x%x\n", current_state, current_state2);
	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | addr, 0x0000, 3);
	usleep(100);
	current_state = APS_ReadFPGA(device, gRegRead | addr, 1);
	current_state2 = APS_ReadFPGA(device, gRegRead | addr, 2);
	dlog(DEBUG_INFO,"Try again to write 0x0000 FPGA1: 0x%x FPGA2 0x%x\n", current_state, current_state2);
	// clear the registers
	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | addr, 0x0000, 1);
	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | addr, 0x0000, 2);
	usleep(100);
	current_state = APS_ReadFPGA(device, gRegRead | addr, 1);
	current_state2 = APS_ReadFPGA(device, gRegRead | addr, 2);
	dlog(DEBUG_INFO,"Cleared values FPGA1: 0x%x FPGA2 0x%x\n", current_state, current_state2);
	return 0;
}
