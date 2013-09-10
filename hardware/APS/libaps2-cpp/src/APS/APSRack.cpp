/*
 * APSRack.cpp
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#include "APSRack.h"

APSRack::APSRack() : numDevices_{0} {
}

APSRack::~APSRack()  {
	//Close the logging file so we don't leave it dangling
	fclose(Output2FILE::Stream());
}

//Initialize the rack by polling for devices and serial numbers
int APSRack::init(const string & NICName) {

	//Create the logger
	//TODO: renable 
	FILE_LOG(logWARNING) << "libaps log file disabled in APSRack::init";
	//FILE* pFile = fopen("libaps.log", "a");
	//Output2FILE::Stream() = pFile;

	//Setup the NIC connected to the devices
	APSEthernet::get_instance().init(NICName);

	//Enumerate the serial numbers and MAC addresses of the devices attached
	enumerate_devices();

	return 0;
}

void APSRack::enumerate_devices() {
	/*
	* Look for all APS devices in this APS Rack.
	* This will reset the APS vector so it really should only be called during initialization
	*/

	set<string> oldSerials = deviceSerials_;
	deviceSerials_ = APSEthernet::get_instance().enumerate();
	numDevices_ = deviceSerials_.size();

	//See if any devices have been removed
	set<string> diffSerials;
	set_difference(oldSerials.begin(), oldSerials.end(), deviceSerials_.begin(), deviceSerials_.end(), std::inserter(diffSerials, diffSerials.begin()));
	for (auto serial : diffSerials) APSs.erase(serial);

	//Or if any devices have been added
	diffSerials.clear();
	set_difference(deviceSerials_.begin(), deviceSerials_.end(), oldSerials.begin(), oldSerials.end(), std::inserter(diffSerials, diffSerials.begin()));
	for (auto serial : diffSerials) APSs[serial] = APS2(serial);
}


int APSRack::get_num_devices()  {
	enumerate_devices();
	return numDevices_;
}


int APSRack::set_log(FILE * pFile) {
	if (pFile) {
		//Close the current file
		if(Output2FILE::Stream()) fclose(Output2FILE::Stream());
		//Assign the new one
		Output2FILE::Stream() = pFile;
		return 1;
	} else {
		return 0;
	}
}

int APSRack::set_logging_level(const int & logLevel){
	FILELog::ReportingLevel() = TLogLevel(logLevel);
	return 0;
}


/*
int APSRack::save_state_files(){
	// loop through available APS Units and save state
	for(unsigned int apsct = 0; apsct < APSs.size(); apsct++) {
		string stateFileName = ""; // use default file name
		APSs[apsct].save_state_file(stateFileName);
	}
	return 0;
}


int APSRack::read_state_files(){
	// loop through available APS Units and load state
	for(unsigned int  apsct = 0; apsct < APSs.size(); apsct++) {
		string stateFileName = ""; // use default file name
		APSs[apsct].read_state_file(stateFileName);
	}
	return 0;
}

int APSRack::save_bulk_state_file(string & stateFile){

	if (stateFile.length() == 0) {
		stateFile += "cache_APSRack.h5";
	}

	FILE_LOG(logDEBUG) << "Writing Bulk State File " << stateFile;
	H5::H5File H5StateFile(stateFile, H5F_ACC_TRUNC);
	// loop through available APS Units and save state
	for(unsigned int  apsct = 0; apsct < APSs.size(); apsct++) {
		string rootStr = "/";
		rootStr += APSs[apsct].deviceSerial_ ;
		FILE_LOG(logDEBUG) << "Creating Group: " << rootStr;
		H5::Group tmpGroup = H5StateFile.createGroup(rootStr);
		tmpGroup.close();
		APSs[apsct].write_state_to_hdf5(H5StateFile, rootStr);
	}
	//Close the file
	H5StateFile.close();
	return 0;
}

int APSRack::read_bulk_state_file(string & stateFile){
	if (stateFile.length() == 0) {
		stateFile += "cache_APSRack.h5";
	}
	FILE_LOG(logDEBUG) << "Reading Bulk State File " << stateFile;
	H5::H5File H5StateFile(stateFile, H5F_ACC_RDONLY);

	// loop through available APS Units and load data
	for(unsigned int  apsct = 0; apsct < APSs.size(); apsct++) {
		string rootStr = "/";
		rootStr += "/" + APSs[apsct].deviceSerial_;
		APSs[apsct].read_state_from_hdf5(H5StateFile, rootStr);
	}
	//Close the file
	H5StateFile.close();
	return 0;
}
*/
int APSRack::raw_write(const string & deviceID, int numBytes, uint8_t* data){
	uint16_t bytesWritten;
	//bytesWritten = APSs[deviceID].handle_.Write(data, numBytes);
	return int(bytesWritten);
}

int APSRack::raw_read(const string & deviceID) {
	uint16_t bytesRead, bytesWritten;
	uint8_t dataBuffer[2];
	uint16_t transferSize = 1;
	//TODO: fix!
	int Command = 0;

	//Send the read command byte
	uint8_t commandPacket = 0x80 | Command | transferSize;
   	//bytesWritten = APSs[deviceID].handle_.Write(&commandPacket, 1);

	//Look for the data
	//bytesRead = APSs[deviceID].handle_.Read(dataBuffer, 2);
	FILE_LOG(logDEBUG2) << "Read " << bytesRead << " bytes with value" << myhex << ((dataBuffer[0] << 8) | dataBuffer[1]);
	return int((dataBuffer[0] << 8) | dataBuffer[1]);
}

int APSRack::read_register(const string & deviceID, int addr){
	uint32_t value;
	//TODO: fix me!
	// APSs[deviceID].handle_.read_register(addr,value);
	return value;
}
