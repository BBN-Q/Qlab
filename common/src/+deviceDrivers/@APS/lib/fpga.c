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
#include <stdlib.h>
#include <unistd.h>
#include "aps.h"
#include "fpga.h"
#include "libaps.h"
#include "common.h"
#include "waveform.h"

#ifdef LOG_WRITE_FPGA
FILE * outfile = 0;
#endif

int gBitFileVersion = 0; // set default version to 0 as all valid version numbers are > 0
int gRegRead =  FPGA_ADDR_REGREAD; // register read address to or
WORD gCheckSum[MAX_APS_DEVICES][2] = {0}; // checksum for data written to each fpga
WORD gAddrCheckSum[MAX_APS_DEVICES][2] = {0}; // checksum for addresses written to each fpga

extern waveform_t * waveforms[]; // from libaps.c

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
	// cmd
	buffer[0] = cmd;
	// offset
	buffer[1] = (addr >> 8) & LSB_MASK;
	buffer[2]  = addr & LSB_MASK;
	buffer[3]  = (offset >> 8) & LSB_MASK;
	buffer[4]  = offset & LSB_MASK;
	// count
	buffer[5] = ((addr+1) >> 8) & LSB_MASK;
	buffer[6]  = (addr+1) & LSB_MASK;
	buffer[7]  = (count >> 8) & LSB_MASK;
	buffer[8]  = count & LSB_MASK;
	// trigger
	buffer[9] = ((addr+2) >> 8) & LSB_MASK;
	buffer[10]  = (addr+2) & LSB_MASK;
	buffer[11]  = (trigger >> 8) & LSB_MASK;
	buffer[12]  = trigger & LSB_MASK;
	// repeat
	buffer[13] = ((addr+3) >> 8) & LSB_MASK;
	buffer[14]  = (addr+3) & LSB_MASK;
	buffer[15]  = (repeat >> 8) & LSB_MASK;
	buffer[16]  = repeat & LSB_MASK;
	
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

	// address checksum is defined as (bits 0-14: addr, 15: 0)
	// so, set bit 15 to zero
	if (fpga == 3) {
		gAddrCheckSum[device][0] += addr & 0x7FFF;
		gCheckSum[device][0] += data;
		gAddrCheckSum[device][1] += addr & 0x7FFF;
		gCheckSum[device][1] += data;
	} else {
		gAddrCheckSum[device][fpga - 1] += addr & 0x7FFF;
		gCheckSum[device][fpga - 1] += data;
	}

	dlog(DEBUG_VERBOSE2,"Writing Addr 0x%x Data 0x%x\n", addr, data);

	return APS_WriteReg(device, APS_FPGA_IO, 2, fpga, outdata);
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
	// write to registers to clear them
	APS_WriteFPGA(device, FPGA_OFF_DATA_CHECKSUM, 0, fpga);
	APS_WriteFPGA(device, FPGA_OFF_ADDR_CHECKSUM, 0, fpga);
	gCheckSum[device][fpga-1] = 0;
	gAddrCheckSum[device][fpga-1] = 0;
	return 0;
}

