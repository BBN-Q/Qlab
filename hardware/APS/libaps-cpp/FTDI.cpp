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

	FT_STATUS ftStatus;
	FT_DEVICE_LIST_INFO_NODE *devInfo; 
	DWORD numDevices;

	// create the device information list 
	ftStatus = FT_CreateDeviceInfoList(&numDevices);

	if(!FT_SUCCESS(ftStatus)) {
		FILE_LOG(logERROR) << "Unable to run FT_CreateDeviceInfoList with error code " << static_cast<int>(ftStatus);
		return;
	}

	FILE_LOG(logDEBUG) << "Found " << numDevices << " devices attached";

	if (numDevices > 0) { 
		// allocate storage for list based on numDevs 
		devInfo = static_cast<FT_DEVICE_LIST_INFO_NODE*>( malloc(sizeof(FT_DEVICE_LIST_INFO_NODE)*numDevices) ); 
		// get the device information list 
		ftStatus = FT_GetDeviceInfoList(devInfo,&numDevices); 

		if (!FT_SUCCESS(ftStatus)) {
			FILE_LOG(logERROR) << "Unable to run FT_GetDeviceInfoList with error code " << static_cast<int>(ftStatus);
			return;
		}

		// available members in devInfo
		// devInfo[i].Flags 
		// devInfo[i].Type
		// devInfo[i].ID
		// devInfo[i].LocId
		// devInfo[i].SerialNumber
		// devInfo[i].Description
		// devInfo[i].ftHandle); 

		//Copy over the char buffers to the vector of strings
		for(int devicect=0; (devicect < static_cast<int>(numDevices)) && (devicect<MAX_APS_DEVICES); devicect++){
			deviceSerials.push_back(string(devInfo[devicect].SerialNumber));
		}
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
		//Since we are polling a few bytes at a time on the device we can shorten up the latency
		ftStatus = FT_SetLatencyTimer(deviceHandle, 2);
		if(!FT_SUCCESS(ftStatus)) {
			FILE_LOG(logERROR) << "Unable to set latency for device " << deviceID;
			return -1;
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

int FTDI::isOpen(const int & deviceID) {

	// test to see if FTDI driver thinks that a device is open
	// test assumes that ftHandle is set to 0 is device is not open
	// this assumption determined to be true via experimentation not documentation

	FT_STATUS ftStatus; 
	FT_HANDLE ftHandleTemp; 
	DWORD numDevices; 
	DWORD Flags; 
	DWORD ID; 
	DWORD Type; 
	DWORD LocId; 
	char SerialNumber[16]; 
	char Description[64];

	// create the device information list 
	ftStatus = FT_CreateDeviceInfoList(&numDevices);

	if(!FT_SUCCESS(ftStatus)) {
		FILE_LOG(logERROR) << "Unable to run FT_CreateDeviceInfoList with error code " << static_cast<int>(ftStatus);
		return -1;
	}

	if ((numDevices > 0) && (deviceID < static_cast<int>(numDevices))) { 

		ftStatus = FT_GetDeviceInfoDetail(deviceID, &Flags, &Type, &ID, &LocId, SerialNumber, Description, &ftHandleTemp);		
		if (!FT_SUCCESS(ftStatus)) {
			FILE_LOG(logERROR) << "Unable to run FT_GetDeviceInfoDetail with error code " << static_cast<int>(ftStatus);
			return -2;
		}

		return ( ftHandleTemp != 0);
	}
	return -3;
}