/*
 * libx6adc.cpp
 *
 * A thin wrapper around X6Rack to allow calling from Matlab without name-mangling.
 *  Created on: Oct 30, 2013
 *      Author: qlab
 */

#include "X6Rack.h"
#include "libx6adc.h"


X6Rack X6Rack_;

#ifdef __cplusplus
extern "C" {
#endif

int init(){

	X6Rack_.init();

	return X6_OK;
}

int get_num_devices(){
	return X6Rack_.get_num_devices();
}

int connect_by_ID(int deviceID){
	return X6Rack_.connect(deviceID);
}

int disconnect(int deviceID){
	return X6Rack_.disconnect(deviceID);
}

//Initialize an X6-1000M board
int initX6(int deviceID) {
	return X6Rack_.initX6(deviceID);
}

int read_firmware_version(int deviceID) {
	return X6Rack_.read_firmware_version(deviceID);
}

int set_digitizer_mode(int deviceID, int mode) {
	return X6Rack_.set_digitizer_mode(deviceID, DIGITIZER_MODE(mode));
}

int get_digitizer_mode(int deviceID) {
	return int(X6Rack_.get_digitizer_mode(deviceID));
}

int set_sampleRate(int deviceID, double freq){
	return X6Rack_.set_sampleRate(deviceID, freq);
}

double get_sampleRate(int deviceID){
	return X6Rack_.get_sampleRate(deviceID);
}

int acquire(int deviceID) {
	return X6Rack_.acquire(deviceID);
}

int wait_for_acquisition(int deviceID, int timeOut) {
	return X6Rack_.wait_for_acquisition(deviceID, timeOut);
}

int stop(int deviceID) {
	return X6Rack_.stop(deviceID);
}

int transfer_waveform(int deviceID, int channel, unsigned short *buffer, size_t bufferLength) {
	return X6Rack_.transfer_waveform(deviceID, channel, buffer, bufferLength);
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
			return X6_FILE_ERROR;
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

int raw_read(int deviceID){
	return X6Rack_.raw_read(deviceID);
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

