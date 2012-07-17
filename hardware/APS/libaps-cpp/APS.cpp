/*
 * APS.cpp
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#include "APS.h"

APS::APS() :  deviceID_{-1}, handle_{NULL}, channels_(4), triggerSource_{SOFTWARE_TRIGGER}, samplingRate_{-1}, running_{false} {}

APS::APS(int deviceID, string deviceSerial) :  deviceID_{deviceID}, deviceSerial_{deviceSerial},
		handle_{NULL}, triggerSource_{SOFTWARE_TRIGGER}, samplingRate_{-1}, running_{false} {
		for(int ct=0; ct<4; ct++){
			channels_.push_back(Channel(ct));
		}
		checksums_[FPGA1] = CheckSum();
		checksums_[FPGA2] = CheckSum();
};

APS::~APS() {
	// TODO Auto-generated destructor stub
}

int APS::connect(){
	int success = 0;
	success = FTDI::connect(deviceID_, handle_);
	if (success == 0) {
		FILE_LOG(logDEBUG) << "Opened connection to device " << deviceID_ << " (Serial: " << deviceSerial_ << ")";
	}
	return success;
}

int APS::disconnect(){
	int success = 0;
	success = FTDI::disconnect(handle_);
	if (success == 0) {
		FILE_LOG(logDEBUG) << "Closed connection to device " << deviceID_ << " (Serial: " << deviceSerial_ << ")";
	}
	return success;
}

int APS::init(const string & bitFile, const bool & forceReload){

	if (forceReload || read_bitFile_version(ALL_FPGAS) != FIRMWARE_VERSION || read_PLL_status(ALL_FPGAS)) {
		FILE_LOG(logINFO) << "Resetting instrument";
		FILE_LOG(logINFO) << "Found force: " << forceReload << " bitFile version: " << myhex << read_bitFile_version(ALL_FPGAS) << " PLL status: " << read_PLL_status(ALL_FPGAS);
		//Setup the oscillators
		setup_VCXO();
		setup_PLL();

		//Program the bitfile to both FPGA's
		int bytesProgramed = program_FPGA(bitFile, ALL_FPGAS, 0x10);

		//Default to max sample rate
		set_sampleRate(1200);

		// seems to be necessary on DAC2 devices
		// probably worth further investigation to remove if possible
		reset_status_ctrl();

		// test PLL sync on each FPGA
		int status = test_PLL_sync(FPGA1) || test_PLL_sync(FPGA2);
		if (status) {
			FILE_LOG(logERROR) << "DAC PLLs failed to sync";
		}

		// align DAC data clock boundaries
		setup_DACs();

		// clear channel data
		clear_channel_data();

		// update LED mode
		set_LED_mode(ALL_FPGAS, LED_RUNNING);

		return bytesProgramed;
	}

	return 0;
}


int APS::setup_DACs() const{
	//Call the setup function for each DAC
	for(int dac=0; dac<4; dac++){
		setup_DAC(dac);
	}
	return 0;
}
int APS::program_FPGA(const string & bitFile, const FPGASELECT & chipSelect, const int & expectedVersion) const {

	//Open the bitfile
	FILE_LOG(logDEBUG2) << "Opening bitfile: " << bitFile;
	std::ifstream FID (bitFile, std::ios::in|std::ios::binary);
	//Get the size
	if (!FID.is_open()){
		FILE_LOG(logERROR) << "Unable to open bitfile: " << bitFile;
		throw runtime_error("Unable to open bitfile.");
	}

	//Copy over the file data to the data vector
	//The default istreambuf_iterator constructor returns the "end-of-stream" iterator.
	vector<UCHAR> fileData((std::istreambuf_iterator<char>(FID)), std::istreambuf_iterator<char>());
	ULONG numBytes = fileData.size();
	FILE_LOG(logDEBUG) << "Read " << numBytes << " bytes from bitfile";

	//Pass of the data to a lower-level function to actually push it to the FPGA
	int bytesProgrammed = FPGA::program_FPGA(handle_, fileData, chipSelect);

	if (bytesProgrammed > 0) {
		// Read Bit File Version
		int version;
		bool ok = false;
		for (int ct = 0; ct < 20 && !ok; ct++) {
			version =  APS::read_bitFile_version(chipSelect);
			if (version == expectedVersion) ok = true;
			usleep(1000); // if doesn't match, wait a bit and try again
		}
		if (!ok) return -11;
	}

	return bytesProgrammed;
}

int APS::read_bitFile_version(const FPGASELECT & chipSelect) const {

// Reads version information from register 0x8006

int version, version2;

//For single FPGA we return that version, for both we return both if the same otherwise error.
switch (chipSelect) {
case FPGA1:
case FPGA2:
	version = FPGA::read_FPGA(handle_, FPGA_ADDR_REGREAD | FPGA_OFF_VERSION, chipSelect);
	version &= 0x1FF; // First 9 bits hold version
	FILE_LOG(logDEBUG2) << "Bitfile version for FPGA " << chipSelect << " is "  << myhex << version;
	break;
case ALL_FPGAS:
	version = FPGA::read_FPGA(handle_, FPGA_ADDR_REGREAD | FPGA_OFF_VERSION, FPGA1);
	version &= 0x1FF; // First 9 bits hold version
	FILE_LOG(logDEBUG2) << "Bitfile version for FPGA 1 is "  << myhex << version;
	version2 = FPGA::read_FPGA(handle_, FPGA_ADDR_REGREAD | FPGA_OFF_VERSION, FPGA2);
	version2 &= 0x1FF; // First 9 bits hold version
	FILE_LOG(logDEBUG2) << "Bitfile version for FPGA 2 is "  << myhex << version2;
		if (version != version2) {
		FILE_LOG(logERROR) << "Bitfile versions are not the same on the two FPGAs: " << version << " and " << version2;
		return -1;
	}
	break;
default:
	FILE_LOG(logERROR) << "Unknown chipSelect value in APS::read_bitfile_version: " << chipSelect;
	return -1;
}

return version;
}

int APS::set_sampleRate(const int & freq){
	if (samplingRate_ != freq){
		//Set PLL frequency for each fpga
		APS::set_PLL_freq(FPGA1, freq);
		APS::set_PLL_freq(FPGA2, freq);

		samplingRate_ = freq;

		//Test the sync
		return APS::test_PLL_sync(FPGA1) || APS::test_PLL_sync(FPGA2);
	}
	else{
		return 0;
	}
}

int APS::get_sampleRate() const{
	//Pass through to FPGA code
	int freq1 = APS::get_PLL_freq(FPGA1);
	int freq2 = APS::get_PLL_freq(FPGA2);
	if (freq1 != freq2){
		FILE_LOG(logERROR) << "FGPA's did not have same PLL frequency.";
		return -1;
	}
	return freq1;
}

int APS::clear_channel_data() {
	for (auto ch : channels_) {
		ch.clear_data();
	}
	return 0;
}

int APS::load_sequence_file(const string & seqFile){
	/*
	 * Load a sequence file from a H5 file
	 */
	//First open the file
