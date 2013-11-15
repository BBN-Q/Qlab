/*
 * libx6adc.cpp
 *
 *  Created on: Oct 30, 2013
 *      Author: qlab
 */

#include "libx6adc.h"
#include "headings.h"
#include "X6.h"

// stub class to close the logger file handle when the driver goes out of scope
class CleanUp {
public:
	~CleanUp();
};

CleanUp::~CleanUp() {
	if (Output2FILE::Stream()) {
		fclose(Output2FILE::Stream());
	}
}

// globals
X6 X6s_[MAX_NUM_DEVICES];
int numDevices_ = 0;
CleanUp cleanup_;

#ifdef __cplusplus
extern "C" {
#endif

// initialize the library
int init() {
	//Create the logger
	FILE* pFile = fopen("libaps.log", "a");
	Output2FILE::Stream() = pFile;

	numDevices_ = get_num_devices();

	return X6::X6_OK;
}

// initialize an X6-1000M board
int initX6(int deviceID) {
	return X6s_[deviceID].init();
}

int get_num_devices() {
	return X6_1000::getBoardCount();
}

int connect_by_ID(int deviceID) {
	if (deviceID >= numDevices_) return X6::X6_INVALID_DEVICEID;
	return X6s_[deviceID].connect(deviceID);
}

int disconnect(int deviceID) {
	if (deviceID >= numDevices_) return X6::X6_INVALID_DEVICEID;
	return X6s_[deviceID].disconnect();
}

int read_firmware_version(int deviceID) {
	return X6s_[deviceID].read_firmware_version();
}

int set_digitizer_mode(int deviceID, int mode) {
	return X6s_[deviceID].set_digitizer_mode(DIGITIZER_MODE(mode));
}

int get_digitizer_mode(int deviceID) {
	return int(X6s_[deviceID].get_digitizer_mode());
}

int set_sampleRate(int deviceID, double freq){
	return X6s_[deviceID].set_sampleRate(freq);
}

double get_sampleRate(int deviceID) {
	return X6s_[deviceID].get_sampleRate();
}

int set_trigger_source(int deviceID, int triggerSource) {
	return X6s_[deviceID].set_trigger_source(TRIGGERSOURCE(triggerSource));
}

int get_trigger_source(int deviceID) {
	return int(X6s_[deviceID].get_trigger_source());
}

int set_averager_settings(int deviceID, int recordLength, int numSegments, int waveforms, int roundRobins) {
	return X6s_[deviceID].set_averager_settings(recordLength, numSegments, waveforms, roundRobins);
}

int acquire(int deviceID) {
	return X6s_[deviceID].acquire();
}

int wait_for_acquisition(int deviceID, int timeOut) {
	return X6s_[deviceID].wait_for_acquisition(timeOut);
}

int stop(int deviceID) {
	return X6s_[deviceID].stop();
}

int transfer_waveform(int deviceID, int channel, short *buffer, size_t bufferLength) {
	return X6s_[deviceID].transfer_waveform(channel, buffer, bufferLength);
}

//Expects a null-terminated character array
int set_log(char * fileNameArr) {
	string fileName(fileNameArr);
	if (fileName.compare("stdout") == 0){
		return update_log(stdout);
	}
	else if (fileName.compare("stderr") == 0){
		return update_log(stderr);
	}
	else{

		FILE* pFile = fopen(fileName.c_str(), "a");
		if (!pFile) {
			return X6::X6_FILE_ERROR;
		}

		return update_log(pFile);
	}
}

int update_log(FILE * pFile) {
	if (pFile) {
		//Close the current file
		if (Output2FILE::Stream()) fclose(Output2FILE::Stream());
		//Assign the new one
		Output2FILE::Stream() = pFile;
		return X6::X6_OK;
	} else {
		return X6::X6_FILE_ERROR;
	}
}

int set_logging_level(int logLevel) {
	FILELog::ReportingLevel() = TLogLevel(logLevel);
	return X6::X6_OK;
}

int read_register(int deviceID, int wbAddr, int offset){
	return X6s_[deviceID].read_register(wbAddr, offset);
}

int write_register(int deviceID, int wbAddr, int offset, int data){
	return X6s_[deviceID].write_register(wbAddr, offset, data);
}

float get_logic_temperature(int deviceID, int method) {
	return X6s_[deviceID].get_logic_temperature(method);
}

#ifdef __cplusplus
}
#endif

