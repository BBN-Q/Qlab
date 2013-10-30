/*
 * FPGA.cpp
 *
 *  Created on: Jun 26, 2012
 *      Author: cryan
 */

#include "FPGA.h"

static const UCHAR BitReverse[256] =
{
		0x00, 0x80, 0x40, 0xC0, 0x20, 0xA0, 0x60, 0xE0, 0x10, 0x90, 0x50, 0xD0, 0x30, 0xB0, 0x70, 0xF0,
		0x08, 0x88, 0x48, 0xC8, 0x28, 0xA8, 0x68, 0xE8, 0x18, 0x98, 0x58, 0xD8, 0x38, 0xB8, 0x78, 0xF8,
		0x04, 0x84, 0x44, 0xC4, 0x24, 0xA4, 0x64, 0xE4, 0x14, 0x94, 0x54, 0xD4, 0x34, 0xB4, 0x74, 0xF4,
		0x0C, 0x8C, 0x4C, 0xCC, 0x2C, 0xAC, 0x6C, 0xEC, 0x1C, 0x9C, 0x5C, 0xDC, 0x3C, 0xBC, 0x7C, 0xFC,
		0x02, 0x82, 0x42, 0xC2, 0x22, 0xA2, 0x62, 0xE2, 0x12, 0x92, 0x52, 0xD2, 0x32, 0xB2, 0x72, 0xF2,
		0x0A, 0x8A, 0x4A, 0xCA, 0x2A, 0xAA, 0x6A, 0xEA, 0x1A, 0x9A, 0x5A, 0xDA, 0x3A, 0xBA, 0x7A, 0xFA,
		0x06, 0x86, 0x46, 0xC6, 0x26, 0xA6, 0x66, 0xE6, 0x16, 0x96, 0x56, 0xD6, 0x36, 0xB6, 0x76, 0xF6,
		0x0E, 0x8E, 0x4E, 0xCE, 0x2E, 0xAE, 0x6E, 0xEE, 0x1E, 0x9E, 0x5E, 0xDE, 0x3E, 0xBE, 0x7E, 0xFE,
		0x01, 0x81, 0x41, 0xC1, 0x21, 0xA1, 0x61, 0xE1, 0x11, 0x91, 0x51, 0xD1, 0x31, 0xB1, 0x71, 0xF1,
		0x09, 0x89, 0x49, 0xC9, 0x29, 0xA9, 0x69, 0xE9, 0x19, 0x99, 0x59, 0xD9, 0x39, 0xB9, 0x79, 0xF9,
		0x05, 0x85, 0x45, 0xC5, 0x25, 0xA5, 0x65, 0xE5, 0x15, 0x95, 0x55, 0xD5, 0x35, 0xB5, 0x75, 0xF5,
		0x0D, 0x8D, 0x4D, 0xCD, 0x2D, 0xAD, 0x6D, 0xED, 0x1D, 0x9D, 0x5D, 0xDD, 0x3D, 0xBD, 0x7D, 0xFD,
		0x03, 0x83, 0x43, 0xC3, 0x23, 0xA3, 0x63, 0xE3, 0x13, 0x93, 0x53, 0xD3, 0x33, 0xB3, 0x73, 0xF3,
		0x0B, 0x8B, 0x4B, 0xCB, 0x2B, 0xAB, 0x6B, 0xEB, 0x1B, 0x9B, 0x5B, 0xDB, 0x3B, 0xBB, 0x7B, 0xFB,
		0x07, 0x87, 0x47, 0xC7, 0x27, 0xA7, 0x67, 0xE7, 0x17, 0x97, 0x57, 0xD7, 0x37, 0xB7, 0x77, 0xF7,
		0x0F, 0x8F, 0x4F, 0xCF, 0x2F, 0xAF, 0x6F, 0xEF, 0x1F, 0x9F, 0x5F, 0xDF, 0x3F, 0xBF, 0x7F, 0xFF
};





int FPGA::program_FPGA(const ModuleIo & deviceHandle, vector<UCHAR> bitFileData, const FPGASELECT & chipSelect) {

	FILE_LOG(logDEBUG2) << "Starting to program FPGA Device from FPGA::program_FGPA with chipSelect = " << chipSelect;


	return 0;
}

int FPGA::reset(const ModuleIo & deviceHandle, const FPGASELECT & fpga) {
	
	return 0;
}

int FPGA::read_register(
		const ModuleIo & deviceHandle,
		const ULONG & Command, // APS_FPGA_IO, APS_FPGA_ADDR, APS_CONF_DATA, APS_CONF_STAT, or APS_STATUS_CTRL
		const ULONG & transferSize,    // Transfer size, 0, 1, 2, or 3 for 1, 2, 4, or 8 bytes.  Ignored for Config cycles
		const FPGASELECT & chipSelect,     // Select bits to drive FPGA selects for I/O or Config
		UCHAR *Data    // Buffer for read data
)
{
	
	return 0 ;
}


