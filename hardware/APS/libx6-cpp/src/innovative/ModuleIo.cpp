// ModuleIo.h
//
// Board-specific module operations

#include "ModuleIo.h"

using namespace Innovative;
using namespace std;



//---------------------------------------------------------------------------
//  TestModeStrings() -- return vector of strings for Test Mode Listbox
//---------------------------------------------------------------------------

std::vector<std::string>  RxTestModeStrings()
{
    std::vector<std::string>  List;

    List.push_back( std::string("Sawtooth") );
    List.push_back( std::string("Saw (Paced)") );

    return List;
}

//---------------------------------------------------------------------------
//  TestModeStrings() -- return vector of strings for Test Mode Listbox
//---------------------------------------------------------------------------

std::vector<std::string>  TxTestModeStrings()
{
    std::vector<std::string>  List;

    List.push_back( std::string("Ramp") );
    List.push_back( std::string("Sine") );
    List.push_back( std::string("Test") );
    List.push_back( std::string("Zero") );
    List.push_back( std::string("Max +") );
    List.push_back( std::string("Max -") );
    List.push_back( std::string("0101") );
    List.push_back( std::string("0011") );

    return List;
}

//---------------------------------------------------------------------------
//  ExtClockSrcSelectStrings() -- return strings for Ext Src Select Listbox
//---------------------------------------------------------------------------

std::vector<std::string>  ExtClockSrcSelectStrings()
{
    std::vector<std::string>  List;

    List.push_back( std::string("Front Panel") );
    List.push_back( std::string("P16") );

    return List;
}

//---------------------------------------------------------------------------
//  ExtTriggerSrcSelectStrings() -- return strings for Trigger Src Select LB
//---------------------------------------------------------------------------

std::vector<std::string>  ExtTriggerSrcSelectStrings()
{
    std::vector<std::string>  List;

    List.push_back( std::string("Front Panel") );
    List.push_back( std::string("P16") );

    return List;
}

//===========================================================================
//  CLASS ModuleIo  -- Hardware Access and Application Io Class
//===========================================================================
//---------------------------------------------------------------------------
//  constructor for class ModuleIo
//---------------------------------------------------------------------------

ModuleIo::ModuleIo()
{
}

//---------------------------------------------------------------------------
//  destructor for class ModuleIo
//---------------------------------------------------------------------------

ModuleIo::~ModuleIo()
{
}

//---------------------------------------------------------------------------
//  ModuleIo::PreOpen() --
//---------------------------------------------------------------------------

void ModuleIo::PreOpen()
{
    //nothing for now
}

//---------------------------------------------------------------------------
//  ModuleIo::FiclConnectTo() --  Connect to FICL system
//---------------------------------------------------------------------------

void  ModuleIo::FiclConnectTo(FiclSystem & ficl)
{
    // do nothing if FICL is not supported by the board

    //  Attach board specific commands to FICL
    ficl.ConnectTarget(FiclTarget());
}

//---------------------------------------------------------------------------
//  ModuleIo::Log() --  Log message thunked to owner
//---------------------------------------------------------------------------

void  ModuleIo::Log(const std::string & msg)
{
    ProcessStatusEvent e(msg);
    OnLog.Execute(e);
}

//---------------------------------------------------------------------------
//  ModuleIo::Help() --  module-specific help command
//---------------------------------------------------------------------------

std::string ModuleIo::Help() const
{
    return "cr ?system cr ?X6-1000M";
}

//---------------------------------------------------------------------------
//  ModuleIo::SetInputSoftwareTrigger() --  Set or Clear Software Trigger
//---------------------------------------------------------------------------

void  ModuleIo::SetInputSoftwareTrigger(bool state)
{
    Module.Input().SoftwareTrigger(state);
}

//---------------------------------------------------------------------------
//  ModuleIo::SetOutputSoftwareTrigger() --  Set or Clear Software Trigger
//---------------------------------------------------------------------------

void  ModuleIo::SetOutputSoftwareTrigger(bool state)
{
    Module.Output().SoftwareTrigger(state);
}

//---------------------------------------------------------------------------
//  ModuleIo::SetOutputTestConfiguration() --  Configure Test Setup
//---------------------------------------------------------------------------

void  ModuleIo::SetOutputTestConfiguration( bool enable, int mode_idx )
{
    // Optionally enable test mode generator
    Module.Output().TestModeEnabled(enable, mode_idx);
}

//---------------------------------------------------------------------------
//  ModuleIo::SetInputTestConfiguration() --  Configure Test Setup
//---------------------------------------------------------------------------

