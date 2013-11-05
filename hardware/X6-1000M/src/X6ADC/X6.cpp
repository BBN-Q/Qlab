/*
 * X6.cpp
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#include "X6.h"

X6::X6() : isOpen_{false}, deviceID_{-1}, samplingRate_{-1} {}

X6::X6(int deviceID) : isOpen_{false}, deviceID_{deviceID}, samplingRate_{-1} {
	// set X6 device ID
	handle_.set_deviceID(deviceID);
};

X6::X6(X6 && other) : isOpen_{other.isOpen_}, deviceID_{other.deviceID_}, samplingRate_{other.samplingRate_},
		handle_{std::move(other.handle_} {
};


X6::~X6() = default;

int X6::connect(){
	int success = 0;

	if (!isOpen_) {
		success = handle_.Open(deviceID_);
		
		if (success == 0) {
			FILE_LOG(logINFO) << "Opened connection to device " << deviceID_;
			isOpen_ = true;
		}
	}
	return success;
}

int X6::disconnect(){
	int success = 0;

	if (isOpen_) {
		success = handle_.Close();

		if (success == 0) {
			FILE_LOG(logINFO) << "Closed connection to device " << deviceID_ << " (Serial: " << deviceSerial_ << ")";
			isOpen = false;
		}	
	}
	return success;
}

int X6::init() {
	/* 
	 * Initializes the X6 into its default ready state.
	 */

	samplingRate_ = get_sampleRate();

	return 0;
}

/*
int X6::read_firmware_version() const {
	// Reads version information from register 0x8006

	int version, version2;

	version = FPGA::read_FPGA(handle_, FPGA_ADDR_VERSION, FPGA1);
	version &= 0x1FF; // First 9 bits hold version
	FILE_LOG(logDEBUG2) << "Bitfile version for FPGA 1 is "  << myhex << version;
	version2 = FPGA::read_FPGA(handle_, FPGA_ADDR_VERSION, FPGA2);
	version2 &= 0x1FF; // First 9 bits hold version
	FILE_LOG(logDEBUG2) << "Bitfile version for FPGA 2 is "  << myhex << version2;
		if (version != version2) {
		FILE_LOG(logERROR) << "Bitfile versions are not the same on the two FPGAs: " << version << " and " << version2;
		return -1;

	return version;
}
*/

int X6::set_sampleRate(const double & freq) {
	if (samplingRate_ != freq) {
		
		handle_.set_clock(X6_1000::INTERNAL, freq);
		samplingRate_ = freq;

		return 1;
	} else {
		return 0;
	}
}

double X6::get_sampleRate() const {
	double freq;

	// work around for const conversion issues
	X6_1000 *h = const_cast<X6_1000*>(&handle_);

	freq = h->get_pll_frequency();

	FILE_LOG(logDEBUG2) << "PLL frequency for X6: " << freq;

	return freq;
}

int X6::set_trigger_source(const TRIGGERSOURCE & triggerSource){

	int returnVal;
	switch (triggerSource){
	case INTERNAL:
		returnVal = handle_.set_trigger_src(X6_1000::SOFTWARE_TRIGGER);
		break;
	case EXTERNAL:
		returnVal = handle_.set_trigger_src(X6_1000::EXTERNAL_TRIGGER);
		break;
	default:
		returnVal = X6::X6_UNKNOWN_ERROR;
		break;
	}
	return returnVal;
}

TRIGGERSOURCE X6::get_trigger_source() const{
	// work around for const conversion issues
	X6_1000 *h = const_cast<X6_1000*>(&handle_);

	X6_1000::TriggerSource src = h->get_trigger_src();
	if (src == X6_1000::EXTERNAL_TRIGGER)
		return EXTERNAL;
	else
		return INTERNAL;
}

int X6::acquire() {
	handle_.acquire();
	return 0;
}

int X6::wait_for_acquisition(const int & timeOut) {
	// timeOut in seconds
	// TODO
	return 0;
}

int X6::stop() {
	handle_.Stop();
	return 0;
}

int X6::transfer_waveform(const int & channel, unsigned short *buffer, const size_t & bufferLength) {
	// TODO
	for (size_t ct = 0; ct < bufferLength; ct++) {
		buffer[ct] = ct;
	}
	return 0;
}

int X6::set_digitizer_mode(const DIGITIZER_MODE & mode) {
	FILE_LOG(logINFO) << "Setting ditizier mode to: " << mode;
	write_register(WB_ADDR_DIGITIZER_MODE, WB_OFFSET_DIGITIZER_MODE, mode);
	return 0;
}

DIGITIZER_MODE X6::get_digitizer_mode() const {
	return read_register(WB_ADDR_DIGITIZER_MODE, WB_OFFSET_DIGITIZER_MODE);
}

int X6::write_register(const uint32_t & address, const uint32_t & offset, const uint32_t & data) {
	return handle_.write_wishbone_register(address, offset, data);
}

uint32_t X6::read_register(const uint32_t & address, const uint32_t & offset) {
	return handle_.read_wishbone_register(address, offset);
}

/*
 *
 * Private Functions
 */

// int X6::write( const unsigned int & addr, const USHORT & data, const bool & queue  see header for default ){
// 	//Create the vector and pass through
// 	return write(fpga, addr, vector<USHORT>(1, data), queue);
// }

// int X6::write( const unsigned int & addr, const vector<USHORT> & data, const bool & queue /* see header for default */){
// 	/* X6::write
// 	 * fpga = FPAG1, FPGA2, or ALL_FPGAS (for simultaneous writes)
// 	 * addr = valid memory address to start to write to
// 	 * data = vector<WORD> data
// 	 * queue = false - write immediately, true - add write command to output queue
// 	 */

// 	//Pack the data
// 	vector<UCHAR> dataPacket = FPGA::format(fpga, addr, data);

// 	//Update the software checksums
// 	//Address checksum is defined as lower word of address
// 	checksums_[fpga].address += addr & 0xFFFF;
// 	for(auto tmpData : data)
// 		checksums_[fpga].data += tmpData;

// 	//Push into queue or write to FPGA
// 	auto offsets = FPGA::computeCmdByteOffsets(data.size());
// 	if (queue) {
// 		//Calculate offsets of command bytes
// 		for (auto tmpOffset : offsets){
// 			offsetQueue_.push_back(tmpOffset + writeQueue_.size());
// 		}
// 		for (auto tmpByte : dataPacket){
// 			writeQueue_.push_back(tmpByte);
// 		}
// 	}
// 	else{
// 		FPGA::write_block(handle_, dataPacket, offsets);
// 	}

// 	return 0;
// }

float X6::get_logic_temperature(int method) {
	if (method == 0)
		return handle_.get_logic_temperature();
	else
		return handle_.get_logic_temperature_by_reg();
}