int FPGA::write_register(
		const ModuleIo & deviceHandle,
		const ULONG & Command, // APS_FPGA_IO, APS_FPGA_ADDR, APS_CONF_DATA, APS_CONF_STAT, or APS_STATUS_CTRL
		const ULONG & transferSize,    // Transfer size, 0, 1, 2, or 3 for 1, 2, 4, or 8 bytes.  Ignored for Config cycles
		const FPGASELECT & chipSelect,     // Select bits to drive FPGA selects for I/O or Config
		UCHAR * Data    // Data bytes to be written.  Must match length/transfer type
)
{
	
	return 0;
}


USHORT FPGA::read_FPGA(const ModuleIo & deviceHandle, const ULONG & addr, FPGASELECT chipSelect)
{

	
	return 0;
}

int FPGA::write_FPGA(const ModuleIo & deviceHandle, const unsigned int & addr, const USHORT & data, const FPGASELECT & fpga){
	//Create a vector and pass on
	return write_FPGA(deviceHandle, addr, vector<USHORT>(1, data), fpga );
}

int FPGA::write_FPGA(const ModuleIo & deviceHandle, const unsigned int & addr, const vector<USHORT> & data, const FPGASELECT & fpga)
/********************************************************************
 *
 * Function Name : Write_FPGA()
 *
 * Description :  Writes data to FPGA.
 *
 * Inputs :		deviceHandle
 *              addr  - starting address to write to
 *              data   - Data to write
 *              fpga - FPGA selection bit (0 or 1, 2 = both)
 ********************************************************************/
{

	
	return 0;
}

int FPGA::write_FPGA(const ModuleIo & deviceHandle, const unsigned int & addr, const vector<USHORT> & data, const FPGASELECT & fpga, map<FPGASELECT, CheckSum> & checksums)
/********************************************************************
 *
 * Function Name : APS_WriteFPGA()
 *
 * Description :  Writes data to FPGA. 16 bit numbers are unpacked to 2 bytes
 *
 * Inputs :
 *              addr  - Address to write to
 *              data   - Data to write
 *              fpga - FPGA selection bit (0 or 1, 2 = both)
 *              checksumAddr - vector of FPGA checksums passed by reference
 *              checksumData - vector of FPGA checksums passed by reference
 ********************************************************************/
{

	
	return 0;
}

int FPGA::write_block(const ModuleIo & deviceHandle, vector<UCHAR> & dataPackets, const vector<size_t> & offsets){

	return 0;
}

vector<UCHAR> FPGA::format(const FPGASELECT & fpga, const unsigned int & addr, const vector<USHORT> & data){
/* Helper function to format data for the FGPA in block mode:
 * 	command byte followed by 4 bytes address
 * 	command byte followed by 2 bytes data length
 * 	n bytes data
 */

	//Some constants
	const UCHAR fpgaSelectMask = fpga << 2;
	const UCHAR write2Bytes = APS_FPGA_IO | fpgaSelectMask | 1;
	const UCHAR write4Bytes = APS_FPGA_IO | fpgaSelectMask | 2;
	const UCHAR write8Bytes = APS_FPGA_IO | fpgaSelectMask | 3;
	const UCHAR writeAddress = APS_FPGA_ADDR | fpgaSelectMask | 2;

	//We return a vector of bytes to write
	vector<UCHAR> dataPacket(0);
	if (data.size() > 0) {
		dataPacket.reserve(5 + 3 + 2*data.size() + data.size()/3 + data.size()%3 );
	}
	else{
		dataPacket.reserve(5);
	}

	//First push on the address
	//4Byte command byte with address line high
	dataPacket.push_back(writeAddress);

	// 4 bytes of address
	dataPacket.push_back((addr >> 24) & LSB_MASK);
	dataPacket.push_back((addr >> 16) & LSB_MASK);
	dataPacket.push_back((addr >> 8) & LSB_MASK);
	dataPacket.push_back(addr & LSB_MASK);

	//Now push on the number of points data if necessary
	if (data.size() > 0){
		// command byte
		dataPacket.push_back(write2Bytes);

		//
		dataPacket.push_back((data.size() >> 8) & LSB_MASK);
		dataPacket.push_back(data.size() & LSB_MASK);

		// push on data
		int ptsRemaining = data.size();
		int ptsToWrite = 0;
		int wfIndex = 0;
		while (ptsRemaining > 0) {
			switch (ptsRemaining) {
			case 1:
				ptsToWrite = 1;
				dataPacket.push_back(write2Bytes);
				break;
			case 2:
			case 3:
				ptsToWrite = 2;
				dataPacket.push_back(write4Bytes);
				break;
			default: // 4 or more
				ptsToWrite = 4;
				dataPacket.push_back(write8Bytes);
				break;
			}

			for (int ct = 0; ct < ptsToWrite; ct++, wfIndex++ ) {
				dataPacket.push_back((data[wfIndex] >> 8) & LSB_MASK);
				dataPacket.push_back(data[wfIndex] & LSB_MASK);
			}
			ptsRemaining -= ptsToWrite;
		}
	}
	return dataPacket;
}