/*
	H5::H5File H5SeqFile(seqFile, H5F_ACC_RDONLY);

	const vector<string> chanStrs = {"chan_1", "chan_2", "chan_3", "chan_4"};
	//For now assume 4 channel data
	//TODO: check the channelDataFor attribute
	for(int chanct=0; chanct<4; chanct++){
		//Reset the LL banks
		channels_[chanct].reset_LL_banks();

		//Load the waveform library first
		string chanStr = chanStrs[chanct];
		vector<short> tmpVec = h5array2vector<short>(&H5SeqFile, chanStr + "/waveformLib", H5::PredType::NATIVE_INT16);
		APS::set_waveform(chanct, tmpVec);

		//Load the linklist data
		//First figure our how many banks there are from the attribute
		H5::Group tmpGroup = H5SeqFile.openGroup(chanStr + "/linkListData");
		H5::Attribute tmpAttribute = tmpGroup.openAttribute("numBanks");
		USHORT numBanks;
		tmpAttribute.read(H5::PredType::NATIVE_UINT16, &numBanks);
		tmpAttribute.close();
		tmpGroup.close();

		//Now loop over the number of banks found and add the bank
		for (USHORT bankct=0; bankct<numBanks; bankct++){
			std::ostringstream tmpStream;
			tmpStream.str("");
			tmpStream << chanStr << "/linkListData/bank" << bankct+1 << "/offset";
			vector<USHORT> offset = h5array2vector<USHORT>(&H5SeqFile, tmpStream.str(), H5::PredType::NATIVE_UINT16);
			tmpStream.str("");
			tmpStream << chanStr << "/linkListData/bank" << bankct+1 << "/count";
			vector<USHORT> count = h5array2vector<USHORT>(&H5SeqFile, tmpStream.str(), H5::PredType::NATIVE_UINT16);
			tmpStream.str("");
			tmpStream << chanStr << "/linkListData/bank" << bankct+1 << "/repeat";
			vector<USHORT> repeat = h5array2vector<USHORT>(&H5SeqFile, tmpStream.str(), H5::PredType::NATIVE_UINT16);
			tmpStream.str("");
			tmpStream << chanStr << "/linkListData/bank" << bankct+1 << "/trigger";
			vector<USHORT> trigger = h5array2vector<USHORT>(&H5SeqFile, tmpStream.str(), H5::PredType::NATIVE_UINT16);

			//Push back the new bank
			add_LL_bank(chanct, offset, count, repeat, trigger);
		}
	}
	//Close the file
	H5SeqFile.close();
*/

	return 0;

}

int APS::set_channel_enabled(const int & dac, const bool & enable){
	return channels_[dac].set_enabled(enable);
}

bool APS::get_channel_enabled(const int & dac) const{
	return channels_[dac].get_enabled();
}

int APS::set_channel_offset(const int & dac, const float & offset){
	//Update the waveform in driver
	channels_[dac].set_offset(offset);
	//Write to device if necessary
	if (!channels_[dac].waveform_.empty()){
		write_waveform(dac, channels_[dac].prep_waveform());
	}

	//Update TAZ register
	set_offset_register(dac, channels_[dac].get_offset());

	return 0;
}

float APS::get_channel_offset(const int & dac) const{
	return channels_[dac].get_offset();
}

int APS::set_channel_scale(const int & dac, const float & scale){
	channels_[dac].set_scale(scale);
	if (!channels_[dac].waveform_.empty()){
		write_waveform(dac, channels_[dac].prep_waveform());
	}
	return 0;
}

float APS::get_channel_scale(const int & dac) const{
	return channels_[dac].get_scale();
}

int APS::set_channel_trigDelay(const int & dac, const USHORT & delay){
/* set_trigDelay
* Write the trigger delay register for the associated channel
* delay - unsigned 16-bit value (0, 65535) representing the trigger delay in units of FPGA clock cycles
*         ie., delay of 1 is 3.333 ns at full sampling rate.
*/
ULONG trigDelayRegisterAddr;

FPGASELECT fpga = dac2fpga(dac);
if (fpga == INVALID_FPGA) {
	return -1;
}

switch (dac) {
	case 0:
	case 2:
		trigDelayRegisterAddr = FPGA_OFF_CHA_TRIG_DELAY;
		break;
	case 1:
	case 3:
		trigDelayRegisterAddr = FPGA_OFF_CHB_TRIG_DELAY;
		break;
	default:
		return -2;
}

FILE_LOG(logINFO) << "Setting trigger delay for channel " << dac << " to " << delay;

FPGA::write_FPGA(handle_, FPGA_ADDR_REGWRITE | trigDelayRegisterAddr, delay, fpga);
channels_[dac].trigDelay_ = delay;
return 0;
}

unsigned short APS::get_channel_trigDelay(const int & dac){
/* APS_ReadTriggerDelay
 * Read the trigger delay register for the associated channel
 */
	ULONG trigDelayRegisterAddr;

	FPGASELECT fpga = dac2fpga(dac);
	if (fpga == INVALID_FPGA) {
		return -1;
	}

	switch (dac) {
		case 0:
			// fall through
		case 2:
			trigDelayRegisterAddr = FPGA_OFF_CHA_TRIG_DELAY;
			break;
		case 1:
			// fall through
		case 3:
			trigDelayRegisterAddr = FPGA_OFF_CHB_TRIG_DELAY;
			break;
		default:
			return -2;
	}

	return FPGA::read_FPGA(handle_, FPGA_ADDR_REGREAD| trigDelayRegisterAddr, fpga);
}



int APS::run() {

	//Depending on how the channels are enabled, trigger the appropriate FPGA's
	vector<bool> channelsEnabled;
	bool allChannels = false;
	for (const auto tmpChannel : channels_){
		channelsEnabled.push_back(tmpChannel.enabled_);
		allChannels &= tmpChannel.enabled_;
	}

	running_ = true;

	//If we have more than two banks we need to start the thread
	if (channels_[0].banks_.size() > 2){
		bankBouncerThread_ = new thread(&APS::stream_LL_data, this);
	}


	//If all channels are enabled then trigger together
	if (allChannels) {
		trigger(ALL_FPGAS);
	}
	else if (channelsEnabled[0] || channelsEnabled[1]) {
		trigger(FPGA1);
	}
	else if (channelsEnabled[2] || channelsEnabled[3]) {
		trigger(FPGA2);
	}

	return 0;
}

int APS::stop(){
	disable(ALL_FPGAS);
	running_ = false;

	if (channels_[0].banks_.size() > 2){
		bankBouncerThread_->join();
		delete bankBouncerThread_;
	}

	return 0;

}

int APS::set_run_mode(const int & dac, const bool & mode){
/********************************************************************
 * Description : Sets run mode
 *
 * Inputs :
*              mode -  enable link list 1 = LL mode 0 = waveform mode
*
* Returns : 0 on success < 0 on failure
*
********************************************************************/
  int dacModeMask;

  auto fpga = dac2fpga(dac);
  if (fpga == INVALID_FPGA) {
    return -1;
  }

  // setup register addressing based on DAC
  switch(dac) {
    case 0:
    case 2:
      dacModeMask = CSRMSK_CHA_OUTMODE;
      break;
    case 1:
    case 3:
      dacModeMask = CSRMSK_CHB_OUTMODE;
      break;
    default:
      return -2;
  }

  //Set the run mode bit
  FILE_LOG(logINFO) << "Setting Run Mode ==> DAC: " << dac << " Mode: " << mode;
  if (mode) {
    FPGA::set_bit(handle_, fpga, FPGA_OFF_CSR, dacModeMask);
  } else {
    FPGA::clear_bit(handle_, fpga, FPGA_OFF_CSR, dacModeMask);
  }

  return 0;
}

int APS::set_repeat_mode(const int & dac, const bool & mode) {
/*
 * set_repeat_mode
 * dac - channel (0-3)
 * mode - 1 = one-shot 0 = continuous
 */
int dacModeMask;

auto fpga = dac2fpga(dac);
if (fpga == INVALID_FPGA) {
  return -1;
}

// setup register addressing based on DAC
switch(dac) {
  case 0:
  case 2:
    dacModeMask   = CSRMSK_CHA_LLMODE;
    break;
  case 1:
  case 3:
    dacModeMask   = CSRMSK_CHB_LLMODE;
    break;
  default:
    return -2;
}

//Set or clear the mode bit
FILE_LOG(logINFO) << "Setting repeat mode ==> DAC: " << dac << " Mode: " << mode;
if (mode) {
	  FPGA::set_bit(handle_, fpga, FPGA_OFF_CSR, dacModeMask);
} else {
	  FPGA::clear_bit(handle_, fpga, FPGA_OFF_CSR, dacModeMask);
}

return 0;
}


