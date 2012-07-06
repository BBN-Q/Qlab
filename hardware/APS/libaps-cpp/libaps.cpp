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
int program_FPGA(int deviceID, char * bitFile, int chipSelect, int expectedVersion){
	return _APSRack.program_FPGA(deviceID, string(bitFile), chipSelect, expectedVersion);
}

int set_sampleRate(int deviceID, int fpga, int freq, int testLock){
	return _APSRack.set_sampleRate(deviceID, fpga, freq, testLock);
}

int get_sampleRate(int deviceID, int fpga){
	return _APSRack.get_sampleRate(deviceID, fpga);
}

//Load the waveform library as floats
int set_waveform_float(int deviceID, int channelNum, float* data, int numPts){
	return _APSRack.set_waveform(deviceID, channelNum, vector<float>(data, data+numPts));
}

//Load the waveform library as int16
int set_waveform_int(int deviceID, int channelNum, short* data, int numPts){
	return _APSRack.set_waveform(deviceID, channelNum, vector<short>(data, data+numPts));
}


#ifdef __cplusplus
}
#endif

