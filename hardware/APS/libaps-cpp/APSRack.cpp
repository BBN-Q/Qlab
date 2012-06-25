/*
 * APSRack.cpp
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#include "APSRack.h"

APSRack::APSRack() {
	// TODO Auto-generated constructor stub

}

APSRack::~APSRack() {
	//Close the FTDI library
	dlclose(hdll);
	cout << "Caught destructor" << endl;
	FILE_LOG(logDEBUG) << "Closed FTDI library";
}

//Initialize the rack by polling for devices and serial numbers
int APSRack::Init() {

	//Create the logger
	FILE* pFile = fopen("libaps.log", "a");
	Output2FILE::Stream() = pFile;

	//Enumerate the serial numbers of the devices attached
	enumerate_devices();

	return 0;

}

int APSRack::get_num_devices() {

	int numDevices;
	FT_ListDevices(&numDevices, NULL, FT_LIST_NUMBER_ONLY);
	return numDevices;

}

void APSRack::enumerate_devices() {

	_deviceSerials = FTDI::get_device_serials();
	_numDevices = _deviceSerials.size();

	//Now setup the map between device serials and number
	size_t devicect = 0;
	for (string tmpSerial : _deviceSerials) {
		_serial2dev[tmpSerial] = devicect;
		FILE_LOG(logDEBUG) << "Device" << devicect << " has serial number: " << tmpSerial;
		devicect++;
	}

}

int APSRack::connect(const int & deviceID){
	//Connect to a instrument specified by deviceID
	FTDI::connect(deviceID, _deviceHandles[deviceID]);

	return 0;
}

int APSRack::disconnect(const int & deviceID){
	//Disconnect

	return 0;
}