int APS::add_LL_bank(const int & dac, const vector<unsigned short> & offset, const vector<unsigned short> & count, const vector<unsigned short> & repeat, const vector<unsigned short> & trigger){

	//Update the driver storage
	channels_[dac].add_LL_bank(offset, count, repeat, trigger);

	//If it is one of the first two banks then write to device
	size_t curBank = channels_[dac].banks_.size()-1;
	if ( curBank < 2){
		write_LL_data(dac, curBank, curBank);
	}
	//Otherwise print a message so we know something has happened
	FILE_LOG(logINFO) << "Loaded LL bank into driver at bank position: " << curBank;

	return 0;
}


/*
 *
 * Private Functions
 */


int APS::write(const FPGASELECT & fpga, const ULONG & addr, const ULONG & data, const bool & queue /* see header for default */){

	//Pack the data into COMMAND - ADDRESS - DATA
	vector<UCHAR> dataPacket = FPGA::format(fpga, addr, data);

	//Update the software checksums
	//Address checksum is defined as (bits 0-14: addr, 15: 0)
	// so, set bit 15 to zero
	checksums_[fpga].address += addr & 0x7FFF;
	checksums_[fpga].data += data;

	//Push into queue or write to FPGA
	if (queue) {
		for (const UCHAR tmpByte : dataPacket){
			writeQueue_.push_back(tmpByte);
		}
	}
	else{
		FPGA::write_block(handle_, dataPacket);
	}

	return 0;
}



int APS::flush(){
	int bytesWritten = FPGA::write_block(handle_, writeQueue_);
	writeQueue_.clear();
	return bytesWritten;
}


// sets Status/CTRL register to default state when running (OSCEN enabled)
int APS::reset_status_ctrl()
{
	UCHAR WriteByte = APS_OSCEN_BIT;
	return FPGA::write_register(handle_, APS_STATUS_CTRL, 0, INVALID_FPGA, &WriteByte);
}



// clears Status/CTRL register. This is the required state to program the VCXO and PLL
int APS::clear_status_ctrl()
{
	UCHAR WriteByte = APS_OSCEN_BIT;
	return FPGA::write_register(handle_, APS_STATUS_CTRL, 0, INVALID_FPGA, &WriteByte);
}


int APS::setup_PLL()
{
	FILE_LOG(logINFO) << "Setting up PLL";

	// Disable DDRs
	int ddrMask = CSRMSK_CHA_DDR | CSRMSK_CHB_DDR;
	FPGA::clear_bit(handle_, ALL_FPGAS, FPGA_OFF_CSR, ddrMask);

	// Setup modified for 300 MHz FPGA clock rate
	//Setup of a vector of address-data pairs for all the writes we need for the PLL routine
	const vector<PLLAddrData> PLL_Routine = {
		{0x0,  0x99},  // Use SDO, Long instruction mode
		{0x10, 0x7C},  // Enable PLL , set charge pump to 4.8ma
		{0x11, 0x5},  // Set reference divider R to 5 to divide 125 MHz reference to 25 MHz
		{0x14, 0x06},  // Set B counter to 6
		{0x16, 0x5},   // Set P prescaler to 16 and enable B counter (N = P*B = 96 to divide 2400 MHz to 25 MHz)
		{0x17, 0x4},   // Selects readback of N divider on STATUS bit in Status/Control register
		{0x18, 0x60},  // Calibrate VCO with 2 divider, set lock detect count to 255, set high range
		{0x1A, 0x2D},  // Selects readback of PLL Lock status on LOCK bit in Status/Control register
		{0x1C, 0x7},   // Enable differential reference, enable REF1/REF2 power, disable reference switching
		{0xF0, 0x00},  // Enable un-inverted 400mv clock on OUT0
		{0xF1, 0x00},  // Enable un-inverted 400mv clock on OUT1
		{0xF2, 0x00},  // Enable un-inverted 400mv clock on OUT2
		{0xF3, 0x00},  // Enable un-inverted 400mv clock on OUT3
		{0xF4, 0x00},  // Enable un-inverted 400mv clock on OUT4
		{0xF5, 0x00},  // Enable un-inverted 400mv clock on OUT5
		{0x190, 0x00}, //	No division on channel 0
		{0x191, 0x80}, //	Bypass 0 divider
		{0x193, 0x11}, //	(2 high, 2 low = 1.2 GHz / 4 = 300 MHz = Reference 300 MHz)
		{0x196, 0x00}, //	No division on channel 2
		{0x197, 0x80}, //   Bypass 2 divider
		{0x1E0, 0x0}, // Set VCO post divide to 2
		{0x1E1, 0x2},  // Select VCO as clock source for VCO divider
		{0x232, 0x1},  // Set bit 0 to 1 to simultaneously update all registers with pending writes.
		{0x18, 0x71},  // Initiate Calibration.  Must be followed by Update Registers Command
		{0x232, 0x1},  // Set bit 0 to 1 to simultaneously update all registers with pending writes.
		{0x18, 0x70},  // Clear calibration flag so that next set generates 0 to 1.
		{0x232, 0x1},   // Set bit 0 to 1 to simultaneously update all registers with pending writes.
	};

//	PLL_Routine.reserve(27);


	// Go through the routine
	for (auto tmpPair : PLL_Routine){
		FPGA::write_SPI(handle_, APS_PLL_SPI, tmpPair.first, &tmpPair.second);
	}

	// enable the oscillator
	if (APS::reset_status_ctrl() != 1)
		return -1;

	// Enable DDRs
	FPGA::set_bit(handle_, ALL_FPGAS, FPGA_OFF_CSR, ddrMask);

	//Record that sampling rate has been set to 1200
	samplingRate_ = 1200;

	return 0;
}



int APS::set_PLL_freq(const FPGASELECT & fpga, const int & freq)
{

	ULONG pllCyclesAddr, pllBypassAddr;
	UCHAR pllCyclesVal, pllBypassVal;

	FILE_LOG(logDEBUG) << "Setting PLL FPGA: " << fpga << " Freq.: " << freq;

	switch(fpga) {
		case FPGA1:
			pllCyclesAddr = FPGA1_PLL_CYCLES_ADDR;
			pllBypassAddr = FPGA1_PLL_BYPASS_ADDR;
			break;
		case FPGA2:
			pllCyclesAddr = FPGA2_PLL_CYCLES_ADDR;
			pllBypassAddr = FPGA2_PLL_BYPASS_ADDR;
			break;
		default:
			return -1;
	}

	switch(freq) {
		case 40: pllCyclesVal = 0xEE; break; // 15 high / 15 low (divide by 30)
		case 50: pllCyclesVal = 0xBB; break;// 12 high / 12 low (divide by 24)
		case 100: pllCyclesVal = 0x55; break; // 6 high / 6 low (divide by 12)
		case 200: pllCyclesVal = 0x22; break; // 3 high / 3 low (divide by 6)
		case 300: pllCyclesVal = 0x11; break; // 2 high /2 low (divide by 4)
		case 600: pllCyclesVal = 0x00; break; // 1 high / 1 low (divide by 2)
		case 1200: pllCyclesVal = 0x00; break; // value ignored, set bypass below
		default:
			return -2;
	}

	// bypass divider if freq == 1200
	pllBypassVal = (freq==1200) ?  0x80 : 0x00;
	FILE_LOG(logDEBUG2) << "Setting PLL cycles addr: " << myhex << pllCyclesAddr << " val: " << int(pllCyclesVal);
	FILE_LOG(logDEBUG2) << "Setting PLL bypass addr: " << myhex << pllBypassAddr << " val: " << int(pllBypassVal);


	// Disable DDRs
	int ddr_mask = CSRMSK_CHA_DDR | CSRMSK_CHB_DDR;
	FPGA::clear_bit(handle_, fpga, FPGA_OFF_CSR, ddr_mask);

	// Disable oscillator by clearing APS_STATUS_CTRL register
	if (APS::clear_status_ctrl() != 1) return -4;

	//Setup of a vector of address-data pairs for all the writes we need for the PLL routine
	const vector<PLLAddrData> PLL_Routine = {
		{pllCyclesAddr, pllCyclesVal},
		{pllBypassAddr, pllBypassVal},
		{0x18, 0x71}, // Initiate Calibration.  Must be followed by Update Registers Command
		{0x232, 0x1}, // Set bit 0 to 1 to simultaneously update all registers with pending writes.
		{0x18, 0x70}, // Clear calibration flag so that next set generates 0 to 1.
		{0x232, 0x1} // Set bit 0 to 1 to simultaneously update all registers with pending writes.
	};
	// Go through the routine
	for (auto tmpPair : PLL_Routine){
		FPGA::write_SPI(handle_, APS_PLL_SPI, tmpPair.first, &tmpPair.second);
	}

	// Enable Oscillator
	if (APS::reset_status_ctrl() != 1) return -4;

	// Enable DDRs
	FPGA::set_bit(handle_, fpga, FPGA_OFF_CSR, ddr_mask);

	return 0;
}



