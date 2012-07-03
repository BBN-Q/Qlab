/*
 * FPGA.cpp
 *
 *  Created on: Jun 26, 2012
 *      Author: cryan
 */

#include "headings.h"


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


int FPGA::program_FPGA(FT_HANDLE deviceHandle, vector<UCHAR> bitFileData, const int & chipSelect, const int & expectedVersion) {

	// To configure the FPGAs, you initialize them, send the byte stream, and
	// then wait for the DONE flag to be asserted.

	// Note that FPGAs can be programmed with the same image by setting Sel = 3.
	// However, the pinouts of the connections to the DAC are different for the two
	// FPGAs.  Unless there is a post-configuration modification of the DAC output
	// mapping, a different image must be written to each FPGA.

	// Create bit masks matching Config Status Register bits for the active FPGAs ...
	// Create masks
	UCHAR PgmMask=0, InitMask=0, DoneMask=0, RstMask=0;
	if(chipSelect & 1){
		PgmMask |= APS_PGM01_BIT;
		InitMask |= APS_INIT01_BIT;
		DoneMask |= APS_DONE01_BIT;
		RstMask |= APS_FRST01_BIT;
	}
	if(chipSelect & 2) {
		PgmMask |= APS_PGM23_BIT;
		InitMask |= APS_INIT23_BIT;
		DoneMask |= APS_DONE23_BIT;
		RstMask |= APS_FRST23_BIT;
	}

	FILE_LOG(logDEBUG2) << "Starting to program FPGA Device from FPGA::program_FGPA with chipSelect = " << chipSelect;

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
	int ok = 0; // flag to indicate test worked
	UCHAR readByte, writeByte;

	//Steps 1 and 2
	for(int ct = 0, ok = 0; ct < maxAttemptCnt && ok == 0; ct++) {
		FILE_LOG(logDEBUG2) << "Attempt: " << ct+1;
		// Read the Status to get state of RESETN for unused channel
		if(FPGA::read_register(deviceHandle, APS_CONF_STAT, 1, 0, &readByte) != 1) return(-1);
		FILE_LOG(logDEBUG2) << "Read 1: " << std::hex << readByte;

		// Clear Program and Reset Masks
		writeByte = ~PgmMask & ~RstMask & 0xF;
		FILE_LOG(logDEBUG2) << "Write 1: " << std::hex << writeByte;
		if(FPGA::write_register(deviceHandle,  APS_CONF_STAT, 1, 0, &writeByte) != 1) return(-2);

		// Read the Status to see that INITN is asserted in response to PROGRAMN
		if(FPGA::read_register(deviceHandle, APS_CONF_STAT, 1, 0, &readByte) != 1) return(-3);
		FILE_LOG(logDEBUG2) << "Read 2: " << std::hex << readByte;

		// verify Init bits are cleared
		if((readByte & InitMask) == 0) ok = 1;
	}
	if (!ok) return -4;

	//Steps 3 and 4
	for(int ct = 0, ok = 0; ct < maxAttemptCnt && ok == 0; ct++) {
		FILE_LOG(logDEBUG2) << "Attempt: " << ct+1;

		// Set Program and Reset Bits
		writeByte = (PgmMask | RstMask) & 0xF;
		FILE_LOG(logDEBUG2) << "Write 2: " << std::hex << writeByte;
		if(FPGA::write_register(deviceHandle, APS_CONF_STAT, 1, 0, &writeByte) != 1)return(-5);

		// sleep to allow init to take place
		// if the sleep is left out the next test might fail
		usleep(1000);

		// Read the Status to see that INITN is deasserted in response to PROGRAMN deassertion
		if(FPGA::read_register(deviceHandle, APS_CONF_STAT, 1, 0, &readByte) != 1) return(-6);
		FILE_LOG(logDEBUG2) << "Read 3: " << std::hex << readByte;

		// verify Init Mask is high
		if((readByte & InitMask) == InitMask) ok = 1;
	}
	if (!ok) return -7;

	// Step 5

	// Bit reverse the data
	for(UCHAR & tmpVal : bitFileData)
		tmpVal = BitReverse[tmpVal];

	#define BLOCKSIZE 61

	// At this point, the selected FPGA is ready to receive configuration bytes.
	// Write out all of the bytes in groups of 61 bytes, since that is the most that
	// can be written in a single USB packet.

	for(auto dataIter=bitFileData.begin(); dataIter < bitFileData.end(); dataIter += BLOCKSIZE) {
		// Write a full buffer if not at the end of the input data
		if(dataIter + BLOCKSIZE < bitFileData.end()) {
			if(FPGA::write_register(deviceHandle, APS_CONF_DATA, 0, chipSelect, &*dataIter) != BLOCKSIZE)  // Defaults to 61 bytes for CONF_DATA
				return(-8);
		}
		else {
			// Create a zero padded final buffer
			vector<UCHAR> lastBuffer(BLOCKSIZE, 0);
			std::copy(dataIter, bitFileData.end(), lastBuffer.begin());

			// Write out the last buffer
			if(FPGA::write_register(deviceHandle, APS_CONF_DATA, 0, chipSelect, &lastBuffer[0]) != BLOCKSIZE)  // Defaults to 61 bytes for CONF_DATA
				return(-9);
		}
	}

	int numBytesProgrammed = bitFileData.size();

	// check done bits
	for(int ct = 0, ok = 0; ct < maxAttemptCnt && !ok; ct++) {
		if(FPGA::read_register(deviceHandle, APS_CONF_STAT, 1, 0, &readByte) != 1) return(-3);
		FILE_LOG(logDEBUG2) << "Read 4: " << std::hex << readByte << " (looking for " << DoneMask << " HIGH)";
		if ((readByte & DoneMask) == DoneMask) ok = 1;
		usleep(1000); // if done has not set wait a bit
	}

	if (!ok) {FILE_LOG(logWARNING) << "FPGAs did not set DONE bits after programming, attempting to continue.";}


	FILE_LOG(logDEBUG) << "Done programming FPGA";

	// wait 10ms for FPGA to deal with the bitfile data
	usleep(10000);

	// Read Bit File Version
	int version;
	for (int ct = 0, ok = 0; ct < maxAttemptCnt && !ok; ct++) {
		version =  FPGA::read_bitFile_version(deviceHandle, chipSelect);
		if (version == expectedVersion) ok = 1;
		usleep(1000); // if doesn't match, wait a bit and try again
	}
	if (!ok) return -11;

	// Return the number of data bytes written
	return numBytesProgrammed;
}

