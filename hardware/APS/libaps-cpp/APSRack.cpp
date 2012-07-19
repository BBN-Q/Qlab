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
	return APSs_[deviceID].init(bitFile, forceReload);
}

int APSRack::get_num_devices() const {

	int numDevices;
	FT_ListDevices(&numDevices, NULL, FT_LIST_NUMBER_ONLY);
	return numDevices;

}

string APSRack::get_deviceSerial(const int & deviceID) const{
	return deviceSerials_[deviceID];
}

//This will reset the APS vector so it really should only be called during initialization
void APSRack::enumerate_devices() {

	FTDI::get_device_serials(deviceSerials_);
	numDevices_ = deviceSerials_.size();

	APSs_.clear();
	APSs_.reserve(numDevices_);

	//Now setup the map between device serials and number and assign the APS units appropriately
	//Also setup the FPGA checksums
	size_t devicect = 0;
	for (string tmpSerial : deviceSerials_) {
		serial2dev[tmpSerial] = devicect;
		APSs_.push_back(APS(devicect, tmpSerial));
		FILE_LOG(logDEBUG) << "Device " << devicect << " has serial number " << tmpSerial;
		devicect++;
	}
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
	return APSs_[serial2dev[deviceSerial]].connect();
}

int APSRack::disconnect(const string & deviceSerial){
	//Look up the associated ID and call the next connect
	return APSs_[serial2dev[deviceSerial]].disconnect();
}

int APSRack::program_FPGA(const int & deviceID, const string &bitFile, const FPGASELECT & chipSelect, const int & expectedVersion){
	return APSs_[deviceID].program_FPGA(bitFile, chipSelect, expectedVersion);
}

int APSRack::setup_DACs(const int & deviceID) const{
	return APSs_[deviceID].setup_DACs();
}

int APSRack::set_sampleRate(const int & deviceID, const int & freq) {
	return APSs_[deviceID].set_sampleRate(freq);
}

int APSRack::get_sampleRate(const int & deviceID) const{
	return APSs_[deviceID].get_sampleRate();
}

int APSRack::set_run_mode(const int & deviceID, const int & dac, const bool & mode){
	return APSs_[deviceID].set_run_mode(dac, mode);
}

int APSRack::set_repeat_mode(const int & deviceID, const int & dac, const bool & mode){
	return APSs_[deviceID].set_repeat_mode(dac, mode);
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

int APSRack::trigger_FPGA_debug(const int & deviceID, const FPGASELECT & fpga){
	return APSs_[deviceID].trigger(fpga);
}

int APSRack::disable_FPGA_debug(const int & deviceID, const FPGASELECT & fpga){
	return APSs_[deviceID].disable(fpga);
}

int APSRack::load_sequence_file(const int & deviceID, const string & seqFile){
	return APSs_[deviceID].load_sequence_file(seqFile);
}

int APSRack::add_LL_bank(const int & deviceID, const int & channelNum, const vector<USHORT> & offset, const vector<USHORT> & count, const vector<USHORT> & repeat, const vector<USHORT> & trigger){
	return APSs_[deviceID].add_LL_bank(channelNum, offset, count, repeat, trigger);
}

int APSRack::reset_LL_banks(const int & deviceID, const int & channelNum){
	return APSs_[deviceID].channels_[channelNum].reset_LL_banks();
}

int APSRack::get_running(const int & deviceID){
	return APSs_[deviceID].running_;
}

int APSRack::set_log(FILE * pFile) {
	if (pFile) {
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

int APSRack::set_trigger_source(const int & deviceID, const int & triggerSource) {
	return APSs_[deviceID].triggerSource_ = triggerSource;
}

int APSRack::get_trigger_source(const int & deviceID) const{
	return APSs_[deviceID].triggerSource_;
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

int APSRack::set_channel_trigDelay(const int & deviceID, const int & channelNum, const USHORT & delay){
	return APSs_[deviceID].set_channel_trigDelay(channelNum, delay);
}
unsigned short APSRack::get_channel_trigDelay(const int & deviceID, const int & dac){
	return APSs_[deviceID].get_channel_trigDelay(dac);
}