int APS::test_PLL_sync(const FPGASELECT & fpga, const int & numRetries /* see header for default */) {
	/*
		APS_TestPllSync synchronized the phases of the DAC clocks with the following procedure:
		1) Make sure all PLLs have locked.
		2) Test for sync of 600 MHz clocks from DACs. They must be in sync with each other
	    and in sync with the 300 MHz reference. If they are out of sync with each other,
		  the 300 MHz DDR PLLs in the FPGA will come up 90 or 270 degrees out of phase.
		  This has a test signature of the global XOR bit set roughly half the time. If they
	    are in sync but out of phase with the reference, then both DDR PLLs will be 90/270
	    degrees out of phase with the reference (it is sufficient to test only one DDR PLL)
			- If either of these conditions exist, disable and re-enable the PLL output to one
	    of the DACs connected to the FPGA. Reset the FPGA PLLs, wait for lock, then loop.
		3) Test channel 0/2 PLL against reference PLL. Reset until in phase.
		4) Test channel 1/3 PLL against reference PLL. Reset until in phase.
		5) Verify that sync worked by testing 0/2 XOR 1/3 (global phase).
	 *
	 * Inputs: device
	 *         fpga (1 or 2)
	 *         numRetries - number of times to restart the test if the global sync test fails (step 5)
	 */

	// Test for DAC clock phase match
	bool inSync, globalSync;
	vector<int> xorFlagCnts(3);
	int dac02Reset, dac13Reset;

	int pllBit;
	UINT pllEnableAddr, pllEnableAddr2;
	UCHAR writeByte;

	const vector<int> PLL_XOR_TEST = {PLL_02_XOR_BIT, PLL_13_XOR_BIT,PLL_GLOBAL_XOR_BIT};
	const vector<int> PLL_LOCK_TEST = {PLL_02_LOCK_BIT, PLL_13_LOCK_BIT, REFERENCE_PLL_LOCK_BIT};
	const vector<int> PLL_RESET = {CSRMSK_CHA_PLLRST, CSRMSK_CHB_PLLRST, 0};

	UINT pllResetBit  = CSRMSK_CHA_PLLRST | CSRMSK_CHB_PLLRST;

	FILE_LOG(logINFO) << "Running channel sync on FPGA " << fpga;

	switch(fpga) {
	case FPGA1:
		pllEnableAddr = DAC0_ENABLE_ADDR;
		pllEnableAddr2 = DAC1_ENABLE_ADDR;
		break;
	case FPGA2:
		pllEnableAddr = DAC2_ENABLE_ADDR;
		pllEnableAddr2 = DAC3_ENABLE_ADDR;
		break;
	default:
		return -1;
	}

	// Disable DDRs
	int ddr_mask = CSRMSK_CHA_DDR | CSRMSK_CHB_DDR;
	FPGA::clear_bit(handle_, fpga, FPGA_OFF_CSR, ddr_mask);

	//A little helper function to wait for the PLL's to lock and reset if necessary
	auto wait_PLL_relock = [this, &fpga, &pllResetBit](bool resetPLL, const int & regAddress, const vector<int> & pllBits) -> bool {
		bool inSync = false;
		int testct = 0;
		while (!inSync && (testct < 20)){
			inSync = (APS::read_PLL_status(fpga, regAddress, pllBits) == 0) ? true : false;
			//If we aren't locked then reset for the next try by clearing the PLL reset bits
			if (resetPLL) {
				FPGA::clear_bit(handle_, fpga, FPGA_PLL_RESET_ADDR, pllResetBit);
			}
			//Otherwise just wait
			else{
				usleep(1000);
			}
			testct++;
		}
		return inSync;
	};

	// Step 1: test for the PLL's being locked to the reference
	inSync = wait_PLL_relock(true, FPGA_ADDR_REGREAD | FPGA_OFF_VERSION, PLL_LOCK_TEST);
	if (!inSync) {
		FILE_LOG(logERROR) << "Reference PLL failed to lock";
		return -5;
	}

	inSync = false; globalSync = false;


	//Step 2:
	// start by testing for a global or channel XOR count near 50%, which indicates
	// that DAC 600 MHz clocks have come up out of phase.

	//First a little helper function to update the PLL registers
	auto update_PLL_register = [this] (){
		ULONG address = 0x232;
		UCHAR data = 0x1;
		FPGA::write_SPI(handle_, APS_PLL_SPI, address, &data);
	};

	FILE_LOG(logINFO) << "Testing for DAC clock phase sync";
	//Loop over number of tries
	static const int xorCounts = 20, lowCutoff = 5, highCutoff = 15;
	for (int ct = 0; ct < MAX_PHASE_TEST_CNT; ct++) {
		//Reset the counts
		xorFlagCnts.assign(3,0);
		dac02Reset = 0;
		dac13Reset = 0;

		//Take twenty counts of the the xor data
		for(int xorct = 0; xorct < xorCounts; xorct++) {
			//TODO: fix up the hardcoded ugly stuff and maybe integrate with read_PLL_status
			pllBit = FPGA::read_FPGA(handle_, FPGA_ADDR_SYNC_REGREAD | FPGA_OFF_VERSION, fpga);
			if ((pllBit & 0x1ff) != 2*FIRMWARE_VERSION) {
				FILE_LOG(logERROR) << "Reg 0xF006 bitfile version does not match. Read " << std::hex << (pllBit & 0x1ff);
				return -6;
			}
			xorFlagCnts[0] += (pllBit >> PLL_GLOBAL_XOR_BIT) & 0x1;
			xorFlagCnts[1] += (pllBit >> PLL_02_XOR_BIT) & 0x1;
			xorFlagCnts[2] += (pllBit >> PLL_13_XOR_BIT) & 0x1;
		}

		// due to clock skews, need to accept a range of counts as "0" and "1"
		if ( (xorFlagCnts[0] < lowCutoff || xorFlagCnts[0] > highCutoff) &&
				(xorFlagCnts[1] < lowCutoff || xorFlagCnts[1] > highCutoff) &&
				(xorFlagCnts[2] < lowCutoff || xorFlagCnts[2] > highCutoff) ) {
			// 300 MHz clocks on FPGA are either 0 or 180 degrees out of phase, so 600 MHz clocks
			// from DAC must be in phase. Move on.
			FILE_LOG(logDEBUG1) << "DAC clocks in phase with reference, XOR counts : " << xorFlagCnts[0] << ", " << xorFlagCnts[1] << ", " << xorFlagCnts[2];
			//Get out of MAX_PHAST_TEST ct loop
			break;
		}
		else {
			// 600 MHz clocks out of phase, reset DAC clocks that are 90/270 degrees out of phase with reference
			FILE_LOG(logDEBUG1) << "DAC clocks out of phase; resetting, XOR counts: " << xorFlagCnts[0] << ", " << xorFlagCnts[1] << ", " << xorFlagCnts[2];
			writeByte = 0x2; //disable clock outputs
			//If the 02 XOR Bit is coming up at half-count then reset it
			if (xorFlagCnts[1] >= lowCutoff || xorFlagCnts[1] <= highCutoff) {
				dac02Reset = 1;
				FPGA::write_SPI(handle_, APS_PLL_SPI, pllEnableAddr, &writeByte);
			}
			//If the 02 XOR Bit is coming up at half-count then reset it
			if (xorFlagCnts[2] >= lowCutoff || xorFlagCnts[2] <= highCutoff) {
				dac13Reset = 1;
				FPGA::write_SPI(handle_, APS_PLL_SPI, pllEnableAddr2, &writeByte);
			}
			//Actually update things
			update_PLL_register();
			writeByte = 0x0; // enable clock outputs
			if (dac02Reset)
				FPGA::write_SPI(handle_, APS_PLL_SPI, pllEnableAddr, &writeByte);
			if (dac13Reset)
				FPGA::write_SPI(handle_, APS_PLL_SPI, pllEnableAddr2, &writeByte);
			update_PLL_register();

			// reset FPGA PLLs
			FPGA::set_bit(handle_, fpga, FPGA_PLL_RESET_ADDR, pllResetBit);
			FPGA::clear_bit(handle_, fpga, FPGA_PLL_RESET_ADDR, pllResetBit);

			// wait for the PLL to relock
			inSync = wait_PLL_relock(false, FPGA_ADDR_REGREAD | FPGA_OFF_VERSION, PLL_LOCK_TEST);
			if (!inSync) {
				FILE_LOG(logERROR) << "PLLs did not re-sync after reset";
				return -7;
			}
		}
	}

	//Steps 3,4,5
	const vector<string> pllStrs = {"02", "13", "Global"};
	for (int pll = 0; pll < 3; pll++) {

		FILE_LOG(logDEBUG) << "Testing channel " << pllStrs[pll];
		for (int ct = 0; ct < MAX_PHASE_TEST_CNT; ct++) {

			int xorFlagCnt = 0;

			for(int xorct = 0; xorct < xorCounts; xorct++) {
				pllBit = FPGA::read_FPGA(handle_, FPGA_ADDR_SYNC_REGREAD | FPGA_OFF_VERSION, fpga);
				if ((pllBit & 0x1ff) != 2*FIRMWARE_VERSION) {
					FILE_LOG(logERROR) << "Reg 0xF006 bitfile version does not match. Read " << std::hex << (pllBit & 0x1ff);
					return -8;
				}
				xorFlagCnt += (pllBit >> PLL_XOR_TEST[pll]) & 0x1;
			}

			// here we are just looking for in-phase or 180 degrees out of phase, so we accept a large
			// range around "0"
			if (xorFlagCnt < lowCutoff) {
				globalSync = true;
				break; // passed, move on to next channel
			}
			else {
				// PLLs out of sync, reset
				FILE_LOG(logDEBUG1) << "Channel " << pllStrs[pll] << " PLL not in sync.. resetting (XOR Count " << xorFlagCnt << " )";
				globalSync = false;

				if (pll == 2) { // global pll compare did not sync
					if (numRetries > 0) {
						FILE_LOG(logDEBUG) << "Global sync failed; retrying.";
						// restart both DAC clocks and try again
						writeByte = 0x2;
						FPGA::write_SPI(handle_, APS_PLL_SPI, pllEnableAddr, &writeByte);
						FPGA::write_SPI(handle_, APS_PLL_SPI, pllEnableAddr2, &writeByte);
						update_PLL_register();
						writeByte = 0x0;
						FPGA::write_SPI(handle_, APS_PLL_SPI, pllEnableAddr, &writeByte);
						FPGA::write_SPI(handle_, APS_PLL_SPI, pllEnableAddr2, &writeByte);
						update_PLL_register();

						//Try again by recursively calling the same function
						return APS::test_PLL_sync(fpga, numRetries - 1);
					}
					// we failed, but enable DDRs to get a usable state
					FPGA::set_bit(handle_, fpga, FPGA_OFF_CSR, ddr_mask);

					FILE_LOG(logERROR) << "Error could not sync PLLs";
					return -9;
				}

				// reset a single channel PLL
				FPGA::set_bit(handle_, fpga, FPGA_PLL_RESET_ADDR, PLL_RESET[pll]);
				FPGA::clear_bit(handle_, fpga, FPGA_PLL_RESET_ADDR, PLL_RESET[pll]);

				// wait for lock
				inSync = wait_PLL_relock(false, FPGA_ADDR_REGREAD | FPGA_OFF_VERSION, vector<int>(PLL_LOCK_TEST[pll]));
				if (!inSync) {
					FILE_LOG(logERROR) << "PLL " << pllStrs[pll] << " did not re-sync after reset";
					return -10;
				}
			}
		}
	}

	// Enable DDRs
	FPGA::set_bit(handle_, fpga, FPGA_OFF_CSR, ddr_mask);

	if (!globalSync) {
		FILE_LOG(logWARNING) << "PLLs are not in sync";
		return -11;
	}
	FILE_LOG(logINFO) << "Sync test complete";
	return 0;
}