int FPGA::read_register(
		FT_HANDLE deviceHandle,
		const ULONG & Command, // APS_FPGA_IO, APS_FPGA_ADDR, APS_CONF_DATA, APS_CONF_STAT, or APS_STATUS_CTRL
		const ULONG & transferSize,    // Transfer size, 0, 1, 2, or 3 for 1, 2, 4, or 8 bytes.  Ignored for Config cycles
		const ULONG & chipSelect,     // Select bits to drive FPGA selects for I/O or Config
		UCHAR *Data    // Buffer for read data
)
{
	UCHAR commandPacket;
	DWORD packetLength, bytesRead, bytesWritten;
	FT_STATUS ftStatus;

	const int max_repeats = 5;

	//Figure out how many bytes we're sending
	switch(Command)
	{
	case APS_FPGA_IO:
		packetLength = 1<<transferSize;
		break;
	case APS_FPGA_ADDR:
	case APS_CONF_STAT:
	case APS_STATUS_CTRL:
		packetLength = 1;
		break;
	default:
		// Illegal command type
		return(-1);
	}
	// Start all packets with a APS Command Byte with the R/W = 1 for read
	commandPacket = 0x80 | Command | (chipSelect<<2) | transferSize;

	// Send the read command with the number of bytes specified in the Command Byte
	for (int repeats = 0; repeats < max_repeats; repeats++) {

		//Write the commmand
		if (repeats > 0) {FILE_LOG(logDEBUG2) << "Retry USB Write " << repeats;}
		ftStatus = FT_Write(deviceHandle, &commandPacket, 1, &bytesWritten);

		if (!FT_SUCCESS(ftStatus) || bytesWritten != 1) {
			FILE_LOG(logDEBUG2) << "FPGA::read_register: Error writing to USB with status = " << ftStatus << "; bytes written = " << bytesWritten << "; repeat count = " << repeats;
			continue;
		}

		usleep(10);

		//Read the result
		ftStatus = FT_Read(deviceHandle, Data, packetLength, &bytesRead);
		if (repeats > 0) {FILE_LOG(logDEBUG2) << "Retry USB Read " << repeats;}
		if (!FT_SUCCESS(ftStatus) || bytesRead != 1){
			FILE_LOG(logDEBUG2) << "FPGA::read_register: Error reading to USB with status = " << ftStatus << "; bytes read = " << bytesRead << "; repeat count = " << repeats;
		}
		else
			break;
	}
	if (!FT_SUCCESS(ftStatus) || bytesRead != 1){
		FILE_LOG(logERROR) << "FPGA::read_register: Error reading to USB with status = " << ftStatus << "; bytes read = " << bytesRead;
		return -1;
	}

	return(bytesRead);
}