void  ModuleIo::SetInputTestConfiguration( bool enable, int mode_idx )
{
    // Optionally enable test mode generator
    Module.Input().TestModeEnabled(enable, mode_idx);
}

//---------------------------------------------------------------------------
//  ModuleIo::SetInputPacketDataSize() --  Set Velocia packet data size
//---------------------------------------------------------------------------

void  ModuleIo::SetInputPacketDataSize( unsigned int data_size )
{
    Module.Velo().LoadAll_VeloDataSize(data_size);
}

//---------------------------------------------------------------------------
//  ModuleIo::SetOutputPacketDataSize() --  Set Velocia packet data size
//---------------------------------------------------------------------------

void  ModuleIo::SetOutputPacketDataSize( unsigned int data_size )
{
    // not needed - output sizes are not loaded to board
}

//---------------------------------------------------------------------------
//  ModuleIo::DacTestStatus() --  Display Dac Test Status
//---------------------------------------------------------------------------

void  ModuleIo::DacTestStatus()
{
    // single dac device
    int D0_value = Module.Output().Device(0).DacTestStatus();
    //int D1_value = Module.Output().Device(1).DacTestStatus();

    std::stringstream msg;
    msg << "Test Bits (Dac 0): " << std::hex << " 0x" << D0_value;
    //msg << " (Dac 1): " << std::hex << " 0x" << D1_value;
    Log(std::string(msg.str()));
}

//---------------------------------------------------------------------------
//  ModuleIo::ClearDacTestStatus() --  clear Dac Test Status Bits
//---------------------------------------------------------------------------

void ModuleIo::ClearDacTestStatus()
{
    Module.Output().Device(0).ClearDacTestStatus();
    //Module.Output().Device(1).ClearDacTestStatus();

    std::stringstream msg;
    msg << "Test Bits Cleared";
    Log(std::string(msg.str()));
}

//---------------------------------------------------------------------------
//  AlertStrings() -- return vector of strings for Alert Listbox
//---------------------------------------------------------------------------

std::vector<std::string>  AlertStrings()
{
    std::vector<std::string>  List;

    List.push_back( std::string("Timestamp") );
    List.push_back( std::string("Software") );
    List.push_back( std::string("Temperature") );
    List.push_back( std::string("Fifo Underflow") );
    List.push_back( std::string("Trigger") );

    List.push_back( std::string("Fifo Overrun") );
    List.push_back( std::string("Input Overrange") );

    return List;
}

//---------------------------------------------------------------------------
//  ModuleIo::HookAlerts() --  Hook Alerts
//---------------------------------------------------------------------------

void  ModuleIo::HookAlerts()
{
    // Output
	Module.Alerts().OnTimeStampRolloverAlert.SetEvent(this, &ModuleIo::HandleTimestampRolloverAlert);
	Module.Alerts().OnSoftwareAlert.SetEvent(this, &ModuleIo::HandleSoftwareAlert);
	Module.Alerts().OnWarningTemperature.SetEvent(this, &ModuleIo::HandleWarningTempAlert);
	Module.Alerts().OnOutputUnderflow.SetEvent(this, &ModuleIo::HandleOutputFifoUnderflowAlert);
	Module.Alerts().OnTrigger.SetEvent(this, &ModuleIo::HandleTriggerAlert);
	Module.Alerts().OnOutputOverrange.SetEvent(this, &ModuleIo::HandleOutputOverrangeAlert);
    // Input 
	Module.Alerts().OnInputOverflow.SetEvent(this, &ModuleIo::HandleInputFifoOverrunAlert);
    Module.Alerts().OnInputOverrange.SetEvent(this, &ModuleIo::HandleInputOverrangeAlert);
}

//---------------------------------------------------------------------------
//  ModuleIo::ConfigureAlerts() --  Configure Alerts
//---------------------------------------------------------------------------

void  ModuleIo::ConfigureAlerts(std::vector<char> & AlertEnable)
{
    enum IUsesX6Alerts::AlertType Alert[] = {
        IUsesX6Alerts::alertTimeStampRollover, IUsesX6Alerts::alertSoftware,
        IUsesX6Alerts::alertWarningTemperature,
        IUsesX6Alerts::alertOutputUnderflow,
        IUsesX6Alerts::alertTrigger ,
        IUsesX6Alerts::alertInputOverrange,
        IUsesX6Alerts::alertInputOverflow
    };

    for (unsigned int i = 0; i < AlertEnable.size(); ++i)
        Module.Alerts().AlertEnable(Alert[i], AlertEnable[i] ? true : false);
}

