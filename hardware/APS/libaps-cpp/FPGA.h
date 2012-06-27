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

int program_FPGA(FT_HANDLE, const vector<UCHAR> &, const int &);

int read_register(FT_HANDLE, const ULONG &, const ULONG &, const ULONG &, UCHAR *);

int write_register(FT_HANDLE, const ULONG &, const ULONG &, const ULONG &, UCHAR *);

int read_bitFile_version(FT_HANDLE, const UCHAR &);

ULONG read_FPGA(FT_HANDLE, const ULONG &, const UCHAR &);

} //end namespace FPGA


#endif /* FGPA_H_ */
