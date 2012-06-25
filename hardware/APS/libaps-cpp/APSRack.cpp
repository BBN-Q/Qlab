/*
 * APSRack.cpp
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#include "APSRack.h"

void * hdll;


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

	//Load the FTDI USB library
	#ifdef WIN32

		hdll = LoadLibrary(LIBFILE);
		if ((uintptr_t)hdll <= HINSTANCE_ERROR) {
			FILE_LOG(logERROR) << "Error opening FTDI library";
			return -1;
		}

	#else
		hdll = dlopen(LIBFILE,RTLD_LAZY);
		if (hdll == 0) {
			FILE_LOG(logERROR) << "Error opening FTDI library: " << dlerror();
			return -1;
		}
	#endif
	FILE_LOG(logDEBUG) << "Opened ftd2xx.dll library";

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

	//Use the FTDI driver to get serial numbers (from "Simple" example)
	char * pBufSerials[MAX_APS_DEVICES+1];
	char bufSerials[MAX_APS_DEVICES][64];
	FT_STATUS ftStatus;

	for(int devicect = 0; devicect < MAX_APS_DEVICES; devicect++) {
		pBufSerials[devicect] = bufSerials[devicect];
		}
	pBufSerials[MAX_APS_DEVICES] = NULL;

	ftStatus = FT_ListDevices(pBufSerials, &_numDevices, FT_LIST_ALL | FT_OPEN_BY_SERIAL_NUMBER);

	if(!FT_SUCCESS(ftStatus)) {
		FILE_LOG(logERROR) << "Error: FT_ListDevices " << static_cast<int>(ftStatus);
		}

	FILE_LOG(logDEBUG) << "Found " << _numDevices << " devices attached";

	//Now setup the map between device serials and number
	for (int devicect = 0; (devicect < MAX_APS_DEVICES) && (devicect < _numDevices); devicect++) {
		_serial2dev[string(bufSerials[devicect])] = devicect;
		FILE_LOG(logDEBUG) << "Device" << devicect << " has serial number: " << bufSerials[devicect];
	}

}
