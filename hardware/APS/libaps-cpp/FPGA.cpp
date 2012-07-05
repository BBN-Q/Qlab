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


// sets Status/CTRL register to default state when running (OSCEN enabled)
int FPGA::reset_status_ctrl(FT_HANDLE deviceHandle)
{
	UCHAR WriteByte = APS_OSCEN_BIT;
	return FPGA::write_register(deviceHandle, APS_STATUS_CTRL, 0, 0, &WriteByte);
}

// clears Status/CTRL register. This is the required state to program the VCXO and PLL
int FPGA::clear_status_ctrl(FT_HANDLE deviceHandle)
{
	UCHAR WriteByte = APS_OSCEN_BIT;
	return FPGA::write_register(deviceHandle, APS_STATUS_CTRL, 0, 0, &WriteByte);
}

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
	bool ok = false; // flag to indicate test worked
	UCHAR readByte, writeByte;

	//Steps 1 and 2
	for(int ct = 0; ct < maxAttemptCnt && !ok; ct++) {
		FILE_LOG(logDEBUG2) << "Attempt: "  << ct+1;
		// Read the Status to get state of RESETN for unused channel
		//TODO: is this necessary or used at all?
		if(FPGA::read_register(deviceHandle, APS_CONF_STAT, 1, 0, &readByte) != 1) return(-1);
		FILE_LOG(logDEBUG2) << "Read 1: " << myhex << int(readByte);

		// Clear Program and Reset Masks
		writeByte = ~PgmMask & ~RstMask & 0xF;
		FILE_LOG(logDEBUG2) << "Write 1: "  << myhex << int(writeByte);
		if(FPGA::write_register(deviceHandle,  APS_CONF_STAT, 1, 0, &writeByte) != 1) return(-2);

		// Read the Status to see that INITN is asserted in response to PROGRAMN
		if(FPGA::read_register(deviceHandle, APS_CONF_STAT, 1, 0, &readByte) != 1) return(-3);
		FILE_LOG(logDEBUG2) << "Read 2: " <<  myhex << int(readByte);

		// verify Init bits are cleared
		if((readByte & InitMask) == 0) ok = true;
	}
	if (!ok) return -4;

	//Steps 3 and 4
	for(int ct = 0, ok = 0; ct < maxAttemptCnt && ok == 0; ct++) {
		FILE_LOG(logDEBUG2) << "Attempt: "  << ct+1;

		// Set Program and Reset Bits
		writeByte = (PgmMask | RstMask) & 0xF;
		FILE_LOG(logDEBUG2) << "Write 2: " << myhex << int(writeByte);
		if(FPGA::write_register(deviceHandle, APS_CONF_STAT, 1, 0, &writeByte) != 1)return(-5);

		// sleep to allow init to take place
		// if the sleep is left out the next test might fail
		usleep(1000);

		// Read the Status to see that INITN is deasserted in response to PROGRAMN deassertion
		if(FPGA::read_register(deviceHandle, APS_CONF_STAT, 1, 0, &readByte) != 1) return(-6);
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
	ok = false;
	for(int ct = 0; ct < maxAttemptCnt && !ok; ct++) {
		if(FPGA::read_register(deviceHandle, APS_CONF_STAT, 1, 0, &readByte) != 1) return(-3);
		FILE_LOG(logDEBUG2) << "Read 4: " << myhex << int(readByte) << " (looking for " << int(DoneMask) << " HIGH)";
		if ((readByte & DoneMask) == DoneMask) ok = true;
		usleep(1000); // if done has not set wait a bit
	}

	if (!ok) {FILE_LOG(logWARNING) << "FPGAs did not set DONE bits after programming, attempting to continue.";}


	FILE_LOG(logDEBUG) << "Done programming FPGA";

	// wait 10ms for FPGA to deal with the bitfile data
	usleep(10000);

	// Read Bit File Version
	int version;
	ok = false;
	for (int ct = 0; ct < maxAttemptCnt && !ok; ct++) {
		version =  FPGA::read_bitFile_version(deviceHandle, chipSelect);
		if (version == expectedVersion) ok = true;
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

		if (!FT_SUCCESS(ftStatus) || bytesWritten != 1){
			FILE_LOG(logDEBUG2) << "FPGA::read_register: Error writing to USB with status = " << ftStatus << "; bytes written = " << bytesWritten << "; repeat count = " << repeats;
			continue;
		}

		usleep(100);

		//Read the result
		ftStatus = FT_Read(deviceHandle, Data, packetLength, &bytesRead);
		if (repeats > 0) {FILE_LOG(logDEBUG2) << "Retry USB Read " << repeats;}
		if (!FT_SUCCESS(ftStatus) || bytesRead != packetLength){
			FILE_LOG(logDEBUG2) << "FPGA::read_register: Error reading from USB with status = " << ftStatus << "; bytes read = " << bytesRead << "; repeat count = " << repeats;
		}
		else{
			break;
		}
	}
	if (!FT_SUCCESS(ftStatus) || bytesRead != packetLength){
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
		ftStatus = FT_Write(deviceHandle, &dataPacket[0], packetLength+1, &bytesWritten);
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
	FILE_LOG(logDEBUG2) << "Bitfile version for FPGA " << chipSelect << " is "  << myhex << version;
	break;
case 3:
	version = FPGA::read_FPGA(deviceHandle, FPGA_ADDR_REGREAD | FPGA_OFF_VERSION, 1);
	version &= 0x1FF; // First 9 bits hold version
	FILE_LOG(logDEBUG2) << "Bitfile version for FPGA 1 is "  << myhex << version;
	version2 = FPGA::read_FPGA(deviceHandle, FPGA_ADDR_REGREAD | FPGA_OFF_VERSION, 2);
	version2 &= 0x1FF; // First 9 bits hold version
	FILE_LOG(logDEBUG2) << "Bitfile version for FPGA 2 is "  << myhex << version2;
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

	FILE_LOG(logDEBUG2) << "Reading address " << myhex << addr << " with data " << data;

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

	// address checksum is defined as (bits 0-14: addr, 15: 0)
	// so, set bit 15 to zero
	if ((fpga==1) || (fpga == 3)) {
		FPGA::checksumAddr[deviceHandle][0] += addr & 0x7FFF;
		FPGA::checksumData[deviceHandle][0] += data;
	}
	if((fpga==1) || (fpga == 3)) {
		FPGA::checksumAddr[deviceHandle][1] += addr & 0x7FFF;
		FPGA::checksumData[deviceHandle][1] += data;
	}

	FILE_LOG(logDEBUG2) << "Writing Addr: " << myhex << addr << " Data: " << data;

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
	FILE_LOG(logDEBUG2) << "Addr: " << myhex << addr << " Current State: " << currentState << " Writing: " << (currentState & ~mask);

	//TODO: take out if possible
	usleep(100);

	FPGA::write_FPGA(deviceHandle, FPGA_ADDR_REGWRITE | addr, currentState & ~mask, fpga);

	if (FILELog::ReportingLevel() >= logDEBUG2) {
		// verify write
		//TODO: take out if possible
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
	FILE_LOG(logDEBUG2) << "Addr: " <<  myhex << addr << " Current State: " << currentState << " Mask: " << mask << " Writing: " << (currentState | mask);

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


// Write the PLL setup
int FPGA::setup_PLL(FT_HANDLE deviceHandle)
{
	FILE_LOG(logINFO) << "Setting up PLL";

	// Disable DDRs
	int ddr_mask = CSRMSK_CHA_DDR | CSRMSK_CHB_DDR;
	FPGA::clear_bit(deviceHandle, 3, FPGA_OFF_CSR, ddr_mask);

	// Setup modified for 300 MHz FPGA clock rate
	//Setup of a vector of address-data pairs for all the writes we need for the PLL routine
	//TODO: this could be an initializer list when cl supports it
	vector<std::pair<ULONG, UCHAR > > PLL_Routine;
	PLL_Routine.reserve(27);

	PLL_Routine.push_back(std::make_pair(0x0,  0x99));  // Use SDO, Long instruction mode
	PLL_Routine.push_back(std::make_pair(0x10, 0x7C));  // Enable PLL , set charge pump to 4.8ma
	PLL_Routine.push_back(std::make_pair(0x11, 0x5));   // Set reference divider R to 5 to divide 125 MHz reference to 25 MHz
	PLL_Routine.push_back(std::make_pair(0x14, 0x06));  // Set B counter to 6
	PLL_Routine.push_back(std::make_pair(0x16, 0x5));   // Set P prescaler to 16 and enable B counter (N = P*B = 96 to divide 2400 MHz to 25 MHz)
	PLL_Routine.push_back(std::make_pair(0x17, 0x4));   // Selects readback of N divider on STATUS bit in Status/Control register
	PLL_Routine.push_back(std::make_pair(0x18, 0x60));  // Calibrate VCO with 2 divider, set lock detect count to 255, set high range
	PLL_Routine.push_back(std::make_pair(0x1A, 0x2D));  // Selects readback of PLL Lock status on LOCK bit in Status/Control register
	PLL_Routine.push_back(std::make_pair(0x1C, 0x7));   // Enable differential reference, enable REF1/REF2 power, disable reference switching
	PLL_Routine.push_back(std::make_pair(0xF0, 0x00));  // Enable un-inverted 400mv clock on OUT0
	PLL_Routine.push_back(std::make_pair(0xF1, 0x00));  // Enable un-inverted 400mv clock on OUT1
	PLL_Routine.push_back(std::make_pair(0xF2, 0x00));  // Enable un-inverted 400mv clock on OUT2
	PLL_Routine.push_back(std::make_pair(0xF3, 0x00));  // Enable un-inverted 400mv clock on OUT3
	PLL_Routine.push_back(std::make_pair(0xF4, 0x00));  // Enable un-inverted 400mv clock on OUT4
	PLL_Routine.push_back(std::make_pair(0xF5, 0x00));  // Enable un-inverted 400mv clock on OUT5
	PLL_Routine.push_back(std::make_pair(0x190, 0x00)); //	No division on channel 0
	PLL_Routine.push_back(std::make_pair(0x191, 0x80)); //	Bypass 0 divider
	PLL_Routine.push_back(std::make_pair(0x193, 0x11)); //	(2 high, 2 low = 1.2 GHz / 4 = 300 MHz = Reference 300 MHz)
	PLL_Routine.push_back(std::make_pair(0x196, 0x00)); //	No division on channel 2
	PLL_Routine.push_back(std::make_pair(0x197, 0x80)); //   Bypass 2 divider
	PLL_Routine.push_back(std::make_pair(0x1E0, 0x0));  // Set VCO post divide to 2
	PLL_Routine.push_back(std::make_pair(0x1E1, 0x2));  // Select VCO as clock source for VCO divider
	PLL_Routine.push_back(std::make_pair(0x232, 0x1));  // Set bit 0 to 1 to simultaneously update all registers with pending writes.
	PLL_Routine.push_back(std::make_pair(0x18, 0x71));  // Initiate Calibration.  Must be followed by Update Registers Command
	PLL_Routine.push_back(std::make_pair(0x232, 0x1));  // Set bit 0 to 1 to simultaneously update all registers with pending writes.
	PLL_Routine.push_back(std::make_pair(0x18, 0x70));  // Clear calibration flag so that next set generates 0 to 1.
	PLL_Routine.push_back(std::make_pair(0x232, 0x1));   // Set bit 0 to 1 to simultaneously update all registers with pending writes.

	// Go through the routine
	for (auto tmpPair : PLL_Routine){
		FPGA::write_SPI(deviceHandle, APS_PLL_SPI, tmpPair.first, &tmpPair.second);
	}

	// enable the oscillator
	if (FPGA::reset_status_ctrl(deviceHandle) != 1)
		return -1;

	// Enable DDRs
	FPGA::set_bit(deviceHandle, 3, FPGA_OFF_CSR, ddr_mask);

	return 0;
}




int FPGA::set_PLL_freq(FT_HANDLE deviceHandle, const int & fpga, const int & freq, const bool & testLock)
{

	static int fpgaFrequencies[2] = {1200,1200};

	ULONG pllCyclesAddr, pllBypassAddr;
	UCHAR pllCyclesVal, pllBypassVal;

	int syncStatus;
	int numSyncChannels;

	FILE_LOG(logDEBUG) << "Setting PLL FPGA: " << fpga << " Freq.: " << freq;

	switch(fpga) {
		case 1:
			pllCyclesAddr = FPGA1_PLL_CYCLES_ADDR;
			pllBypassAddr = FPGA1_PLL_BYPASS_ADDR;
			break;
		case 2:
			pllCyclesAddr = FPGA2_PLL_CYCLES_ADDR;
			pllBypassAddr = FPGA2_PLL_BYPASS_ADDR;
			break;
		default:
			return -1;
	}

	switch(freq) {
		case 40: pllCyclesVal = 0xEE; break; // 15 high / 15 low (divide by 30)
		case 50: pllCyclesVal = 0xBB; break;// 12 high / 12 low (divide by 24)
		case 100: pllCyclesVal = 0x55; break; // 6 high / 6 low (divide by 12)
		case 200: pllCyclesVal = 0x22; break; // 3 high / 3 low (divide by 6)
		case 300: pllCyclesVal = 0x11; break; // 2 high /2 low (divide by 4)
		case 600: pllCyclesVal = 0x00; break; // 1 high / 1 low (divide by 2)
		case 1200: pllCyclesVal = 0x00; break; // value ignored, set bypass below
		default:
			return -2;
	}

	// bypass divider if freq == 1200
	pllBypassVal = (freq==1200) ?  0x80 : 0x00;
	FILE_LOG(logDEBUG2) << "Setting PLL cycles addr: " << myhex << pllCyclesAddr << " val: " << int(pllCyclesVal);
	FILE_LOG(logDEBUG2) << "Setting PLL bypass addr: " << myhex << pllBypassAddr << " val: " << int(pllBypassVal);

	// fpga = 1 or 2 save frequency for later comparison to decide to use
	// 4 channel sync or 2 channel sync
	fpgaFrequencies[fpga - 1] = freq;

	// Disable DDRs
	int ddr_mask = CSRMSK_CHA_DDR | CSRMSK_CHB_DDR;
	FPGA::clear_bit(deviceHandle, fpga, FPGA_OFF_CSR, ddr_mask);

	// Disable oscillator by clearing APS_STATUS_CTRL register
	if (FPGA::clear_status_ctrl(deviceHandle) != 1) return -4;

	//Setup of a vector of address-data pairs for all the writes we need for the PLL routine
	vector<std::pair<ULONG, UCHAR > > PLL_Routine;
	PLL_Routine.reserve(6);

	PLL_Routine.push_back(std::make_pair(pllCyclesAddr, pllCyclesVal));
	PLL_Routine.push_back(std::make_pair(pllBypassAddr, pllBypassVal));

	PLL_Routine.push_back(std::make_pair(0x18, 0x71)); // Initiate Calibration.  Must be followed by Update Registers Command
	PLL_Routine.push_back(std::make_pair(0x232, 0x1)); // Set bit 0 to 1 to simultaneously update all registers with pending writes.
	PLL_Routine.push_back(std::make_pair(0x18, 0x70)); // Clear calibration flag so that next set generates 0 to 1.
	PLL_Routine.push_back(std::make_pair(0x232, 0x1)); // Set bit 0 to 1 to simultaneously update all registers with pending writes.

	// Go through the routine
	for (auto tmpPair : PLL_Routine){
		FPGA::write_SPI(deviceHandle, APS_PLL_SPI, tmpPair.first, &tmpPair.second);
	}

	// Enable Oscillator
	//TODO: figure out why this the same as above disabling
	if (FPGA::reset_status_ctrl(deviceHandle) != 1) return -4;

	// Enable DDRs
	FPGA::set_bit(deviceHandle, fpga, FPGA_OFF_CSR, ddr_mask);

	syncStatus = 0;

	if (testLock) {
		// We have reset the global oscillator, so should sync both FPGAs, but the current
		// test only works for channels running at 1.2 GHz
		numSyncChannels = (fpgaFrequencies[0] == 1200 && fpgaFrequencies[1] == 1200) ? 4 : 2;
		if (numSyncChannels == 4) {
			FPGA::test_PLL_sync(deviceHandle, 1, 5);
			syncStatus = FPGA::test_PLL_sync(deviceHandle, 2, 5);
		}
		else if (fpgaFrequencies[fpga] == 1200)
			syncStatus = FPGA::test_PLL_sync(deviceHandle, fpga, 5);
	}

	return syncStatus;
}



int FPGA::test_PLL_sync(FT_HANDLE deviceHandle, const int & fpga, const int & numRetries) {
	/*
		APS_TestPllSync synchronized the phases of the DAC clocks with the following procedure:
		1) Make sure all PLLs have locked.
		2) Test for sync of 600 MHz clocks from DACs. They must be in sync with each other
	    and in sync with the 300 MHz reference. If they are out of sync with each other,
		  the 300 MHz DDR PLLs in the FPGA will come up 90 or 270 degrees out of phase.
		  This has a test signature of the global XOR bit set roughly half the time. If they
	    are in sync but out of phase with the reference, then both DDR PLLs will be 90/270
	    degrees out of phase with the reference (it is sufficient to test only one DDR PLL)
			- If either of these conditions exist, disable and re-enable the PLL output to one
	    of the DACs connected to the FPGA. Reset the FPGA PLLs, wait for lock, then loop.
		3) Test channel 0/2 PLL against reference PLL. Reset until in phase.
		4) Test channel 1/3 PLL against reference PLL. Reset until in phase.
		5) Verify that sync worked by testing 0/2 XOR 1/3 (global phase).
	 *
	 * Inputs: device
	 *         fpga (1 or 2)
	 *         numRetries - number of times to restart the test if the global sync test fails (step 5)
	 */

	// Test for DAC clock phase match
	bool inSync, globalSync;
	vector<int> xorFlagCnts(3);
	int dac02Reset, dac13Reset;

	int pllBit;
	UINT pllRegValue;
	UINT pllResetBit, pllEnableAddr, pllEnableAddr2;
	UCHAR writeByte;

	//TODO: convert back to initializer lists once Microsoft gets its act together
	int tmpPLL_XOR_TEST[] = {PLL_02_XOR_BIT, PLL_13_XOR_BIT,PLL_GLOBAL_XOR_BIT};
	int tmpPLL_LOCK_TEST[] = {PLL_02_LOCK_BIT, PLL_13_LOCK_BIT, REFERENCE_PLL_LOCK_BIT};
	int tmpPLL_RESET[] = {CSRMSK_CHA_PLLRST, CSRMSK_CHB_PLLRST, 0};
	vector<int> PLL_XOR_TEST(tmpPLL_XOR_TEST, tmpPLL_XOR_TEST+3);
	vector<int> PLL_LOCK_TEST(tmpPLL_LOCK_TEST, tmpPLL_LOCK_TEST+3);
	vector<int> PLL_RESET(tmpPLL_RESET, tmpPLL_RESET+3);

	pllResetBit  = CSRMSK_CHA_PLLRST | CSRMSK_CHB_PLLRST;

	FILE_LOG(logINFO) << "Running channel sync on FPGA " << fpga;

	switch(fpga) {
	case 1:
		pllEnableAddr = DAC0_ENABLE_ADDR;
		pllEnableAddr2 = DAC1_ENABLE_ADDR;
		break;
	case 2:
		pllEnableAddr = DAC2_ENABLE_ADDR;
		pllEnableAddr2 = DAC3_ENABLE_ADDR;
		break;
	default:
		return -1;
	}

	// Disable DDRs
	int ddr_mask = CSRMSK_CHA_DDR | CSRMSK_CHB_DDR;
	FPGA::clear_bit(deviceHandle, fpga, FPGA_OFF_CSR, ddr_mask);

	//A little helper function to wait for the PLL's to lock and reset if necessary
	auto wait_PLL_relock = [&deviceHandle, &fpga, &pllResetBit](bool resetPLL, const int & regAddress, const vector<int> & pllBits) -> bool {
		bool inSync = false;
		int testct = 0;
		while (!inSync && (testct < 20)){
			inSync = (FPGA::read_PLL_status(deviceHandle, fpga, regAddress, pllBits) == 0) ? true : false;
			//If we aren't locked then reset for the next try by clearing the PLL reset bits
			if (resetPLL) {
			UINT pllRegValue = FPGA::read_FPGA(deviceHandle, FPGA_ADDR_REGREAD | FPGA_PLL_RESET_ADDR, fpga);
			FPGA::write_FPGA(deviceHandle, FPGA_ADDR_REGWRITE | FPGA_PLL_RESET_ADDR, pllRegValue & ~pllResetBit, fpga);
			}
			//Otherwise just wait
			else{
				usleep(1000);
			}
			testct++;
		}
		return inSync;
	};

	// Step 1: test for the PLL's being locked to the reference
	inSync = wait_PLL_relock(true, FPGA_ADDR_REGREAD | FPGA_OFF_VERSION, PLL_LOCK_TEST);
	if (!inSync) {
		FILE_LOG(logERROR) << "Reference PLL failed to lock";
		return -5;
	}

	inSync = false; globalSync = false;


	//Step 2:
	// start by testing for a global or channel XOR count near 50%, which indicates
	// that DAC 600 MHz clocks have come up out of phase.

	//First a little helper function to update the PLL registers
	auto update_PLL_register = [&deviceHandle] (){
		ULONG address = 0x232;
		UCHAR data = 0x1;
		FPGA::write_SPI(deviceHandle, APS_PLL_SPI, address, &data);
	};

	FILE_LOG(logINFO) << "Testing for DAC clock phase sync";
	//Loop over number of tries
	static const int xorCounts = 20, lowCutoff = 5, highCutoff = 15;
	for (int ct = 0; ct < MAX_PHASE_TEST_CNT; ct++) {
		//Reset the counts
		xorFlagCnts.assign(3,0);
		dac02Reset = 0;
		dac13Reset = 0;

		//Take twenty counts of the the xor data
		for(int xorct = 0; xorct < xorCounts; xorct++) {
			//TODO: fix up the hardcoded ugly stuff and maybe integrate with read_PLL_status
			pllBit = FPGA::read_FPGA(deviceHandle, FPGA_ADDR_SYNC_REGREAD | FPGA_OFF_VERSION, fpga);
			if ((pllBit & 0x1ff) != 2*FIRMWARE_VERSION) {
				FILE_LOG(logERROR) << "Reg 0xF006 bitfile version does not match. Read " << std::hex << (pllBit & 0x1ff);
				return -6;
			}
			xorFlagCnts[0] += (pllBit >> PLL_GLOBAL_XOR_BIT) & 0x1;
			xorFlagCnts[1] += (pllBit >> PLL_02_XOR_BIT) & 0x1;
			xorFlagCnts[2] += (pllBit >> PLL_13_XOR_BIT) & 0x1;
		}

		// due to clock skews, need to accept a range of counts as "0" and "1"
		if ( (xorFlagCnts[0] < lowCutoff || xorFlagCnts[0] > highCutoff) &&
				(xorFlagCnts[1] < lowCutoff || xorFlagCnts[1] > highCutoff) &&
				(xorFlagCnts[2] < lowCutoff || xorFlagCnts[2] > highCutoff) ) {
			// 300 MHz clocks on FPGA are either 0 or 180 degrees out of phase, so 600 MHz clocks
			// from DAC must be in phase. Move on.
			FILE_LOG(logDEBUG2) << "DAC clocks in phase with reference, XOR counts : " << xorFlagCnts[0] << ", " << xorFlagCnts[1] << ", " << xorFlagCnts[2];
			//Get out of MAX_PHAST_TEST ct loop
			break;
		}
		else {
			// 600 MHz clocks out of phase, reset DAC clocks that are 90/270 degrees out of phase with reference
			FILE_LOG(logDEBUG2) << "DAC clocks out of phase; resetting, XOR counts: " << xorFlagCnts[0] << ", " << xorFlagCnts[1] << ", " << xorFlagCnts[2];
			writeByte = 0x2; //disable clock outputs
			//If the 02 XOR Bit is coming up at half-count then reset it
			if (xorFlagCnts[1] >= lowCutoff || xorFlagCnts[1] <= highCutoff) {
				dac02Reset = 1;
				FPGA::write_SPI(deviceHandle, APS_PLL_SPI, pllEnableAddr, &writeByte);
			}
			//If the 02 XOR Bit is coming up at half-count then reset it
			if (xorFlagCnts[2] >= lowCutoff || xorFlagCnts[2] <= highCutoff) {
				dac13Reset = 1;
				FPGA::write_SPI(deviceHandle, APS_PLL_SPI, pllEnableAddr2, &writeByte);
			}
			//Actually update things
			update_PLL_register();
			writeByte = 0x0; // enable clock outputs
			if (dac02Reset)
				FPGA::write_SPI(deviceHandle, APS_PLL_SPI, pllEnableAddr, &writeByte);
			if (dac13Reset)
				FPGA::write_SPI(deviceHandle, APS_PLL_SPI, pllEnableAddr2, &writeByte);
			update_PLL_register();

			// reset FPGA PLLs
			pllRegValue = FPGA::read_FPGA(deviceHandle, FPGA_ADDR_REGREAD | FPGA_PLL_RESET_ADDR, fpga);
			// Write PLL with bits set
			FPGA::write_FPGA(deviceHandle, FPGA_ADDR_REGWRITE | FPGA_PLL_RESET_ADDR, pllRegValue | pllResetBit, fpga);
			// Clear reset bits
			FPGA::write_FPGA(deviceHandle, FPGA_ADDR_REGWRITE | FPGA_PLL_RESET_ADDR, pllRegValue & ~pllResetBit, fpga);

			// wait for the PLL to relock
			inSync = wait_PLL_relock(false, FPGA_ADDR_REGREAD | FPGA_OFF_VERSION, PLL_LOCK_TEST);
			if (!inSync) {
				FILE_LOG(logERROR) << "PLLs did not re-sync after reset";
				return -7;
			}
		}
	}

	//Steps 3,4,5
	//TODO: fix when MSVC is better
	const char * tmpStrs[] = {"02", "13", "Global"};
	vector<string> pllStrs(tmpStrs, tmpStrs+3);
	for (int pll = 0; pll < 3; pll++) {

		FILE_LOG(logDEBUG) << "Testing channel " << pllStrs[pll];
		for (int ct = 0; ct < MAX_PHASE_TEST_CNT; ct++) {

			int xorFlagCnt = 0;

			for(int xorct = 0; xorct < xorCounts; xorct++) {
				pllBit = FPGA::read_FPGA(deviceHandle, FPGA_ADDR_SYNC_REGREAD | FPGA_OFF_VERSION, fpga);
				if ((pllBit & 0x1ff) != 2*FIRMWARE_VERSION) {
					FILE_LOG(logERROR) << "Reg 0xF006 bitfile version does not match. Read " << std::hex << (pllBit & 0x1ff);
					return -8;
				}
				xorFlagCnt += (pllBit >> PLL_XOR_TEST[pll]) & 0x1;
			}

			// here we are just looking for in-phase or 180 degrees out of phase, so we accept a large
			// range around "0"
			if (xorFlagCnt < lowCutoff) {
				globalSync = true;
				break; // passed, move on to next channel
			}
			else {
				// PLLs out of sync, reset
				FILE_LOG(logDEBUG2) << "Channel " << pllStrs[pll] << " PLL not in sync.. resetting (XOR Count " << xorFlagCnt << " )";
				globalSync = false;

				if (pll == 2) { // global pll compare did not sync
					if (numRetries > 0) {
						FILE_LOG(logDEBUG2) << "Global sync failed; retrying.";
						// restart both DAC clocks and try again
						writeByte = 0x2;
						FPGA::write_SPI(deviceHandle, APS_PLL_SPI, pllEnableAddr, &writeByte);
						FPGA::write_SPI(deviceHandle, APS_PLL_SPI, pllEnableAddr2, &writeByte);
						update_PLL_register();
						writeByte = 0x0;
						FPGA::write_SPI(deviceHandle, APS_PLL_SPI, pllEnableAddr, &writeByte);
						FPGA::write_SPI(deviceHandle, APS_PLL_SPI, pllEnableAddr2, &writeByte);
						update_PLL_register();

						//Try again by recursively calling the same function
						return FPGA::test_PLL_sync(deviceHandle, fpga, numRetries - 1);
					}
					FILE_LOG(logERROR) << "Error could not sync PLLs";
					return -9;
				}

				// Read PLL register
				pllRegValue = FPGA::read_FPGA(deviceHandle, FPGA_ADDR_REGWRITE | FPGA_PLL_RESET_ADDR, fpga);
				// Write PLL with bit set
				FPGA::write_FPGA(deviceHandle, FPGA_ADDR_REGWRITE | FPGA_PLL_RESET_ADDR, pllRegValue | PLL_RESET[pll], fpga);
				// Write original value (making sure to clear the PLL reset bit)
				FPGA::write_FPGA(deviceHandle, FPGA_ADDR_REGWRITE | FPGA_PLL_RESET_ADDR, pllRegValue & ~PLL_RESET[pll], fpga);

				// wait for lock
				inSync = wait_PLL_relock(false, FPGA_ADDR_REGREAD | FPGA_OFF_VERSION, vector<int>(PLL_LOCK_TEST[pll]));
				if (!inSync) {
					FILE_LOG(logERROR) << "PLL " << pllStrs[pll] << " did not re-sync after reset";
					return -10;
				}
			}
		}
	}

	// Enable DDRs
	FPGA::set_bit(deviceHandle, fpga, FPGA_OFF_CSR, ddr_mask);

	if (!globalSync) {
		FILE_LOG(logWARNING) << "PLLs are not in sync";
		return -11;
	}
	FILE_LOG(logINFO) << "Sync test complete";
	return 0;
}


int FPGA::read_PLL_status(FT_HANDLE deviceHandle, const int & fpga, const int & regAddr /*check header for default*/, vector<int> pllLockBits  /*check header for default*/ ){
	/*
	 * Helper function to read the status of some PLL bit and whether the main PLL is locked.
	 */

	//TODO: fix this when MVSC is better
	//Hack around MSVC not supporting initializer lists
	//Should have in the default parameter in the header as {PLL_02_LOCK_BIT, PLL_13_LOCK_BIT, REFERENCE_PLL_LOCK_BIT}
	if (pllLockBits.size() == 0) {
		pllLockBits.push_back(PLL_02_LOCK_BIT); pllLockBits.push_back(PLL_13_LOCK_BIT); pllLockBits.push_back(REFERENCE_PLL_LOCK_BIT);
	}

	int pllStatus = 0;

	//We can latch based off either the USB or PLL clock.  USB seems to flicker so default to PLL for now but
	//we should double check the FIRMWARE_VERSION
	ULONG FIRMWARECHECK;
	if (regAddr == (FPGA_ADDR_SYNC_REGREAD | FPGA_OFF_VERSION)) {
		FIRMWARECHECK = 2*FIRMWARE_VERSION;
	}
	else if (regAddr == (FPGA_ADDR_REGREAD | FPGA_OFF_VERSION)){
		FIRMWARECHECK = FIRMWARE_VERSION;
	}
	else{
		FILE_LOG(logERROR) << "Undefined register address for PLL sync status reading.";
		return -1;
	}

//	pll_bit = FPGA::read_FPGA(deviceHandle, FPGA_ADDR_SYNC_REGREAD | FPGA_OFF_VERSION, fpga); // latched to USB clock (has version 0x020)
//	pll_bit = FPGA::read_FPGA(deviceHandle, FPGA_ADDR_REGREAD | FPGA_OFF_VERSION, fpga); // latched to 200 MHz PLL (has version 0x010)

	ULONG pllRegister = FPGA::read_FPGA(deviceHandle, regAddr, fpga);

	if ((pllRegister & 0x1ff) != FIRMWARECHECK) {
		FILE_LOG(logERROR) << "Reg 0x8006 bitfile version does not match. Read: " << std::hex << (pllRegister & 0x1ff);
		return -1;
	}

	//Check each of the clocks in series
	for(int tmpBit : pllLockBits){
		pllStatus |= ((pllRegister >> tmpBit) & 0x1);
		FILE_LOG(logDEBUG2) << "FPGA " << fpga << " PLL status: " << ((pllRegister >> tmpBit) & 0x1);
	}
	return pllStatus;
}

int FPGA::get_PLL_freq(FT_HANDLE deviceHandle, const int & fpga) {
	// Poll APS PLL chip to determine current frequency

	ULONG pll_cycles_addr, pll_bypass_addr;
	UCHAR pll_cycles_val, pll_bypass_val;

	int freq;

	FILE_LOG(logDEBUG2) << "Getting PLL frequency for FGPA " << fpga;

	switch(fpga) {
	case 1:
		pll_cycles_addr = FPGA1_PLL_CYCLES_ADDR;
		pll_bypass_addr = FPGA1_PLL_BYPASS_ADDR;
		break;
	case 2:
		pll_cycles_addr = FPGA2_PLL_CYCLES_ADDR;
		pll_bypass_addr = FPGA2_PLL_BYPASS_ADDR;
		break;
	default:
		return -1;
	}

	FPGA::read_SPI(deviceHandle, APS_PLL_SPI, pll_cycles_addr, &pll_cycles_val);
	FPGA::read_SPI(deviceHandle, APS_PLL_SPI, pll_bypass_addr, &pll_bypass_val);

	// select frequency based on pll cycles setting
	// the values here should match the reverse lookup in FGPA::set_PLL_freq

	if (pll_bypass_val == 0x80 && pll_cycles_val == 0x00)
		return 1200;
	switch(pll_cycles_val) {
		case 0xEE: freq = 40;  break;
		case 0xBB: freq = 50;  break;
		case 0x55: freq = 100; break;
		case 0x22: freq = 200; break;
		case 0x11: freq = 300; break;
		case 0x00: freq = 600; break;
		default:
			return -2;
	}

	FILE_LOG(logDEBUG2) << "PLL frequency for FPGA: " << fpga << " Freq: " << freq;

	return freq;
}


// Write the standard VCXO setup
int FPGA::setup_VCXO(FT_HANDLE deviceHandle)
{

	FILE_LOG(logINFO) << "Setting up VCX0";

	// Register 00 VCXO value, MS Byte First
	UCHAR Reg00Bytes[4] = {0x8, 0x60, 0x0, 0x4};

	// Register 01 VCXO value, MS Byte First
	UCHAR Reg01Bytes[4] = {0x64, 0x91, 0x0, 0x61};

	// ensure the oscillator is disabled before programming
	if (FPGA::clear_status_ctrl(deviceHandle) != 1)
		return -1;

	FPGA::write_SPI(deviceHandle, APS_VCXO_SPI, 0, Reg00Bytes);
	FPGA::write_SPI(deviceHandle, APS_VCXO_SPI, 0, Reg01Bytes);

	return 0;
}

int FPGA::reset_checksums(FT_HANDLE deviceHandle, const int & fpga){
	// write to registers to clear them
	FPGA::write_FPGA(deviceHandle, FPGA_OFF_DATA_CHECKSUM, 0, fpga);
	FPGA::write_FPGA(deviceHandle, FPGA_OFF_ADDR_CHECKSUM, 0, fpga);
	//Reset the software side too
	FPGA::checksumAddr[deviceHandle].assign(2,0);
	FPGA::checksumData[deviceHandle].assign(2,0);

	return 0;
}

bool FPGA::verify_checksums(FT_HANDLE deviceHandle, const int & fpga) {
	//Checks that software and hardware checksums agree

	ULONG checksumData, checksumAddr;
	if (fpga < 0 || fpga == 3) {
		FILE_LOG(logERROR) << "Can only check the checksum of one fpga at a time.";
		return false;
	}

	checksumAddr = FPGA::read_FPGA(deviceHandle, FPGA_ADDR_REGREAD | FPGA_OFF_ADDR_CHECKSUM, fpga);
	checksumData = FPGA::read_FPGA(deviceHandle, FPGA_ADDR_REGREAD | FPGA_OFF_DATA_CHECKSUM, fpga);

	FILE_LOG(logINFO) << "Checksum Address (hardware =? software): " << myhex << checksumAddr << " =? "
			<< FPGA::checksumAddr[deviceHandle][fpga-1] << " Data: " << checksumData << " =? "
			<< FPGA::checksumData[deviceHandle][fpga-1];

	return ((checksumAddr == FPGA::checksumAddr[deviceHandle][fpga-1]) &&
		(checksumData == FPGA::checksumData[deviceHandle][fpga-1]));
}

//Write waveform data FPGA memory
int FPGA::write_waveform(FT_HANDLE deviceHandle, const int & dac, const vector<short> & wfData) {

	int dacOffset, dacSize, dacWrite, dacRead, dacMemLock;
	int fpga;
	ULONG tmpData, wfLength;
	//We assume the Channel object has properly formated the waveform
	// setup register addressing based on DAC
	switch(dac) {
		case 0:
		case 2:
			dacOffset = FPGA_OFF_CHA_OFF;
			dacSize   = FPGA_OFF_CHA_SIZE;
			dacMemLock = CSRMSK_CHA_MEMLCK;
			dacWrite =  FPGA_ADDR_CHA_WRITE;
			break;
		case 1:
		case 3:
			dacOffset = FPGA_OFF_CHB_OFF;
			dacSize   = FPGA_OFF_CHB_SIZE;
			dacMemLock = CSRMSK_CHB_MEMLCK;
			dacWrite =  FPGA_ADDR_CHB_WRITE;
			break;
		default:
			return -2;
	}

	dacRead = FPGA_ADDR_REGREAD | dacWrite;

	//Waveform length used by FPGA must be an integer multiple of WF_MODULUS and is 0 counted
	wfLength = wfData.size() / WF_MODULUS - 1;

	fpga = dac2fpga(dac);
	if (fpga < 0) {
		return -1;
	}

	FILE_LOG(logDEBUG) << "Loading Waveform length " << wfData.size() << " (FPGA count = " << wfLength << " ) into FPGA  " << fpga << " DAC " << dac;

	//Write the waveform parameters
	//TODO: handle arbitrary offsets
	FPGA::write_FPGA(deviceHandle, FPGA_ADDR_REGWRITE | dacOffset, 0, fpga);
	FPGA::write_FPGA(deviceHandle, FPGA_ADDR_REGWRITE | dacSize, wfLength, fpga);

	if (FILELog::ReportingLevel() >= logDEBUG2) {
		//Double check it took
		tmpData = FPGA::read_FPGA(deviceHandle, FPGA_ADDR_REGREAD | dacOffset, fpga);
		FILE_LOG(logDEBUG2) << "Offset set to: " << myhex << tmpData;
		tmpData = FPGA::read_FPGA(deviceHandle, FPGA_ADDR_REGREAD | dacSize, fpga);
		FILE_LOG(logDEBUG2) << "Size set to: " << tmpData;
		FILE_LOG(logDEBUG2) << "Loading waveform at " << myhex << dacWrite;
	}

	//Reset the checksums
	FPGA::reset_checksums(deviceHandle, fpga);

	//Pack the waveform data and write it
	DWORD bytesWritten = 0;
	vector<UCHAR> tmpVec = FPGA::pack_waveform(deviceHandle, fpga, dacOffset, wfData);
	FT_Write(deviceHandle, &tmpVec[0], tmpVec.size(), &bytesWritten);

	//Verify the checksums
	if (!FPGA::verify_checksums(deviceHandle, fpga)){
		FILE_LOG(logERROR) << "Checksums didn't match after writing waveform data";
		return -2;
	}

	return 0;
}



vector<UCHAR> pack_waveform(FT_HANDLE deviceHandle, const int & fpga, const ULONG & startAddr, const vector<short> & data){
	/*
	 * Helper function to pack waveform data into command packages.
	 * Given a starting address and a vector of values it packs into into a byte vector of repeated
	 *  Command - 2 byte address - 2 byte data
	 */


	//Reserve space for the output vector.  As per above we need 5 bytes per data entry
	vector<UCHAR> vecOut;
	vecOut.reserve(5*data.size());

	const int LSB_MASK = 0xFF;

	//Loop
	ULONG curAddr = startAddr;
	for (short tmpData : data){
		//First the Command byte (we're sending 4 bytes so transferSize selector is 2)
		vecOut.push_back(APS_FPGA_IO | (fpga<<2) | 2);
		//Now the two address bytes
		vecOut.push_back((curAddr >> 8) & LSB_MASK);
		vecOut.push_back(curAddr & LSB_MASK);
		//Now the two data bytes
		vecOut.push_back((tmpData >> 8) & LSB_MASK);
		vecOut.push_back(tmpData & LSB_MASK);

		//Update the checksums
		//Address checksum is defined as (bits 0-14: addr, 15: 0)
		// so, set bit 15 to zero
		FPGA::checksumAddr[deviceHandle][fpga-1] += curAddr & 0x7FFF;
		curAddr++;
		FPGA::checksumData[deviceHandle][fpga-1] += tmpData;
	}

	return vecOut;
}


int FPGA::set_LL_mode(FT_HANDLE deviceHandle, const int & dac, const bool & enable, const bool & mode)
/********************************************************************
 * Description : Loads LinkList to FPGA
 *
 * Inputs :
*              enable -  enable link list 1 = enabled 0 = disabled
*              mode - 1 = DC mode 0 = waveform mode
*
* Returns : 0 on success < 0 on failure
*
********************************************************************/
{
  int fpga;
  int dacEnableMask, dacModeMask, ctrlReg;

  fpga = dac2fpga(dac);
  if (fpga < 0) {
    return -1;
  }

  // setup register addressing based on DAC
  switch(dac) {
    case 0:
    case 2:
      dacEnableMask = CSRMSK_CHA_OUTMODE;
      dacModeMask   = CSRMSK_CHA_LLMODE;
      break;
    case 1:
    case 3:
      dacEnableMask = CSRMSK_CHB_OUTMODE;
      dacModeMask   = CSRMSK_CHB_LLMODE;
      break;
    default:
      return -2;
  }

  //Load the current CSR register
  ctrlReg = FPGA::read_FPGA(deviceHandle, FPGA_ADDR_REGREAD | FPGA_OFF_CSR, fpga);
  FILE_LOG(logDEBUG2) << "Current CSR: " << myhex << ctrlReg;

  //Set or clear the enable bit
  FILE_LOG(logINFO) << "Setting Link List Enable ==> FPGA: " << fpga << " DAC: " << dac << " Enable: " << enable;
  if (enable) {
    FPGA::set_bit(deviceHandle, fpga, FPGA_OFF_CSR, dacEnableMask);
  } else {
    FPGA::clear_bit(deviceHandle, fpga, FPGA_OFF_CSR, dacEnableMask);
  }

  //Set or clear the mode bit
  FILE_LOG(logINFO) << "Setting Link List Mode ==> FPGA: " << fpga << " DAC: " << dac << " Mode: " << mode;
  if (mode) {
	  FPGA::set_bit(deviceHandle, fpga, FPGA_OFF_CSR, dacModeMask);
  } else {
	  FPGA::clear_bit(deviceHandle, fpga, FPGA_OFF_CSR, dacModeMask);
  }

  return 0;
}

