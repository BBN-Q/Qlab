/*
 * FPGA.cpp
 *
 *  Created on: Jun 26, 2012
 *      Author: cryan
 */

#include "FPGA.h"
#include "APS2.h"

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




#if 0
int FPGA::program_FPGA(EthernetControl & deviceHandle, vector<UCHAR> bitFileData) {

	// To configure the FPGAs, you initialize them, send the byte stream, and
	// then wait for the DONE flag to be asserted.

	// Note that FPGAs can be programmed with the same image by setting Sel = 3.
	// However, the pinouts of the connections to the DAC are different for the two
	// FPGAs.  Unless there is a post-configuration modification of the DAC output
	// mapping, a different image must be written to each FPGA.

	// Create bit masks matching Config Status Register bits for the active FPGAs ...
	// Create masks
	UCHAR PgmMask=0, InitMask=0, DoneMask=0, RstMask=0;

	PgmMask |= APS_PGM01_BIT;
	InitMask |= APS_INIT01_BIT;
	DoneMask |= APS_DONE01_BIT;
	RstMask |= APS_FRST01_BIT;

	FILE_LOG(logDEBUG2) << "Starting to program FPGA Device from FPGA::program_FGPA";

	/*
	 * Programming order:
	 *
	 * 1) clear PGM and RESET
	 * 2) issue status READ and verify init bits are low
	 * 3) set PGM and RESET high
	 * 4) verify init bits are HIGH
	 * 5) write program
	 * 6) test done bits
	 */

	int maxAttemptCnt = 3;
	bool ok = false; // flag to indicate test worked
	UCHAR readByte, writeByte;

	//Steps 1 and 2
	for(int ct = 0; ct < maxAttemptCnt && !ok; ct++) {
		FILE_LOG(logDEBUG2) << "Attempt: "  << ct+1;
		// Read the Status to get state of RESETN for unused channel
		//TODO: is this necessary or used at all?
		if(FPGA::read_register(deviceHandle, APS_CONF_STAT, 0, &readByte) != 1) return(-1);
		FILE_LOG(logDEBUG2) << "Read 1: " << myhex << int(readByte);

		// Clear Program and Reset Masks
		writeByte = ~PgmMask & ~RstMask & 0xF;
		FILE_LOG(logDEBUG2) << "Write 1: "  << myhex << int(writeByte);
		if(FPGA::write_register(deviceHandle,  APS_CONF_STAT, 0, &writeByte) != 1) return(-2);

		// Read the Status to see that INITN is asserted in response to PROGRAMN
		if(FPGA::read_register(deviceHandle, APS_CONF_STAT, 0, &readByte) != 1) return(-3);
		FILE_LOG(logDEBUG2) << "Read 2: " <<  myhex << int(readByte);

		// verify Init bits are cleared
		if((readByte & InitMask) == 0) ok = true;
	}
	if (!ok) return -4;

	//Steps 3 and 4
	for(int ct = 0, ok = 0; ct < maxAttemptCnt && ok == 0; ct++) {
		FILE_LOG(logDEBUG2) << "Attempt: "  << ct+1;

		// Set *ALL* Program and Reset Bits
		writeByte = (APS_PGM_BITS | APS_FRST_BITS) & 0xF;
		FILE_LOG(logDEBUG2) << "Write 2: " << myhex << int(writeByte);
		if(FPGA::write_register(deviceHandle, APS_CONF_STAT, 0,  &writeByte) != 1)return(-5);

		// sleep to allow init to take place
		// if the sleep is left out the next test might fail
		usleep(1000);

		// Read the Status to see that INITN is deasserted in response to PROGRAMN deassertion
		if(FPGA::read_register(deviceHandle, APS_CONF_STAT, 0, &readByte) != 1) return(-6);
		FILE_LOG(logDEBUG2) << "Read 3: "  << myhex << int(readByte);

		// verify Init Mask is high
		if((readByte & InitMask) == InitMask) ok = 1;
	}
	if (!ok) return -7;

	// Step 5

	// Bit reverse the data
	for(UCHAR & tmpVal : bitFileData)
		tmpVal = BitReverse[tmpVal];

	static const int BLOCKSIZE = 61;

	// At this point, the selected FPGA is ready to receive configuration bytes.
	// Write out all of the bytes in groups of 61 bytes, since that is the most that
	// can be written in a single APS packet.

	for(auto dataIter=bitFileData.begin(); dataIter < bitFileData.end(); dataIter += BLOCKSIZE) {
		// Write a full buffer if not at the end of the input data
		if(dataIter + BLOCKSIZE < bitFileData.end()) {
			if(FPGA::write_register(deviceHandle, APS_CONF_DATA, 0, &*dataIter) != BLOCKSIZE)  // Defaults to 61 bytes for CONF_DATA
				return(-8);
		}
		else {
			// Create a zero padded final buffer
			vector<UCHAR> lastBuffer(BLOCKSIZE, 0);
			std::copy(dataIter, bitFileData.end(), lastBuffer.begin());

			// Write out the last buffer
			if(FPGA::write_register(deviceHandle, APS_CONF_DATA, 0, &lastBuffer.front()) != BLOCKSIZE)  // Defaults to 61 bytes for CONF_DATA
				return(-9);
		}
	}

	int numBytesProgrammed = bitFileData.size();

	// check done bits
	ok = false;
	for(int ct = 0; ct < maxAttemptCnt && !ok; ct++) {
		if(FPGA::read_register(deviceHandle, APS_CONF_STAT, 1, &readByte) != 1) return(-3);
		FILE_LOG(logDEBUG2) << "Read 4: " << myhex << int(readByte) << " (looking for " << int(DoneMask) << " HIGH)";
		if ((readByte & DoneMask) == DoneMask) ok = true;
		usleep(1000); // if done has not set wait a bit
	}

	if (!ok) {FILE_LOG(logWARNING) << "FPGAs did not set DONE bits after programming, attempting to continue.";}


	FILE_LOG(logDEBUG) << "Done programming FPGA";

	// wait 10ms for FPGA to deal with the bitfile data
	usleep(10000);

	// Assert FPGA_RESETN to reset all registers and state machines
	reset(deviceHandle);

	// Return the number of data bytes written
	return numBytesProgrammed;
}
#endif