int FPGA::write_register(
		FT_HANDLE deviceHandle,
		const ULONG & Command, // APS_FPGA_IO, APS_FPGA_ADDR, APS_CONF_DATA, APS_CONF_STAT, or APS_STATUS_CTRL
		const ULONG & transferSize,    // Transfer size, 0, 1, 2, or 3 for 1, 2, 4, or 8 bytes.  Ignored for Config cycles
		const ULONG & chipSelect,     // Select bits to drive FPGA selects for I/O or Config
		UCHAR * Data    // Data bytes to be written.  Must match length/transfer type
)
{
	vector<UCHAR> dataPacket;
	DWORD packetLength, bytesWritten;
	FT_STATUS ftStatus;

	int repeats;
	const int max_repeats = 5;

	switch(Command)
	{
	case APS_FPGA_IO:
		packetLength = 1<<transferSize;
		break;
	case APS_CONF_DATA:
		packetLength = 61;
		break;
	case APS_FPGA_ADDR:
	case APS_CONF_STAT:
	case APS_STATUS_CTRL:
		packetLength = 1;
		break;
	default:
		// Illegal command type
		return(0);
	}

	dataPacket.reserve(packetLength+1);

	// Start all packets with a APS Command Byte with the R/W = 0 for write
	dataPacket[0] = Command | (chipSelect<<2) | transferSize;

	// Copy data bytes to output packet
	std::copy(Data, Data+packetLength, dataPacket.begin()+1);

	for (repeats = 0; repeats < max_repeats; repeats++) {
		if (repeats > 0) {FILE_LOG(logDEBUG2) << "Repeat Write " << repeats;}
		ftStatus = FT_Write(deviceHandle,static_cast<void*>(&dataPacket[0]), packetLength+1, &bytesWritten);
		if (FT_SUCCESS(ftStatus)) break;
	}

	if (!FT_SUCCESS(ftStatus) || bytesWritten != packetLength+1){
		FILE_LOG(logERROR) << "FPGA::write_register: Error writing to USB status with status = " << ftStatus << "; bytes written = " << bytesWritten;
	}

	// Adjust for command byte when returning bytes written
	return(bytesWritten - 1);
}

int FPGA::read_bitFile_version(FT_HANDLE deviceHandle, const UCHAR & chipSelect) {

// Reads version information from register 0x8006

int version, version2;

//For single FPGA we return that version, for both we return both if the same otherwise error.
switch (chipSelect) {
case 1:
case 2:
	version = FPGA::read_FPGA(deviceHandle, FPGA_ADDR_REGREAD | FPGA_OFF_VERSION, chipSelect);
	version &= 0x1FF; // First 9 bits hold version
	break;
case 3:
	version = FPGA::read_FPGA(deviceHandle, FPGA_ADDR_REGREAD | FPGA_OFF_VERSION, 1);
	version &= 0x1FF; // First 9 bits hold version
	version2 = FPGA::read_FPGA(deviceHandle, FPGA_ADDR_REGREAD | FPGA_OFF_VERSION, 2);
	version2 &= 0x1FF; // First 9 bits hold version
	if (version != version2) {
		FILE_LOG(logERROR) << "Bitfile versions are not the same on the two FPGAs: " << version << " and " << version2;
		return -1;
	}
	break;
default:
	FILE_LOG(logERROR) << "Unknown chipSelect value in APS::read_bitfile_version: " << chipSelect;
	return -1;
}
return version;
}

ULONG FPGA::read_FPGA(FT_HANDLE deviceHandle, const ULONG & addr, UCHAR chipSelect)
/*
 * Specialized form of read_register for FPGA info.
 */
{
	ULONG data;
	UCHAR read[2];

	if (chipSelect == 3) chipSelect = 1; // can only read from one FPGA at a time, assume we want data from FPGA 1

	read[0] = (addr >> 8) & LSB_MASK;
	read[1] = addr & LSB_MASK;

	FPGA::write_register(deviceHandle, APS_FPGA_IO, 1, chipSelect, read);

	read[0] = 0xBA;
	read[1] = 0xD0;

	FPGA::read_register(deviceHandle, APS_FPGA_IO, 1, chipSelect, read);

	data = (read[0] << 8) | read[1];

	FILE_LOG(logDEBUG2) << "Reading address " << std::hex << addr << " with data " << data;

	return data;
}