int APS::read_PLL_status(const FPGASELECT & fpga, const int & regAddr /*check header for default*/, const vector<int> & pllLockBits  /*check header for default*/ ){
	/*
	 * Helper function to read the status of some PLL bit and whether the main PLL is locked.
	 */

	int pllStatus = 0;

	//We can latch based off either the USB or PLL clock.  USB seems to flicker so default to PLL for now but
	//we should double check the FIRMWARE_VERSION
	ULONG FIRMWARECHECK;
	if (regAddr == (FPGA_ADDR_SYNC_REGREAD | FPGA_OFF_VERSION)) {
		FIRMWARECHECK = 2*FIRMWARE_VERSION;
	}
	else if (regAddr == (FPGA_ADDR_REGREAD | FPGA_OFF_VERSION)){
		FIRMWARECHECK = FIRMWARE_VERSION;
	}
	else{
		FILE_LOG(logERROR) << "Undefined register address for PLL sync status reading.";
		return -1;
	}

//	pll_bit = FPGA::read_FPGA(handle_, FPGA_ADDR_SYNC_REGREAD | FPGA_OFF_VERSION, fpga); // latched to USB clock (has version 0x020)
//	pll_bit = FPGA::read_FPGA(handle_, FPGA_ADDR_REGREAD | FPGA_OFF_VERSION, fpga); // latched to 200 MHz PLL (has version 0x010)

	ULONG pllRegister = FPGA::read_FPGA(handle_, regAddr, fpga);

	if ((pllRegister & 0x1ff) != FIRMWARECHECK) {
		FILE_LOG(logERROR) << "Reg 0x8006 bitfile version does not match. Read: " << std::hex << (pllRegister & 0x1ff);
		return -1;
	}

	//Check each of the clocks in series
	for(int tmpBit : pllLockBits){
		pllStatus |= ((pllRegister >> tmpBit) & 0x1);
		FILE_LOG(logDEBUG2) << "FPGA " << fpga << " PLL status: " << ((pllRegister >> tmpBit) & 0x1);
	}
	return pllStatus;
}