//---------------------------------------------------------------------------
//  ModuleIo::SetInputPulseTriggerConfiguration() --  Configure Pulse Trigger
//---------------------------------------------------------------------------

void  ModuleIo::SetInputPulseTriggerConfiguration(bool enable, float period, const std::vector<float> &Delays, const std::vector<float> &Widths )
{
    // Optionally enable ramp generator
    Module.Input().Pulse().Reset();
    Module.Input().Pulse().Enabled(enable);

    for (unsigned int i=0; i<Delays.size(); i++)
        {
        Module.Input().Pulse().AddEvent(static_cast<unsigned int>(period),
                                        static_cast<unsigned int>(Delays[i]),
                                        static_cast<unsigned int>(Widths[i]));
        }
}

//---------------------------------------------------------------------------
//  ModuleIo::SetOutputPulseTriggerConfiguration() --  Configure Pulse Trigger
//---------------------------------------------------------------------------

void  ModuleIo::SetOutputPulseTriggerConfiguration(bool enable, float period, const std::vector<float> &Delays, const std::vector<float> &Widths )
{
    // Optionally enable ramp generator
    Module.Output().Pulse().Reset();
    Module.Output().Pulse().Enabled(enable);

    for (unsigned int i=0; i<Delays.size(); i++)
        {
        Module.Output().Pulse().AddEvent(static_cast<unsigned int>(period),
                                        static_cast<unsigned int>(Delays[i]),
                                        static_cast<unsigned int>(Widths[i]));
        }
}

//---------------------------------------------------------------------------
//  ModuleIo::StreamIdVector() --  Return Sid Vector
//---------------------------------------------------------------------------
std::vector<int> ModuleIo::VitaStreamIdVector()
{
    std::vector<int> sids;      
    
    //  Read Sid Values
    int sid_0 = Module.VitaOut().VitaStreamId(0);
    int sid_1 = Module.VitaOut().VitaStreamId(1);

    if (Module.Output().ChannelEnabled(0) || Module.Output().ChannelEnabled(1))
        sids.push_back(sid_0);
    if (Module.Output().ChannelEnabled(2) || Module.Output().ChannelEnabled(3))
        sids.push_back(sid_1);

    return sids;
}

//---------------------------------------------------------------------------
//  ModuleIo::AllInputVitaStreamIdVector() --  Return Sid Vector
//---------------------------------------------------------------------------

