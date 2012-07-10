/*
 * APS.cpp
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#include "APS.h"

APS::APS() :  deviceID_{-1}, handle_{NULL}, channels_(4), checksums_(2), triggerSource_{SOFTWARE_TRIGGER} {}

APS::APS(int deviceID, string deviceSerial) :  deviceID_{deviceID}, deviceSerial_{deviceSerial},
		handle_{NULL}, checksums_(2), triggerSource_{SOFTWARE_TRIGGER}{
		for(int ct=0; ct<4; ct++){
			channels_.push_back(Channel(ct));
		}
};

APS::~APS() {
	// TODO Auto-generated destructor stub
}

int APS::connect(){
	int success = 0;
	success = FTDI::connect(deviceID_, handle_);
	if (success == 0) {
		FILE_LOG(logDEBUG) << "Opened connection to device " << deviceID_ << " (Serial: " << deviceSerial_ << ")";
	}
	return success;
}

int APS::disconnect(){
	int success = 0;
	success = FTDI::disconnect(handle_);
	if (success == 0) {
		FILE_LOG(logDEBUG) << "Closed connection to device " << deviceID_ << " (Serial: " << deviceSerial_ << ")";
	}
	return success;
}

int APS::init(const string & bitFile, const bool & forceReload){

	if (forceReload) {
		//Setup the oscillators
		setup_VCXO();
		setup_PLL();

		//Program the bitfile to both FPGA's
		int bytesProgramed = program_FPGA(bitFile, 2, 0x10);

		//Default to max sample rate
		set_sampleRate(0, 1200, 0);
		set_sampleRate(1, 1200, 0);

		setup_DACs();

		return bytesProgramed;
	}

	return 0;
}

int APS::setup_VCXO() const{
	return FPGA::setup_VCXO(handle_);
}

int APS::setup_PLL() const{
	return FPGA::setup_PLL(handle_);
}

int APS::setup_DACs() const{
	//Call the setup function for each DAC
	for(int dac=0; dac<4; dac++){
		FPGA::setup_DAC(handle_, dac);
	}
	return 0;
}
int APS::program_FPGA(const string & bitFile, const UCHAR & chipSelect, const int & expectedVersion) const {

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
	return FPGA::program_FPGA(handle_, fileData, chipSelect, expectedVersion);
}


int APS::read_bitfile_version(const UCHAR & chipSelect) const{
	//Pass through to FPGA code
	return FPGA::read_bitFile_version(handle_, chipSelect);
}

int APS::set_sampleRate(const int & fpga, const int & freq, const bool & testLock){
	//Pass through to the FPGA code
	return FPGA::set_PLL_freq(handle_, fpga, freq, testLock);
}

int APS::get_sampleRate(const int & fpga) const{
	//Pass through to FPGA code
	return FPGA::get_PLL_freq(handle_, fpga);
}

int APS::set_LL_mode(const int & dac , const bool & enable, const bool & mode){
	//Pass through to FPGA code
	return FPGA::set_LL_mode(handle_, dac, enable, mode);
}

int APS::load_sequence_file(const string & seqFile){
	/*
	 * Load a sequence file from a H5 file
	 */


	return 0;

}

int APS::trigger_FPGA(const int & fpga) const{
	return FPGA::trigger(handle_, fpga, triggerSource_);
}

int APS::disable_FPGA(const int & fpga) const{
	return FPGA::disable(handle_, fpga);
}

int APS::run() const{

	//Depending on how the channels are enabled, trigger the appropriate FPGA's
	vector<bool> channelsEnabled;
	bool allChannels = false;
	for (const auto tmpChannel : channels_){
		channelsEnabled.push_back(tmpChannel.enabled_);
		allChannels &= tmpChannel.enabled_;
	}

	//If all channels are enabled then trigger together
	if (allChannels) {
		trigger_FPGA(2);
	}
	else if (channelsEnabled[0] || channelsEnabled[1]) {
		trigger_FPGA(0);
	}
	else if (channelsEnabled[2] || channelsEnabled[3]) {
		trigger_FPGA(1);
	}

	return 0;
}
