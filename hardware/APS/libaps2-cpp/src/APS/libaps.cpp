/*
 * libaps.cpp - Library for APSv2 control. 
 *
 */

#include "headings.h"
#include "libaps.h"
#include "APS2.h"

map<string, APS2> APSs; //map to hold on to the APS instances
set<string> deviceSerials; // set of APSs that responded to an enumerate broadcast


// stub class to close the logger file handle when the driver goes out of scope
class CleanUp {
public:
        ~CleanUp();
};

CleanUp::~CleanUp() {
        if (Output2FILE::Stream()) {
                fclose(Output2FILE::Stream());
        }
}

#ifdef __cplusplus
extern "C" {
#endif

int init(const char* NICName){

	//TODO: bind to particular NIC here?

	//Create the logger
	//TODO: renable 
	FILE_LOG(logWARNING) << "libaps log file disabled in APSRack::init";
	//FILE* pFile = fopen("libaps.log", "a");
	//Output2FILE::Stream() = pFile;

	//Setup the NIC connected to the devices
	APSEthernet::get_instance().init(NICName);

	//Enumerate the serial numbers and MAC addresses of the devices attached
	enumerate_devices();

	return APS_OK;
}

int enumerate_devices(){

	/*
	* Look for all APS devices in this APS Rack.
	*/

	set<string> oldSerials = deviceSerials;
	deviceSerials = APSEthernet::get_instance().enumerate();

	//See if any devices have been removed
	set<string> diffSerials;
	set_difference(oldSerials.begin(), oldSerials.end(), deviceSerials.begin(), deviceSerials.end(), std::inserter(diffSerials, diffSerials.begin()));
	for (auto serial : diffSerials) APSs.erase(serial);

	//Or if any devices have been added
	diffSerials.clear();
	set_difference(deviceSerials.begin(), deviceSerials.end(), oldSerials.begin(), oldSerials.end(), std::inserter(diffSerials, diffSerials.begin()));
	for (auto serial : diffSerials) APSs[serial] = APS2(serial);

	return APS_OK;
}

int get_numDevices(){
	return deviceSerials.size();
}

void get_deviceSerials(const char ** deviceSerialsOut){
	//Assumes sufficient memory has been allocated
	size_t ct = 0;
	for (auto serial : deviceSerials){
		deviceSerialsOut[ct] = serial.c_str();
		ct++;
	}
}

//Connect to a device specified by serial number string
//Assumes null-terminated deviceSerial
int connect_APS(const char * deviceSerial){
	return APSs[string(deviceSerial)].connect();
}

//Assumes a null-terminated deviceSerial
int disconnect_APS(const char * deviceSerial){
	return APSs[string(deviceSerial)].disconnect();
}

int reset(const char * deviceSerial, int resetMode){
	return APSs[string(deviceSerial)].reset(static_cast<APS_RESET_MODE_STAT>(resetMode));
}

//Initialize an APS unit
//Assumes null-terminated bitFile
int initAPS(const char * deviceSerial, int forceReload){
	try {
		return APSs[string(deviceSerial)].init(forceReload);
	} catch (std::exception& e) {
		string error = e.what();
		if (error.compare("Unable to open bitfile.") == 0) {
			return APS_FILE_ERROR;
		} else {
			return APS_UNKNOWN_ERROR;
		}
	}

}

int get_bitfile_version(const char * deviceSerial) {
	return APSs[string(deviceSerial)].get_bitfile_version();
}

double get_uptime(const char * deviceSerial){
	return APSs[string(deviceSerial)].get_uptime();
}

int set_sampleRate(const char * deviceSerial, int freq){
	return APSs[string(deviceSerial)].set_sampleRate(freq);
}

int get_sampleRate(const char * deviceSerial){
	return APSs[string(deviceSerial)].get_sampleRate();
}

//Load the waveform library as floats
int set_waveform_float(const char * deviceSerial, int channelNum, float* data, int numPts){
	return APSs[string(deviceSerial)].set_waveform( channelNum, vector<float>(data, data+numPts));
}

//Load the waveform library as int16
int set_waveform_int(const char * deviceSerial, int channelNum, short* data, int numPts){
	return APSs[string(deviceSerial)].set_waveform(channelNum, vector<short>(data, data+numPts));
}

int write_sequence(const char * deviceSerial, uint32_t* data, uint32_t numWords) {
	vector<uint32_t> dataVec(data, data+numWords);
	return APSs[string(deviceSerial)].write_sequence(dataVec);
}

int load_sequence_file(const char * deviceSerial, const char * seqFile){
	try {
		return APSs[string(deviceSerial)].load_sequence_file(string(seqFile));
	} catch (...) {
		return APS_UNKNOWN_ERROR;
	}
	// should not reach this point
	return APS_UNKNOWN_ERROR;
}

int clear_channel_data(const char * deviceSerial) {
	return APSs[string(deviceSerial)].clear_channel_data();
}

int run(const char * deviceSerial) {
	return APSs[string(deviceSerial)].run();
}

int stop(const char * deviceSerial) {
	return APSs[string(deviceSerial)].stop();
}

int get_running(const char * deviceSerial){
	return APSs[string(deviceSerial)].running;
}

//Expects a null-terminated character array
int set_log(const char * fileNameArr) {

	//Close the current file
	if(Output2FILE::Stream()) fclose(Output2FILE::Stream());
	
	string fileName(fileNameArr);
	if (fileName.compare("stdout") == 0){
		Output2FILE::Stream() = stdout;
		return APS_OK;
	}
	else if (fileName.compare("stderr") == 0){
		Output2FILE::Stream() = stdout;
		return APS_OK;
	}
	else{

		FILE* pFile = fopen(fileName.c_str(), "a");
		if (!pFile) {
			return APS_FILE_ERROR;
		}
		Output2FILE::Stream() = pFile;
		return APS_OK;
	}
}

int set_logging_level(int logLevel){
	FILELog::ReportingLevel() = TLogLevel(logLevel);
	return APS_OK;
}

int set_trigger_source(const char * deviceSerial, int triggerSource) {
	return APSs[string(deviceSerial)].set_trigger_source(TRIGGERSOURCE(triggerSource));
}

int get_trigger_source(const char * deviceSerial) {
	return int(APSs[string(deviceSerial)].get_trigger_source());
}

int set_trigger_interval(const char * deviceSerial, double interval){
	return APSs[string(deviceSerial)].set_trigger_interval(interval);
}

double get_trigger_interval(const char * deviceSerial){
	return APSs[string(deviceSerial)].get_trigger_interval();
}

int set_channel_offset(const char * deviceSerial, int channelNum, float offset){
	return APSs[string(deviceSerial)].set_channel_offset(channelNum, offset);
}
int set_channel_scale(const char * deviceSerial, int channelNum, float scale){
	return APSs[string(deviceSerial)].set_channel_scale(channelNum, scale);
}
int set_channel_enabled(const char * deviceSerial, int channelNum, int enable){
	return APSs[string(deviceSerial)].set_channel_enabled(channelNum, enable);
}

float get_channel_offset(const char * deviceSerial, int channelNum){
	return APSs[string(deviceSerial)].get_channel_offset(channelNum);
}
float get_channel_scale(const char * deviceSerial, int channelNum){
	return APSs[string(deviceSerial)].get_channel_scale(channelNum);
}
int get_channel_enabled(const char * deviceSerial, int channelNum){
	return APSs[string(deviceSerial)].get_channel_enabled(channelNum);
}

int set_run_mode(const char * deviceSerial, int mode) {
	return APSs[string(deviceSerial)].set_run_mode(RUN_MODE(mode));
}

//int save_state_files() {
//	return APSRack_.save_state_files();
//}
//
//int read_state_files() {
//	return APSRack_.read_state_files();
//}
//
//int save_bulk_state_file() {
//	string fileName = "";
//	return APSRack_.save_bulk_state_file(fileName);
//}
//int read_bulk_state_file() {
//	string fileName = "";
//	return APSRack_.read_bulk_state_file(fileName);
//}

int write_memory(const char * deviceSerial, uint32_t addr, uint32_t* data, uint32_t numWords) {
	vector<uint32_t> dataVec(data, data+numWords);
	return APSs[string(deviceSerial)].write_memory(addr, dataVec);
}

int read_memory(const char * deviceSerial, uint32_t addr, uint32_t* data, uint32_t numWords) {
	auto readData = APSs[string(deviceSerial)].read_memory(addr, numWords);
	std::copy(readData.begin(), readData.end(), data);
	return 0;
}

// int read_register(const char * deviceSerial, int addr){
// 	return APSRack_.read_register(string(deviceSerial), addr);
// }

int program_FPGA(const char * deviceSerial, const char * bitFile) {
	return APSs[string(deviceSerial)].program_FPGA(string(bitFile));
}

int write_flash(const char * deviceSerial, uint32_t addr, uint32_t* data, uint32_t numWords) {
	vector<uint32_t> writeData(data, data+numWords);
	return APSs[string(deviceSerial)].write_flash(addr, writeData);
}
int read_flash(const char * deviceSerial, uint32_t addr, uint32_t numWords, uint32_t* data) {
	auto readData = APSs[string(deviceSerial)].read_flash(addr, numWords);
	cout << endl;
	std::copy(readData.begin(), readData.end(), data);
	return 0;
}
int write_SPI_setup(const char * deviceSerial) {
	return APSs[string(deviceSerial)].write_SPI_setup();
}

#ifdef __cplusplus
}
#endif

