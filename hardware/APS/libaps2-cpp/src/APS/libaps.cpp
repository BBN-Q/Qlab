/*
 * libaps.cpp
 *
 * A thin wrapper around APSRack to allow calling from Matlab without name-mangling.
 *  Created on: Jun 25, 2012
 *      Author: qlab
 */

#include "headings.h"
#include "libaps.h"
#include "APSRack.h"
 
APSRack APSRack_;

#ifdef __cplusplus
extern "C" {
#endif

int init(char* NICName){

	APSRack_.init(string(NICName));

	return APS_OK;
}

int get_numDevices(){
	return APSRack_.get_num_devices();
}

void get_deviceSerials(char * deviceSerials){
	//TODO: fix me!
	//Assumes sufficient memory has been allocated
	string serialStr;
	size_t strLen = serialStr.copy(deviceSerials, serialStr.size());
	deviceSerials[strLen] = '\0';
}

//Connect to a device specified by serial number string
//Assumes null-terminated deviceSerial
int connect_APS(char * deviceSerial){
	return APSRack_.connect(string(deviceSerial));
}

//Assumes a null-terminated deviceSerial
int disconnect_APS(char * deviceSerial){
	return APSRack_.disconnect(string(deviceSerial));
}

//Initialize an APS unit
//Assumes null-terminated bitFile
int initAPS(char * deviceSerial, char * bitFile, int forceReload){
	try {
		return APSRack_.initAPS(string(deviceSerial), string(bitFile), forceReload);
	} catch (std::exception& e) {
		string error = e.what();
		if (error.compare("Unable to open bitfile.") == 0) {
			return APS_FILE_ERROR;
		} else {
			return APS_UNKNOWN_ERROR;
		}
	}

}

int get_bitfile_version(char * deviceSerial) {
	return APSRack_.get_bitfile_version(string(deviceSerial));
}

int set_sampleRate(char * deviceSerial, int freq){
	return APSRack_.set_sampleRate(string(deviceSerial), freq);
}

int get_sampleRate(char * deviceSerial){
	return APSRack_.get_sampleRate(string(deviceSerial));
}

//Load the waveform library as floats
int set_waveform_float(char * deviceSerial, int channelNum, float* data, int numPts){
	return APSRack_.set_waveform(string(deviceSerial), channelNum, vector<float>(data, data+numPts));
}

//Load the waveform library as int16
int set_waveform_int(char * deviceSerial, int channelNum, short* data, int numPts){
	return APSRack_.set_waveform(string(deviceSerial), channelNum, vector<short>(data, data+numPts));
}

int load_sequence_file(char * deviceSerial, const char * seqFile){
	try {
		return APSRack_.load_sequence_file(string(deviceSerial), string(seqFile));
	} catch (...) {
		return APS_UNKNOWN_ERROR;
	}
	// should not reach this point
	return APS_UNKNOWN_ERROR;
}

int clear_channel_data(char * deviceSerial) {
	return APSRack_.clear_channel_data(string(deviceSerial));
}

int run(char * deviceSerial) {
	return APSRack_.run(string(deviceSerial));
}

int stop(char * deviceSerial) {
	return APSRack_.stop(string(deviceSerial));
}

int get_running(char * deviceSerial){
	return APSRack_.get_running(string(deviceSerial));
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

int set_trigger_source(char * deviceSerial, int triggerSource) {
	return APSRack_.set_trigger_source(string(deviceSerial), TRIGGERSOURCE(triggerSource));
}

int get_trigger_source(char * deviceSerial) {
	return int(APSRack_.get_trigger_source(string(deviceSerial)));
}

int set_trigger_interval(char * deviceSerial, double interval){
	return APSRack_.set_trigger_interval(string(deviceSerial), interval);
}

double get_trigger_interval(char * deviceSerial){
	return APSRack_.get_trigger_interval(string(deviceSerial));
}

int set_channel_offset(char * deviceSerial, int channelNum, float offset){
	return APSRack_.set_channel_offset(string(deviceSerial), channelNum, offset);
}
int set_channel_scale(char * deviceSerial, int channelNum, float scale){
	return APSRack_.set_channel_scale(string(deviceSerial), channelNum, scale);
}
int set_channel_enabled(char * deviceSerial, int channelNum, int enable){
	return APSRack_.set_channel_enabled(string(deviceSerial), channelNum, enable);
}

float get_channel_offset(char * deviceSerial, int channelNum){
	return APSRack_.get_channel_offset(string(deviceSerial), channelNum);
}
float get_channel_scale(char * deviceSerial, int channelNum){
	return APSRack_.get_channel_scale(string(deviceSerial), channelNum);
}
int get_channel_enabled(char * deviceSerial, int channelNum){
	return APSRack_.get_channel_enabled(string(deviceSerial), channelNum);
}

int set_LL_data_IQ(char * deviceSerial, int channelNum, int length, unsigned short* addr, unsigned short* count,
					unsigned short* trigger1, unsigned short * trigger2, unsigned short* repeat){
	//Convert data pointers to vectors and passed through
	return APSRack_.set_LL_data(string(deviceSerial), channelNum, WordVec(addr, addr+length), WordVec(count, count+length),
			WordVec(trigger1, trigger1+length), WordVec(trigger2, trigger2+length), WordVec(repeat, repeat+length));
}

int set_run_mode(char * deviceSerial, int channelNum, int mode) {
	return APSRack_.set_run_mode(string(deviceSerial), channelNum, RUN_MODE(mode));
}

//int save_state_files() {
//	return APSRack_.save_state_files();
//}
//
//int read_state_files() {
//	return APSRack_.read_state_files();
//}
//
//int save_bulk_state_file() {
//	string fileName = "";
//	return APSRack_.save_bulk_state_file(fileName);
//}
//int read_bulk_state_file() {
//	string fileName = "";
//	return APSRack_.read_bulk_state_file(fileName);
//}

int raw_write(char * deviceSerial, int numBytes, uint8_t* data){
	return APSRack_.raw_write(string(deviceSerial), numBytes, data);
}

int raw_read(char * deviceSerial){
	return APSRack_.raw_read(string(deviceSerial));
}

int read_register(char * deviceSerial, int addr){
	return APSRack_.read_register(string(deviceSerial), addr);
}

int program_FPGA(char * deviceSerial, int bitFileNum) {
	return APSRack_.program_FPGA(string(deviceSerial), bitFileNum);
}

#ifdef __cplusplus
}
#endif