int FPGA::write_FPGA(FT_HANDLE deviceHandle, const ULONG & addr, const ULONG & data, const UCHAR & fpga)
/********************************************************************
 *
 * Function Name : APS_WriteFPGA()
 *
 * Description :  Writes data to FPGA. 16 bit numbers are unpacked to 2 bytes
 *
 * Inputs :
 *              addr  - Address to write to
 *              data   - Data to write
 *              fpga - FPGA selection bit (1 or 2, 3 = both)
 ********************************************************************/
{
	UCHAR outData[4];

	outData[0] = (addr >> 8) & LSB_MASK;
	outData[1] = addr & LSB_MASK;
	outData[2] = (data >> 8) & LSB_MASK;
	outData[3] = data & LSB_MASK;

	//TODO: sort out where to keep this checksum  info
	// address checksum is defined as (bits 0-14: addr, 15: 0)
	// so, set bit 15 to zero
//	if (fpga == 3) {
//		gAddrCheckSum[device][0] += addr & 0x7FFF;
//		gCheckSum[device][0] += data;
//		gAddrCheckSum[device][1] += addr & 0x7FFF;
//		gCheckSum[device][1] += data;
//	} else {
//		gAddrCheckSum[device][fpga - 1] += addr & 0x7FFF;
//		gCheckSum[device][fpga - 1] += data;
//	}

	FILE_LOG(logDEBUG2) << "Writing Addr: " << std::hex << addr << " Data: " << data;

	FPGA::write_register(deviceHandle, APS_FPGA_IO, 2, fpga, outData);

	return 0;
}


int FPGA::write_SPI
(
		FT_HANDLE deviceHandle,
		ULONG Command,   // APS_DAC_SPI, APS_PLL_SPI, or APS_VCXO_SPI
		const ULONG & Address,   // SPI register address.  Ignored for VCXO since address embedded in the data
		UCHAR *Data      // Data bytes to be written.  1 for DAC, 1 for PLL, or 4 for VCXO.  LS Byte first.
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
	FT_STATUS ftStatus;
	vector<UCHAR> dataPacket(0);
	DWORD bytesWritten;
	vector<UCHAR> byteBuffer(0);

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
		byteBuffer.assign(Data, Data+4);
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

	ftStatus = FT_Write(deviceHandle, &dataPacket[0], dataPacket.size(), &bytesWritten);
	if (!FT_SUCCESS(ftStatus)) {FILE_LOG(logERROR) << "Write SPI command failed";}

	return bytesWritten;
}


int FPGA::read_SPI
(
		FT_HANDLE deviceHandle,
		ULONG Command,   // APS_DAC_SPI, APS_PLL_SPI, or APS_VCXO_SPI
		const ULONG & Address,   // SPI register address.  Ignored for VCXO since address embedded in the data
		UCHAR *Data      // Destination for the returned data byte.  Only single byte reads supported.
)

