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
	// TODO renable 
	FILE_LOG(logWARNING) << "libaps log file disabled in APSRack::init";
	//FILE* pFile = fopen("libaps.log", "a");
	//Output2FILE::Stream() = pFile;

	//Setup the NIC connected to the devices
	socket_.init(NICName);

	//Enumerate the serial numbers and MAC addresses of the devices attached
	enumerate_devices();

	return 0;
}

//Initialize a specific APS unit
int APSRack::initAPS(const int & deviceID, const string & bitFile, const bool & forceReload){
	return APSs_[deviceID].init(forceReload);
}

int APSRack::get_num_devices()  {
	int numDevices;
	vector<string> APSDevices = socket_.enumerate();
	numDevices = APSDevices.size();
	if (numDevices_ != numDevices) {
		update_device_enumeration();
	}
	return numDevices;
}

string APSRack::get_deviceSerial(const int & deviceID) {

	// get current number of devices
	get_num_devices();

	// Get serials from FTDI layer to check for change in devices
	vector<string> testSerials;
	//TODO: fix me!
	// interface_.get_device_serials(testSerials);

	// match serials for each device id to make sure mapping of device count to serial
	// number is still correct
	// if serial number is different re-enumerate
	for(unsigned int cnt = 0; cnt < testSerials.size(); cnt++) {
		if (testSerials[cnt].compare(deviceSerials_[cnt]) != 0) {
			FILE_LOG(logDEBUG) << testSerials[cnt] << " does not match " << deviceSerials_[cnt] << " re-enumerating.";
			update_device_enumeration();
			break;
		}
	}

	// test to make sure ID is valid relative to vector size
	if (static_cast<size_t>(deviceID) > deviceSerials_.size()) {
		return "InvalidID";
	}

	return deviceSerials_[deviceID];
}

void APSRack::enumerate_devices() {
	/*
	* Look for all APS devices in this APS Rack.
	* This will reset the APS vector so it really should only be called during initialization
	*/

	vector<string> oldSerials = deviceSerials;
	deviceSerials_ = socket_.enumerate();

	//See if any devices have been removed
	vector<string> diffSerials;
	set_difference(oldSerials.begin(), oldSerials.end(), deviceSerials_.begin(), deviceSerials_.end(), diffSerials.begin());
	for (auto serial : diffSerials){
		APSs_.erase(serial);
	}

	//Or if any devices have been added
	diffSerials.clear();
	set_difference(deviceSerials_.begin(), deviceSerials_.end(), oldSerials.begin(), oldSerials.end(), diffSerials.begin());
	for (auto serial : diffSerials){
		APSs_[serial] = APS(serial);
	}
}

// This will update enumerate of devices by matching serial numbers
// If a device is missing it will be removed
// New devices are added 
// Old devices are left as is (moved in place to new vector)
void APSRack::update_device_enumeration() {

	vector<string> newSerials;
	//TODO: fix me!
	// interface_.get_device_serials(newSerials);

	// construct new APS_ vector & new serial2dev map
	vector<APS2> newAPS_;
	map<string, int> newSerial2dev;

	size_t devicect = 0;
	for (string tmpSerial : newSerials) {
		
		// example test to see if APS thinks device is open
	//TODO: fix me!
		// if (EthernetControl::isOpen(devicect)) {
		if(true){
			FILE_LOG(logDEBUG) << "Device " << devicect << " [ " << tmpSerial << " ] is open";
		}

		// does the new serial number exist in the old list? 
		if ( serial2dev.count(tmpSerial) > 0) {
			// move from old APSs_ vector to new
			newAPS_.push_back(std::move(APSs_[serial2dev[tmpSerial]]));
			newAPS_.back().deviceID_ = devicect;
			FILE_LOG(logDEBUG) << "Old Device " << devicect << " [ " << tmpSerial << " ] moved";
		} else {
			// does not exist so construct it in the new vector
			newAPS_.emplace_back(devicect, tmpSerial);
			FILE_LOG(logDEBUG) << "New Device " << devicect << " [ " << tmpSerial << " ]";
		}

		newSerial2dev[tmpSerial] = devicect;
		devicect++;
	}

	// update APSRack members with new lists
	numDevices_ = newSerials.size();  // number of devices
	deviceSerials_ = newSerials;		  // device serial vector
	APSs_ = std::move(newAPS_);           // APS vector
	serial2dev = newSerial2dev;           // serial to device map
}



int APSRack::get_bitfile_version(const int & deviceID) {
	return APSs_[deviceID].get_bitfile_version();
}

int APSRack::connect(const int & deviceID){
	//Connect to a instrument specified by deviceID
	return APSs_[deviceID].connect();
}

int APSRack::disconnect(const int & deviceID){
	return APSs_[deviceID].disconnect();
}

int APSRack::connect(const string & deviceSerial){
	//Look up the associated ID and call the next connect
	if (serial2dev.count(deviceSerial) > 0) {
		return APSs_[serial2dev[deviceSerial]].connect();
	} else {
		return -1;
	}
}

int APSRack::disconnect(const string & deviceSerial){
	//Look up the associated ID and call the next connect
	return APSs_[serial2dev[deviceSerial]].disconnect();
}

int APSRack::program_FPGA(const int & deviceID, const int & bitFileNum){
	return APSs_[deviceID].program_FPGA(bitFileNum);
}

int APSRack::setup_DACs(const int & deviceID) {
	return APSs_[deviceID].setup_DACs();
}