int FPGA::reset(EthernetControl & deviceHandle) {
	
	FILE_LOG(logDEBUG) << "Resetting FPGA ";
	uint32_t RstMask=0;
	
	RstMask |= APS_FRST01_BIT;
	
	FILE_LOG(logDEBUG2) << "Reset mask " << myhex << RstMask;
	// Bring RESETN low to reset all registers and state machines
	uint32_t writeByte = ~RstMask & 0xF;
	if(deviceHandle.WriteRegister(APS_CONF_STAT, writeByte) != EthernetControl::SUCCESS) 
		return(-1);

	// Bring RESETN back high
	writeByte = 0xF;
	if(deviceHandle.WriteRegister( APS_CONF_STAT, writeByte) != EthernetControl::SUCCESS) 
		return(-2);

	return 0;
}

#if 0
int FPGA::read_register(
		EthernetControl & deviceHandle,
		const ULONG & Command, // APS_FPGA_IO, APS_FPGA_ADDR, APS_CONF_DATA, APS_CONF_STAT, or APS_STATUS_CTRL
		const ULONG & transferSize,    // Transfer size, 0, 1, 2, or 3 for 1, 2, 4, or 8 bytes.  Ignored for Config cycles
		UCHAR *Data    // Buffer for read data
)
{

	FILE_LOG(logERROR) << "Error: FGPA::read_register no longer valid user EthernetControl::ReadRegister";
}


int FPGA::write_register(
		EthernetControl & deviceHandle,
		const ULONG & Command, // APS_FPGA_IO, APS_FPGA_ADDR, APS_CONF_DATA, APS_CONF_STAT, or APS_STATUS_CTRL
		const ULONG & transferSize,    // Transfer size, 0, 1, 2, or 3 for 1, 2, 4, or 8 bytes.  Ignored for Config cycles
		UCHAR * Data    // Data bytes to be written.  Must match length/transfer type
)
{
	FILE_LOG(logERROR) << "Error: FGPA::write_register no longer valid user EthernetControl::WriteRegister";
}


