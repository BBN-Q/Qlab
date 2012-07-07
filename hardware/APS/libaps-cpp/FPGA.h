/*
 * FGPA.h
 *
 * Hide some of the messy FPGA interaction in here.
 *
 *  Created on: Jun 26, 2012
 *      Author: cryan
 */

#include "headings.h"

#ifndef FGPA_H_
#define FGPA_H_


namespace FPGA {

int program_FPGA(FT_HANDLE, vector<UCHAR>, const int &, const int &);

int read_register(FT_HANDLE, const ULONG &, const ULONG &, const ULONG &, UCHAR *);
int write_register(FT_HANDLE, const ULONG &, const ULONG &, const ULONG &, UCHAR *);

int read_SPI(FT_HANDLE, ULONG, const ULONG &, UCHAR *);
int write_SPI(FT_HANDLE, ULONG, const ULONG &, UCHAR *);

int clear_bit(FT_HANDLE, const int &, const int &, const int &, const int & readAddr = FPGA_ADDR_REGREAD);
int set_bit(FT_HANDLE, const int &, const int &, const int &, const int & readAddr = FPGA_ADDR_REGREAD);

ULONG read_FPGA(FT_HANDLE, const ULONG &, UCHAR);
int write_FPGA(FT_HANDLE, const ULONG &, const ULONG &, const UCHAR &);
int write_FPGA(FT_HANDLE, const ULONG &, const ULONG &, const UCHAR &, vector<CheckSum> &);


int trigger(FT_HANDLE, const int &, const int &);
int disable(FT_HANDLE, const int &);

int read_bitFile_version(FT_HANDLE, const UCHAR &);

int setup_PLL(FT_HANDLE);
int set_PLL_freq(FT_HANDLE, const int &, const int &, const bool &);
int test_PLL_sync(FT_HANDLE, const int &, const int &);
int read_PLL_status(FT_HANDLE deviceHandle, const int & fpga, const int & regAddr = FPGA_ADDR_REGREAD | FPGA_OFF_VERSION, vector<int> pllLockBits = vector<int>(0));
int get_PLL_freq(FT_HANDLE, const int &);

int setup_VCXO(FT_HANDLE);

int setup_DAC(FT_HANDLE, const int &);

int reset_status_ctrl(FT_HANDLE);
int clear_status_ctrl(FT_HANDLE);

int reset_checksums(FT_HANDLE, const int &, vector<CheckSum> &);
bool verify_checksums(FT_HANDLE, const int &, vector<CheckSum> &);

int write_waveform(FT_HANDLE, const int &, const vector<short> &, vector<CheckSum> &);

vector<UCHAR> pack_waveform(FT_HANDLE, const int &, const ULONG &, const vector<short> &, vector<CheckSum> &);

int set_LL_mode(FT_HANDLE, const int &, const bool &, const bool &);

} //end namespace FPGA

inline int dac2fpga(int dac)
{
	/* select FPGA based on DAC id number
	    DAC0 & DAC1 -> FPGA 0
	    DAC2 & DAC3 -> FPGA 1
	    Added a special case: sending dac = -1 will trigger both FPGAs
	    at the same time.
	 */
	switch(dac) {
		case -1:
			return 2;
		case 0:
		case 1:
			return 0;
		case 2:
		case 3:
			return 1;
		default:
			return -1;
	}
}


#endif /* FGPA_H_ */
