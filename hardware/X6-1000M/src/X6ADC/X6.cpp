/*
 * X6.cpp
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#include "X6.h"

X6::X6() : isOpen_{false}, deviceID_{-1}, samplingRate_{-1} {}

X6::~X6() = default;

int X6::connect(const int & deviceID) {
	int success = 0;

	if (!isOpen_) {
		deviceID_ = deviceID;
		success = handle_.open(deviceID_);
		
		if (success == 0) {
			isOpen_ = true;
		}
	}
	return success;
}

int X6::disconnect(){
	int success = 0;

	if (isOpen_) {
		success = handle_.close();

		if (success == 0) {
			FILE_LOG(logINFO) << "Closed connection to device " << deviceID_ << endl;
			isOpen_ = false;
		}	
	}
	return success;
}

int X6::init() {
	/* 
	 * Initializes the X6 into its default ready state.
	 */

	 // TODO
	samplingRate_ = get_sampleRate();

	return 0;
}

int X6::read_firmware_version() const {
	int version, subrevision;
	X6_1000 *h = const_cast<X6_1000*>(&handle_);
	h->read_firmware_version(version, subrevision);

	FILE_LOG(logINFO) << "Logic version: " << myhex << version << ", " << myhex << subrevision;

	return version;
}

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

int X6::set_averager_settings(const int & recordLength, const int & numSegments, const int & waveforms,	const int & roundRobins) {
	handle_.set_averager_settings(recordLength, numSegments, waveforms, roundRobins);
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
	X6_1000::TriggerSource src = handle_.get_trigger_src();
	if (src == X6_1000::EXTERNAL_TRIGGER)
		return EXTERNAL;
	else
		return INTERNAL;
}

int X6::set_reference_source(const REFERENCESOURCE & reference){

	int returnVal;
	switch (reference){
	case INTERNALREF:
		returnVal = handle_.set_reference(X6_1000::INTERNAL);
		break;
	case EXTERNALREF:
		returnVal = handle_.set_reference(X6_1000::EXTERNAL);
		break;
	default:
		returnVal = X6::X6_UNKNOWN_ERROR;
		break;
	}
	return returnVal;
}

REFERENCESOURCE X6::get_reference_source() {
	X6_1000::ExtInt src = handle_.get_reference();
	if (src == X6_1000::EXTERNAL)
		return EXTERNALREF;
	else
		return INTERNALREF;
}

int X6::set_channel_enable(const int & channel, const bool & enable) {
	return handle_.set_channel_enable(channel, enable);
}

bool X6::get_channel_enable(const int & channel) {
	return handle_.get_channel_enable(channel);
}

int X6::acquire() {
	handle_.acquire();
	return 0;
}

int X6::wait_for_acquisition(const int & timeOut) {
	// timeOut in seconds
	/*
	I eventually want this to look like:
	while (handle_.get_is_running() {
		if (!hanlde_.data_available()) {
			std::sleep_for(10ms);
		}
		else {
			ch1data = handle_.transfer_waveform(1, buffer, len);
			avgch1data += ch1data;
			ch2data = ...

		}
	}
	*/
	auto start = std::chrono::system_clock::now();
	auto end = start + std::chrono::seconds(timeOut);
	while (handle_.get_is_running()) {
		if (std::chrono::system_clock::now() > end)
			return X6::X6_TIMEOUT;
		std::this_thread::sleep_for( std::chrono::milliseconds(100) );
	}
	return 0;
}

int X6::stop() {
	handle_.stop();
	return 0;
}

int X6::transfer_waveform(const int & channel, int64_t *buffer, const size_t & bufferLength) {
	// TODO: manage averaging of data based on waveforms and round robins
	return handle_.transfer_waveform(channel, buffer, bufferLength);
}

int X6::set_digitizer_mode(const DIGITIZER_MODE & mode) {
	FILE_LOG(logINFO) << "Setting digitizer mode to: " << mode;
	write_register(WB_ADDR_DIGITIZER_MODE, WB_OFFSET_DIGITIZER_MODE, mode);
	return 0;
}

DIGITIZER_MODE X6::get_digitizer_mode() const {
	return DIGITIZER_MODE(read_register(WB_ADDR_DIGITIZER_MODE, WB_OFFSET_DIGITIZER_MODE));
}

int X6::write_register(const uint32_t & address, const uint32_t & offset, const uint32_t & data) {
	return handle_.write_wishbone_register(address, offset, data);
}

uint32_t X6::read_register(const uint32_t & address, const uint32_t & offset) const {
	return handle_.read_wishbone_register(address, offset);
}

float X6::get_logic_temperature(int method) {
	if (method == 0)
		return handle_.get_logic_temperature();
	else
		return handle_.get_logic_temperature_by_reg();
}