uint32_t FPGA::read_FPGA(EthernetControl & deviceHandle, const uint32_t & addr)
{
	FILE_LOG(logWARNING) << "Error: FGPA::read_FPGA no longer valid user EthernetControl::ReadRegister";

	uint32_t data;
	deviceHandle.ReadRegister(addr, data);
	return data;
}

int FPGA::write_FPGA(EthernetControl & deviceHandle, const unsigned int & addr, const USHORT & data){
	//Create a vector and pass on
	FILE_LOG(logWARNING) << "Error: FGPA::write_FPGA no longer valid user EthernetControl::WriteRegister";
	return deviceHandle.WriteRegister(addr, data);
}

int FPGA::write_FPGA(EthernetControl & deviceHandle, const unsigned int & addr, const vector<USHORT> & data)
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

	FILE_LOG(logERROR) << "Error: FGPA::write_FPGA not implemented";
	return 0;
	//Format for the block write
	vector<UCHAR> dataPacket = format(addr, data);
	vector<size_t> offsets = computeCmdByteOffsets(data.size());
	if (data.size() > 0) {
		FILE_LOG(logDEBUG2) << "Writing " << data.size() << " words at starting address: " << myhex << addr << " with Data[0]: " << data[0];
	}

	//Write to device
	return write_block(deviceHandle, dataPacket, offsets);

	return 0;
}

int FPGA::write_FPGA(EthernetControl & deviceHandle, const unsigned int & addr, const vector<USHORT> & data, CheckSum & checksum)
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

	FILE_LOG(logERROR) << "Error: FGPA::write_FPGA w/ checksum not implemented";
	return 0;

	//Call the basic function to write the data
	int bytesWritten;
	bytesWritten = write_FPGA(deviceHandle, addr, data);

	//Now update the software checksums
	// address checksum is defined as lower word

	checksum.address += addr & 0xFFFF;
	for (auto tmpData : data)
		checksum.data += tmpData;
	
	return bytesWritten;
}
#endif

int FPGA::write_block(EthernetControl & deviceHandle, vector<UCHAR> & dataPackets, const vector<size_t> & offsets){

	FILE_LOG(logERROR) << "FPGA::write_block not implemented";


	// seems to break with writes longer than 64kB so split on that
	ULONG bytesWritten=0, tmpBytesWritten=0;
/*
	auto curIdx = dataPackets.begin();
	const int maxWriteLength = 65536;
	while (std::distance(curIdx, dataPackets.end()) > 0){
		if (std::distance(curIdx,dataPackets.end()) > maxWriteLength){
			//Find the last command byte where the data packet will fit under 64kB.
			auto breakPt = std::lower_bound(offsets.begin(), offsets.end(), std::distance(curIdx,dataPackets.begin()) + maxWriteLength);
			DWORD ptsToWrite = *(breakPt-1) - std::distance(curIdx,dataPackets.begin());
			//tmpBytesWritten - deviceHandle.Write(&(*curIdx), ptsToWrite);
			bytesWritten += tmpBytesWritten;
			std::advance(curIdx, ptsToWrite);
		}
		else{
			//tmpBytesWritten = deviceHandle.Write(&(*curIdx), std::distance(curIdx,dataPackets.end()));
			bytesWritten += tmpBytesWritten;
			curIdx = dataPackets.end();
		}
	}
*/
	return(bytesWritten);
}


