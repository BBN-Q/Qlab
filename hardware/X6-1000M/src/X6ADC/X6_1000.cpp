#include "X6_1000.h"

#include <IppMemoryUtils_Mb.h>  // for Init::UsePerformanceMemoryFunctions
#include <BufferDatagrams_Mb.h> // for ShortDG
#include <algorithm>            // std::max
#include <cstdlib>              // for rand

using namespace Innovative;

// constructor
X6_1000::X6_1000() :
    isOpened_(false), isRunning_(false) {
    numBoards_ = getBoardCount();

    for(int cnt = 0; cnt < get_num_channels(); cnt++) {
        activeChannels_[cnt] = true;
        chData_[cnt].clear(); // initalize vector
    }

    // Use IPP performance memory functions.    
    Init::UsePerformanceMemoryFunctions();
}

X6_1000::~X6_1000() {
	if (isOpened_) close();   
}

unsigned int X6_1000::get_num_channels() {
    return module_.Input().Channels();
}

unsigned int  X6_1000::getBoardCount() {
    static Innovative::X6_1000M  x6;
    return static_cast<unsigned int>(x6.BoardCount());
}

void X6_1000::setHandler(OpenWire::EventHandler<OpenWire::NotifyEvent> & event, 
    void (X6_1000:: *CallBackFunction)(OpenWire::NotifyEvent & Event)) {

    event.SetEvent(this, CallBackFunction );
    event.Unsynchronize();
}


X6_1000::ErrorCodes X6_1000::open(int deviceID) {
    /* Connects to the II module with the given device ID returns MODULE_ERROR
     * if the device cannot be found
     */

    if (deviceID > numBoards_ || isOpened_) return MODULE_ERROR;

    // Timer event handlers
    setHandler(timer_.OnElapsed, &X6_1000::HandleTimer);

    // Trigger event handlers
    trigger_.OnDisableTrigger.SetEvent(this, &X6_1000::HandleDisableTrigger);
    trigger_.OnExternalTrigger.SetEvent(this, &X6_1000::HandleExternalTrigger);
    trigger_.OnSoftwareTrigger.SetEvent(this, &X6_1000::HandleSoftwareTrigger);

    // Module event handlers
    setHandler(module_.OnBeforeStreamStart, &X6_1000::HandleBeforeStreamStart);
    setHandler(module_.OnAfterStreamStart, &X6_1000::HandleAfterStreamStart);
    setHandler(module_.OnAfterStreamStop, &X6_1000::HandleAfterStreamStop);

    // General alerts
    module_.Alerts().OnSoftwareAlert.SetEvent(      this, &X6_1000::HandleSoftwareAlert);
    module_.Alerts().OnWarningTemperature.SetEvent( this, &X6_1000::HandleWarningTempAlert);
    module_.Alerts().OnTrigger.SetEvent(            this, &X6_1000::HandleTriggerAlert);
    // Input alerts
    module_.Alerts().OnInputOverflow.SetEvent(      this, &X6_1000::HandleInputFifoOverrunAlert);
    module_.Alerts().OnInputOverrange.SetEvent(     this, &X6_1000::HandleInputOverrangeAlert);

    // Stream Event Handlers
    stream_.DirectDataMode(false);
    stream_.OnVeloDataAvailable.SetEvent(this, &X6_1000::HandleDataAvailable);

    stream_.RxLoadBalancing(false);
    stream_.TxLoadBalancing(false);


    // Insure BM size is a multiple of four MB
    const int RxBmSize = std::max(BusmasterSize/4, 1) * 4;
    const int TxBmSize = std::max(BusmasterSize/4, 1) * 4;
    module_.IncomingBusMasterSize(RxBmSize * Meg);
    module_.OutgoingBusMasterSize(TxBmSize * Meg);
    module_.Target(deviceID);

    try {
        module_.Open();
        FILE_LOG(logINFO) << "Opened Device " << deviceID;
        FILE_LOG(logINFO) << "Bus master size: Input => " << RxBmSize << " MB" << " Output => " << TxBmSize << " MB";
    }
    catch(...) {
        FILE_LOG(logINFO) << "Module Device Open Failure!";
        return MODULE_ERROR;
    }
        
    module_.Reset();
    FILE_LOG(logINFO) << "Module Device Opened Successfully...";
    
    isOpened_ = true;

    log_card_info();

    set_defaults();
    
    //  Connect Stream
    stream_.ConnectTo(&module_);
    FILE_LOG(logINFO) << "Stream Connected...";

    prefillPacketCount_ = stream_.PrefillPacketCount();
    FILE_LOG(logDEBUG) << "Stream prefill packet count: " << prefillPacketCount_;

    //  Initialize VeloMergeParse with stream IDs
    VMP_.OnDataAvailable.SetEvent(this, &X6_1000::VMPDataAvailable);
    std::vector<int> streamIDs = {static_cast<int>(module_.VitaIn().VitaStreamId(0)), static_cast<int>(module_.VitaIn().VitaStreamId(1))};
    VMP_.Init(streamIDs);
    FILE_LOG(logDEBUG) << "ADC Stream IDs: " << myhex << streamIDs[0] << ", " << myhex << streamIDs[1];
    // streamIDs = {0xffff};
    // VMP_.Init(streamIDs);

    return SUCCESS;
  }

 