int APS::get_PLL_freq(const FPGASELECT & fpga) const {
	// Poll APS PLL chip to determine current frequency

	ULONG pll_cycles_addr, pll_bypass_addr;
	UCHAR pll_cycles_val, pll_bypass_val;

	int freq;

	FILE_LOG(logDEBUG2) << "Getting PLL frequency for FGPA " << fpga;

	switch(fpga) {
	case FPGA1:
		pll_cycles_addr = FPGA1_PLL_CYCLES_ADDR;
		pll_bypass_addr = FPGA1_PLL_BYPASS_ADDR;
		break;
	case FPGA2:
		pll_cycles_addr = FPGA2_PLL_CYCLES_ADDR;
		pll_bypass_addr = FPGA2_PLL_BYPASS_ADDR;
		break;
	default:
		return -1;
	}

	FPGA::read_SPI(handle_, APS_PLL_SPI, pll_cycles_addr, &pll_cycles_val);
	FPGA::read_SPI(handle_, APS_PLL_SPI, pll_bypass_addr, &pll_bypass_val);

	// select frequency based on pll cycles setting
	// the values here should match the reverse lookup in FGPA::set_PLL_freq

	if (pll_bypass_val == 0x80 && pll_cycles_val == 0x00)
		return 1200;
	switch(pll_cycles_val) {
		case 0xEE: freq = 40;  break;
		case 0xBB: freq = 50;  break;
		case 0x55: freq = 100; break;
		case 0x22: freq = 200; break;
		case 0x11: freq = 300; break;
		case 0x00: freq = 600; break;
		default:
			return -2;
	}

	FILE_LOG(logDEBUG2) << "PLL frequency for FPGA: " << fpga << " Freq: " << freq;

	return freq;
}


// Write the standard VCXO setup
int APS::setup_VCXO()
{

	FILE_LOG(logINFO) << "Setting up VCX0";

	// Register 00 VCXO value, MS Byte First
	UCHAR Reg00Bytes[4] = {0x8, 0x60, 0x0, 0x4};

	// Register 01 VCXO value, MS Byte First
	UCHAR Reg01Bytes[4] = {0x64, 0x91, 0x0, 0x61};

	// ensure the oscillator is disabled before programming
	if (APS::clear_status_ctrl() != 1)
		return -1;

	FPGA::write_SPI(handle_, APS_VCXO_SPI, 0, Reg00Bytes);
	FPGA::write_SPI(handle_, APS_VCXO_SPI, 0, Reg01Bytes);

	return 0;
}

int APS::setup_DAC(const int & dac) const
/*
 * Description: Enables the data-skew monitoring and auto-calibration
 * inputs: dac = 0, 1, 2, or 3
 */
{
	BYTE data;
	BYTE SD, MSD, MHD;
	BYTE edgeMSD, edgeMHD;
	ULONG interruptAddr, controllerAddr, sdAddr, msdMhdAddr;

	// For DAC SPI writes, we put DAC select in bits 6:5 of address
	interruptAddr = 0x1 | (dac << 5);
	controllerAddr = 0x6 | (dac << 5);
	sdAddr = 0x5 | (dac << 5);
	msdMhdAddr = 0x4 | (dac << 5);

	if (dac < 0 || dac > 3) {
		FILE_LOG(logERROR) << "FPGA::setup_DAC: unknown DAC, " << dac;
		return -1;
	}
	FILE_LOG(logINFO) << "Setting up DAC " << dac;

	// Step 1: calibrate and set the LVDS controller.
	// Ensure that surveilance and auto modes are off
	// get initial states of registers
	FPGA::read_SPI(handle_, APS_DAC_SPI, interruptAddr, &data);
	FILE_LOG(logDEBUG2) <<  "Reg: " << myhex << int(interruptAddr & 0x1F) << " Val: " << int(data & 0xFF);
	FPGA::read_SPI(handle_, APS_DAC_SPI, msdMhdAddr, &data);
	FILE_LOG(logDEBUG2) <<  "Reg: " << myhex << int(msdMhdAddr & 0x1F) << " Val: " << int(data & 0xFF);
	FPGA::read_SPI(handle_, APS_DAC_SPI, sdAddr, &data);
	FILE_LOG(logDEBUG2) <<  "Reg: " << myhex << int(sdAddr & 0x1F) << " Val: " << int(data & 0xFF);
	FPGA::read_SPI(handle_, APS_DAC_SPI, controllerAddr, &data);
	FILE_LOG(logDEBUG2) <<  "Reg: " << myhex << int(controllerAddr & 0x1F) << " Val: " << int(data & 0xFF);
	data = 0;
	FPGA::write_SPI(handle_,  APS_DAC_SPI, controllerAddr, &data);

	// Slide the data valid window left (with MSD) and check for the interrupt
	SD = 0;  //(sample delay nibble, stored in Reg. 5, bits 7:4)
	MSD = 0; //(setup delay nibble, stored in Reg. 4, bits 7:4)
	MHD = 0; //(hold delay nibble,  stored in Reg. 4, bits 3:0)
	data = SD << 4;
	FPGA::write_SPI(handle_,  APS_DAC_SPI, sdAddr, &data);

	for (MSD = 0; MSD < 16; MSD++) {
		FILE_LOG(logDEBUG2) <<  "Setting MSD: " << int(MSD);
		data = (MSD << 4) | MHD;
		FPGA::write_SPI(handle_,  APS_DAC_SPI, msdMhdAddr, &data);
		FILE_LOG(logDEBUG2) <<  "Write Reg: " << myhex << int(msdMhdAddr & 0x1F) << " Val: " << int(data & 0xFF);
		//FPGA::read_SPI(handle_, APS_DAC_SPI, msd_mhd_addr, &data);
		//dlog(DEBUG_VERBOSE2, "Read reg 0x%x, value 0x%x\n", msd_mhd_addr & 0x1F, data & 0xFF);
		FPGA::read_SPI(handle_, APS_DAC_SPI, sdAddr, &data);
		FILE_LOG(logDEBUG2) <<  "Read Reg: " << myhex << int(sdAddr & 0x1F) << " Val: " << int(data & 0xFF);
		bool check = data & 1;
		FILE_LOG(logDEBUG2) << "Check: " << check;
		if (!check)
			break;
	}
	edgeMSD = MSD;
	FILE_LOG(logDEBUG) << "Found MSD: " << int(edgeMSD);

	// Clear the MSD, then slide right (with MHD)
	MSD = 0;
	for (MHD = 0; MHD < 16; MHD++) {
		FILE_LOG(logDEBUG2) <<  "Setting MHD: " << int(MHD);
		data = (MSD << 4) | MHD;
		FPGA::write_SPI(handle_,  APS_DAC_SPI, msdMhdAddr, &data);
		FPGA::read_SPI(handle_, APS_DAC_SPI, sdAddr, &data);
		FILE_LOG(logDEBUG2) << "Read: " << myhex << int(data & 0xFF);
		bool check = data & 1;
		FILE_LOG(logDEBUG2) << "Check: " << check;
		if (!check)
			break;
	}
	edgeMHD = MHD;
	FILE_LOG(logINFO) << "Found MHD = " << int(edgeMHD);
	SD = (edgeMHD - edgeMSD) / 2;
	FILE_LOG(logINFO) << "Setting SD = " << int(SD);

	// Clear MSD and MHD
	MHD = 0;
	data = (MSD << 4) | MHD;
	FPGA::write_SPI(handle_, APS_DAC_SPI, msdMhdAddr, &data);
	// Set the optimal sample delay (SD)
	data = SD << 4;
	FPGA::write_SPI(handle_, APS_DAC_SPI, sdAddr, &data);

	// AD9376 data sheet advises us to enable surveilance and auto modes, but this
	// has introduced output glitches in limited testing
	// set the filter length, threshold, and enable surveilance mode and auto mode
	/*int filter_length = 12;
	int threshold = 1;
	data = (1 << 7) | (1 << 6) | (filter_length << 2) | (threshold & 0x3);
	FPGA::write_SPI(handle_, APS_DAC_SPI, controller_addr, &data);
	*/
	return 0;
}

