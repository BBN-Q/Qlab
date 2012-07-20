/*
 * libaps.cpp
 *
 * A thin wrapper around APSRack to allow calling from Matlab without name-mangling.
 *  Created on: Jun 25, 2012
 *      Author: qlab
 */

#include "headings.h"
#include "libaps.h"

APSRack APSRack_;

#ifdef __cplusplus
extern "C" {
#endif

int init() {

	APSRack_ = APSRack();
	APSRack_.init();

	return 0;
}

int get_numDevices(){
	return APSRack_.get_num_devices();
}

void get_deviceSerial(int deviceID, char* deviceSerial){
	//Assumes sufficient memory has been allocated
	string serialStr = APSRack_.get_deviceSerial(deviceID);
	size_t strLen = serialStr.copy(deviceSerial, serialStr.size());
	deviceSerial[strLen] = '\0';
}

//Connect to a device specified by ID
int connect_by_ID(int deviceID){
	return APSRack_.connect(deviceID);
}

//Connect to a device specified by serial number string
//Assumes null-terminated deviceSerial
int connect_by_serial(char * deviceSerial){
	return APSRack_.connect(string(deviceSerial));
}

int disconnect_by_ID(int deviceID){
	return APSRack_.disconnect(deviceID);
}

//Assumes a null-terminated deviceSerial
int disconnect_by_serial(char * deviceSerial){
	return APSRack_.disconnect(string(deviceSerial));
}

int serial2ID(char * deviceSerial){
	return APSRack_.serial2dev[string(deviceSerial)];
}

//Initialize an APS unit
//Assumes null-terminated bitFile
int initAPS(int deviceID, char * bitFile, int forceReload){
	return APSRack_.initAPS(deviceID, string(bitFile), forceReload);
}

int read_bitfile_version(int deviceID) {
	return APSRack_.read_bitfile_version(deviceID);
}

int set_sampleRate(int deviceID, int freq){
	return APSRack_.set_sampleRate(deviceID, freq);
}

int get_sampleRate(int deviceID){
	return APSRack_.get_sampleRate(deviceID);
}

//Load the waveform library as floats
int set_waveform_float(int deviceID, int channelNum, float* data, int numPts){
	return APSRack_.set_waveform(deviceID, channelNum, vector<float>(data, data+numPts));
}

//Load the waveform library as int16
int set_waveform_int(int deviceID, int channelNum, short* data, int numPts){
	return APSRack_.set_waveform(deviceID, channelNum, vector<short>(data, data+numPts));
}

int clear_channel_data(int deviceID) {
	return APSRack_.clear_channel_data(deviceID);
}

int run(int deviceID) {
	return APSRack_.run(deviceID);
}
int stop(int deviceID) {
	return APSRack_.stop(deviceID);
}

int trigger_FPGA_debug(int deviceID, int fpga){
	return APSRack_.trigger_FPGA_debug(deviceID, FPGASELECT(fpga));
}

int disable_FPGA_debug(int deviceID, int fpga){
	return APSRack_.disable_FPGA_debug(deviceID, FPGASELECT(fpga));
}

int reset_LL_banks(int deviceID, int channelNum){
	return APSRack_.reset_LL_banks(deviceID, channelNum);
}

int get_running(int deviceID){
	return APSRack_.get_running(deviceID);
}

//Expects a null-terminated character array
int set_log(char * fileNameArr) {
	string fileName(fileNameArr);
	if (fileName.compare("stdout") == 0){
		return APSRack_.set_log(stdout);
	}
	else if (fileName.compare("stderr") == 0){
		return APSRack_.set_log(stderr);
	}
	else{
		FILE* pFile = fopen(fileName.c_str(), "a");
		return APSRack_.set_log(pFile);
	}
}

int set_logging_level(int logLevel){
	return APSRack_.set_logging_level(logLevel);
}

int set_trigger_source(int deviceID, int triggerSource) {
	return APSRack_.set_trigger_source(deviceID,triggerSource);
}

int set_channel_offset(int deviceID, int channelNum, float offset){
	return APSRack_.set_channel_offset(deviceID, channelNum, offset);
}
int set_channel_scale(int deviceID, int channelNum, float scale){
	return APSRack_.set_channel_scale(deviceID, channelNum, scale);
}
int set_channel_enabled(int deviceID, int channelNum, int enable){
	return APSRack_.set_channel_enabled(deviceID, channelNum, enable);
}

float get_channel_offset(int deviceID, int channelNum){
	return APSRack_.get_channel_offset(deviceID, channelNum);
}
float get_channel_scale(int deviceID, int channelNum){
	return APSRack_.get_channel_scale(deviceID, channelNum);
}
int get_channel_enabled(int deviceID, int channelNum){
	return APSRack_.get_channel_enabled(deviceID, channelNum);
}

int set_channel_trigDelay(int deviceID, int channelNum, USHORT delay){
	return APSRack_.set_channel_trigDelay(deviceID, channelNum, delay);
}
unsigned short get_channel_trigDelay(int deviceID, int dac){
	return APSRack_.get_channel_trigDelay(deviceID, dac);
}

int add_LL_bank(int deviceID, int channelNum, int length, unsigned short* offset, unsigned short* count, unsigned short* repeat, unsigned short* trigger){
	//Convert data pointers to vectors and passed through
	return APSRack_.add_LL_bank(deviceID, channelNum, vector<USHORT>(offset, offset+length), vector<USHORT>(count, count+length), vector<USHORT>(repeat, repeat+length), vector<USHORT>(trigger, trigger+length));
}

int set_run_mode(int deviceID, int channelNum, int mode) {
	return APSRack_.set_run_mode(deviceID, channelNum, mode);
}

int set_repeat_mode(int deviceID, int channelNum, int mode) {
	return APSRack_.set_repeat_mode(deviceID, channelNum, mode);
}

#ifdef __cplusplus
}
#endif

