/*
 * libaps.cpp
 *
 * A thin wrapper around APSRack to allow calling from Matlab without name-mangling.
 *  Created on: Jun 25, 2012
 *      Author: qlab
 */

#include "headings.h"
#include "libaps.h"

APSRack _APSRack;

#ifdef __cplusplus
extern "C" {
#endif

int init() {

	_APSRack = APSRack();
	_APSRack.init();

	return 0;
}

//Connect to a device specified by ID
int connect_by_ID(int deviceID){
	return _APSRack.connect(deviceID);
}

//Connect to a device specified by serial number string
//Assumes null-terminated deviceSerial
int connect_by_serial(char * deviceSerial){
	return _APSRack.connect(string(deviceSerial));
}

int disconnect_by_ID(int deviceID){
	return _APSRack.disconnect(deviceID);
}

//Assumes a null-terminated deviceSerial
int disconnect_by_serial(char * deviceSerial){
	return _APSRack.disconnect(string(deviceSerial));
}

int serial2ID(char * deviceSerial){
	return _APSRack.serial2dev[string(deviceSerial)];
}

//Initialize an APS unit
//Assumes null-terminated bitFile
int initAPS(int deviceID, char * bitFile, int forceReload){
	return _APSRack.initAPS(deviceID, string(bitFile), forceReload);
}

//Program the current FPGA
//Assumes null-terminated bitFile
int program_FPGA(int deviceID, char * bitFile, int fpga, int expectedVersion){
	return _APSRack.program_FPGA(deviceID, string(bitFile), FPGASELECT(fpga), expectedVersion);
}

int setup_DACs(int deviceID){
	return _APSRack.setup_DACs(deviceID);
}

int set_sampleRate(int deviceID, int fpga, int freq, int testLock){
	return _APSRack.set_sampleRate(deviceID, FPGASELECT(fpga), freq, testLock);
}

int get_sampleRate(int deviceID, int fpga){
	return _APSRack.get_sampleRate(deviceID, FPGASELECT(fpga));
}

//Load the waveform library as floats
int set_waveform_float(int deviceID, int channelNum, float* data, int numPts){
	return _APSRack.set_waveform(deviceID, channelNum, vector<float>(data, data+numPts));
}

//Load the waveform library as int16
int set_waveform_int(int deviceID, int channelNum, short* data, int numPts){
	return _APSRack.set_waveform(deviceID, channelNum, vector<short>(data, data+numPts));
}

int run(int deviceID) {
	return _APSRack.run(deviceID);
}
int stop(int deviceID) {
	return _APSRack.stop(deviceID);
}

int trigger_FPGA_debug(int deviceID, int fpga){
	return _APSRack.trigger_FPGA_debug(deviceID, FPGASELECT(fpga));
}

int disable_FPGA_debug(int deviceID, int fpga){
	return _APSRack.disable_FPGA_debug(deviceID, FPGASELECT(fpga));
}

int reset_LL_banks(int deviceID, int channelNum){
	return _APSRack.reset_LL_banks(deviceID, channelNum);
}

//Expects a null-terminated character array
int set_log(char * fileNameArr) {
	string fileName(fileNameArr);
	if (fileName.compare("stdout") == 0){
		return _APSRack.set_log(stdout);
	}
	else if (fileName.compare("stderr") == 0){
		return _APSRack.set_log(stderr);
	}
	else{
		FILE* pFile = fopen(fileName.c_str(), "a");
		return _APSRack.set_log(pFile);
	}
}

int set_trigger_source(int deviceID, int triggerSource) {
	return _APSRack.set_trigger_source(deviceID,triggerSource);
}

int set_channel_offset(int deviceID, int channelNum, float offset){
	return _APSRack.set_channel_offset(deviceID, channelNum, offset);
}
int set_channel_scale(int deviceID, int channelNum, float scale){
	return _APSRack.set_channel_scale(deviceID, channelNum, scale);
}
int set_channel_enabled(int deviceID, int channelNum, int enable){
	return _APSRack.set_channel_enabled(deviceID, channelNum, enable);
}

float get_channel_offset(int deviceID, int channelNum){
	return _APSRack.get_channel_offset(deviceID, channelNum);
}
float get_channel_scale(int deviceID, int channelNum){
	return _APSRack.get_channel_scale(deviceID, channelNum);
}
int get_channel_enabled(int deviceID, int channelNum){
	return _APSRack.get_channel_enabled(deviceID, channelNum);
}

int add_LL_bank(int deviceID, int channelNum, int length, unsigned short* offset, unsigned short* count, unsigned short* repeat, unsigned short* trigger){
	//Convert data pointers to vectors and passed through
	return _APSRack.add_LL_bank(deviceID, channelNum, vector<USHORT>(offset, offset+length), vector<USHORT>(count, count+length), vector<USHORT>(repeat, repeat+length), vector<USHORT>(trigger, trigger+length));
}


#ifdef __cplusplus
}
#endif

