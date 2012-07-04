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

int Init() {

	_APSRack = APSRack();
	_APSRack.Init();

	return 0;
}

//Connect to a device specified by ID
int connect_by_ID(int deviceID){
	return _APSRack.connect(deviceID);
}

//Connect to a device specified by serial number string
//Assumes null-terminated deviceSerial
int connect_by_Serial(char * deviceSerial){
	return _APSRack.connect(string(deviceSerial));
}

int disconnect(){
	return _APSRack.disconnect(_APSRack.curDeviceID);
}

//Program the current FPGA
//Assumes null-terminated bitFile
int program_FPGA(char * bitFile, int chipSelect, int expectedVersion){
	return _APSRack.program_FPGA(string(bitFile), chipSelect, expectedVersion);
}

#ifdef __cplusplus
}
#endif

