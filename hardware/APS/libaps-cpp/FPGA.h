/*
 * FGPA.h
 *
 * Hide some of the messy FPGA interaction in here.
 *
 *  Created on: Jun 26, 2012
 *      Author: cryan
 */

#ifndef FGPA_H_
#define FGPA_H_

#include "headings.h"


namespace FPGA {

int program_FPGA(FT_HANDLE, vector<UCHAR>, const int &, const int &);

int read_register(FT_HANDLE, const ULONG &, const ULONG &, const ULONG &, UCHAR *);
int write_register(FT_HANDLE, const ULONG &, const ULONG &, const ULONG &, UCHAR *);

int read_SPI(FT_HANDLE, ULONG, const ULONG &, UCHAR *);
int write_SPI(FT_HANDLE, ULONG, const ULONG &, UCHAR *);

int clear_bit(FT_HANDLE, const int &, const int &, const int &);
int set_bit(FT_HANDLE, const int &, const int &, const int &);

ULONG read_FPGA(FT_HANDLE, const ULONG &, UCHAR);
int write_FPGA(FT_HANDLE, const ULONG &, const ULONG &, const UCHAR &);


int read_bitFile_version(FT_HANDLE, const UCHAR &);

int set_PLL_freq(FT_HANDLE, const int &, const int &, const bool &);
int test_PLL_sync(FT_HANDLE, const int &, const int &);
int read_PLL_status(FT_HANDLE deviceHandle, const int & fpga, const int & regAddr = FPGA_ADDR_REGREAD | FPGA_OFF_VERSION, vector<int> pllLockBits = vector<int>(0));
int get_PLL_freq(FT_HANDLE, const int &);

int reset_status_ctrl(FT_HANDLE);
int clear_status_ctrl(FT_HANDLE);


} //end namespace FPGA

inline int dac2fpga(int dac)
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


#endif /* FGPA_H_ */