vector<size_t> FPGA::computeCmdByteOffsets(const size_t & dataLength){
/* Helper function to find CMD byte offsets in a data vector formatted for sending to the FPGA. */


	//We return a vector of bytes to write
	vector<size_t> offsets(0);
	if (dataLength > 0) {
		offsets.reserve(2 + dataLength/3 + dataLength%3 );
	}
	else{
		offsets.reserve(1);
	}

	// first byte is always a CMD byte
	offsets.push_back(0);

	if (dataLength > 0){
		// data count CMD
		offsets.push_back(5);

		// current index starts after data count bytes
		int currentIdx = 8;
		int ptsRemaining = dataLength;
		int ptsToWrite=0;
		while (ptsRemaining > 0) {
			switch (ptsRemaining) {
			case 1:
				ptsToWrite = 1;
				break;
			case 2:
			case 3:
				ptsToWrite = 2;
				break;
			default: // 4 or more
				ptsToWrite = 4;
				break;
			}
			offsets.push_back(currentIdx);
			ptsRemaining -= ptsToWrite;
			currentIdx += 1+2*ptsToWrite;
		}
	}
	return offsets;
}

int FPGA::write_SPI
(
		const ModuleIo & deviceHandle,
		ULONG Command,   // APS_DAC_SPI, APS_PLL_SPI, or APS_VCXO_SPI
		const ULONG & Address,   // SPI register address.  Ignored for VCXO since address embedded in the data
		const vector<UCHAR> & Data      // Data bytes to be written.  1 for DAC, 1 for PLL, or 4 for VCXO.  LS Byte first.
)
/********************************************************************
 *
 * Function Name : APS_WriteSPI()
 * Description :
 *      Write data to the selected chip via SPI.  The length of the data depends on the chip.
 *      The DAC requires 2 bytes, the PLL requires 3 bytes, and the VCXO requires 4 bytes.
 *      The format of the data bytes can be found in the data sheets for the chips.
 *      Note that the "data" defines an SPI command with R/W bit, a register address, and any write data.
 *      The values for the Command parameter are in aps.h
 *      Returns the number of bytes written
 *
 *      DAC Data Format for first byte: R/W N1 N0 A4 A3 A2 A1 A0
 *      RW = 0 for write, N = 00 for 1 byte transfer.  A = 5-bit register address
 *      Note that DAC channel specified by Address<6:5>, since only Address<4:0> select DAC registers.
 *
 *      PLL Data format for first two bytes: R/W W1 W0 A12 A11 A10 A9 A8 A7 A6 A5 A4 A3 A2 A1 A0
 *      RW = 0 for write, W = 00 for 1 byte transfer.  A = 13-bit register address
 *
 *      VCXO data format: 32-bit value, with the address embedded in D<1:0>.  Bytes stored MS byte first.
 *      Note that this is not the order of the bytes in a 32 bit integer on little-endian CPUs
 *
 * Inputs :
 *                Command -  APS_DAC_SPI, APS_PLL_SPI, or APS_VCXO_SPI
 *               Address    -  SPI register address.  Ignored for VCXO since address embedded in the data
 *                *Data      -  Data bytes to be written.  1 for DAC, 1 for PLL, or 4 for VCXO.  LS Byte first.
 *
 * Returns : 0 on success <0 on failure
 *
 ********************************************************************/
{

	return 0;
}


int FPGA::read_SPI
(
		const ModuleIo & deviceHandle,
		ULONG Command,   // APS_DAC_SPI, APS_PLL_SPI, or APS_VCXO_SPI
		const ULONG & Address,   // SPI register address.  Ignored for VCXO since address embedded in the data
		UCHAR *Data      // Destination for the returned data byte.  Only single byte reads supported.
)

{
	
	return 0;

}


int FPGA::clear_bit(const ModuleIo & deviceHandle, const FPGASELECT & fpga, const int & addr, const int & mask)
/*
 * Description : Clears Bit in FPGA register
 * Returns : 0
 *
 ********************************************************************/
{
	
	return 0;
}


int FPGA::set_bit(const ModuleIo & deviceHandle, const FPGASELECT & fpga, const int & addr, const int & mask)
/*
 * Description : Sets Bit in FPGA register
 * Returns : 0
 *
 ********************************************************************/
{

	
	return 0;

}



