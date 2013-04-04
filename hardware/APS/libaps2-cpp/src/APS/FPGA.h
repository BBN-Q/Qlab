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

int program_FPGA(EthernetControl &, vector<UCHAR>, const FPGASELECT &);
int reset(EthernetControl &, const FPGASELECT &);

int read_register(EthernetControl &, const ULONG &, const ULONG &, const FPGASELECT &, UCHAR *);
int write_register(EthernetControl &, const ULONG &, const ULONG &, const FPGASELECT &, UCHAR *);

int read_SPI(EthernetControl &, ULONG, const ULONG &, UCHAR *);
int write_SPI(EthernetControl &, ULONG, const ULONG &, const vector<UCHAR> &);

int clear_bit(EthernetControl &, const FPGASELECT &, const int &, const int &);
int set_bit(EthernetControl &, const FPGASELECT &, const int &, const int &);

USHORT read_FPGA(EthernetControl &, const ULONG &, FPGASELECT);

int write_FPGA(EthernetControl &, const unsigned int &, const USHORT &, const FPGASELECT &);
int write_FPGA(EthernetControl &, const unsigned int &, const WordVec &, const FPGASELECT &);
int write_FPGA(EthernetControl &, const unsigned int &, const WordVec &, const FPGASELECT &, map<FPGASELECT, CheckSum> &);

int write_block(EthernetControl &, vector<UCHAR> &, const vector<size_t> &);
vector<UCHAR> format(const FPGASELECT &, const unsigned int &, const WordVec &);
vector<size_t> computeCmdByteOffsets(const size_t &);

} //end namespace FPGA




#endif /* FGPA_H_ */
