/*
 * APS.cpp
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#include "APS.h"

APS::APS() {
	// TODO Auto-generated constructor stub
}

APS::~APS() {
	// TODO Auto-generated destructor stub
}

int APS::program_FPGA(const string & bitFile, const UCHAR & chipSelect) {

	//Open the bitfile
	FILE_LOG(logDEBUG2) << "Opening bitfile: " << bitFile;
	std::ifstream FID (bitFile, std::ios::in|std::ios::binary);
	//Get the size
	if (!FID.is_open()){
		FILE_LOG(logERROR) << "Unable to open bitfile: " << bitFile;
		throw runtime_error("Unable to open bitfile.");
	}

	//Copy over the file data to the data vector
	//The default istreambuf_iterator constructor returns the "end-of-stream" iterator.
	vector<UCHAR> fileData(std::istreambuf_iterator<UCHAR>(FID), std::istreambuf_iterator<UCHAR>());
	ULONG numBytes = fileData.size();
	FILE_LOG(logDEBUG) << "Read " << numBytes << " from bitfile";

	//Pass of the data to a lower-level function to actually push it to the FPGA
	FPGA::program_FPGA(_handle, fileData, chipSelect);

	return 0;
}

int APS::read_bitfile_version(const UCHAR & chipSelect){

	//Pass through to FPGA code
	return FGPA::read_bitFile_version(_handle, chipSelect);
}
