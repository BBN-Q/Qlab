/*
 * APS.cpp
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#include "APS.h"

APS::APS() : _deviceID(-1), _handle(NULL), _channels(4) {}

APS::APS(int deviceID, string deviceSerial) : _deviceID(deviceID), _deviceSerial(deviceSerial), _handle(NULL){
		for(int ct=0; ct<4; ct++){
			_channels.push_back(Channel(ct));
		}
};

APS::~APS() {
	// TODO Auto-generated destructor stub
}

int APS::connect(){
	int success = 0;
	success = FTDI::connect(_deviceID, _handle);
	if (success == 0) {
		FILE_LOG(logDEBUG) << "Opened connection to device " << _deviceID << " (Serial: " << _deviceSerial << ")";
	}
	return success;
}

int APS::disconnect(){
	int success = 0;
	success = FTDI::disconnect(_handle);
	if (success == 0) {
		FILE_LOG(logDEBUG) << "Closed connection to device " << _deviceID << " (Serial: " << _deviceSerial << ")";
	}
	return success;
}

int APS::init(const string & bitFile, const bool & forceReload){

	if (forceReload) {
		//Setup the oscillators
		setup_VCXO();
		setup_PLL();

		//Program the bitfile to both FPGA's
		program_FPGA(bitFile, 2, 0x10);

	}

	return 0;
}

int APS::setup_VCXO(){
	return FPGA::setup_VCXO(_handle);
}

int APS::setup_PLL(){
	return FPGA::setup_PLL(_handle);
}

int APS::program_FPGA(const string & bitFile, const UCHAR & chipSelect, const int & expectedVersion) {

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
	vector<UCHAR> fileData((std::istreambuf_iterator<char>(FID)), std::istreambuf_iterator<char>());
	ULONG numBytes = fileData.size();
	FILE_LOG(logDEBUG) << "Read " << numBytes << " bytes from bitfile";

	//Pass of the data to a lower-level function to actually push it to the FPGA
	return FPGA::program_FPGA(_handle, fileData, chipSelect, expectedVersion);
}


int APS::read_bitfile_version(const UCHAR & chipSelect){
		//Pass through to FPGA code
		return FPGA::read_bitFile_version(_handle, chipSelect);
	}

int APS::set_sampleRate(const int & fpga, const int & freq, const bool & testLock){
		//Pass through to the FPGA code
		return FPGA::set_PLL_freq(_handle, fpga, freq, testLock);
}

int APS::get_sampleRate(const int & fpga){
		//Pass through to FPGA code
		return FPGA::get_PLL_freq(_handle, fpga);
}

int APS::set_LL_mode(const int & dac , const bool & enable, const bool & mode){
		//Pass through to FPGA code
		return FPGA::set_LL_mode(_handle, dac, enable, mode);
}

