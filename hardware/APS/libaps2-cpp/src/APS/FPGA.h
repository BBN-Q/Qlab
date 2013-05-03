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

int program_FPGA(EthernetControl &, vector<UCHAR>);
int reset(EthernetControl &);

int read_register(EthernetControl &, const ULONG &, const ULONG &, UCHAR *);
int write_register(EthernetControl &, const ULONG &, const ULONG &, UCHAR *);

int read_SPI(EthernetControl &, ULONG, const ULONG &, UCHAR *);
int write_SPI(EthernetControl &, ULONG, const ULONG &, const vector<UCHAR> &);

int clear_bit(EthernetControl &, const uint32_t , const uint32_t );
int set_bit(EthernetControl &, const uint32_t , const uint32_t );

uint32_t read_FPGA(EthernetControl &, const uint32_t &);

int write_FPGA(EthernetControl &, const unsigned int &, const USHORT &);
int write_FPGA(EthernetControl &, const unsigned int &, const WordVec &);
int write_FPGA(EthernetControl &, const unsigned int &, const WordVec &, CheckSum & checksum);

int write_block(EthernetControl &, vector<UCHAR> &, const vector<size_t> &);
vector<UCHAR> format(const unsigned int &, const WordVec &);
vector<size_t> computeCmdByteOffsets(const size_t &);

} //end namespace FPGA




#endif /* FGPA_H_ */
