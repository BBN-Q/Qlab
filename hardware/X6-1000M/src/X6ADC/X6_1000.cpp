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

    setHandler(timer_.OnElapsed, &X6_1000::HandleTimer);

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

    //  Configure Stream Event Handlers
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

    FILE_LOG(logINFO) << "Stream Connected..." << endl;

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
    IX6ClockIo::IIClockSelect x6extsrc; // external clock source
    if (frequency < 0) return INVALID_FREQUENCY;

    // Route ext clock source
    x6extsrc = (extSrc == FRONT_PANEL) ? IX6ClockIo::cslFrontPanel : IX6ClockIo::cslP16;
    module_.Clock().ExternalClkSelect(x6extsrc);

    // Route clock
    x6clksrc = (src ==  EXTERNAL) ? IX6ClockIo::csExternal : IX6ClockIo::csInternal;
    module_.Clock().Source(x6clksrc);
    module_.Clock().Frequency(frequency);

    return SUCCESS;
}

double X6_1000::get_pll_frequency() {
    return module_.Clock().FrequencyActual();
}

X6_1000::ErrorCodes X6_1000::set_ext_trigger_src(X6_1000::ExtSource extSrc) {
    IX6IoDevice::AfeExtSyncOptions syncsel;
    syncsel = (extSrc == FRONT_PANEL) ? IX6IoDevice::essFrontPanel: IX6IoDevice::essP16;
    module_.Output().Trigger().ExternalSyncSource( syncsel );
    module_.Input().Trigger().ExternalSyncSource( syncsel );
    return SUCCESS;
}

X6_1000::ErrorCodes X6_1000::set_trigger_src(TriggerSource trgSrc) {
    // cache trigger source
    triggerSource_ = trgSrc;

    FILE_LOG(logINFO) << "Trigger Source set to " << (trgSrc == EXTERNAL_TRIGGER) ? "External" : "Internal";

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
    return SUCCESS;
}

X6_1000::ErrorCodes X6_1000::set_decimation(bool enabled, int factor) {
    module_.Input().Decimation((enabled ) ? factor : 0);
    return SUCCESS;
}

int X6_1000::get_decimation() {
    return module_.Input().Decimation();
}

X6_1000::ErrorCodes X6_1000::set_frame(int recordLength, int numRecords) {
    samplesPerFrame_ = recordLength;
    numRecords_ = numRecords;

    int frameGranularity = module_.Input().Info().TriggerFrameGranularity();
    if (recordLength % frameGranularity != 0) {
        return INVALID_FRAMESIZE;
    }
    module_.Input().Trigger().FramedMode(true);
    module_.Input().Trigger().Edge(true);
    module_.Input().Trigger().FrameSize(recordLength); 
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
    set_clock();
    set_reference();
    set_ext_trigger_src();
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

    // figure out when to stop
    samplesToAcquire_ = samplesPerFrame_ * numRecords_ / get_decimation();

    int samplesPerWord = module_.Input().Info().SamplesPerWord();
    int packetSize = num_active_channels()*samplesPerFrame_/samplesPerWord/get_decimation();

    module_.Velo().LoadAll_VeloDataSize(packetSize);
    module_.Velo().ForceVeloPacketSize(true);
    
    trigger_.AtStreamStart();

    // flag must be set before calling stream start
    isRunning_ = true; 

    //  Start Streaming
    FILE_LOG(logINFO) << "Arming acquisition";
    stream_.Start();
    timer_.Enabled(true);
    
    return SUCCESS;
}

X6_1000::ErrorCodes X6_1000::stop() {
    isRunning_ = false;
    stream_.Stop();
    timer_.Enabled(false);
    trigger_.AtStreamStop();
    module_.Output().SoftwareTrigger(false);
    module_.Reset();
    return SUCCESS;
}

bool X6_1000::get_is_running() {
    return isRunning_;
}

X6_1000::ErrorCodes X6_1000::transfer_waveform(int channel, short *buffer, size_t length) {
    // memcpy(buffer, &chData_[channel][0], sizeof(short)*std::min(length, chData_[channel].size()));
    size_t count = std::min(length, chData_[channel].size());
    std::copy(chData_[channel].begin(), chData_[channel].begin() + count, buffer);
    return SUCCESS;
}

/****************************************************************************
 * Event Handlers 
 ****************************************************************************/

 void  X6_1000::HandleDisableTrigger(OpenWire::NotifyEvent & /*Event*/) {
    FILE_LOG(logINFO) << "X6_1000::HandleDisableTrigger";
}


void  X6_1000::HandleExternalTrigger(OpenWire::NotifyEvent & /*Event*/) {
    FILE_LOG(logINFO) << "X6_1000::HandleExternalTrigger";
}


void  X6_1000::HandleSoftwareTrigger(OpenWire::NotifyEvent & /*Event*/) {
    FILE_LOG(logINFO) << "X6_1000::HandleSoftwareTrigger";
}

void X6_1000::HandleBeforeStreamStart(OpenWire::NotifyEvent & /*Event*/) {
    FILE_LOG(logINFO) << "X6_1000::HandleBeforeStreamStart";
}

void X6_1000::HandleAfterStreamStart(OpenWire::NotifyEvent & /*Event*/) {
    FILE_LOG(logINFO) << "X6_1000::HandleAfterStreamStart";
    timer_.Enabled(true);
}

void X6_1000::HandleAfterStreamStop(OpenWire::NotifyEvent & /*Event*/) {
    FILE_LOG(logINFO) << "X6_1000::HandleAfterStreamStop";
    // Disable external triggering initially
    module_.Input().SoftwareTrigger(false);
    module_.Input().Trigger().External(false);
}

void X6_1000::HandleDataAvailable(Innovative::VitaPacketStreamDataEvent & Event) {
    if (!isRunning_) return;

    // create a buffer to receive the data
    VeloBuffer buffer;
    Event.Sender->Recv(buffer);

    PacketBufferHeader header(buffer);
    int channel = header.PeripheralId();

    // interpret the data as integers
    IntegerDG bufferDG(buffer);

    // then we had better put that data somewhere...
    for (int i = 0; i < bufferDG.size(); i++) {
        chData_[channel].push_back(bufferDG[i]);
    }

    // if we've acquired the requested number of samples, stop streaming
    if (chData_.size() > samplesToAcquire_) stop();
}

void X6_1000::HandleTimer(OpenWire::NotifyEvent & /*Event*/) {
    FILE_LOG(logINFO) << "X6_1000::HandleTimer";
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
    LogHandler("HandleTriggerAlert");
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

