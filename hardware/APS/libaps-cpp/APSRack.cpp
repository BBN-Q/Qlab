/*
 * APSRack.cpp
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#include "headings.h"

APSRack::APSRack() : _numDevices(0) {
}

APSRack::~APSRack()  {
}

//Initialize the rack by polling for devices and serial numbers
int APSRack::init() {

	//Create the logger
	FILE* pFile = fopen("libaps.log", "a");
	Output2FILE::Stream() = pFile;

	//Enumerate the serial numbers of the devices attached
	enumerate_devices();

	return 0;
}

//Initialize a specific APS unit
int APSRack::initAPS(const int & deviceID, const string & bitFile, const bool & forceReload){
	return _APSs[deviceID].init(bitFile, forceReload);
}

int APSRack::get_num_devices() {

	int numDevices;
	FT_ListDevices(&numDevices, NULL, FT_LIST_NUMBER_ONLY);
	return numDevices;

}

//This will reset the APS vector so it really should only be called during initialization
void APSRack::enumerate_devices() {

	FTDI::get_device_serials(_deviceSerials);
	_numDevices = _deviceSerials.size();

	_APSs.clear();
	_APSs.reserve(_numDevices);

	//Now setup the map between device serials and number and assign the APS units appropriately
	//Also setup the FPGA checksums
	size_t devicect = 0;
	for (string tmpSerial : _deviceSerials) {
		serial2dev[tmpSerial] = devicect;
		_APSs.push_back(APS(devicect, tmpSerial));
		FILE_LOG(logDEBUG) << "Device " << devicect << " has serial number " << tmpSerial;
		FPGA::checksumAddr[_APSs[devicect]._handle] = vector<ushort>(2,0);
		FPGA::checksumData[_APSs[devicect]._handle] = vector<ushort>(2,0);
		devicect++;
	}
}

int APSRack::connect(const int & deviceID){
	//Connect to a instrument specified by deviceID
	return _APSs[deviceID].connect();
}

int APSRack::disconnect(const int & deviceID){
	return _APSs[deviceID].disconnect();
}

int APSRack::connect(const string & deviceSerial){
	//Look up the associated ID and call the next connect
	return _APSs[serial2dev[deviceSerial]].connect();
}

int APSRack::disconnect(const string & deviceSerial){
	//Look up the associated ID and call the next connect
	return _APSs[serial2dev[deviceSerial]].disconnect();
}

int APSRack::program_FPGA(const int & deviceID, const string &bitFile, const int & chipSelect, const int & expectedVersion){
	return _APSs[deviceID].program_FPGA(bitFile, chipSelect, expectedVersion);
}

int APSRack::set_sampleRate(const int & deviceID, const int & fpga, const int & freq, const bool & testLock) {
	return _APSs[deviceID].set_sampleRate(fpga, freq, testLock);
}

int APSRack::get_sampleRate(const int & deviceID, const int & fpga){
	return _APSs[deviceID].get_sampleRate(fpga);
}


