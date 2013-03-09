#include "X6_1000.h"

using namespace Innovative;

// default constructor
X6_1000::X6_1000() {
	X6_1000(0);
}

X6_1000::X6_1000(unsigned int target) {
    numBoards_ = getBoardCount();

    deviceID_ = target;

    isOpened_ = false;

    /* set active channels map */
    unsigned int numChannels = module_.Output().Channels();
    for(int cnt = 0; cnt < numChannels; cnt++)
        activeChannels_[cnt] = false;

}

X6_1000::~X6_1000()
{
	if (isOpened_) Close();   
}

X6_1000::ErrorCodes X6_1000::set_deviceID(unsigned int deviceID) {
	if (!isOpened_ && deviceID < numBoards_)
		deviceID_ = deviceID;
	else
		return MODULE_ERROR;
    return SUCCESS;
}


unsigned int  X6_1000::getBoardCount() {
	return static_cast<unsigned int>(module_.BoardCount());
}

void X6_1000::get_device_serials(vector<string> & deviceSerials) {
	deviceSerials.clear();

	int numBoards = getBoardCount();

	// TODO: Identify a way to get serial number from X6 board if possible otherwise get slot id etc
	for (int cnt = 0; cnt < numBoards; cnt++) {

		// SNAFU work around for compiler on MQCO11 reporting that to_string is not part of std
		std::stringstream out;
		out << "S" << cnt;

		deviceSerials.push_back(out.str());
	}
}

 bool X6_1000::isOpen() {
 	return isOpened_;
 }

 X6_1000::ErrorCodes X6_1000::Open() {
 	// open function based on Innovative Stream Example ApplicationIO.cpp


 	// TODO: Setup Event Handlers

 	//Trig.OnDisableTrigger.SetEvent(this, &ApplicationIo::HandleDisableTrigger);
    //Trig.OnExternalTrigger.SetEvent(this, &ApplicationIo::HandleExternalTrigger);
    //Trig.OnSoftwareTrigger.SetEvent(this, &ApplicationIo::HandleSoftwareTrigger);
    //Trig.DelayedTrigger(true); // trigger delayed after start
    
    
    //  TODO Set Module Event Handlers
    // Module().OnBeforeStreamStart.SetEvent(this, &ApplicationIo::HandleBeforeStreamStart);
    // Module().OnBeforeStreamStart.Synchronize();
    // Module().OnAfterStreamStart.SetEvent(this, &ApplicationIo::HandleAfterStreamStart);
    // Module().OnAfterStreamStart.Synchronize();
    // Module().OnAfterStreamStop.SetEvent(this, &ApplicationIo::HandleAfterStreamStop);
    // Module().OnAfterStreamStop.Synchronize();

    //
    //  Alerts
    //Module.HookAlerts();

    //
    //  Configure Stream Event Handlers
    // Stream.OnVeloDataRequired.SetEvent(this, &ApplicationIo::HandleDataRequired);
    // Stream.DirectDataMode(false);
    // Stream.OnVeloDataAvailable.SetEvent(this, &ApplicationIo::HandleDataAvailable);

    // Stream.OnAfterStop.SetEvent(this, &ApplicationIo::HandleAfterStop);
    // Stream.OnAfterStop.Synchronize();

    //Stream.RxLoadBalancing(false);
    //Stream.TxLoadBalancing(false);

    // Timer.OnElapsed.SetEvent(this, &ApplicationIo::HandleTimer);
    // Timer.OnElapsed.Thunk();

    // Insure BM size is a multiple of four MB
    const int Meg = 1024 * 1024;
    const int RxBmSize = std::max(BusmasterSize/4, 1) * 4;
    const int TxBmSize = std::max(BusmasterSize/4, 1) * 4;
    module_.IncomingBusMasterSize(RxBmSize * Meg);
    module_.OutgoingBusMasterSize(TxBmSize * Meg);
    module_.Target(deviceID_);

   try
        {

        module_.Open();
        FILE_LOG(logINFO) << "Opened Device " << deviceID_;
        FILE_LOG(logINFO) << "Bus master size: Input => " << RxBmSize << " MB" << " Output => " << TxBmSize << " MB";
        }
    //catch (Innovative::MalibuException & exception)
    //    {
    //    FILE_LOG(logINFO) << "Open Failure:" << exception.what();
    //    return MODULE_ERROR;
    //    }
    catch(...)
        {
        FILE_LOG(logINFO) << "Module Device Open Failure!";
        return MODULE_ERROR;
        }
        
    module_.Reset();
    FILE_LOG(logINFO) << "Module Device Opened Successfully...";
    isOpened_ = true;

    
    log_card_info();

    set_defaults();
    //
    //  Connect Stream
    //Stream.ConnectTo(&(Module.Ref()));
    //FStreamConnected = true;
    //FILE_LOG(logINFO) << "Stream Connected..." << endl;

    //PrefillPacketCount = Stream.PrefillPacketCount();
    
    //
    //  Initialize VeloMergeParse
    //VMP.OnDataAvailable.SetEvent(this, &ApplicationIo::VMPDataAvailable);
    //std::vector<int> sids = Module.AllInputVitaStreamIdVector();
    //VMP.Init( sids );

    //DisplayLogicVersion();
    return SUCCESS;
 }

 