vector<UCHAR> FPGA::format(const unsigned int & addr, const vector<USHORT> & data){
/* Helper function to format data for the FGPA in block mode:
 * 	command byte followed by 4 bytes address
 * 	command byte followed by 2 bytes data length
 * 	n bytes data
 */

 	FILE_LOG(logERROR) << "FPGA::format is no longer valid remove call" << endl;

	//We return a vector of bytes to write
	vector<UCHAR> dataPacket(0);

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

#if 0
int FPGA::write_SPI
(
		EthernetControl & deviceHandle,
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
	vector<UCHAR> dataPacket(0);
	DWORD bytesWritten;
	vector<UCHAR> byteBuffer(0);

	FILE_LOG(logERROR) << "Replace call to FPGA::write_SPI with EthernetControl::WriteSPI";

	switch(Command & APS_CMD)
	{
	case APS_DAC_SPI:
		byteBuffer.push_back(Address & 0x1F);  // R/W = 0 for write, N = 00 for 1 Byte, A<4:0> = Address
		byteBuffer.push_back(Data[0]);
		Command |= ((Address & 0x60)>>3);  // Take bits above register address as DAC channel select
		break;
	case APS_PLL_SPI:
		byteBuffer.push_back((Address>>8) & 0x1F); // R/W = 0 for write, W = 00 for 1 Byte, A<12:8>
		byteBuffer.push_back(Address & 0xFF);  // A<7:0>
		byteBuffer.push_back(Data[0]);
		break;
	case APS_VCXO_SPI:
		// Copy out data bytes to be in MS Byte first order
		byteBuffer = Data;
		break;
	default:
		// Ignore unsupported commands
		return(0);
	}

	// Start all packets with a APS Command Byte with the R/W= 0 for write
	// Note that command byte from DAC has the SEL bits for the desired DAC set
	dataPacket.push_back(Command);

	// Serialize the data into bit 0 of the packet bytes
	for(size_t ct = 0; ct < 8*byteBuffer.size(); ct++)
		dataPacket.push_back( (byteBuffer[ct/8]>>(7-(ct%8))) & 1 );

	//bytesWritten = deviceHandle.Write(&dataPacket[0], dataPacket.size());
	if (bytesWritten != dataPacket.size()) {FILE_LOG(logERROR) << "Write SPI command failed";}

	return bytesWritten;
}


int FPGA::read_SPI
(
		EthernetControl & deviceHandle,
		ULONG target, 
		const ULONG & Address,   // SPI register address.  Ignored for VCXO since address embedded in the data
		UCHAR *Data      // Destination for the returned data byte.  Only single byte reads supported.
)

{
	FILE_LOG(logERROR) << "Replace call to FPGA::read_SPI with EthernetControl::ReadSPI";
}
#endif

int FPGA::clear_bit(EthernetControl & deviceHandle, const uint32_t addr, const uint32_t mask)
/*
 * Description : Clears Bit in FPGA register
 * Returns : 0
 *
 ********************************************************************/
{
	FILE_LOG(logDEBUG2) << "Clearing bit at address: " << myhex << addr;

	//Read the current state so we know how set the uncleared bits.
	uint32_t currentState, currentState2;
	//Use a lambda because we'll need the same call below
	auto check_cur_state = [&] () {
		deviceHandle.ReadRegister(addr, currentState);
	};

	check_cur_state();
	FILE_LOG(logDEBUG2) << "Addr: " << myhex << addr << " Current State: " << currentState << " Writing: " << (currentState & ~mask);

	deviceHandle.WriteRegister(addr, currentState & ~mask);

	if (FILELog::ReportingLevel() >= logDEBUG2) {
		// verify write
		check_cur_state();
	}

	return 0;
}

int FPGA::set_bit(EthernetControl & deviceHandle, const uint32_t addr, const uint32_t mask)
/*
 * Description : Sets Bit in FPGA register
 * Returns : 0
 *
 ********************************************************************/
{

	//Read the current state so we know how set the unset bits.
	uint32_t currentState, currentState2;
	//Use a lambda because we'll need the same call below
	auto check_cur_state = [&] () {
		deviceHandle.ReadRegister(addr, currentState);
	};

	check_cur_state();
	FILE_LOG(logDEBUG2) << "Addr: " <<  myhex << addr << " Current State: " << currentState << " Mask: " << mask << " Writing: " << (currentState | mask);

	deviceHandle.WriteRegister(addr, currentState | mask);

	if (FILELog::ReportingLevel() >= logDEBUG2) {
		// verify write
		check_cur_state();
		if ((currentState & mask) == 0) {
			FILE_LOG(logERROR) << "ERROR: FPGA::set_bit checked data does not match set value";
		}
	}

	return 0;

}



