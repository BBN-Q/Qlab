/*
 * libx6adc.cpp
 *
 * A thin wrapper around X6Rack to allow calling from Matlab without name-mangling.
 *  Created on: Oct 30, 2013
 *      Author: qlab
 */

#include "headings.h"
#include "X6Rack.h"
#include "libx6adc.h"


X6Rack X6Rack_;

#ifdef __cplusplus
extern "C" {
#endif

int init(){

	X6Rack_.init();

	return APS_OK;
}

int get_numDevices(){
	return X6Rack_.get_num_devices();
}

void get_deviceSerial(int deviceID, char* deviceSerial){
	//Assumes sufficient memory has been allocated
	string serialStr = X6Rack_.get_deviceSerial(deviceID);
	size_t strLen = serialStr.copy(deviceSerial, serialStr.size());
	deviceSerial[strLen] = '\0';
}

//Connect to a device specified by ID
int connect_by_ID(int deviceID){
	return X6Rack_.connect(deviceID);
}

//Connect to a device specified by serial number string
//Assumes null-terminated deviceSerial
int connect_by_serial(char * deviceSerial){
	return X6Rack_.connect(string(deviceSerial));
}

int disconnect(int deviceID){
	return X6Rack_.disconnect(deviceID);
}

int serial2ID(char * deviceSerial){
	if ( !X6Rack_.serial2dev.count(deviceSerial)) {
		// serial number not in map of known devices
		return -1;
	} 

	return X6Rack_.serial2dev[string(deviceSerial)];
}

//Initialize an X6-1000M
int initX6(int deviceID){
	return X6Rack_.initX6(deviceID);
}

int read_firmware_version(int deviceID) {
	return X6Rack_.read_firmware_version(deviceID);
}

int set_sampleRate(int deviceID, int freq){
	return X6Rack_.set_sampleRate(deviceID, freq);
}

double get_sampleRate(int deviceID){
	return X6Rack_.get_sampleRate(deviceID);
}

int acquire(int deviceID) {
	return X6Rack_.acquire(deviceID);
}

int wait_for_acquisition(int deviceID) {
	return X6Rack_.wait_for_acquisition(deviceID);
}

int stop(int deviceID) {
	return X6Rack_.stop(deviceID);
}

int transfer_waveform(int deviceID, int channel, unsigned short *buffer) {
	return X6Rack_.transfer_waveform(deviceID, channel, buffer);
}

//Expects a null-terminated character array
int set_log(char * fileNameArr) {

	string fileName(fileNameArr);
	if (fileName.compare("stdout") == 0){
		return X6Rack_.set_log(stdout);
	}
	else if (fileName.compare("stderr") == 0){
		return X6Rack_.set_log(stderr);
	}
	else{

		FILE* pFile = fopen(fileName.c_str(), "a");
		if (!pFile) {
			return APS_FILE_ERROR;
		}

		return X6Rack_.set_log(pFile);
	}
}

int set_logging_level(int logLevel){
	return X6Rack_.set_logging_level(logLevel);
}

int set_trigger_source(int deviceID, int triggerSource) {
	return X6Rack_.set_trigger_source(deviceID, TRIGGERSOURCE(triggerSource));
}

int get_trigger_source(int deviceID) {
	return int(X6Rack_.get_trigger_source(deviceID));
}

int raw_write(int deviceID, int numBytes, UCHAR* data){
	return X6Rack_.raw_write(deviceID, numBytes, data);
}

int raw_read(int deviceID, int fpga){
	return X6Rack_.raw_read(deviceID, FPGASELECT(fpga));
}

int read_register(int deviceID, int wbAddr, int offset){
	return X6Rack_.read_register(deviceID, wbAddr, offset);
}

int write_register(int deviceID, int wbAddr, int offset, int data){
	return X6Rack_.write_register(deviceID, wbAddr, offset, data);
}

float get_logic_temperature(int deviceID, int method) {
	return X6Rack_.get_logic_temperature(deviceID, method);
}

void set_malibu_threading_enable(bool enable) {
	X6_1000::set_threading_enable(enable);
}

#ifdef __cplusplus
}
#endif