int APS::set_LED_mode(const FPGASELECT & fpga, const LED_MODE & mode) {
/********************************************************************
 *
 * Function Name : set_LED_mode()
 *
 * Description : Controls whether the front panel LEDs show the PLL sync
 *		status or the channel output status.
 *
 * Inputs : fpga - 1, 2, or 3
 *          mode  - 1 PLL sync, 2 channel output
 *
 * Returns : 0
 *
 ********************************************************************/
	if (fpga == INVALID_FPGA) {
		FILE_LOG(logERROR) << "set_LED_mode ERROR: invalid FPGA";
	}

	switch (mode) {
	case LED_PLL_SYNC:
		FPGA::clear_bit(handle_, fpga, FPGA_OFF_TRIGLED, TRIGLEDMSK_MODE);
		break;
	case LED_RUNNING:
		FPGA::set_bit(handle_, fpga, FPGA_OFF_TRIGLED, TRIGLEDMSK_MODE);
		break;
	default:
		FILE_LOG(logERROR) << "set_LED_mode ERROR: unknown mode " << mode;
		return -2;
	}

	return 0;
}


int APS::trigger(const FPGASELECT & fpga)
/********************************************************************
 * Description : Triggers Both DACs on FPGA at the same time.
 *
 * Inputs : fpga - fpga id
 *          trigger_type  - 1 software 2 hardware
 *
 * Returns : 0
 ********************************************************************/
{
	int dacSwTrig   = TRIGLEDMSK_CHA_SWTRIG | TRIGLEDMSK_CHB_SWTRIG;
	int dacTrigSrc  = CSRMSK_CHA_TRIGSRC | CSRMSK_CHB_TRIGSRC;
	int dacSMReset  = CSRMSK_CHA_SMRST | CSRMSK_CHB_SMRST;


//	dlog(DEBUG_VERBOSE,"FPGA%d Current CSR: 0x%x TRIGLED: 0x%x\n",
//	     fpga,
//	     APS_ReadFPGA(device, gRegRead | FPGA_OFF_CSR, fpga),
//	     APS_ReadFPGA(device, gRegRead | FPGA_OFF_TRIGLED, fpga)
//
//
//	if (fpga == 3) {
//		dlog(DEBUG_VERBOSE,"FPGA1 Current CSR: 0x%x TRIGLED: 0x%x\n",
//		     APS_ReadFPGA(device, gRegRead | FPGA_OFF_CSR, 1),
//		     APS_ReadFPGA(device, gRegRead | FPGA_OFF_TRIGLED, 1)
//		);
//		dlog(DEBUG_VERBOSE,"FPGA2 Current CSR: 0x%x TRIGLED: 0x%x\n",
//		     APS_ReadFPGA(device, gRegRead | FPGA_OFF_CSR, 2),
//		     APS_ReadFPGA(device, gRegRead | FPGA_OFF_TRIGLED, 2)
//		);
//	} else {
//		dlog(DEBUG_VERBOSE,"FPGA%d Current CSR: 0x%x TRIGLED: 0x%x\n",
//		     fpga,
//		     APS_ReadFPGA(device, gRegRead | FPGA_OFF_CSR, fpga),
//		     APS_ReadFPGA(device, gRegRead | FPGA_OFF_TRIGLED, fpga)
//		);
//	}

	if (triggerSource_ == SOFTWARE_TRIGGER) {
		FILE_LOG(logDEBUG2) << "Setting software trigger...";
		FPGA::clear_bit(handle_, fpga, FPGA_OFF_CSR, dacTrigSrc);
		FPGA::set_bit(handle_, fpga, FPGA_OFF_TRIGLED, dacSwTrig);

	} else if (triggerSource_ == HARDWARE_TRIGGER) {
		FILE_LOG(logDEBUG2) << "Setting hardware trigger...";
		FPGA::clear_bit(handle_, fpga, FPGA_OFF_TRIGLED, dacSwTrig);
		FPGA::set_bit(handle_, fpga, FPGA_OFF_CSR, dacTrigSrc);
	} else {
		FILE_LOG(logERROR) << "Invalid trigger type";
		return -1;
	}

//	if (getDebugLevel() >= DEBUG_VERBOSE) {
//		dlog(DEBUG_VERBOSE,"New CSR: 0x%x TRIGLED 0x%x\n",
//		 APS_ReadFPGA(device, gRegRead | FPGA_OFF_CSR, fpga),
//		 APS_ReadFPGA(device, gRegRead | FPGA_OFF_TRIGLED, fpga)
//	    );
//	}

	// do this last operation simultaneously, if necessary
	FPGA::clear_bit(handle_, fpga, FPGA_OFF_CSR, dacSMReset);

	return 0;
}

int APS::disable(const FPGASELECT & fpga)
/********************************************************************
 * Description : Disables both DACs on an FPGA
 *
 * Returns : 0  on success
 ********************************************************************/
{

	FILE_LOG(logINFO) << "Disable FPGA: " << fpga;

	int dacSwTrig = TRIGLEDMSK_CHA_SWTRIG | TRIGLEDMSK_CHB_SWTRIG;
	int dacSMReset = CSRMSK_CHA_SMRST | CSRMSK_CHB_SMRST;


	FPGA::clear_bit(handle_, fpga, FPGA_OFF_TRIGLED, dacSwTrig);

	FILE_LOG(logDEBUG2) << "Reset state machine for FPGA " << fpga;

	FPGA::set_bit(handle_, fpga, FPGA_OFF_CSR, dacSMReset);

	return 0;
}

int APS::reset_checksums(const FPGASELECT & fpga){
	// write to registers to clear them
	FPGA::write_FPGA(handle_, FPGA_OFF_DATA_CHECKSUM, 0, fpga);
	FPGA::write_FPGA(handle_, FPGA_OFF_ADDR_CHECKSUM, 0, fpga);
	//Reset the software side too
	checksums_[fpga].address = 0;
	checksums_[fpga].data = 0;
	return 0;
}

bool APS::verify_checksums(const FPGASELECT & fpga){
	//Checks that software and hardware checksums agree

	ULONG checksumDataFPGA, checksumAddrFPGA;
	if (fpga == ALL_FPGAS) {
		FILE_LOG(logERROR) << "Can only check the checksum of one fpga at a time.";
		return false;
	}

	checksumAddrFPGA = FPGA::read_FPGA(handle_, FPGA_ADDR_REGREAD | FPGA_OFF_ADDR_CHECKSUM, fpga);
	checksumDataFPGA = FPGA::read_FPGA(handle_, FPGA_ADDR_REGREAD | FPGA_OFF_DATA_CHECKSUM, fpga);

	FILE_LOG(logINFO) << "Checksum Address (hardware =? software): " << myhex << checksumAddrFPGA << " =? "
			<< checksums_[fpga].address << " Data: " << checksumDataFPGA << " =? "
			<< checksums_[fpga].data;

	return ((checksumAddrFPGA == checksums_[fpga].address) && (checksumDataFPGA == checksums_[fpga].data));
}