X6_1000::ErrorCodes X6_1000::close() {
    stream_.Disconnect();
    module_.Close();

    isOpened_ = false;

	return SUCCESS;
}

int X6_1000::read_firmware_version(int & version, int & subrevision) {
    version = module_.Info().FpgaLogicVersion();
    subrevision = module_.Info().FpgaLogicSubrevision();

    return SUCCESS;
}

float X6_1000::get_logic_temperature() {
    return static_cast<float>(module_.Thermal().LogicTemperature());
}

float X6_1000::get_logic_temperature_by_reg() {
    Innovative::AddressingSpace & logicMemory = Innovative::LogicMemorySpace(module_);
    const unsigned int wbTemp_offset = 0x200;    
    const unsigned int tempControl_offset = 0;
    Innovative::WishboneBusSpace wbs = Innovative::WishboneBusSpace(logicMemory, wbTemp_offset);
    Innovative::Register reg = Innovative::Register(wbs, tempControl_offset );
    Innovative::RegisterBitGroup Temperature = Innovative::RegisterBitGroup(reg, 8, 8);

    return static_cast<float>(Temperature.Value());
}

X6_1000::ErrorCodes X6_1000::set_routes() {
    // Route external clock source from front panel (other option is cslP16)
    module_.Clock().ExternalClkSelect(IX6ClockIo::cslFrontPanel);

    // route external sync source from front panel (other option is essP16)
    module_.Output().Trigger().ExternalSyncSource( IX6IoDevice::essFrontPanel );
    module_.Input().Trigger().ExternalSyncSource( IX6IoDevice::essFrontPanel );

    return SUCCESS;
}

X6_1000::ErrorCodes X6_1000::set_reference(X6_1000::ExtInt ref, float frequency) {
    IX6ClockIo::IIReferenceSource x6ref; // reference source
    if (frequency < 0) return INVALID_FREQUENCY;

    x6ref = (ref == EXTERNAL) ? IX6ClockIo::rsExternal : IX6ClockIo::rsInternal;

    module_.Clock().Reference(x6ref);
    module_.Clock().ReferenceFrequency(frequency);
    return SUCCESS;
}

X6_1000::ErrorCodes X6_1000::set_clock(X6_1000::ExtInt src , 
                                       float frequency,
                                       ExtSource extSrc) {

    IX6ClockIo::IIClockSource x6clksrc; // clock source
    if (frequency < 0) return INVALID_FREQUENCY;

    // Route clock
    x6clksrc = (src ==  EXTERNAL) ? IX6ClockIo::csExternal : IX6ClockIo::csInternal;
    module_.Clock().Source(x6clksrc);
    module_.Clock().Frequency(frequency);

    return SUCCESS;
}

double X6_1000::get_pll_frequency() {
    return module_.Clock().FrequencyActual();
}

X6_1000::ErrorCodes X6_1000::set_trigger_src(TriggerSource trgSrc) {
    // cache trigger source
    triggerSource_ = trgSrc;

    FILE_LOG(logINFO) << "Trigger Source set to " << ((trgSrc == EXTERNAL_TRIGGER) ? "External" : "Internal");

    trigger_.ExternalTrigger( (trgSrc == EXTERNAL_TRIGGER) ? true : false);
    trigger_.AtConfigure();

    return SUCCESS;
}