{
	FT_STATUS ftStatus;
	vector<UCHAR> dataPacket(0);
	DWORD bytesWritten, bytesRead;
	vector<UCHAR> byteBuffer(0);


	// Create a 1 byte read command at the specified address of the specified device
	// Note that the VCXO is not readable
	switch(Command & APS_CMD)
	{
	case APS_DAC_SPI:
		byteBuffer.push_back(Address & 0x1F);  // R/W = 0 for write, N = 00 for 1 Byte, A<4:0> = Address
		byteBuffer.push_back(Data[0]);
		Command |= ((Address & 0x60)>>3);  // Take bits above register address as DAC channel select
		break;
	case APS_PLL_SPI:
		byteBuffer.push_back(0x80 | ((Address>>8) & 0x1F)); // R/W = 0 for write, W = 00 for 1 Byte, A<12:8>
		byteBuffer.push_back(Address & 0xFF);  // A<7:0>
		byteBuffer.push_back(Data[0]);
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


	// Write the SPI command.  This stores the last 8 SPI read bits in the I/O FPGA SerData register
	ftStatus = FT_Write(deviceHandle, &dataPacket[0], dataPacket.size(), &bytesWritten);
	if (!FT_SUCCESS(ftStatus)) {FILE_LOG(logERROR) << "Write SPI command failed";}

	dataPacket[0] |= 0x80;  // Convert the SPI write Command Byte into an SPI read Command Byte

	// Queue a read for the SerData from the previous SPI read command
	ftStatus = FT_Write(deviceHandle, &dataPacket[0], 1, &bytesWritten);
	if (!FT_SUCCESS(ftStatus)) {FILE_LOG(logERROR) << "Write SPI command failed";}


	// Read the one byte of serial data from the SerData register
	ftStatus = FT_Read(deviceHandle, Data, 1, &bytesRead);
	if (!FT_SUCCESS(ftStatus)) {FILE_LOG(logERROR) << "Read SPI command failed";}

	return(bytesRead);

}

int FPGA::set_PLL_freq(FT_HANDLE deviceHandle, const int & dac, const int & freq, const bool & testLock)
{

	static int fpgaFrequencies[2] = {1200,1200};

	ULONG pllCyclesAddr, pllBypassAddr;
	UCHAR pllCyclesVal, pllBypassVal;

	int fpga;
	int syncStatus;
	int numSyncChannels;

	FILE_LOG(logDEBUG) << "Setting PLL DAC: " << dac << " Freq: " << freq;

	fpga = dac2fpga(dac);
	if (fpga < 0) {
		return -1;
	}

	switch(dac) {
	case 0:
		// fall through
	case 1:
		pllCyclesAddr = FPGA1_PLL_CYCLES_ADDR;
		pllBypassAddr = FPGA1_PLL_BYPASS_ADDR;
		break;
	case 2:
		// fall through
	case 3:
		pllCyclesAddr = FPGA2_PLL_CYCLES_ADDR;
		pllBypassAddr = FPGA2_PLL_BYPASS_ADDR;
		break;
	default:
		return -1;
	}

	switch(freq) {
	case 40:
		pllCyclesVal = 0xEE; // 15 high / 15 low (divide by 30)
		break;
	case 50:
		pllCyclesVal = 0xBB; // 12 high / 12 low (divide by 24)
		break;
	case 100:
		pllCyclesVal = 0x55; // 6 high / 6 low (divide by 12)
		break;
	case 200:
		pllCyclesVal = 0x22; // 3 high / 3 low (divide by 6)
		break;
	case 300:
		pllCyclesVal = 0x11; // 2 high /2 low (divide by 4)
		break;
	case 600:
		pllCyclesVal = 0x00; // 1 high / 1 low (divide by 2)
		break;
	case 1200:
		pllCyclesVal = 0x00; // value ignored, set bypass below
		break;
	default:
		return -2;
	}

	// bypass divider if freq == 1200
	pllBypassVal = (freq==1200) ?  0x80 : 0x00;

	FILE_LOG(logDEBUG2) << "Setting PLL cycles addr: " << std::hex << pllCyclesAddr << " val: " << pllCyclesVal;
	FILE_LOG(logDEBUG2) << "Setting PLL bypass addr: " << std::hex << pllBypassAddr << " val: " << pllBypassVal;

	// fpga = 1 or 2 save frequency for later comparison to decide to use
	// 4 channel sync or 2 channel sync
	fpgaFrequencies[fpga - 1] = freq;

	// Disable DDRs
	int ddr_mask = CSRMSK_CHA_DDR | CSRMSK_CHB_DDR;
	FPGA::clear_bit(deviceHandle, fpga, FPGA_OFF_CSR, ddr_mask);

	// Disable oscillator by clearing APS_STATUS_CTRL register
	UCHAR WriteByte = APS_OSCEN_BIT;
	if (FPGA::write_register(deviceHandle, APS_STATUS_CTRL, 0, 0, &WriteByte) != 1) return -4;

	//Setup of a vector of address-data pairs for all the writes we need for the PLL routine
	vector<std::pair<ULONG, UCHAR > > PLLroutine;

	PLLroutine.push_back(std::make_pair(pllCyclesAddr, pllCyclesVal));
	PLLroutine.push_back(std::make_pair(pllBypassAddr, pllBypassVal));

	PLLroutine.push_back(std::make_pair(0x18, 0x71)); // Initiate Calibration.  Must be followed by Update Registers Command
	PLLroutine.push_back(std::make_pair(0x232, 0x1)); // Set bit 0 to 1 to simultaneously update all registers with pending writes.
	PLLroutine.push_back(std::make_pair(0x18, 0x70)); // Clear calibration flag so that next set generates 0 to 1.
	PLLroutine.push_back(std::make_pair(0x232, 0x1)); // Set bit 0 to 1 to simultaneously update all registers with pending writes.

	// Go through the routine
	for (auto tmpPair : PLLroutine){
		FPGA::write_SPI(deviceHandle, APS_PLL_SPI, tmpPair.first, &tmpPair.second);
	}

	// Enable Oscillator
	//TODO: figure out why this the same as above disabling
	WriteByte = APS_OSCEN_BIT;
	if (FPGA::write_register(deviceHandle, APS_STATUS_CTRL, 0, 0, &WriteByte) != 1) return -4;


	// Enable DDRs
	FPGA::set_bit(deviceHandle, fpga, FPGA_OFF_CSR, ddr_mask);

	syncStatus = 0;

	if (testLock) {
		// We have reset the global oscillator, so should sync both FPGAs, but the current
		// test only works for channels running at 1.2 GHz
		numSyncChannels = (fpgaFrequencies[0] == 1200 && fpgaFrequencies[1] == 1200) ? 4 : 2;
		if (numSyncChannels == 4) {
			APS_TestPllSync(device, 1, 5);
			syncStatus = APS_TestPllSync(device, 2, 5);
		}
		else if (fpgaFrequencies[fpga] == 1200)
			syncStatus = APS_TestPllSync(device, fpga, 5);
	}

	return syncStatus;
}

int FPGA::clear_bit(FT_HANDLE deviceHandle, const int & fpga, const int & addr, const int & mask)
/*
 * Description : Clears Bit in FPGA register
 * Returns : 0
 *
 ********************************************************************/
{
	//Read the current state so we know how set the uncleared bits.
	int currentState, currentState2;
	//Use a lambda because we'll need the same call below
	auto check_cur_state = [&] () {
		currentState = FPGA::read_FPGA(deviceHandle, FPGA_ADDR_REGREAD | addr, 1);
		if (fpga == 3) { // read the two FPGAs serially
			currentState2 = FPGA::read_FPGA(deviceHandle, FPGA_ADDR_REGREAD | addr, 2);
			if (currentState != currentState2) {
				// note the mismatch in the log file but continue on using FPGA1's data
				FILE_LOG(logERROR) << "FPGA::clear_bit: FPGA registers don't match. Addr: << " << std::hex << addr << " FPGA1: " << currentState << " FPGA2: " << currentState2;
			}
		}
	};

	check_cur_state();
	FILE_LOG(logDEBUG2) << "Addr: " << std::hex << addr << " Current State: " << currentState << " Writing: " << (currentState & ~mask);

	usleep(100);

	FPGA::write_FPGA(deviceHandle, FPGA_ADDR_REGWRITE | addr, currentState & ~mask, fpga);

	if (FILELog::ReportingLevel() >= logDEBUG2) {
		// verify write
		usleep(100);
		check_cur_state();
	}

	return 0;
}


int FPGA::set_bit(FT_HANDLE deviceHandle, const int & fpga, const int & addr, const int & mask)
/*
 * Description : Sets Bit in FPGA register
 * Returns : 0
 *
 ********************************************************************/
{

	//Read the current state so we know how set the uncleared bits.
	int currentState, currentState2;
	//Use a lambda because we'll need the same call below
	auto check_cur_state = [&] () {
		currentState = FPGA::read_FPGA(deviceHandle, FPGA_ADDR_REGREAD | addr, 1);
		if (fpga == 3) { // read the two FPGAs serially
			currentState2 = FPGA::read_FPGA(deviceHandle, FPGA_ADDR_REGREAD | addr, 2);
			if (currentState != currentState2) {
				// note the mismatch in the log file but continue on using FPGA1's data
				FILE_LOG(logERROR) << "FPGA::set_bit: FPGA registers don't match. Addr: << " << std::hex << addr << " FPGA1: " << currentState << " FPGA2: " << currentState2;
			}
		}
	};

	check_cur_state();
	FILE_LOG(logDEBUG2) << "Addr: " << std::hex << addr << " Current State: " << currentState << " Writing: " << (currentState & ~mask);

	usleep(100);

	FPGA::write_FPGA(deviceHandle, FPGA_ADDR_REGWRITE | addr, currentState | mask, fpga);

	if (FILELog::ReportingLevel() >= logDEBUG2) {
		// verify write
		usleep(100);
		check_cur_state();
		if ((currentState & mask) == 0) {
			FILE_LOG(logERROR) << "ERROR: FPGA::set_bit checked data does not match set value";
		}
	}

	return 0;

}






