/*
 * X6Rack.cpp
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#include "X6Rack.h"

X6Rack::X6Rack() {
}

X6Rack::~X6Rack()  {
	//Close the logging file so we don't leave it dangling
	fclose(Output2FILE::Stream());
}

//Initialize the rack by polling for devices and serial numbers
int X6Rack::init() {

	//Create the logger
	FILE* pFile = fopen("libaps.log", "a");
	Output2FILE::Stream() = pFile;

	//Initialize the X6s_ vector
	enumerate_devices();

	return 0;
}

//Initialize a specific X6 board
int X6Rack::initX6(const int & deviceID){
	return X6s_[deviceID].init();
}

int X6Rack::get_num_devices()  {
	return X6_1000::getBoardCount();
}

//This will reset the APS vector so it really should only be called during initialization
void X6Rack::enumerate_devices() {

	//Have to disconnect everything first
	for (auto & aps : X6s_){
		aps.disconnect();
	}

	numDevices = get_num_devices();

	X6s_.clear();
	X6s_.reserve(numDevices);

	for (size_t devicect = 0; devicect < numDevices; devicect++) {
		X6s_.emplace_back(devicect);
	}
}

int X6Rack::connect(const int & deviceID){
	//Connect to a instrument specified by deviceID
	return X6s_[deviceID].connect();
}

int X6Rack::disconnect(const int & deviceID){
	return X6s_[deviceID].disconnect();
}

int X6Rack::read_firmware_version(const int & deviceID) const {
	return 0;
	//return X6s_[deviceID].read_firmware_version();
}

int X6Rack::acquire(const int & deviceID) {
	return X6s_[deviceID].acquire();
}

int X6Rack::wait_for_acquisition(const int & deviceID, int timeOut) {
	return X6s_[deviceID].wait_for_acquisition(timeOut);
}

int X6Rack::stop(const int & deviceID) {
	return X6s_[deviceID].stop();
}

int transfer_waveform(const int & deviceID, const int & channel, unsigned short *buffer) {
	return 0;
}

int X6Rack::set_sampleRate(const int & deviceID, const int & freq) {
	return X6s_[deviceID].set_sampleRate(freq);
}

double X6Rack::get_sampleRate(const int & deviceID) const {
	return X6s_[deviceID].get_sampleRate();
}

int X6Rack::set_digitzer_mode(const int & deviceID, const DIGITIZER_MODE & mode) {
	//return X6s_[deviceID].set_digitzer_mode(mode);
	return 0;
}

DIGITIZER_MODE X6Rack::get_digitzer_mode(const int & deviceID) const {
	//return X6s_[deviceID].get_digitzer_mode();
	return DIGITIZE;
}

int X6Rack::set_trigger_source(const int & deviceID, const TRIGGERSOURCE & triggerSource) {
	return X6s_[deviceID].set_trigger_source(triggerSource);
}

TRIGGERSOURCE X6Rack::get_trigger_source(const int & deviceID) const{
	return X6s_[deviceID].get_trigger_source();
}

int X6Rack::set_log(FILE * pFile) {
	if (pFile) {
		//Close the current file
		if(Output2FILE::Stream()) fclose(Output2FILE::Stream());
		//Assign the new one
		Output2FILE::Stream() = pFile;
		return 1;
	} else {
		return 0;
	}
}

int X6Rack::set_logging_level(const int & logLevel){
	FILELog::ReportingLevel() = TLogLevel(logLevel);
	return 0;
}

int X6Rack::raw_write(int deviceID, int numBytes, UCHAR* data){
	DWORD bytesWritten;
	//FT_Write(X6s_[deviceID].handle_, data, numBytes, &bytesWritten);
	return int(bytesWritten);
}

int X6Rack::raw_read(int deviceID) {
	DWORD bytesRead;
	UCHAR dataBuffer[2];
	//FT_Read(X6s_[deviceID].handle_, dataBuffer, 2, &bytesRead);
	FILE_LOG(logDEBUG2) << "Read " << bytesRead << " bytes with value" << myhex << ((dataBuffer[0] << 8) | dataBuffer[1]);
	return int((dataBuffer[0] << 8) | dataBuffer[1]);
}

int X6Rack::read_register(int deviceID, int wbAddr, int offset){
	return X6s_[deviceID].handle_.read_wishbone_register(wbAddr, offset);
}

int X6Rack::write_register(int deviceID, int wbAddr, int offset, int data){
	return X6s_[deviceID].handle_.write_wishbone_register(wbAddr, offset, data);
}

float X6Rack::get_logic_temperature(int deviceID, int method) {
	return X6s_[deviceID].get_logic_temperature(method);
}