X6_1000::TriggerSource X6_1000::get_trigger_src() const {
    // return cached trigger source until 
    // TODO: identify method for getting source from card
    if (triggerSource_) 
        return EXTERNAL_TRIGGER;
    else
        return SOFTWARE_TRIGGER;
}

X6_1000::ErrorCodes X6_1000::set_trigger_delay(float delay) {
    // going to require a trigger engine modification to work
    // leaving as a TODO for now
    // Something like this might work:
    // trigger_.DelayedTriggerPeriod(delay);
    return SUCCESS;
}

X6_1000::ErrorCodes X6_1000::set_decimation(bool enabled, int factor) {
    module_.Input().Decimation((enabled ) ? factor : 0);
    return SUCCESS;
}

int X6_1000::get_decimation() {
    int decimation = module_.Input().Decimation();
    return (decimation > 0) ? decimation : 1;
}

X6_1000::ErrorCodes X6_1000::set_frame(int recordLength, int numRecords) {
    FILE_LOG(logINFO) << "Setting samplesPerFrame_ = " << recordLength;
    samplesPerFrame_ = recordLength;
    numRecords_ = numRecords;

    int frameGranularity = module_.Input().Info().TriggerFrameGranularity();
    if (recordLength % frameGranularity != 0) {
        FILE_LOG(logERROR) << "Invalid frame size: " << recordLength;
        return INVALID_FRAMESIZE;
    }
    module_.Input().Trigger().FramedMode(true);
    module_.Input().Trigger().Edge(true);
    module_.Input().Trigger().FrameSize(recordLength);

    // (some of?) the following seems to be necessary to get external triggering to work
    module_.Input().Pulse().Reset();
    module_.Input().Pulse().Enabled(false);
}

X6_1000::ErrorCodes X6_1000::set_channel_enable(int channel, bool enabled) {
    if (channel >= get_num_channels()) return INVALID_CHANNEL;
    FILE_LOG(logINFO) << "Set Channel " << channel << " Enable = " << enabled;
    activeChannels_[channel] = enabled;
    return SUCCESS;
}

bool X6_1000::get_channel_enable(int channel) {
    // TODO get active channel status from board
    if (channel >= get_num_channels()) return false;
    else return activeChannels_[channel];
}

X6_1000::ErrorCodes X6_1000::set_active_channels() {
    ErrorCodes status = SUCCESS;

    module_.Output().ChannelDisableAll();
    module_.Input().ChannelDisableAll();

    for (int cnt = 0; cnt < get_num_channels(); cnt++) { 
        FILE_LOG(logINFO) << "Channel " << cnt << " Enable = " << activeChannels_[cnt];
        module_.Input().ChannelEnabled(cnt, activeChannels_[cnt]);
    }
    return status;
}

int X6_1000::num_active_channels() {
    int numActiveChannels = 0;
    for (int i = 0; i < activeChannels_.size(); i++) {
        numActiveChannels += activeChannels_[i] == true ? 1 : 0;
    }

    return numActiveChannels;
}

void X6_1000::set_defaults() {
    set_routes();
    set_reference();
    set_clock();
    set_trigger_src();
    set_decimation();
    set_active_channels();

    // disable test mode 
    module_.Input().TestModeEnabled( false, 0);
    module_.Output().TestModeEnabled( false, 0);
}

void X6_1000::log_card_info() {

    FILE_LOG(logINFO) << std::hex << "Logic Version: " << module_.Info().FpgaLogicVersion()
        << ", Hdw Variant: " << module_.Info().FpgaHardwareVariant()
        << ", Revision: " << module_.Info().PciLogicRevision()
        << ", Subrevision: " << module_.Info().FpgaLogicSubrevision();

    FILE_LOG(logINFO)  << std::hex << "Board Family: " << module_.Info().PciLogicFamily()
        << ", Type: " << module_.Info().PciLogicType()
        << ", Board Revision: " << module_.Info().PciLogicPcb()
        << ", Chip: " << module_.Info().FpgaChipType();

    FILE_LOG(logINFO)  << "PCI Express Lanes: " << module_.Debug()->LaneCount();
}

