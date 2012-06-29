/*
 * FTDI.cpp
 *
 *  Created on: Jun 25, 2012
 *      Author: cryan
 */

#include "headings.h"

void FTDI::get_device_serials(vector<string> & deviceSerials) {

	deviceSerials.clear();

	//Use the FTDI driver to get serial numbers (from "Simple" example)
	char * pBufSerials[MAX_APS_DEVICES+1];
	char bufSerials[MAX_APS_DEVICES][64];
	int numDevices = 0;
	FT_STATUS ftStatus;

	for(int devicect = 0; devicect < MAX_APS_DEVICES; devicect++) {
		pBufSerials[devicect] = bufSerials[devicect];
		}
	pBufSerials[MAX_APS_DEVICES] = NULL;

	ftStatus = FT_ListDevices(pBufSerials, &numDevices, FT_LIST_ALL | FT_OPEN_BY_SERIAL_NUMBER);

	if(!FT_SUCCESS(ftStatus)) {
		FILE_LOG(logERROR) << "Unable to run FT_ListDevices " << static_cast<int>(ftStatus);
		}

	FILE_LOG(logDEBUG) << "Found " << numDevices << " devices attached";

	//Copy over the char buffers to the vector of strings
	for(int devicect=0; (devicect<numDevices) && (devicect<MAX_APS_DEVICES); devicect++){
		deviceSerials.push_back(string(bufSerials[devicect]));
	}

}

int FTDI::connect(const int & deviceID, FT_HANDLE & deviceHandle) {

	FT_STATUS ftStatus;
	ftStatus = FT_Open(deviceID, &deviceHandle);
	if(!FT_SUCCESS(ftStatus)) {
		FILE_LOG(logERROR) << "Unable to open connection to device " << deviceID;
		return -1;
	}
	else{
		FILE_LOG(logDEBUG2) << "Opened connection to " << deviceID;
		ftStatus = FT_SetTimeouts(deviceHandle, APS_READTIMEOUT,APS_WRITETIMEOUT);
		if(!FT_SUCCESS(ftStatus)) {
			FILE_LOG(logERROR) << "Unable to set USB timeouts for device " << deviceID;
			return -1;
		}
		else{
			FILE_LOG(logDEBUG2) << "Set timeouts OK for " << deviceID;
		}
	}

	return 0;
}

int FTDI::disconnect(FT_HANDLE & deviceHandle) {

	FT_STATUS ftStatus;
	ftStatus = FT_Close(deviceHandle);
	if(!FT_SUCCESS(ftStatus)) {
		FILE_LOG(logERROR) << "Unable to close device " << deviceHandle;
		return -1;
	}
	return 0;
}
