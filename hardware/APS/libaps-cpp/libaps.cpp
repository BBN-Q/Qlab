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

int init(){

	APSRack_ = APSRack();
	APSRack_.init();

	return APS_OK;
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
	try {
		return APSRack_.initAPS(deviceID, string(bitFile), forceReload);
	} catch (std::exception& e) {
		string error = e.what();
		if (error.compare("Unable to open bitfile.") == 0) {
			return APS_FILE_ERROR;
		} else {
			return APS_UNKNOWN_ERROR;
		}
	}

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

int set_trigger_interval(int deviceID, double interval){
	return APSRack_.set_trigger_interval(deviceID, interval);
}

//Load the waveform library as floats
int set_waveform_float(int deviceID, int channelNum, float* data, int numPts){
	return APSRack_.set_waveform(deviceID, channelNum, vector<float>(data, data+numPts));
}

//Load the waveform library as int16
int set_waveform_int(int deviceID, int channelNum, short* data, int numPts){
	return APSRack_.set_waveform(deviceID, channelNum, vector<short>(data, data+numPts));
}

int load_sequence_file(int deviceID, char * seqFile){
	try {
		return APSRack_.load_sequence_file(deviceID, string(seqFile));
	} catch (...) {
		return APS_UNKNOWN_ERROR;
	}
	// should not reach this point
	return APS_UNKNOWN_ERROR;
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
		if (!pFile) {
			return APS_FILE_ERROR;
		}

		return APSRack_.set_log(pFile);
	}
}

int set_logging_level(int logLevel){
	return APSRack_.set_logging_level(logLevel);
}

int set_trigger_source(int deviceID, int triggerSource) {
	return APSRack_.set_trigger_source(deviceID,triggerSource);
}

int get_trigger_source(int deviceID) {
	return APSRack_.get_trigger_source(deviceID);
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

int set_LL_data_IQ(int deviceID, int channelNum, int length, unsigned short* addr, unsigned short* count,
					unsigned short* trigger1, unsigned short * trigger2, unsigned short* repeat){
	//Convert data pointers to vectors and passed through
	return APSRack_.set_LL_data(deviceID, channelNum, WordVec(addr, addr+length), WordVec(count, count+length),
			WordVec(trigger1, trigger1+length), WordVec(trigger2, trigger2+length), WordVec(repeat, repeat+length));
}

int set_run_mode(int deviceID, int channelNum, int mode) {
	return APSRack_.set_run_mode(deviceID, channelNum, RUN_MODE(mode));
}

int set_repeat_mode(int deviceID, int channelNum, int mode) {
	return APSRack_.set_repeat_mode(deviceID, channelNum, mode);
}

int save_state_files() {
	return APSRack_.save_state_files();
}

int read_state_files() {
	return APSRack_.read_state_files();
}

int save_bulk_state_file() {
	string fileName = "";
	return APSRack_.save_bulk_state_file(fileName);
}
int read_bulk_state_file() {
	string fileName = "";
	return APSRack_.read_bulk_state_file(fileName);
}

int raw_write(int deviceID, int numBytes, UCHAR* data){
	return APSRack_.raw_write(deviceID, numBytes, data);
}

int raw_read(int deviceID, int fpga){
	return APSRack_.raw_read(deviceID, FPGASELECT(fpga));
}

int program_FPGA(int deviceID, char* bitFile, int chipSelect, int expectedVersion) {
	return APSRack_.program_FPGA(deviceID, string(bitFile), FPGASELECT(chipSelect), expectedVersion);
}

#ifdef __cplusplus
}
#endif

