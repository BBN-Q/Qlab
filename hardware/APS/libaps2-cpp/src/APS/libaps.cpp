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

int init(const char* NICName){

	APSRack_.init(string(NICName));

	return APS_OK;
}

int get_numDevices(){
	return APSRack_.get_num_devices();
}

void get_deviceSerials(const char ** deviceSerials){
	//Assumes sufficient memory has been allocated
	size_t ct = 0;
	for (auto serial : APSRack_.deviceSerials){
		deviceSerials[ct] = serial.c_str();
		ct++;
	}
}

//Connect to a device specified by serial number string
//Assumes null-terminated deviceSerial
int connect_APS(const char * deviceSerial){
	return APSRack_.APSs[string(deviceSerial)].connect();
}

//Assumes a null-terminated deviceSerial
int disconnect_APS(const char * deviceSerial){
	return APSRack_.APSs[string(deviceSerial)].disconnect();
}

//Initialize an APS unit
//Assumes null-terminated bitFile
int initAPS(const char * deviceSerial, int forceReload){
	try {
		return APSRack_.APSs[string(deviceSerial)].init(forceReload);
	} catch (std::exception& e) {
		string error = e.what();
		if (error.compare("Unable to open bitfile.") == 0) {
			return APS_FILE_ERROR;
		} else {
			return APS_UNKNOWN_ERROR;
		}
	}

}

int get_bitfile_version(const char * deviceSerial) {
	return APSRack_.APSs[string(deviceSerial)].get_bitfile_version();
}

int set_sampleRate(const char * deviceSerial, int freq){
	return APSRack_.APSs[string(deviceSerial)].set_sampleRate(freq);
}

int get_sampleRate(const char * deviceSerial){
	return APSRack_.APSs[string(deviceSerial)].get_sampleRate();
}

//Load the waveform library as floats
int set_waveform_float(const char * deviceSerial, int channelNum, float* data, int numPts){
	return APSRack_.APSs[string(deviceSerial)].set_waveform( channelNum, vector<float>(data, data+numPts));
}

//Load the waveform library as int16
int set_waveform_int(const char * deviceSerial, int channelNum, short* data, int numPts){
	return APSRack_.APSs[string(deviceSerial)].set_waveform(channelNum, vector<short>(data, data+numPts));
}

int load_sequence_file(const char * deviceSerial, const char * seqFile){
	try {
		return APSRack_.APSs[string(deviceSerial)].load_sequence_file(string(seqFile));
	} catch (...) {
		return APS_UNKNOWN_ERROR;
	}
	// should not reach this point
	return APS_UNKNOWN_ERROR;
}

int clear_channel_data(const char * deviceSerial) {
	return APSRack_.APSs[string(deviceSerial)].clear_channel_data();
}

int run(const char * deviceSerial) {
	return APSRack_.APSs[string(deviceSerial)].run();
}

int stop(const char * deviceSerial) {
	return APSRack_.APSs[string(deviceSerial)].stop();
}

int get_running(const char * deviceSerial){
	return APSRack_.APSs[string(deviceSerial)].running;
}

//Expects a null-terminated character array
int set_log(const char * fileNameArr) {

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

int set_trigger_source(const char * deviceSerial, int triggerSource) {
	return APSRack_.APSs[string(deviceSerial)].set_trigger_source(TRIGGERSOURCE(triggerSource));
}

int get_trigger_source(const char * deviceSerial) {
	return int(APSRack_.APSs[string(deviceSerial)].get_trigger_source());
}

int set_trigger_interval(const char * deviceSerial, double interval){
	return APSRack_.APSs[string(deviceSerial)].set_trigger_interval(interval);
}

double get_trigger_interval(const char * deviceSerial){
	return APSRack_.APSs[string(deviceSerial)].get_trigger_interval();
}

int set_channel_offset(const char * deviceSerial, int channelNum, float offset){
	return APSRack_.APSs[string(deviceSerial)].set_channel_offset(channelNum, offset);
}
int set_channel_scale(const char * deviceSerial, int channelNum, float scale){
	return APSRack_.APSs[string(deviceSerial)].set_channel_scale(channelNum, scale);
}
int set_channel_enabled(const char * deviceSerial, int channelNum, int enable){
	return APSRack_.APSs[string(deviceSerial)].set_channel_enabled(channelNum, enable);
}

float get_channel_offset(const char * deviceSerial, int channelNum){
	return APSRack_.APSs[string(deviceSerial)].get_channel_offset(channelNum);
}
float get_channel_scale(const char * deviceSerial, int channelNum){
	return APSRack_.APSs[string(deviceSerial)].get_channel_scale(channelNum);
}
int get_channel_enabled(const char * deviceSerial, int channelNum){
	return APSRack_.APSs[string(deviceSerial)].get_channel_enabled(channelNum);
}

int set_LL_data_IQ(const char * deviceSerial, int channelNum, int length, unsigned short* addr, unsigned short* count,
					unsigned short* trigger1, unsigned short * trigger2, unsigned short* repeat){
	//TODO: fix me!
// 	//Convert data pointers to vectors and passed through
// 	return APSRack_.APSs[string(deviceSerial)].set_LL_data(channelNum, WordVec(addr, addr+length), WordVec(count, count+length),
// 			WordVec(trigger1, trigger1+length), WordVec(trigger2, trigger2+length), WordVec(repeat, repeat+length));
	return 0;
}

int set_run_mode(const char * deviceSerial, int channelNum, int mode) {
	return APSRack_.APSs[string(deviceSerial)].set_run_mode(channelNum, RUN_MODE(mode));
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

int raw_write(const char * deviceSerial, int numBytes, uint8_t* data){
	return APSRack_.raw_write(string(deviceSerial), numBytes, data);
}

int raw_read(const char * deviceSerial){
	return APSRack_.raw_read(string(deviceSerial));
}

int read_register(const char * deviceSerial, int addr){
	return APSRack_.read_register(string(deviceSerial), addr);
}

int program_FPGA(const char * deviceSerial, int bitFileNum) {
	return APSRack_.APSs[string(deviceSerial)].program_FPGA(bitFileNum);
}

#ifdef __cplusplus
}
#endif