X6_1000::ErrorCodes X6_1000::acquire() {
    set_active_channels();
    // should only need to call this once, but for now we call it every time
    stream_.Preconfigure();

    // figure out when to stop
    samplesToAcquire_ = num_active_channels() * samplesPerFrame_ * numRecords_ / get_decimation();
    FILE_LOG(logDEBUG) << "samplesToAcquire = " << samplesToAcquire_;
    samplesAcquired_ = 0;

    int samplesPerWord = module_.Input().Info().SamplesPerWord();
    FILE_LOG(logDEBUG) << "samplesPerWord = " << samplesPerWord;
    // pad packets by 8 extra words per channel (VITA packets have 7 word header, 1 word trailer)
    int packetSize = num_active_channels()*( samplesPerFrame_/samplesPerWord/get_decimation() + 8);
    FILE_LOG(logDEBUG) << "packetSize = " << packetSize;

    module_.Velo().LoadAll_VeloDataSize(packetSize);
    module_.Velo().ForceVeloPacketSize(true);

    // clear VMP and channel buffers
    FILE_LOG(logDEBUG) << "Setting VMP buffer size = " << samplesPerFrame_ / samplesPerWord / get_decimation();
    VMP_.Resize(samplesPerFrame_ / samplesPerWord / get_decimation());
    VMP_.Clear();
    for(int cnt = 0; cnt < get_num_channels(); cnt++) chData_[cnt].clear();

    // is this necessary??
    stream_.PrefillPacketCount(prefillPacketCount_);
    
    trigger_.AtStreamStart();

    // flag must be set before calling stream start
    isRunning_ = true; 

    //  Start Streaming
    FILE_LOG(logINFO) << "Arming acquisition";
    stream_.Start();
    
    return SUCCESS;
}

X6_1000::ErrorCodes X6_1000::stop() {
    isRunning_ = false;
    stream_.Stop();
    timer_.Enabled(false);
    trigger_.AtStreamStop();
    return SUCCESS;
}

bool X6_1000::get_is_running() {
    return isRunning_;
}

X6_1000::ErrorCodes X6_1000::transfer_waveform(int channel, short *buffer, size_t length) {
    size_t count = std::min(length, chData_[channel].size());
    std::copy(chData_[channel].begin(), chData_[channel].begin() + count, buffer);
    return SUCCESS;
}

/****************************************************************************
 * Event Handlers 
 ****************************************************************************/

 void  X6_1000::HandleDisableTrigger(OpenWire::NotifyEvent & /*Event*/) {
    FILE_LOG(logDEBUG) << "X6_1000::HandleDisableTrigger";
    module_.Input().Trigger().External(false);
    module_.Output().Trigger().External(false);
}


void  X6_1000::HandleExternalTrigger(OpenWire::NotifyEvent & /*Event*/) {
    FILE_LOG(logDEBUG) << "X6_1000::HandleExternalTrigger";
    module_.Input().Trigger().External(true);
    // module_.Input().Trigger().External( (triggerSource_ == EXTERNAL_TRIGGER) ? true : false );
}


void  X6_1000::HandleSoftwareTrigger(OpenWire::NotifyEvent & /*Event*/) {
    FILE_LOG(logDEBUG) << "X6_1000::HandleSoftwareTrigger";
}

void X6_1000::HandleBeforeStreamStart(OpenWire::NotifyEvent & /*Event*/) {
}

void X6_1000::HandleAfterStreamStart(OpenWire::NotifyEvent & /*Event*/) {
    FILE_LOG(logINFO) << "Analog I/O started";
    timer_.Enabled(true);
}

void X6_1000::HandleAfterStreamStop(OpenWire::NotifyEvent & /*Event*/) {
    FILE_LOG(logINFO) << "Analog I/O stopped";
    // Disable external triggering initially
    module_.Input().SoftwareTrigger(false);
    module_.Input().Trigger().External(false);
    VMP_.Flush();
}

void X6_1000::HandleDataAvailable(Innovative::VitaPacketStreamDataEvent & Event) {
    FILE_LOG(logDEBUG) << "X6_1000::HandleDataAvailable";
    if (!isRunning_) return;

    // create a buffer to receive the data
    VeloBuffer buffer;
    Event.Sender->Recv(buffer);

    FILE_LOG(logDEBUG) << "buffer.size() = " << buffer.SizeInInts();

    AlignedVeloPacketExQ::Range InVelo(buffer);
    unsigned int * pos = InVelo.begin();
    VitaHeaderDatagram vh_dg(pos);
    FILE_LOG(logDEBUG) << "buffer stream ID = " << myhex << vh_dg.StreamId();

    VMP_.Append(buffer);
    VMP_.Parse();

    FILE_LOG(logDEBUG) << "samplesAcquired_ = " << samplesAcquired_;
    // if we've acquired the requested number of samples, stop streaming
    if (samplesAcquired_ >= samplesToAcquire_) stop();
}