EXPORT UINT APS_ResetAllCheckSum() {
	int i;
	for (i = 0; i < MAX_APS_DEVICES; i++) {
		gCheckSum[i][0] = 0;
		gCheckSum[i][1] = 0;
		gAddrCheckSum[i][0] = 0;
		gAddrCheckSum[i][1] = 0;
	}
	return 0;
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
		                      int nbrSamples, int memory_offset, int dac,
		                      int validate, int storeWaveform)
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

	max_wf_length = K8;
	if(nbrSamples > max_wf_length ) {
		dlog(DEBUG_INFO,"[WARNING] Waveform length > Maximum. Truncating waveform");
		nbrSamples = max_wf_length;
	}

	// waveform length used by FPGA must be an integer multiple of WF_MODULUS
	wf_length = nbrSamples / WF_MODULUS - 1;


	if (nbrSamples % WF_MODULUS != 0) {
		dlog(DEBUG_INFO,"[WARNING] Waveform data needs to be padded");
	}
	
	int16_t *scaledData;
	if (storeWaveform) {
		// use APS_SetWaveform() to scale and shift data
		dlog(DEBUG_VERBOSE, "Storing waveform\n");
		APS_SetWaveform(device, dac, Data, nbrSamples, INT_TYPE);
		scaledData = WF_GetDataPtr(waveforms[device], dac);
	} else {
		scaledData = Data;
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

	if (memory_offset < 0 || memory_offset > max_wf_length) {
		dlog(DEBUG_INFO, "APS_LoadWaveform ERROR: Waveform memory offset out of range\n");
		return -3;
	}

	// check to make sure that waveform will fit
	if ((memory_offset + nbrSamples) > max_wf_length) {
		dlog(DEBUG_INFO, "APS_LoadWaveform ERROR: Waveform has too many samples\n");
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

	// write waveform mode parameters (memory offset and length)
	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | dac_offset, memory_offset, fpga);
	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | dac_size, wf_length, fpga);

	if (getDebugLevel() >= DEBUG_VERBOSE) {
		data = APS_ReadFPGA(device, gRegRead | dac_offset, fpga);
		dlog(DEBUG_VERBOSE,"Offset set to: %i\n", data);

		data = APS_ReadFPGA(device, gRegRead | dac_size, fpga);
		dlog(DEBUG_VERBOSE,"Size set to: %i\n", data);
		dlog(DEBUG_VERBOSE,"Loading %s (%i) Waveform at 0x%x ...\n", dac_type, dac, dac_write);
	}

	int error = 0;

	// Adjust start of writing by offset
	dac_write += memory_offset;

	#define ADDRDATASIZE 5
	
	// clear checksums
	APS_ResetCheckSum(device, fpga);

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
		APS_FormatForFPGA(formatedDataIdx, dac_write + cnt, scaledData[cnt], fpga);
		formatedDataIdx += ADDRDATASIZE;
		// address checksum is defined as (bits 0-14: addr, 15: 0)
		// so, set bit 15 to zero
		addr = dac_write + cnt;
		addr &= 0x7FFF;
		gAddrCheckSum[device][fpga-1] += addr;
		gCheckSum[device][fpga-1] += scaledData[cnt];
	}

	//struct timeval t0, t1;
	//gettimeofday(&t0, NULL);
	APS_WriteBlock(device, formated_length, formatedData);
	//gettimeofday(&t1, NULL);
	free(formatedData);
	//printf("Time to write: %f\n", (1/1e6)*(t1.tv_sec*1e6 + t1.tv_usec - t0.tv_sec*1e6 - t0.tv_usec));
	
	// verify the checksum
	data = APS_CompareCheckSum(device, fpga);
	if (!data) {
		dlog(DEBUG_INFO, "APS_LoadWaveform ERROR: Checksum does not match\n");
		return -6;
	}
	
	// this section does a word by word comparison of the written data
	if (validate != 0) {
		dlog(DEBUG_VERBOSE,"Validating Waveform\n");
		
		for(cnt = 0; cnt < nbrSamples; cnt++) {
			data = APS_ReadFPGA(device, dac_read + cnt, fpga);
			// only lower word is valid
			data &= 0xFFFF;
			if (data != (scaledData[cnt] & 0xFFFF)) {
				dlog(DEBUG_INFO,"Error reading back memory: cnt = %i expected 0x%x read 0x%x\n", cnt, Data[cnt] & 0xFFFF, data);
				error = 1;
			}
		}
		
		if (!error) {
			dlog(DEBUG_VERBOSE,"Read back complete: no errors found\n");
		}
	}
  
	dlog(DEBUG_VERBOSE,"LoadWaveform Done\n");

	if (getDebugLevel() >= DEBUG_VERBOSE) {
	    data = APS_ReadFPGA(device, gRegRead | FPGA_OFF_CSR, fpga);
	    dlog(DEBUG_VERBOSE,"CSR set to: 0x%x\n", data);
	}
	
	// mark the stored waveform as 'loaded'
	if (storeWaveform) {
		WF_SetIsLoaded(waveforms[device], dac, 1);
	}
	// mark the channel as enabled
	APS_SetWaveformEnabled(device, dac, 1);

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

	return 0;
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

	return 0;
}