int APS::set_offset_register(const int & dac, const float & offset) {
/* APS_SetChannelOffset
 * Write the zero register for the associated channel
 * offset - offset in normalized full range (-1, 1)
 */

ULONG zeroRegisterAddr;
WORD scaledOffset;

FPGASELECT fpga = dac2fpga(dac);
if (fpga == INVALID_FPGA) {
	return -1;
}

switch (dac) {
	case 0:
	case 2:
		zeroRegisterAddr = FPGA_OFF_CHA_ZERO;
		break;
	case 1:
		// fall through
	case 3:
		zeroRegisterAddr = FPGA_OFF_CHB_ZERO;
		break;
	default:
		return -2;
}

scaledOffset = WORD(offset * MAX_WF_VALUE);
FILE_LOG(logINFO) << "Setting DAC " << dac << "  zero register to " << scaledOffset;

FPGA::write_FPGA(handle_, FPGA_ADDR_REGWRITE | zeroRegisterAddr, scaledOffset, fpga);

return 0;
}

//Write waveform data FPGA memory
int APS::write_waveform(const int & dac, const vector<short> & wfData) {

	ULONG tmpData, wfLength;
	int offsetReg, sizeReg, startAddr;
	//We assume the Channel object has properly formated the waveform
	// setup register addressing based on DAC
	switch(dac) {
		case 0:
		case 2:
			offsetReg = FPGA_OFF_CHA_OFF;
			sizeReg   = FPGA_OFF_CHA_SIZE;
			startAddr =  FPGA_ADDR_CHA_WRITE;
			break;
		case 1:
		case 3:
			offsetReg = FPGA_OFF_CHB_OFF;
			sizeReg   = FPGA_OFF_CHB_SIZE;
			startAddr =  FPGA_ADDR_CHB_WRITE;
			break;
		default:
			return -2;
	}

	//Waveform length used by FPGA must be an integer multiple of WF_MODULUS and is 0 counted
	wfLength = wfData.size() / WF_MODULUS - 1;

	auto fpga = dac2fpga(dac);
	if (fpga == INVALID_FPGA) {
		return -1;
	}

	FILE_LOG(logDEBUG) << "Loading Waveform length " << wfData.size() << " (FPGA count = " << wfLength << " ) into FPGA  " << fpga << " DAC " << dac;

	//Write the waveform parameters
	//TODO: handle arbitrary offsets
	FPGA::write_FPGA(handle_, FPGA_ADDR_REGWRITE | offsetReg, 0, fpga);
	FPGA::write_FPGA(handle_, FPGA_ADDR_REGWRITE | sizeReg, wfLength, fpga);

	if (FILELog::ReportingLevel() >= logDEBUG2) {
		//Double check it took
		tmpData = FPGA::read_FPGA(handle_, FPGA_ADDR_REGREAD | offsetReg, fpga);
		FILE_LOG(logDEBUG2) << "Offset set to: " << myhex << tmpData;
		tmpData = FPGA::read_FPGA(handle_, FPGA_ADDR_REGREAD | sizeReg, fpga);
		FILE_LOG(logDEBUG2) << "Size set to: " << tmpData;
		FILE_LOG(logDEBUG2) << "Loading waveform at " << myhex << startAddr;
	}

	//Reset the checksums
	reset_checksums(fpga);

	//Format the data and add to write queue
	write(fpga, startAddr, wfData, true);
	flush();

	//Verify the checksums
	if (!verify_checksums(fpga)){
		FILE_LOG(logERROR) << "Checksums didn't match after writing waveform data";
		return -2;
	}

	return 0;
}



int APS::write_LL_data(const int & dac, const int & bankNum, const int & targetBank){

int startAddr;
int sizeReg;

FPGASELECT fpga = dac2fpga(dac);
if (fpga == INVALID_FPGA) {
	return -1;
}

// setup register addressing based on DAC
switch(dac) {
	case 0:
	case 2:
		if (targetBank == 0) {
			startAddr = FPGA_ADDR_CHA_LL_A_WRITE;
			sizeReg = FPGA_OFF_CHA_LL_A_CTRL;
		} else {
			startAddr = FPGA_ADDR_CHA_LL_B_WRITE;
			sizeReg = FPGA_OFF_CHA_LL_B_CTRL;
		}
		break;
	case 1:
		// fall through
	case 3:
		if (targetBank == 0) {
			startAddr    = FPGA_ADDR_CHB_LL_A_WRITE;
			sizeReg = FPGA_OFF_CHB_LL_A_CTRL;
		} else {
			startAddr = FPGA_ADDR_CHB_LL_B_WRITE;
			sizeReg = FPGA_OFF_CHB_LL_B_CTRL;
		}
		break;
	default:
		return -2;
}

size_t bankLength = channels_[dac].banks_[bankNum].length;

if ( int(bankLength) > MAX_LL_LENGTH)  {
	return -3;
}
FILE_LOG(logINFO) << "Loading LinkList length " << bankLength << " into DAC " << dac << " bank " << bankNum << " targetBank " << targetBank;

//Set the link list size
int lastElementOffset = (targetBank==0) ? (bankLength-1) : (bankLength-1) + MAX_LL_LENGTH ;

FILE_LOG(logDEBUG2) << "Writing Link List Control Reg: " << myhex << sizeReg << " = " << lastElementOffset;

// clear checksums
reset_checksums(fpga);

// write control reg
write(fpga, sizeReg, lastElementOffset, true);

//Write the LL data and flush to device
write(fpga, startAddr, channels_[dac].banks_[bankNum].get_packed_data(), true);
flush();

// verify the checksum
if (!verify_checksums(fpga)){
	FILE_LOG(logERROR) << "Checksums didn't match after writing LL data";
	return -2;
}

return 0;

}

int APS::read_LL_status(const int & dac){

	int linklistStatusMask;

	int val;
	int status;

	FPGASELECT fpga = dac2fpga(dac);
	if (fpga == INVALID_FPGA) {
		return -1;
	}

	// setup register addressing based on DAC
	switch(dac) {
		case 0:
		case 2:
			linklistStatusMask  = CSRMSK_CHA_LLSTATUS;
			break;
		case 1:
		case 3:
			linklistStatusMask  = CSRMSK_CHB_LLSTATUS;
			break;
		default:
			return -2;
	}

	// read CSR
	val = FPGA::read_FPGA(handle_, FPGA_ADDR_REGREAD | FPGA_OFF_CSR, fpga);
	status = (val & linklistStatusMask) == linklistStatusMask;

	FILE_LOG(logDEBUG2) << "CSR = " << myhex << val << "; LL Status = " << std::dec << status;

	return status;

}

int APS::stream_LL_data(){

	int currentBankID, pollBankID;

	//Banks 0 and 1 have already been loaded so the next one is 2
	int curBankNum = 2;

	//Initialize to the starting bank
	currentBankID  = 0;

	while(running_) {
		//Poll for current bank to see if bank has switched
		pollBankID = read_LL_status(0);

		FILE_LOG(logDEBUG2) << "Device ID: " << deviceID_ << " Current Bank: " << pollBankID;

		//If it isn't what we used to have then the device must have switched
		if (pollBankID != currentBankID) {
			FILE_LOG(logDEBUG) << "Bank switch detected for Device ID: " << deviceID_ << "; currentBankID = " << currentBankID << " polledBankID = " << pollBankID;
			for(int chanct=0; chanct<4; chanct++){
				write_LL_data(chanct, curBankNum % channels_[chanct].banks_.size(), currentBankID);
			}
			curBankNum++;
			currentBankID = pollBankID;

			pollBankID = read_LL_status(0);
			if (pollBankID != currentBankID) {
				FILE_LOG(logWARNING) << "Bank swapped during load of link list";
			}
		}
		std::this_thread::sleep_for( std::chrono::milliseconds(10) );
	}
	
	// reload banks 0 and 1 to get back to reset state
	for (int chanct=0; chanct<4; chanct++) {
		write_LL_data(chanct, 0, 0);
		write_LL_data(chanct, 1, 1);
	}

	return 0;
}