void X6_1000::VMPDataAvailable(Innovative::VeloMergeParserDataAvailable & Event) {
    FILE_LOG(logDEBUG) << "X6_1000::VMPDataAvailable";
    // StreamID is now encoded in the PeripheralID of the VMP Vita buffer
    PacketBufferHeader header(Event.Data);
    int channel = header.PeripheralId();
    FILE_LOG(logDEBUG) << "VMP buffer channel = " << channel;

    // interpret the data as integers
    ShortDG bufferDG(Event.Data);
    FILE_LOG(logDEBUG) << "VMP buffer size = " << bufferDG.size() << " samples";
    // copy the data to the appropriate channel
    chData_[channel].insert(std::end(chData_[channel]), std::begin(bufferDG), std::end(bufferDG));

    FILE_LOG(logDEBUG) << "chData_[" << channel << "].size() = " << chData_[channel].size();

    samplesAcquired_ += bufferDG.size();
}

void X6_1000::HandleTimer(OpenWire::NotifyEvent & /*Event*/) {
    // FILE_LOG(logDEBUG) << "X6_1000::HandleTimer";
    trigger_.AtTimerTick();
}

void X6_1000::HandleSoftwareAlert(Innovative::AlertSignalEvent & event) {
    LogHandler("HandleSoftwareAlert");
}

void X6_1000::HandleWarningTempAlert(Innovative::AlertSignalEvent & event) {
    LogHandler("HandleWarningTempAlert");
}

void X6_1000::HandleInputFifoOverrunAlert(Innovative::AlertSignalEvent & event) {
    LogHandler("HandleInputFifoOverrunAlert");
}

void X6_1000::HandleInputOverrangeAlert(Innovative::AlertSignalEvent & event) {
    LogHandler("HandleInputOverrangeAlert");
}

void X6_1000::HandleTriggerAlert(Innovative::AlertSignalEvent & event) {
    std::string triggerType;
    switch (event.Argument & 0x3) {
        case 0:  triggerType = "? "; break;
        case 1:  triggerType = "Input "; break;
        case 2:  triggerType = "Output "; break;
        case 3:  triggerType = "Input and Output "; break;
    }
    std::stringstream msg;
    msg << "Trigger 0x" << std::hex << event.Argument
        << " Type: " <<  triggerType;
    FILE_LOG(logINFO) << msg.str();
}

void X6_1000::LogHandler(string handlerName) {
    FILE_LOG(logINFO) << "Alert:" << handlerName;
}

X6_1000::ErrorCodes X6_1000::write_wishbone_register(uint32_t baseAddr, uint32_t offset, uint32_t data) {
     // Initialize WishboneAddress Space for APS specific firmware
    Innovative::AddressingSpace & logicMemory = Innovative::LogicMemorySpace(const_cast<X6_1000M&>(module_));
    Innovative::WishboneBusSpace WB_X6 = Innovative::WishboneBusSpace(logicMemory, baseAddr);
    Innovative::Register reg = Register(WB_X6, offset);
    reg.Value(data);
    return SUCCESS;
}

X6_1000::ErrorCodes X6_1000::write_wishbone_register(uint32_t offset, uint32_t data) {
    return write_wishbone_register(wbX6ADC_offset, offset, data);
}

uint32_t X6_1000::read_wishbone_register(uint32_t baseAddr, uint32_t offset) const {
    Innovative::AddressingSpace & logicMemory = Innovative::LogicMemorySpace(const_cast<X6_1000M&>(module_));
    Innovative::WishboneBusSpace WB_X6 = Innovative::WishboneBusSpace(logicMemory, baseAddr);
    Innovative::Register reg = Register(WB_X6, offset);
    return reg.Value();
}

uint32_t X6_1000::read_wishbone_register(uint32_t offset) const {
    return read_wishbone_register(wbX6ADC_offset, offset);
}
