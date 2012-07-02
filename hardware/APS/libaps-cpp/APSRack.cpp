/*
 * APSRack.cpp
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#include "headings.h"

APSRack::APSRack() {
	// TODO Auto-generated constructor stub

}

APSRack::~APSRack() {
}

//Initialize the rack by polling for devices and serial numbers
int APSRack::Init() {

	//Create the logger
	FILE* pFile = fopen("libaps.log", "a");
	Output2FILE::Stream() = pFile;

	//Enumerate the serial numbers of the devices attached
	enumerate_devices();

	_APSs.resize(_numDevices);

	return 0;

}

int APSRack::get_num_devices() {

	int numDevices;
	FT_ListDevices(&numDevices, NULL, FT_LIST_NUMBER_ONLY);
	return numDevices;

}

void APSRack::enumerate_devices() {

	FTDI::get_device_serials(_deviceSerials);
	_numDevices = _deviceSerials.size();

	//Now setup the map between device serials and number
	size_t devicect = 0;
	for (string tmpSerial : _deviceSerials) {
		_serial2dev[tmpSerial] = devicect;
		FILE_LOG(logDEBUG) << "Device " << devicect << " has serial number " << tmpSerial;
		devicect++;
	}
}

int APSRack::connect(const int & deviceID){
	//Connect to a instrument specified by deviceID
	int success = 0;
	success = FTDI::connect(deviceID, _APSs[deviceID]._handle);
	if (success == 0) {
		FILE_LOG(logDEBUG) << "Opened connection to device " << deviceID;
	}
	return success;
}

int APSRack::disconnect(const int & deviceID){
	//Disconnect
	int success = 0;
	success = FTDI::disconnect(_APSs[deviceID]._handle);
	if (success == 0) {
		FILE_LOG(logDEBUG) << "Closed connection to device " << deviceID;
	}
	return success;
}