EXPORT int APS_Run(int device, int trigger_type)
/***********************************************
 *
 * Function name: APS_Run()
 *
 * Description: Triggers all enabled channels
 *
 * Inputs: device ID
 *         trigger_type - 1 software, 2 hardware
 *
 * Returns: 0
 *
 ***********************************************/
 {
	int enabledChannels[MAX_APS_CHANNELS];
	int triggeredFPGA[2] = {0, 0};
	int allEnabled = 1;
	int ch;
	
	for (ch = 0; ch < MAX_APS_CHANNELS; ch++) {
		enabledChannels[ch] = WF_GetEnabled(waveforms[device], ch);
		allEnabled = allEnabled && enabledChannels[ch];
	}
	
	if (allEnabled) {
		APS_TriggerFpga(device, -1, trigger_type);
	} else {
		// trigger paired channels if possible
		if (enabledChannels[0] && enabledChannels[1]) {
			triggeredFPGA[0] = 1;
			APS_TriggerFpga(device, 0, trigger_type);
		}
		if (enabledChannels[2] && enabledChannels[3]) {
			triggeredFPGA[1] = 1;
			APS_TriggerFpga(device, 2, trigger_type);
		}

		// otherwise, trigger individuals channels
		for (ch = 0; ch < MAX_APS_CHANNELS; ch++) {
			if (!triggeredFPGA[ch/2] && enabledChannels[ch]) {
				APS_TriggerDac(device, ch, trigger_type);
			}
		}
	}
	
	return 0;
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

	APS_ClearBit(device, fpga,FPGA_OFF_TRIGLED, dac_sw_trig);

	dlog(DEBUG_VERBOSE, "Reset %s State Machine ... \n", dac_type);

	APS_SetBit(device, fpga,FPGA_OFF_CSR, dac_sm_reset);
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

	ULONG formated_length;
	BYTE * formatedData;
	BYTE * formatedDataIdx;

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

	// set link list size
	ctrl_reg = (length-1) & 0x3FFF;

	// if bank is Bank B need to add 0x200 to length
	if (bank == 1) {
		ctrl_reg = ctrl_reg + 0x200;  // Link List B offset is 0x200 (on DAC side)
	}

	dlog(DEBUG_VERBOSE,"Writing Link List Control Reg: 0x%x = 0x%x\n", dac_ctrl_reg,ctrl_reg);

	// write control reg
	APS_WriteFPGA(device, dac_ctrl_reg, ctrl_reg, fpga);

	if (getDebugLevel() >= DEBUG_VERBOSE) {
		// load current ctrl reg
		ctrl_reg_read = APS_ReadFPGA(device, gRegRead | dac_ctrl_reg, fpga);

		dlog(DEBUG_VERBOSE,"Loaded Link List %s DAC%i... Ctrl Reg = 0x%x\n", dac_type, dac, ctrl_reg_read);

		if (ctrl_reg_read != ctrl_reg) {
			dlog(DEBUG_VERBOSE, "WARNING: LinkList Control Reg Did Not Write Correctly\n");
		}
	}
	
	// clear checksums
	APS_ResetCheckSum(device, fpga);

// ADDRDATASIZE_ELL 1 cmd 8 addr 2 offset 2 count 2 trigger 2 repeat
#define ADDRDATASIZE_ELL 17
	formated_length  = ADDRDATASIZE_ELL * length;  // link list write buffer length in bytes
	formatedData = (BYTE *) malloc(formated_length);
	if (!formatedData)
		return -5;
	formatedDataIdx = formatedData;

	// Format data as would be expected for FPGA
	// This mimics the calls to APS_WriteFPGA followed by APS_WriteReg

	for(cnt = 0; cnt < length; cnt++) {
		APS_FormatForFPGA_ELL(formatedDataIdx, dac_write + 4*cnt,
								OffsetData[cnt], CountData[cnt],
								TriggerData[cnt], RepeatData[cnt],
								fpga );
		formatedDataIdx += ADDRDATASIZE_ELL;
		// address checksum is defined as (bits 0-14: addr, 15: 0)
		// so, set bit 15 to zero
		gAddrCheckSum[device][fpga-1] += (dac_write + 4*cnt) & 0x7FFF;
		gAddrCheckSum[device][fpga-1] += (dac_write + 4*cnt+1) & 0x7FFF;
		gAddrCheckSum[device][fpga-1] += (dac_write + 4*cnt+2) & 0x7FFF;
		gAddrCheckSum[device][fpga-1] += (dac_write + 4*cnt+3) & 0x7FFF;
		gCheckSum[device][fpga-1] += OffsetData[cnt];
		gCheckSum[device][fpga-1] += CountData[cnt];
		gCheckSum[device][fpga-1] += TriggerData[cnt];
		gCheckSum[device][fpga-1] += RepeatData[cnt];
	}
	APS_WriteBlock(device,formated_length, formatedData);
	free(formatedData);

	// verify the checksum
	ULONG data = APS_CompareCheckSum(device, fpga);
	if (!data) {
		dlog(DEBUG_INFO, "APS_LoadLinkList ERROR: Checksum does not match\n");
	}
	
	if (validate) {
		for(cnt = 0; cnt < length; cnt++) {
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

	// zero repeat register
	//APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | dac_rpt_reg, 0, fpga);

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
		dlog(DEBUG_INFO, "Link lists not supported on this bitfile version\n.");
		return -1;
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

	dlog(DEBUG_VERBOSE,"Clear Link List ELL\n");

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

  dlog(DEBUG_VERBOSE, "Setting Link List Enable ==> FPGA: %i DAC: %i Enable: %i\n", fpga, dac, enable);

  // load current CSR register
  ctrl_reg = APS_ReadFPGA(device, gRegRead | FPGA_OFF_CSR, fpga);

  dlog(DEBUG_VERBOSE,"Current CSR: 0x%x\n", ctrl_reg);


  // set link list enable bit
  if (enable) {
	  ctrl_reg |= dac_enable_mask;
  } else {
	  ctrl_reg &= ~dac_enable_mask;
  }

  dlog(DEBUG_VERBOSE, "Setting Link List Mode ==> FPGA: %i DAC: %i Mode: %i\n", fpga, dac, mode);

  // set link list mode bit
  if (mode) {
	  ctrl_reg |= dac_mode_mask;
  } else {
	  ctrl_reg &= ~dac_mode_mask;
  }
  APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | FPGA_OFF_CSR, ctrl_reg, fpga);

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

EXPORT int APS_SetLEDMode(int device, int fpga, int mode)
/********************************************************************
 *
 * Function Name : APS_SetLEDMode()
 *
 * Description : Controls whether the front panel LEDs show the PLL sync
 *		status or the channel output status.
 *
 * Inputs : fpga - 1, 2, or 3
 *          mode  - 1 PLL sync, 2 channel output
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
	if (fpga < 0 || fpga > 3) {
		dlog(DEBUG_INFO, "APS_SetLEDMode ERROR: unknown fpga %d\n", fpga);
		return -1;
	}
	
	switch (mode) {
	case 1:
		APS_ClearBit(device, fpga, FPGA_OFF_TRIGLED, TRIGLEDMSK_MODE);
		break;
	case 2:
		APS_SetBit(device, fpga, FPGA_OFF_TRIGLED, TRIGLEDMSK_MODE);
		break;
	default:
		dlog(DEBUG_INFO, "APS_SetLEDMode ERROR: unknown mode %d\n", mode);
		return -2;
	}
	
	return 0;
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
	int dac_sw_led, dac_trig_src, dac_sw_trig, dac_sm_reset;

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
	int expected_values[] = {-1,-1,0,-1,0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,0xc0de,-1,-1,-1,-1,0xbadd,0xbadd};

	dlog(DEBUG_VERBOSE,"====== Register Read %3i ======\n", readCnt++);

	for(cnt = 0; cnt < 22; cnt++) {
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

EXPORT int APS_IsRunning(int device, int fpga)
/********************************************************************
 *
 * Function Name : APS_IsRunning()
 *
 * Description : Returns 1 if APS is running 0 otherwise
 *
 * Inputs : device device id
 *          fpga (1, 2, or 3 = all dacs)
 *
 * APS is running if any of the channels are enabled
 *
 ********************************************************************/
{
	ULONG csrReg1, csrReg2;
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
	switch (fpga) {
		case 1:
			running = ~csrReg1;
			break;
		case 2:
			running = ~csrReg2;
			break;
		case 3:
			// pass thru
		default:
			running = ~csrReg1 | ~csrReg2;
			break;
	}
	
	return running & 0x1;
}

EXPORT int APS_SetChannelOffset(int device, int dac, float offset)
/* APS_SetChannelOffset
 * Write the zero register for the associated channel and update the channel waveform
 * offset - offset in normalized full range (-1, 1)
 */
{
	int fpga, zero_register_addr;
	int16_t sOffset;
	
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
	if (offset > 1)
		offset = 1;
	if (offset < -1)
		offset = -1;
	sOffset = (int16_t) (offset * (float) MAX_WF_VALUE);
	dlog(DEBUG_INFO, "Setting DAC%i zero register to %i\n", dac, sOffset);
	
	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | zero_register_addr, sOffset, fpga);
	
	// update channel waveform, if necessary
	APS_SetWaveformOffset(device, dac, offset);
	return 0;
}

EXPORT float APS_ReadChannelOffset(int device, int dac)
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
	
	return (float) APS_ReadFPGA(device, gRegRead | zero_register_addr, fpga) / MAX_WF_VALUE;
}

