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


#ifdef __cplusplus
}
#endif