std::vector<int> ModuleIo::AllInputVitaStreamIdVector()
{
    std::vector<int> all_sids;
    //  Read Sid Values
    int sid_0 = Module.VitaIn().VitaStreamId(0);
    int sid_1 = Module.VitaIn().VitaStreamId(1);

    all_sids.push_back(sid_0);
    all_sids.push_back(sid_1);

    return all_sids;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//  Alert Handlers
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//------------------------------------------------------------------------------
//  ModuleIo::HandleTimestampRolloverAlert() --
//------------------------------------------------------------------------------

void  ModuleIo::HandleTimestampRolloverAlert(Innovative::AlertSignalEvent & event)
{
    std::stringstream msg;
    msg << "Time stamp rollover 0x" << std::hex << event.Argument
        << " after " << std::dec << Elapsed(event.TimeStamp);
    Log(msg.str());
}

//------------------------------------------------------------------------------
//  ModuleIo::HandleSoftwareAlert() --
//------------------------------------------------------------------------------

void  ModuleIo::HandleSoftwareAlert(Innovative::AlertSignalEvent & event)
{
    std::stringstream msg;
    msg << "Software alert 0x" << std::hex << event.Argument
        << " after " << std::dec << Elapsed(event.TimeStamp);
    Log(msg.str());
}

//------------------------------------------------------------------------------
//  ModuleIo::HandleWarningTempAlert() --
//------------------------------------------------------------------------------

void  ModuleIo::HandleWarningTempAlert(Innovative::AlertSignalEvent & event)
{
    // Clear warning condition (reading clears)
    //Module.Thermal().LogicWarningTemperature();

    std::stringstream msg;
    msg << "Temp warning alert 0x" << std::hex << event.Argument
        << " after " << std::dec << Elapsed(event.TimeStamp);

    Log(msg.str());
}

//------------------------------------------------------------------------------
//  ModuleIo::HandleInputFifoOverrunAlert() --
//------------------------------------------------------------------------------

void  ModuleIo::HandleInputFifoOverrunAlert(Innovative::AlertSignalEvent & event)
{
    std::stringstream msg;
    msg << "Input FIFO overrun 0x" << std::hex << event.Argument
        << " after " << std::dec << Elapsed(event.TimeStamp);
    Log(msg.str());

    //
    //  Alert Acknowledgement - some alerts can recur so frequently as to potentially
    //    overload the system with warnings.  Therefore, these alerts require a request
    //    to clear the lock that prevents a second alert be made at the application level.
    //
    //  The line below is how the event is acked. Even clearing it automatically here risks
    //    a cascade of alerts - ideally this would be cleared by the app elsewhere...
    //
    //  Module.Alerts().AlertClear(IUsesX6Alerts::alertInputOverflow);
}

//------------------------------------------------------------------------------
//  ModuleIo::HandleOutputFifoUnderflowAlert() --
//------------------------------------------------------------------------------

void  ModuleIo::HandleOutputFifoUnderflowAlert(Innovative::AlertSignalEvent & event)
{
    std::stringstream msg;
    msg << "Output FIFO underflow 0x" << std::hex << event.Argument
        << " after " << std::dec << Elapsed(event.TimeStamp);
    Log(msg.str());

    //
    //  Alert Acknowledgement - some alerts can recur so frequently as to potentially
    //    overload the system with warnings.  Therefore, these alerts require a request
    //    to clear the lock that prevents a second alert be made at the application level.
    //
    //  The line below is how the event is acked. Even clearing it automatically here risks
    //    a cascade of alerts - ideally this would be cleared by the app elsewhere...
    //
    //  Module.Alerts().AlertClear(IUsesX6Alerts::alertOutputUnderflow);

}

//------------------------------------------------------------------------------
//  ModuleIo::HandleTriggerAlert() --
//------------------------------------------------------------------------------

void  ModuleIo::HandleTriggerAlert(Innovative::AlertSignalEvent & event)
{
    std::string triggerType;
    switch (event.Argument & 0x3)
        {
        case 0:  triggerType = "? ";  break;
        case 1:  triggerType = "Input ";  break;
        case 2:  triggerType = "Output ";  break;
        case 3:  triggerType = "Input and Output ";  break;
        }
    std::stringstream msg;
    msg << "Trigger 0x" << std::hex << event.Argument
        << " Type: " <<  triggerType
        << " after " << std::dec << Elapsed(event.TimeStamp);
    Log(msg.str());
}

//------------------------------------------------------------------------------
//  ModuleIo::HandleInputOverrangeAlert() --
//------------------------------------------------------------------------------

void  ModuleIo::HandleInputOverrangeAlert(Innovative::AlertSignalEvent & event)
{
    std::stringstream msg;
    msg << "Input overrange 0x " << std::hex << event.Argument
        << " after " << std::dec << Elapsed(event.TimeStamp);
    Log(msg.str());

    //
    //  Alert Acknowledgement - some alerts can recur so frequently as to potentially
    //    overload the system with warnings.  Therefore, these alerts require a request
    //    to clear the lock that prevents a second alert be made at the application level.
    //
    //  The line below is how the event is acked. Even clearing it automatically here risks
    //    a cascade of alerts - ideally this would be cleared by the app elsewhere...
    //
    //  Module.Alerts().AlertClear(IUsesX6Alerts::alertInputOverrange);
}

//------------------------------------------------------------------------------
//  ModuleIo::HandleOutputOverrangeAlert() --
//------------------------------------------------------------------------------

void  ModuleIo::HandleOutputOverrangeAlert(Innovative::AlertSignalEvent & event)
{
    std::stringstream msg;
    msg << "Output overrange 0x " << std::hex << event.Argument
        << " after " << std::dec << Elapsed(event.TimeStamp);
    Log(msg.str());

    //
    //  Alert Acknowledgement - some alerts can recur so frequently as to potentially
    //    overload the system with warnings.  Therefore, these alerts require a request
    //    to clear the lock that prevents a second alert be made at the application level.
    //
    //  The line below is how the event is acked. Even clearing it automatically here risks
    //    a cascade of alerts - ideally this would be cleared by the app elsewhere...
    //
    //  Module.Alerts().AlertClear(IUsesX6Alerts::alertOutputOverrange);
}

//------------------------------------------------------------------------------
//  ModuleIo::Elapsed() --  Display timestamp as elapsed MCLKs
//------------------------------------------------------------------------------

std::string ModuleIo::Elapsed(size_t timestamp)
{
    stringstream msg;
    msg << timestamp << " master clocks";
    return msg.str();
}

