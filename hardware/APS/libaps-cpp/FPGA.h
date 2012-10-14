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

int program_FPGA(FT_HANDLE, vector<UCHAR>, const FPGASELECT &);

int read_register(FT_HANDLE, const ULONG &, const ULONG &, const FPGASELECT &, UCHAR *);
int write_register(FT_HANDLE, const ULONG &, const ULONG &, const FPGASELECT &, UCHAR *);

int read_SPI(FT_HANDLE, ULONG, const ULONG &, UCHAR *);
int write_SPI(FT_HANDLE, ULONG, const ULONG &, const vector<UCHAR> &);

int clear_bit(FT_HANDLE, const FPGASELECT &, const int &, const int &);
int set_bit(FT_HANDLE, const FPGASELECT &, const int &, const int &);

USHORT read_FPGA(FT_HANDLE, const ULONG &, FPGASELECT);

int write_FPGA(FT_HANDLE, const unsigned int &, const USHORT &, const FPGASELECT &);
int write_FPGA(FT_HANDLE, const unsigned int &, const WordVec &, const FPGASELECT &);
int write_FPGA(FT_HANDLE, const unsigned int &, const WordVec &, const FPGASELECT &, map<FPGASELECT, CheckSum> &);

int write_block(FT_HANDLE, vector<UCHAR> &);
vector<UCHAR> format(const FPGASELECT &, const unsigned int &, const WordVec &);

} //end namespace FPGA




#endif /* FGPA_H_ */