X6_1000::ErrorCodes X6_1000::Close() {

    	//Stream.Disconnect();
    module_.Close();

    isOpened_ = true;

    FILE_LOG(logINFO) << "Closed X6 Board " << deviceID_;

	return SUCCESS;
}

float X6_1000::get_logic_temperature() {
    return static_cast<float>(module_.Thermal().LogicTemperature());
}

X6_1000::ErrorCodes X6_1000::set_reference(X6_1000::ExtInt ref, float frequency) {
    IX6ClockIo::IIReferenceSource x6ref; // reference source

    if (frequency < 0) return INVALID_FREQUENCY;

    x6ref = (ref == EXTERNAL) ? IX6ClockIo::rsExternal : IX6ClockIo::rsInternal;

    module_.Clock().Reference(x6ref);
    module_.Clock().ReferenceFrequency(frequency * MHz);
    return SUCCESS;
}

X6_1000::ErrorCodes X6_1000::set_clock(X6_1000::ExtInt src , 
                                       float frequency,
                                       ExtSource extSrc) {

    IX6ClockIo::IIClockSource x6clksrc; // clock source
    IX6ClockIo::IIClockSelect x6extsrc; // external clock source

    if (frequency < 0) return INVALID_FREQUENCY;

    x6clksrc = (src ==  EXTERNAL) ? IX6ClockIo::csExternal : IX6ClockIo::csInternal;
    x6extsrc = (extSrc == FRONT_PANEL) ? IX6ClockIo::cslFrontPanel : IX6ClockIo::cslP16;

    module_.Clock().ExternalClkSelect(x6extsrc);
    module_.Clock().Source(x6clksrc);
    module_.Clock().Frequency(frequency * MHz);
    return SUCCESS;
}

X6_1000::ErrorCodes X6_1000::set_ext_trigger_src(X6_1000::ExtSource extSrc) {
    IX6IoDevice::AfeExtSyncOptions syncsel;
    syncsel = (extSrc == FRONT_PANEL) ? IX6IoDevice::essFrontPanel: IX6IoDevice::essP16;
    module_.Output().Trigger().ExternalSyncSource( syncsel );
    module_.Input().Trigger().ExternalSyncSource( syncsel );
    return SUCCESS;
}

X6_1000::ErrorCodes X6_1000::set_trigger_src(
                                TriggerSource trgSrc,
                                bool framed,
                                bool edgeTrigger,
                                unsigned int frameSize) {
    // cache trigger source
    triggerSource_ = trgSrc;

    FILE_LOG(logINFO) << "Trigger Source set to " << trgSrc;

    trig_.DelayedTriggerPeriod(triggerDelayPeriod_);
    trig_.ExternalTrigger( (trgSrc == EXTERNAL_TRIGGER) ? true : false);
    trig_.AtConfigure();

    module_.Output().Trigger().FramedMode(framed);
    module_.Output().Trigger().Edge(edgeTrigger);
    module_.Output().Trigger().FrameSize(frameSize); 
    return SUCCESS;
}

X6_1000::TriggerSource X6_1000::get_trigger_src() {
    // return cached trigger source until 
    // TODO: identify method for getting source from card
    if (triggerSource_) 
        return EXTERNAL_TRIGGER;
    else
        return SOFTWARE_TRIGGER;
}

X6_1000::ErrorCodes X6_1000::set_decimation(bool enabled, int factor) {
    module_.Output().Decimation( (enabled ) ? factor : 0);
    module_.Input().Decimation((enabled ) ? factor : 0); 
    return SUCCESS;
}

X6_1000::ErrorCodes X6_1000::set_channel_enable(int channel, bool enabled) {
    unsigned int numChannels = module_.Output().Channels();
    if (channel >= numChannels) return INVALID_CHANNEL;

    activeChannels_[channel] = enabled;
    return SUCCESS;
}

bool X6_1000::get_channel_enable(int channel) {
    // TODO get active channel status from board
    unsigned int numChannels = module_.Output().Channels();
    if (channel >= numChannels) return false;
    else return activeChannels_[channel];
}


X6_1000::ErrorCodes X6_1000::set_active_channels() {
    ErrorCodes status = SUCCESS;
    unsigned int numChannels = module_.Output().Channels();

    module_.Output().ChannelDisableAll();
    module_.Input().ChannelDisableAll();

    for (int cnt = 0; cnt < numChannels; cnt++) { 
        module_.Output().ChannelEnabled(cnt, activeChannels_[cnt]);
    }
    return status;
}

double X6_1000::get_pll_frequency() {
    double freq = module_.Clock().FrequencyActual();
    return (freq / MHz);
}

void X6_1000::set_defaults() {
    set_clock();
    set_reference();
    set_ext_trigger_src();
    set_trigger_src();
    set_decimation();
    set_active_channels();
}

/**************************************************************
* Waveform source demo code
* This code is to demo access to default II FGPA wavform source
* from library.
***************************************************************/

// X6_1000::ErrorCodes X6_1000::set_waveform_generator(bool enabled/*, type */) {
//     Builder.Settings.WaveType = 1;
//     Builder.Settings.WaveformFrequency = 1.0f;
//     Builder.Settings.WaveformAmplitude = 95.04f;
//     Builder.Settings.TwoToneMode = false;
//     Builder.Settings.TwoToneFrequency = 1.01f;
//     Builder.Settings.SingleChannelMode = true;
//     Builder.Settings.SingleChannelChannel = 0;
// }

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