int APSRack::set_sampleRate(const int & deviceID, const int & freq) {
	return APSs_[deviceID].set_sampleRate(freq);
}

int APSRack::get_sampleRate(const int & deviceID) {
	return APSs_[deviceID].get_sampleRate();
}

int APSRack::set_run_mode(const int & deviceID, const int & dac, const RUN_MODE & mode){
	return APSs_[deviceID].set_run_mode(dac, mode);
}

int APSRack::clear_channel_data(const int & deviceID) {
	return APSs_[deviceID].clear_channel_data();
}

int APSRack::run(const int & deviceID) {
	return APSs_[deviceID].run();
}
int APSRack::stop(const int & deviceID) {
	return APSs_[deviceID].stop();
}

int APSRack::load_sequence_file(const int & deviceID, const string & seqFile){
	return APSs_[deviceID].load_sequence_file(seqFile);
}

int APSRack::set_LL_data(const int & deviceID, const int & channelNum, const WordVec & addr, const WordVec & count, const WordVec & trigger1, const WordVec & trigger2, const WordVec & repeat){
	return APSs_[deviceID].set_LLData_IQ(addr, count, trigger1, trigger2, repeat);
}

int APSRack::get_running(const int & deviceID){
	//TODO:
//	return APSs_[deviceID].running_;
	return 0;
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

int APSRack::set_trigger_source(const int & deviceID, const TRIGGERSOURCE & triggerSource) {
	return APSs_[deviceID].set_trigger_source(triggerSource);
}

TRIGGERSOURCE APSRack::get_trigger_source(const int & deviceID) {
	return APSs_[deviceID].get_trigger_source();
}

int APSRack::set_trigger_interval(const int & deviceID, const double & interval){
	return APSs_[deviceID].set_trigger_interval(interval);
}

double APSRack::get_trigger_interval(const int & deviceID) {
	return APSs_[deviceID].get_trigger_interval();
}

int APSRack::set_channel_enabled(const int & deviceID, const int & channelNum, const bool & enable){
	return APSs_[deviceID].set_channel_enabled(channelNum, enable);
}

bool APSRack::get_channel_enabled(const int & deviceID, const int & channelNum) const{
	return APSs_[deviceID].get_channel_enabled(channelNum);
}

int APSRack::set_channel_offset(const int & deviceID, const int & channelNum, const float & offset){
	return APSs_[deviceID].set_channel_offset(channelNum, offset);
}

float APSRack::get_channel_offset(const int & deviceID, const int & channelNum) const{
	return APSs_[deviceID].get_channel_offset(channelNum);
}

int APSRack::set_channel_scale(const int & deviceID, const int & channelNum, const float & scale){
	return APSs_[deviceID].set_channel_scale(channelNum, scale);
}

float APSRack::get_channel_scale(const int & deviceID, const int & channelNum) const{
	return APSs_[deviceID].get_channel_scale(channelNum);
}

/*
int APSRack::save_state_files(){
	// loop through available APS Units and save state
	for(unsigned int apsct = 0; apsct < APSs_.size(); apsct++) {
		string stateFileName = ""; // use default file name
		APSs_[apsct].save_state_file(stateFileName);
	}
	return 0;
}


int APSRack::read_state_files(){
	// loop through available APS Units and load state
	for(unsigned int  apsct = 0; apsct < APSs_.size(); apsct++) {
		string stateFileName = ""; // use default file name
		APSs_[apsct].read_state_file(stateFileName);
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
	for(unsigned int  apsct = 0; apsct < APSs_.size(); apsct++) {
		string rootStr = "/";
		rootStr += APSs_[apsct].deviceSerial_ ;
		FILE_LOG(logDEBUG) << "Creating Group: " << rootStr;
		H5::Group tmpGroup = H5StateFile.createGroup(rootStr);
		tmpGroup.close();
		APSs_[apsct].write_state_to_hdf5(H5StateFile, rootStr);
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
	for(unsigned int  apsct = 0; apsct < APSs_.size(); apsct++) {
		string rootStr = "/";
		rootStr += "/" + APSs_[apsct].deviceSerial_;
		APSs_[apsct].read_state_from_hdf5(H5StateFile, rootStr);
	}
	//Close the file
	H5StateFile.close();
	return 0;
}
*/
int APSRack::raw_write(int deviceID, int numBytes, uint8_t* data){
	uint16_t bytesWritten;
	//bytesWritten = APSs_[deviceID].handle_.Write(data, numBytes);
	return int(bytesWritten);
}

int APSRack::raw_read(int deviceID) {
	uint16_t bytesRead, bytesWritten;
	uint8_t dataBuffer[2];
	uint16_t transferSize = 1;
	//TODO: fix!
	int Command = 0;

	//Send the read command byte
	uint8_t commandPacket = 0x80 | Command | transferSize;
   	//bytesWritten = APSs_[deviceID].handle_.Write(&commandPacket, 1);

	//Look for the data
	//bytesRead = APSs_[deviceID].handle_.Read(dataBuffer, 2);
	FILE_LOG(logDEBUG2) << "Read " << bytesRead << " bytes with value" << myhex << ((dataBuffer[0] << 8) | dataBuffer[1]);
	return int((dataBuffer[0] << 8) | dataBuffer[1]);
}

int APSRack::read_register(int deviceID, int addr){
	uint32_t value;
	//TODO: fix me!
	// APSs_[deviceID].handle_.read_register(addr,value);
	return value;
}