EXPORT int APS_SetTriggerDelay(int device, int dac, unsigned short delay)
/* APS_SetTriggerDelay
 * Write the trigger delay register for the associated channel
 * delay - unsigned 16-bit value (0, 65535) representing the trigger delay in units of FPGA clock cycles
 *         ie., delay of 1 is 3.333 ns at full sampling rate.
 */
{
	int fpga, triggerDelay_register_addr;
	
	fpga = dac2fpga(dac);
	if (fpga < 0) {
		return -1;
	}
	
	switch (dac) {
		case 0:
			// fall through
		case 2:
			triggerDelay_register_addr = FPGA_OFF_DAC02_TRIG_DELAY;
			break;
		case 1:
			// fall through
		case 3:
			triggerDelay_register_addr = FPGA_OFF_DAC13_TRIG_DELAY;
			break;
		default:
			return -2;
	}
	
	dlog(DEBUG_INFO, "Setting DAC%i trigger delay register to %i\n", dac, delay);
	
	APS_WriteFPGA(device, FPGA_ADDR_REGWRITE | triggerDelay_register_addr, delay, fpga);
	return 0;
}

EXPORT unsigned short APS_ReadTriggerDelay(int device, int dac)
/* APS_ReadTriggerDelay
 * Read the trigger delay register for the associated channel
 */
{
	int fpga, triggerDelay_register_addr;
	
	fpga = dac2fpga(dac);
	if (fpga < 0) {
		return -1;
	}
	
	switch (dac) {
		case 0:
			// fall through
		case 2:
			triggerDelay_register_addr = FPGA_OFF_DAC02_TRIG_DELAY;
			break;
		case 1:
			// fall through
		case 3:
			triggerDelay_register_addr = FPGA_OFF_DAC13_TRIG_DELAY;
			break;
		default:
			return -2;
	}
	
	return APS_ReadFPGA(device, gRegRead | triggerDelay_register_addr, fpga);
}

EXPORT int APS_SetWaveformTriggerMode(int device, int dac, int mode)
/* APS_SetWaveformTriggerMode
 * Enables or disables the output of a trigger in waveform mode
 * dac - channel (0-3)
 * mode - 1 (enable trigger), 0 (disable trigger)
 */
{
	int fpga, trigger_mask;
	
	fpga = dac2fpga(dac);
	if (fpga < 0) {
		return -1;
	}

	switch (dac) {
		case 0:
			// fall through
		case 2:
			trigger_mask = TRIGLEDMSK_WFMTRIG02;
			break;
		case 1:
			// fall through
		case 3:
			trigger_mask = TRIGLEDMSK_WFMTRIG13;
			break;
		default:
			return -2;
	}

	dlog(DEBUG_INFO, "Setting DAC%i waveform output mode %i\n", dac, mode);

	if (mode) {
		APS_SetBit(device, fpga, FPGA_OFF_TRIGLED, trigger_mask);
	} else {
		APS_ClearBit(device, fpga, FPGA_OFF_TRIGLED, trigger_mask);
	}
	
	return 0;
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
