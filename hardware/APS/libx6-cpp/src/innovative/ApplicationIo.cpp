// ApplicationIo.cpp
//
// Board-specific data flow and hardware I/O
// Copyright 2006 Innovative Integration
//---------------------------------------------------------------------------

#define NOMINMAX

#include <Malibu_Mb.h>
#include <Analysis_Mb.h>
#include <IppMemoryUtils_Mb.h>
#include <Magic_Mb.h>
#include "ApplicationIo.h"
#include <SystemSupport_Mb.h>
#include <StringSupport_Mb.h>
#include <Buffer_Mb.h>
#include <BufferDatagrams_Mb.h>
#include <BufferHeader_Mb.h>
#include <Application/StaticWaveform_App.h>
#include <Exception_Mb.h>

using namespace Innovative;
//using namespace InnovativeKernel;
using namespace std;

//===========================================================================
//  CLASS ApplicationIo  -- Hardware Access and Application I/O Class
//===========================================================================
//---------------------------------------------------------------------------
//  constructor for class ApplicationIo
//---------------------------------------------------------------------------

ApplicationIo::ApplicationIo(IUserInterface * ui)
    :  FiclIo(ui), Settings(this), UI(ui),
       FOpened(false), FStreamConnected(false), 
       Stopped(true),
       RxTime(6), RxBytesPerBlock(6),
       TxTime(6), TxBytesPerBlock(6),
       FWordCount(0), SamplesPerWord(1), WordsToLog(0)
{
    TraceVerbosity(Settings.DebugVerbosity);

    OnLog.SetEvent(this, &ApplicationIo::HandleOnLog);
    Module.OnLog.SetEvent(this, &ApplicationIo::HandleOnLog);

    //
    // Use IPP performance memory functions.
    Init::UsePerformanceMemoryFunctions();
    
    //
    //  Set up Loggers and graphs
    {
    std::stringstream ss;
    ss << Settings.Root() << "Data.bin";
    Logger.FileName(ss.str());
    Graph.BinFile(Logger.FileName());
    Graph.System().ServerSlotName("Stream");
    }
    {
    std::stringstream ss;
    ss << Settings.Root() << "VeloData.bin";
    VMPLogger.FileName(ss.str());
    VMPGraph.BinFile(VMPLogger.FileName());
    VMPGraph.System().ServerSlotName("VMPStream");
    }

    Timer.Interval(1000);

    std::stringstream msg;
    msg << "Be sure to read the help file for info on this program";
    msg << " located in the root of the this example folder.  ";
    Log(msg.str());
}

//---------------------------------------------------------------------------
//  destructor for class ApplicationIo
//---------------------------------------------------------------------------

ApplicationIo::~ApplicationIo()
{
    Close();
}

//---------------------------------------------------------------------------
//  ApplicationIo::BoardCount() -- Query number of installed boards
//---------------------------------------------------------------------------

unsigned int ApplicationIo::BoardCount()
{
    return static_cast<unsigned int>(Module().BoardCount());
}

//---------------------------------------------------------------------------
// ApplicationIo::Open()
//---------------------------------------------------------------------------

void ApplicationIo::Open()
{
    UI->GetSettings();
    //
    //  Configure Trigger Manager Event Handlers
    Trig.OnDisableTrigger.SetEvent(this, &ApplicationIo::HandleDisableTrigger);
    Trig.OnExternalTrigger.SetEvent(this, &ApplicationIo::HandleExternalTrigger);
    Trig.OnSoftwareTrigger.SetEvent(this, &ApplicationIo::HandleSoftwareTrigger);
    Trig.DelayedTrigger(true); // trigger delayed after start
    //
    //  Configure Module Event Handlers
    Module().OnBeforeStreamStart.SetEvent(this, &ApplicationIo::HandleBeforeStreamStart);
    Module().OnBeforeStreamStart.Synchronize();
    Module().OnAfterStreamStart.SetEvent(this, &ApplicationIo::HandleAfterStreamStart);
    Module().OnAfterStreamStart.Synchronize();
    Module().OnAfterStreamStop.SetEvent(this, &ApplicationIo::HandleAfterStreamStop);
    Module().OnAfterStreamStop.Synchronize();

    //
    //  Alerts
    Module.HookAlerts();

    //
    //  Configure Stream Event Handlers
    Stream.OnVeloDataRequired.SetEvent(this, &ApplicationIo::HandleDataRequired);
    Stream.DirectDataMode(false);
    Stream.OnVeloDataAvailable.SetEvent(this, &ApplicationIo::HandleDataAvailable);

    Stream.OnAfterStop.SetEvent(this, &ApplicationIo::HandleAfterStop);
    Stream.OnAfterStop.Synchronize();

    Stream.RxLoadBalancing(false);
    Stream.TxLoadBalancing(false);

    Timer.OnElapsed.SetEvent(this, &ApplicationIo::HandleTimer);
    Timer.OnElapsed.Thunk();

    // Insure BM size is a multiple of four MB
    const int Meg = 1024 * 1024;
    const int RxBmSize = std::max(Settings.Rx.BusmasterSize/4, 1) * 4;
    const int TxBmSize = std::max(Settings.Tx.BusmasterSize/4, 1) * 4;
    Module().IncomingBusMasterSize(RxBmSize * Meg);
    Module().OutgoingBusMasterSize(TxBmSize * Meg);
    Module().Target(Settings.Target);
    //
    //  Open Devices
    try
        {
        Module.PreOpen();
        Module().Open();

        std::stringstream msg;
        msg << "Bus master size: Input => " << RxBmSize << " MB" << " Output => " << TxBmSize << " MB";
        Log(msg.str());
        }
    catch (Innovative::MalibuException & exception)
        {
        Log("Open Failure:");
        Log(exception.what());
        return;
        }
    catch(...)
        {
        Log("Module Device Open Failure!");
        return;
        }
        
    Module().Reset();
    Log("Module Device Opened Successfully...");
    FOpened = true;

    //
    //  Connect Stream
    Stream.ConnectTo(&(Module.Ref()));
    FStreamConnected = true;
    Log("Stream Connected...");

    PrefillPacketCount = Stream.PrefillPacketCount();
    
    //
    //  Initialize VeloMergeParse
    VMP.OnDataAvailable.SetEvent(this, &ApplicationIo::VMPDataAvailable);
    std::vector<int> sids = Module.AllInputVitaStreamIdVector();
    VMP.Init( sids );

    DisplayLogicVersion();
}

//---------------------------------------------------------------------------
// ApplicationIo::Close()
//---------------------------------------------------------------------------

void ApplicationIo::Close()
{
    Stream.Disconnect();
    Module().Close();
    FStreamConnected = false;
    FOpened = false;
    Log("Stream Disconnected...");
}

//---------------------------------------------------------------------------
// ApplicationIo::StreamPreconfigure()
//---------------------------------------------------------------------------

void ApplicationIo::StreamPreconfigure()
{
    Log("Preconfiguring Stream....");
    //
    //  Make sure if Wave Generator is in single channel mode, we have a valid
    //    active channel filled in
    if (Builder.Settings.SingleChannelMode)
        {
        int active_channels = 0;
        for (unsigned int i = 0; i < Settings.Tx.ActiveChannels.size(); ++i)
            if ((Settings.Tx.ActiveChannels[i] ? true : false))
                active_channels++;
        if (active_channels==3)
            active_channels = 4;   // can't do a true 3 channel run, promote to 4.
        if (Builder.Settings.SingleChannelChannel >= active_channels)
            {
            Log("Error: Invalid Active Channel selected in Single Channel Mode");
            return;
            }
        }
    //
    //  Set Channel Enables
    Module().Output().ChannelDisableAll();
    for (unsigned int i = 0; i < Module().Output().Channels(); ++i)
        {
        bool active = Settings.Tx.ActiveChannels[i] ? true : false;
        if (active==true)
            Module().Output().ChannelEnabled(i, true);
        }
    //  Channel Enables
    Module().Input().ChannelDisableAll();
    for (unsigned int i = 0; i < Module().Input().Channels(); ++i)
        {
        bool active = Settings.Rx.ActiveChannels[i] ? true : false;
        if (active==true)
            Module().Input().ChannelEnabled(i, true);
        }

    //
    // Clock Configuration
    
    //   Route ext clock source
    IX6ClockIo::IIClockSelect cks[] = { IX6ClockIo::cslFrontPanel, IX6ClockIo::cslP16 };
    Module().Clock().ExternalClkSelect(cks[Settings.ExtClockSrcSelection]);
    //   Route reference.
    IX6ClockIo::IIReferenceSource ref[] = { IX6ClockIo::rsExternal, IX6ClockIo::rsInternal };
    Module().Clock().Reference(ref[Settings.ReferenceClockSource]);
    Module().Clock().ReferenceFrequency(Settings.ReferenceRate * 1e6);
    //   Route clock
    IX6ClockIo::IIClockSource src[] = { IX6ClockIo::csExternal, IX6ClockIo::csInternal };
    Module().Clock().Source(src[Settings.SampleClockSource]);
    Module().Clock().Frequency(Settings.SampleRate * 1e6);

    // Readback Frequency
    double freq_actual = Module().Clock().FrequencyActual();
    {
    std::stringstream msg;
    msg << "Actual PLL Frequency: " << freq_actual ;
    Log(msg.str());
    }

    Stream.Preconfigure();

}

//---------------------------------------------------------------------------
// ApplicationIo::StartStreaming()
//---------------------------------------------------------------------------

bool ApplicationIo::StartStreaming()
{
    //
    //  Set up Parameters for Data Streaming
    //  ...First have UI get settings into our settings store
    UI->GetSettings();

    //  if auto-preconfiging, call preconfig here.
    if (Settings.AutoPreconfig)
        StreamPreconfigure();

    if (!FStreamConnected)
        {
        Log("Stream not connected! -- Open the boards");
        return false;
        }
    if (Settings.Tx.Framed)
        {
        // Granularity is firmware limitation
        int framesize = Module().Output().Info().TriggerFrameGranularity();

        if (Settings.Tx.FrameSize % framesize)
            {
            std::stringstream msg;
            msg << "Error: Ouput frame count must be a multiple of " << framesize;
            Log(msg.str());
            UI->AfterStreamStop();
            return false;
            }
        }
    if (Settings.Rx.Framed)
        {
        // Granularity is firmware limitation
        int framesize = Module().Input().Info().TriggerFrameGranularity();

        if (Settings.Rx.FrameSize % framesize)
            {
            std::stringstream msg;
            msg << "Error: Input frame count must be a multiple of " << framesize;
            Log(msg.str());
            UI->AfterStreamStop();
            return false;
            }
        }
    FWordCount = 0;
     
    unsigned int SamplesPerWord = Module().Input().Info().SamplesPerWord();
    WordsToLog = Settings.Rx.SamplesToLog / SamplesPerWord;
    //
    //  Configure Merge Parser
    VMP.Resize(Settings.Rx.MergePacketSize);
    VMP.Clear();
    // Configure Trigger Mananger
    Trig.DelayedTriggerPeriod(Settings.Tx.TriggerDelayPeriod);
	Trig.ExternalTrigger(Settings.Rx.ExternalTrigger ? true : false || Settings.Tx.ExternalTrigger ? true : false);
    Trig.AtConfigure();

    FTxBlockCount = FRxBlockCount = 0;
    FTxBlockRate  = FRxBlockRate  = 0;
    VMP_VeloCount = 0;

    //
    //  Check Channel Enables
    if (!Module().Output().ActiveChannels() && !Module().Input().ActiveChannels())
        {
        Log("Error: Must enable at least one channel");
        UI->AfterStreamStop();
        return false;
        }

    //
    // Trigger Configuration
    //  Frame Triggering
    Module().Output().Trigger().FramedMode((Settings.Tx.Framed)? true : false);
    Module().Output().Trigger().Edge((Settings.Tx.EdgeTrigger)? true : false);
    Module().Output().Trigger().FrameSize(Settings.Tx.FrameSize);

    Module().Input().Trigger().FramedMode((Settings.Rx.Framed)? true : false);
    Module().Input().Trigger().Edge((Settings.Rx.EdgeTrigger)? true : false);
    Module().Input().Trigger().FrameSize(Settings.Rx.FrameSize);

    //  Route External Trigger source
    IX6IoDevice::AfeExtSyncOptions syncsel[] = { IX6IoDevice::essFrontPanel, IX6IoDevice::essP16 };
    Module().Output().Trigger().ExternalSyncSource( syncsel[ Settings.ExtTriggerSrcSelection ] );
    Module().Input().Trigger().ExternalSyncSource( syncsel[ Settings.ExtTriggerSrcSelection ] );

    //  Pulse Trigger Config
    {
    std::vector<float> Delays;
    std::vector<float> Widths;
    //  ...push first delay
    Delays.push_back(Settings.Rx.Pulse.Delay);  Widths.push_back(Settings.Rx.Pulse.Width);
    //  ...do we push delay 2?
    if (Settings.Rx.Pulse.Delay2!=0 && Settings.Rx.Pulse.Width2!=0)
        {  Delays.push_back(Settings.Rx.Pulse.Delay2);  Widths.push_back(Settings.Rx.Pulse.Width2 ); }

     //  ...add to module configuration
    Module.SetInputPulseTriggerConfiguration(Settings.Rx.Pulse.Enable, 
                                             Settings.Rx.Pulse.Period,
                                             Delays, Widths);
    Delays.clear();
    Widths.clear();
    //  ...push first delay
    Delays.push_back(Settings.Tx.Pulse.Delay);  Widths.push_back(Settings.Tx.Pulse.Width);
    //  ...do we push delay 2?
    if (Settings.Tx.Pulse.Delay2!=0 && Settings.Tx.Pulse.Width2!=0)
        {  Delays.push_back(Settings.Tx.Pulse.Delay2);  Widths.push_back(Settings.Tx.Pulse.Width2 ); }

     //  ...add to module configuration
    Module.SetOutputPulseTriggerConfiguration(Settings.Tx.Pulse.Enable, 
                                             Settings.Tx.Pulse.Period,
                                             Delays, Widths);
    }
    //
    //  Velocia Packet Size
    Module.SetOutputPacketDataSize(Settings.Tx.PacketSize);
    Module.SetInputPacketDataSize(Settings.Rx.PacketSize);
    Module().Velo().ForceVeloPacketSize(Settings.Rx.ForceSize);
    //
    //  Output Test Generator Setup
    Module.SetOutputTestConfiguration( Settings.Tx.TestGenEnable, Settings.Tx.TestGenMode );
    Module.SetInputTestConfiguration( Settings.Rx.TestCounterEnable, Settings.Rx.TestGenMode );
    Module().Output().TestFrequency( Settings.Tx.TestFrequencyMHz * 1e6 );
    Module().Input().TestFrequency( Settings.Tx.TestFrequencyMHz * 1e6 );

    // Set Decimation Factor
    int factor = Settings.Tx.DecimationEnable ? Settings.Tx.DecimationFactor : 0;
    Module().Output().Decimation(factor);
    factor = Settings.Rx.DecimationEnable ? Settings.Rx.DecimationFactor : 0;
    Module().Input().Decimation(factor);
    //
    //  Configure Alert Enables
    Module.ConfigureAlerts(Settings.AlertEnable);

    // Disable prefill if in test mode
    if (Module().Output().ActiveChannels())
        Stream.PrefillPacketCount(Settings.Tx.TestGenEnable ? 0 : PrefillPacketCount);
    else
        Stream.PrefillPacketCount(0);
    // Fill Waveform Buffer (if streaming)
    if ((Settings.Tx.TestGenEnable == false) && Module().Output().ActiveChannels())
        FillWaveformBuffer();
    //
    //  Start Player if in use
    if (Settings.Tx.PlayFromFile.Enable)
        {
        Player.FileName(Settings.Tx.PlayFromFile.Filename);
        bool player_opened = Player.Start();
        if (player_opened==false)
            Log("PlayFromFile Open Error.");
        }
    //
    //  Start Loggers on active channels
	if (Settings.Rx.PlotEnable)
		{
		Graph.Quit();
		VMPGraph.Quit();
		}

	if (Settings.Rx.LoggerEnable || Settings.Rx.PlotEnable)
		{
		Logger.Start();     // we will use one or the other...
		VMPLogger.Start();
		}
    Trig.AtStreamStart();
    //  Start Streaming
    Stopped = false;
    Stream.Start();
    RunTimeSW.Start();
    Log("Stream Mode started");

    return true;
}

//---------------------------------------------------------------------------
// ApplicationIo::StopStreaming()
//---------------------------------------------------------------------------

void ApplicationIo::StopStreaming()
{
    if (!IsStreaming())
        return;

    if (!FStreamConnected)
        {
        Log("Stream not connected! -- Open the boards");
        return;
        }

    //
    //  Stop Streaming
    Stream.Stop();
    Stopped = true;
    Timer.Enabled(false);


    //  Disable test generator
    if (Settings.Tx.TestGenEnable)
        Module.SetOutputTestConfiguration( false, Settings.Tx.TestGenMode );

    if (Settings.Rx.TestCounterEnable)
        Module.SetInputTestConfiguration( false, Settings.Tx.TestGenMode );


	Trig.AtStreamStop();
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//  Data Flow Event Handlers
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

//---------------------------------------------------------------------------
//  ApplicationIo::HandleDataAvailable() --  Handle received packet
//---------------------------------------------------------------------------

void  ApplicationIo::HandleDataAvailable(VitaPacketStreamDataEvent & Event)
{
    if (Stopped)
        return;

    VeloBuffer Packet;

    //
    //  Extract the packet from the Incoming Queue...
    Event.Sender->Recv(Packet);

    if (Settings.Rx.MergeParseEnable==false)
        {
        //  normal processing
        if (Settings.Rx.LoggerEnable)
            if (FWordCount < WordsToLog)
                {
                Logger.LogWithHeader(Packet);
                }
        }
    else
        {
        //  merge parse processing
        VMP.Append(Packet);
        VMP.Parse();
        }
 

    IntegerDG Packet_DG(Packet);

    TallyBlock(Packet_DG.size()*sizeof(int));

    FWordCount += Packet.SizeInInts();
    // Per block triggering actions
    Trig.AtBlockProcess(static_cast<unsigned int>(Packet_DG.size()*sizeof(int)));
}

//---------------------------------------------------------------------------
//  ApplicationIo::TallyBlock() --  Finish processing of received packet
//---------------------------------------------------------------------------

void  ApplicationIo::TallyBlock(size_t bytes)
{
	double Period = RxTime.Differential();
    double AvgBytes = RxBytesPerBlock.Process(static_cast<double>(bytes));
    if (Period)
		FRxBlockRate = AvgBytes / (Period*1.0e6);
    //
    //  Tally the blocks received
    ++FRxBlockCount;
    //
    //  Stop streaming when both Channels have passed their limit
    if (Settings.Rx.AutoStop && IsDataLoggingCompleted() && !Stopped)
        {
        // Stop counter and display it
		double elapsed = RunTimeSW.Stop();

        StopStreaming();
        Log("Stream Mode Stopped automatically");
        Log(std::string("Elasped (S): ") + FloatToString(elapsed));
        }
}

//---------------------------------------------------------------------------
// ApplicationIo::HandleDataRequired()
//---------------------------------------------------------------------------

void ApplicationIo::HandleDataRequired(VitaPacketStreamDataEvent & Event)
{
    SendOneBlock(Event.Sender);

    // Per block triggering actions (not used on X6)
    //Trig.AtBlockProcess( WaveformPacket.SizeInInts() );
}

//------------------------------------------------------------------------------
// ApplicationIo::SendOneBlock()
//------------------------------------------------------------------------------

void ApplicationIo::SendOneBlock(VitaPacketStream * PS)
{
    ShortDG Packet_DG(WaveformPacket);

    // Calculate transfer rate in kB/s
    double Period = TxTime.Differential();

    double AvgBytes = TxBytesPerBlock.Process(static_cast<double>(Packet_DG.SizeInBytes()));
    if (Period)
		FTxBlockRate = AvgBytes / (Period*1.0e6);

    //
    //  No matter what channels are enabled, we have one packet type
    //    to send here
    if (Settings.Tx.PlayFromFile.Enable)
        {
        if (Player.Percent()<100)
            {
            VeloBuffer VB;
            Player.PlayWithHeader(VB);
            PS->Send(0, VB);
            ++FTxBlockCount;
            }
        }
    else
        {
        //  Send the single WF packet
        PS->Send(0, WaveformPacket);
        ++FTxBlockCount;
        }

}

//------------------------------------------------------------------------
//  ApplicationIo::VMPDataAvailable() -- Merge Parser Data Available
//------------------------------------------------------------------------

void  ApplicationIo::VMPDataAvailable(VeloMergeParserDataAvailable & Event)
{
    VMP_VeloCount++;

    if (Settings.Rx.LoggerEnable)
        if (FWordCount < WordsToLog)
            {
            //  Log Data To VMP file - oops, use ceiling?
            VMPLogger.LogWithHeader(Event.Data);
            }
                
}

//------------------------------------------------------------------------
//  ApplicationIo::FillWaveformBuffer() -- Fill buffer with waveform data
//------------------------------------------------------------------------

void ApplicationIo::FillWaveformBuffer()
{
    //
    //  Builds a N channel buffer
    int channels = Module().Output().ActiveChannels();
    int bits = Module().Output().Info().Bits();
    int samples = static_cast<int>(Settings.Tx.PacketSize);


    //  Pack SIDs Array
    std::vector<int> sids(Module.VitaStreamIdVector());

    Builder.SampleRate(Settings.SampleRate*1e6);
    Builder.Format(sids, channels, bits, samples);
    Builder.BuildWave(WaveformPacket);
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//  Support Functions
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//---------------------------------------------------------------------------
//  ApplicationIo::IsDataLoggingCompleted() --check if done logging
//---------------------------------------------------------------------------

bool  ApplicationIo::IsDataLoggingCompleted()
{
    return FWordCount >= WordsToLog;
}
//---------------------------------------------------------------------------
//  ApplicationIo::Temperature() --  Query current module temperature
//---------------------------------------------------------------------------

float ApplicationIo::Temperature()
{
    return static_cast<float>(Module().Thermal().LogicTemperature());
}

//---------------------------------------------------------------------------
//  ApplicationIo::PllLocked() --  Query pll lock status
//---------------------------------------------------------------------------

bool ApplicationIo::PllLocked()
{
    return Module().Clock().Locked();
}

//------------------------------------------------------------------------------
//  ApplicationIo::DisplayLogicVersion() --  Log version info
//------------------------------------------------------------------------------

void  ApplicationIo::DisplayLogicVersion()
{
    std::stringstream msg;
    msg << std::hex << "Logic Version: " << Module().Info().FpgaLogicVersion()
        << ", Hdw Variant: " << Module().Info().FpgaHardwareVariant()
        << ", Revision: " << Module().Info().PciLogicRevision()
        << ", Subrevision: " << Module().Info().FpgaLogicSubrevision();
    Log(msg.str());

    std::stringstream msg2;
    msg2 << std::hex << "Board Family: " << Module().Info().PciLogicFamily()
        << ", Type: " << Module().Info().PciLogicType()
        << ", Board Revision: " << Module().Info().PciLogicPcb()
        << ", Chip: " << Module().Info().FpgaChipType();
    Log(msg2.str());

    msg.str("");
    msg << "PCI Express Lanes: " << Module().Debug()->LaneCount();
    Log(msg.str());
}

//---------------------------------------------------------------------------
//  ApplicationIo::InitBddFile() --  Set up BDD File for an output file
//---------------------------------------------------------------------------

void ApplicationIo::InitBddFile(BinView & graph)
{
	// Optionally skip u
    PathSpec spec(graph.BinFile());
    spec.Ext(".bdd");
    if (FileExists(spec.Full()) && !Settings.Rx.OverwriteBdd)
        return;

    remove(spec.Full().c_str());

	// Make a new BDD
	const int bits = Module().Input().Info().Bits();

	const int limit = 1 << (bits-1);
    // Time
	graph.Time().LowerLimit(-limit);
	graph.Time().UpperLimit(limit);
	graph.Time().Break(1);
    graph.Time().SeamSize((Module().Velo().VeloPacketSize(0)-2)*sizeof(int));
    graph.Time().AnnotateSeams(true);
    // Fft
    graph.Fft().LowerLimit(-150);
    graph.Fft().ScaleYType(BinViewOptions::FftOptions::sLog);
    graph.Fft().ScaleXType(BinViewOptions::FftOptions::sLog);
    graph.Fft().CriteriaThreshold(75);
    int pktsize = std::min(Settings.Rx.PacketSize, 0x10000);
    BinViewOptions::FftOptions::IIPoints pts(static_cast<BinViewOptions::FftOptions::IIPoints>(
        TrailingZeroCount(pktsize)-7));
    graph.Fft().Points(pts);
    graph.Fft().Window(BinViewOptions::FftOptions::wBlackmann);
    graph.Fft().Average(1);
    //
    graph.Text().DataFormat("%11.3f");
    graph.System().UpdateRate(BinViewOptions::SystemOptions::ms1000);
    graph.Leap(Settings.Rx.PacketSize);
    graph.SignificantBits(bits);
    graph.Polarity(Module().Input().Info().Span().IsUnipolar() ? BinView::pUnsigned : BinView::pSigned);
    graph.DataSpan(300);
    graph.DataType(BinView::tInt);
    graph.Units("mV");
    graph.Samples(1000);
    graph.SampleRate(Settings.SampleRate * 1000);

    graph.Channels(Module().Input().ActiveChannels());
    graph.Devices(Module().Input().ActiveChannels());


    graph.System().Source(BinViewOptions::SystemOptions::sVita);
    graph.NullDataValue(.12345e-19f);
    graph.InputSpan(2000);
    graph.ScalingEnabled(true);

    graph.Save();
}

//---------------------------------------------------------------------------
//  ApplicationIo::InitVMPBddFile() --  Set up BDD File for VMP data file
//---------------------------------------------------------------------------

void ApplicationIo::InitVMPBddFile(BinView & graph)
{
	// Optionally skip u
    PathSpec spec(graph.BinFile());
    spec.Ext(".bdd");
    if (FileExists(spec.Full()) && !Settings.Rx.OverwriteBdd)
        return;

    remove(spec.Full().c_str());

	// Make a new BDD
	const int bits = Module().Input().Info().Bits();

	const int limit = 1 << (bits-1);
    // Time
	graph.Time().LowerLimit(-limit);
	graph.Time().UpperLimit(limit);
	graph.Time().Break(1);
    graph.Time().SeamSize((Module().Velo().VeloPacketSize(0)-2)*sizeof(int));
    graph.Time().AnnotateSeams(true);
    // Fft
    graph.Fft().LowerLimit(-150);
    graph.Fft().ScaleYType(BinViewOptions::FftOptions::sLog);
    graph.Fft().ScaleXType(BinViewOptions::FftOptions::sLog);
    graph.Fft().CriteriaThreshold(75);
    int pktsize = std::min(Settings.Rx.PacketSize, 0x10000);
    BinViewOptions::FftOptions::IIPoints pts(static_cast<BinViewOptions::FftOptions::IIPoints>(
        TrailingZeroCount(pktsize)-7));
    graph.Fft().Points(pts);
    graph.Fft().Window(BinViewOptions::FftOptions::wBlackmann);
    graph.Fft().Average(1);
    //
    graph.Text().DataFormat("%11.3f");
    graph.System().UpdateRate(BinViewOptions::SystemOptions::ms1000);
    graph.Leap(Settings.Rx.PacketSize);
    graph.SignificantBits(bits);
    graph.Polarity(Module().Input().Info().Span().IsUnipolar() ? BinView::pUnsigned : BinView::pSigned);
    graph.DataSpan(300);
    graph.DataType(BinView::tInt);
    graph.Units("mV");
    graph.Samples(1000);
    graph.SampleRate(Settings.SampleRate * 1000);

    // Tally active channels
    unsigned int active = 0;
    for (int i = 0; i < AnalogInChannels(); ++i)
        active += Module().Input().ChannelEnabled(i) ? 1 : 0;

    graph.Channels(active);
    graph.Devices(active);

    graph.System().Source(BinViewOptions::SystemOptions::sVelo);
    graph.NullDataValue(.12345e-19f);
    graph.InputSpan(2000);
    graph.ScalingEnabled(true);

    graph.Save();
}

//---------------------------------------------------------------------------
// ApplicationIo::WriteRom()
//---------------------------------------------------------------------------

void ApplicationIo::WriteRom()
{
    //  System Page Operations
    Module().IdRom().System().Name(Settings.ModuleName);
    Module().IdRom().System().Revision(Settings.ModuleRevision);
    Module().IdRom().System().Updated(true);  // T if data has been loaded

    Module().IdRom().System().StoreToRom();

    //  AdcCal Page Operations
    for (unsigned int ch = 0; ch < InputChannels(); ++ch)
        {
        Module().Input().Cal().Gain(ch, Settings.Rx.Gain[ch]);
        Module().Input().Cal().Offset(ch, Settings.Rx.Offset[ch]);
        }
    Module().Input().Cal().Calibrated(Settings.Rx.Calibrated);

    Module().IdRom().AdcCal().StoreToRom();
    //  DacCal Page Operations
    for (unsigned int ch = 0; ch < OutputChannels(); ++ch)
        {
        Module().Output().Cal().Gain(ch, Settings.Tx.Gain[ch]);
        Module().Output().Cal().Offset(ch, Settings.Tx.Offset[ch]);
        }
    Module().Output().Cal().Calibrated(Settings.Tx.Calibrated);

    Module().IdRom().DacCal().StoreToRom();
}

//---------------------------------------------------------------------------
// ApplicationIo::ReadRom()
//---------------------------------------------------------------------------

void ApplicationIo::ReadRom()
{
    //  System Page Operations
    Module().IdRom().System().LoadFromRom();

    Settings.ModuleName = Module().IdRom().System().Name();
    Settings.ModuleRevision = Module().IdRom().System().Revision();
    //  Can use 'Updated' to check if data valid
    
    Module().IdRom().AdcCal().LoadFromRom();
    for (unsigned int ch = 0; ch < InputChannels(); ++ch)
        {
        Settings.Rx.Gain[ch] = Module().Input().Cal().Gain(ch);
        Settings.Rx.Offset[ch] = Module().Input().Cal().Offset(ch);
        }

    Settings.Rx.Calibrated = Module().Input().Cal().Calibrated();

    // Dac
    Module().IdRom().DacCal().LoadFromRom();
    for (unsigned int ch = 0; ch < OutputChannels(); ++ch)
        {
        Settings.Tx.Gain[ch] = Module().Output().Cal().Gain(ch);
        Settings.Tx.Offset[ch] = Module().Output().Cal().Offset(ch);
        }

    Settings.Tx.Calibrated = Module().Output().Cal().Calibrated();
}

//---------------------------------------------------------------------------
// ApplicationIo::BlockRate() -- Return Tx block rate.
//---------------------------------------------------------------------------

double ApplicationIo::TxBlockRate() const
{  
    return FTxBlockRate;
}

//------------------------------------------------------------------------
// ApplicationIo::BlockCount() -- Returns Tx block count.
//------------------------------------------------------------------------

unsigned int ApplicationIo::TxBlockCount() const
{  
    return FTxBlockCount;
}
//---------------------------------------------------------------------------
// ApplicationIo::BlockRate() -- Return Rx block rate.
//---------------------------------------------------------------------------

double ApplicationIo::RxBlockRate() const
{  
    return FRxBlockRate;
}

//------------------------------------------------------------------------
// ApplicationIo::BlockCount() -- Returns Rx block count.
//------------------------------------------------------------------------

unsigned int ApplicationIo::RxBlockCount() const
{  
    return FRxBlockCount;
}

//---------------------------------------------------------------------------
//  ApplicationIo::DacInternalCal() --  Query DacInternalCal status
//---------------------------------------------------------------------------

bool ApplicationIo::DacInternalCal()
{
    return Module().Output().DacInternalCalibrationOk();
}

//---------------------------------------------------------------------------
//  ApplicationIo::Log() --  Log message thunked to main thread
//---------------------------------------------------------------------------

void  ApplicationIo::Log(const std::string & msg)
{
    ProcessStatusEvent e(msg);
    OnLog.Execute(e);
}

//---------------------------------------------------------------------------
//  ApplicationIo::SoftwareAlert() --  Issue specified software alert
//---------------------------------------------------------------------------

void ApplicationIo::SoftwareAlert(unsigned int value)
{
    Log(std::string("Posting SW alert..."));
    Module().Alerts().SoftwareAlert(value);
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//  Configuration Event Handlers
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

//---------------------------------------------------------------------------
//  ApplicationIo::HandleBeforeStreamStart() --  Pre-streaming init event
//---------------------------------------------------------------------------

void ApplicationIo::HandleBeforeStreamStart(OpenWire::NotifyEvent & /*Event*/)
{
}

//---------------------------------------------------------------------------
//  ApplicationIo::HandleAfterStreamStart() --  Post streaming init event
//---------------------------------------------------------------------------

void ApplicationIo::HandleAfterStreamStart(OpenWire::NotifyEvent & /*Event*/)
{
    Log(std::string("Analog I/O started"));

    Timer.Enabled(true);
}

//---------------------------------------------------------------------------
//  ApplicationIo::HandleAfterStreamStop() --  Post stream termination event
//---------------------------------------------------------------------------

void ApplicationIo::HandleAfterStreamStop(OpenWire::NotifyEvent & /*Event*/)
{
    // Disable external triggering initially
    Module.SetInputSoftwareTrigger(false);
    Module().Input().Trigger().External(false);

}

//---------------------------------------------------------------------------
//  ApplicationIo::HandleAfterStop() --  Post stream termination event
//---------------------------------------------------------------------------

void ApplicationIo::HandleAfterStop(OpenWire::NotifyEvent & /*Event*/)
{
    //
    //  Stop Loggers on active Channels
    if (Settings.Rx.LoggerEnable || Settings.Rx.PlotEnable)
        {
        Logger.Stop();
        InitBddFile(Graph);
        //
        //  Output Remaining Data
        VMP.Flush();
        VMPLogger.Stop();
        InitVMPBddFile(VMPGraph);
        
        if (Settings.Rx.MergeParseEnable==false)
            {
            if (Logger.Logged() && Settings.Rx.PlotEnable)
                Graph.Plot();
            }
        else
            {
            if (VMPLogger.Logged() && Settings.Rx.PlotEnable)
                VMPGraph.Plot();
            }
         }

    Player.Stop();

    UI->AfterStreamStop();

    Log(std::string("Analog I/O Stopped"));
}

//---------------------------------------------------------------------------
//  ApplicationIo::HandleOnLog() --
//---------------------------------------------------------------------------

void ApplicationIo::HandleOnLog(Innovative::ProcessStatusEvent & Event)
{
    UI->Log(Event.Message);
}

//---------------------------------------------------------------------------
//  ApplicationIo::HandleTimer() --  Per-second status timer event
//---------------------------------------------------------------------------

void ApplicationIo::HandleTimer(OpenWire::NotifyEvent & /*Event*/)
{
    // Display status
    UI->PeriodicStatus();

    Trig.AtTimerTick();
}

//---------------------------------------------------------------------------
//  ApplicationIo::HandleDisableTrigger() --  Trigger Manager Trig OFF
//------------------------------------------------------------------------------

void  ApplicationIo::HandleDisableTrigger(OpenWire::NotifyEvent & /*Event*/)
{
    Module().Output().Trigger().External(false);
    Module().Input().Trigger().External(false);
}

//---------------------------------------------------------------------------
//  ApplicationIo::HandleSoftwareTrigger() --  Trigger Manager Trig OFF
//------------------------------------------------------------------------------

void  ApplicationIo::HandleSoftwareTrigger(OpenWire::NotifyEvent & /*Event*/)
{
    if (Settings.Tx.ExternalTrigger == 0) 
        Module.SetOutputSoftwareTrigger(true);
    if (Settings.Rx.ExternalTrigger == 0) 
        Module.SetInputSoftwareTrigger(true);
}


//---------------------------------------------------------------------------
//  ApplicationIo::HandleExternalTrigger() --  Enable External trigger
//------------------------------------------------------------------------------

void  ApplicationIo::HandleExternalTrigger(OpenWire::NotifyEvent & /*Event*/)
{
	if (Settings.Rx.ExternalTrigger == 1)
		Module().Input().Trigger().External(true);
    if (Settings.Tx.ExternalTrigger == 1)
 		Module().Output().Trigger().External(true);
}

//---------------------------------------------------------------------------
//  ApplicationIo::ClockInfo() -- Dump clock info
//---------------------------------------------------------------------------

void  ApplicationIo::ClockInfo()
{

    Log("Clock output data");
    for (int i=0; i<10; i++)
        {
        std::stringstream msg;
        msg << std::hex << "Out # " << i << ": "
            << " Divider: "   << Module().RawClockDevice().Pll().OutputDivider(i)
            << ", Out Freq: " << Module().RawClockDevice().Pll().OutputFrequency(i)
            << ", Actual: "   << Module().RawClockDevice().Pll().OutputFrequencyActual(i) ;
        Log(msg.str());
        }
}

//---------------------------------------------------------------------------
//  ApplicationIo::FillLogs() -- Fill Busmaster Logs from trace info
//---------------------------------------------------------------------------

void  ApplicationIo::FillLogs()
{
    // Fill Logs vector from Log
    Module().Debug()->DumpLog(Settings.Log.LogData);

    //  Fill ISR vector
    Module().Debug()->DumpIsrStatus(Settings.Log.IsrStatusData);

}

//==============================================================================
//  CLASS ApplicationSettings
//==============================================================================
//------------------------------------------------------------------------------
//  ApplicationSettings::ApplicationSettings() --  Ctor, load from INI file
//------------------------------------------------------------------------------

ApplicationSettings::ApplicationSettings( ApplicationIo * owner )
    : AlertEnable(AnalogOutAlerts() + 2, false),TestFrequency(2), 
      Owner(owner)
{
    //  Board Settings
    Install( ToIni("Target",                    Target,          0)  );
    Install( ToIni("Rx.BMSize",                 Rx.BusmasterSize,   4)  );
    Install( ToIni("Tx.BMSize",                 Tx.BusmasterSize,   4)  );
    //Install( ToIni("LogicFailureTemperature",   LogicFailureTemperature,   85.0f)  );

    //  Config Data
    //  ..Clock
    Install( ToIni("ExtClockSrcSelection", ExtClockSrcSelection, 0)  );
    Install( ToIni("ReferenceClockSource", ReferenceClockSource, 1)  );
    Install( ToIni("ReferenceRate",        ReferenceRate,       10.0f)  );
    Install( ToIni("SampleClockSource",    SampleClockSource, 1)  );
    Install( ToIni("SampleRate",           SampleRate,  static_cast<float>(MaxOutRateMHz()))  );
    //  ..Trigger
    Install( ToIni("ExternalTrigger",        Tx.ExternalTrigger,     0)  );
    Install( ToIni("EdgeTrigger",            Tx.EdgeTrigger,         0)  );
    Install( ToIni("Framed",                 Tx.Framed,              0)  );
    Install( ToIni("FrameSize",              Tx.FrameSize,           0x4000)  );
    Install( ToIni("ExtTriggerSrcSelection", ExtTriggerSrcSelection, 0)  );
    Install( ToIni("Trigger Delay",          Tx.TriggerDelayPeriod,  1)  );
    //  ..Analog
    Install( ToIni("ActiveChannels", "Ch", Tx.ActiveChannels,    char(0) ));
    Install( ToIni("TestGenEnable",        Tx.TestGenEnable,   false)  );
    Install( ToIni("TestGenMode",          Tx.TestGenMode,         0)  );
    Install( ToIni("TestFrequency",        Tx.TestFrequencyMHz,    10.0) );
    Install( ToIni("AlertEnable", "Alert", AlertEnable,         char(0) ));
    Install( ToIni("DecimationEnable",     Tx.DecimationEnable,    false)  );
    Install( ToIni("DecimationFactor",     Tx.DecimationFactor,    1)  );
    Install( ToIni("Tx.PulseEnable",       Tx.Pulse.Enable,      false)  );
    Install( ToIni("Tx.PulsePeriod",       Tx.Pulse.Period,      10.0e6f)  );
    Install( ToIni("Tx.PulseDelay",        Tx.Pulse.Delay,       0.0f)  );
    Install( ToIni("Tx.PulseWidth",        Tx.Pulse.Width,       1.0e6f)  );
    Install( ToIni("Tx.Pulse2Delay",       Tx.Pulse.Delay2,      0.0f)  );
    Install( ToIni("Tx.Pulse2Width",       Tx.Pulse.Width2,      1.0e6f)  );
    //  ..PlayFromFile
    Install( ToIni("Tx.PlayFromFile.Enable",    Tx.PlayFromFile.Enable,     false)  );
    Install( ToIni("Tx.PlayFromFile.Filename",  Tx.PlayFromFile.Filename,   std::string("WaveFileIn.bin"))  );

    //  ..Streaming
    Install( ToIni("PacketSize",           Tx.PacketSize,        0x10000)  );
    Install( ToIni("AutoPreconfig",        AutoPreconfig,     true)  );

    //  ..Wave Generator
    Install( ToIni("WaveType",             Owner->Builder.Settings.WaveType,             1) );
    Install( ToIni("WaveformFrequency",    Owner->Builder.Settings.WaveformFrequency,    1.0f) );
    Install( ToIni("WaveformAmplitude",    Owner->Builder.Settings.WaveformAmplitude,    95.0f) );
    Install( ToIni("WaveFile",             Owner->Builder.Settings.WaveFile,             std::string("")) );
    Install( ToIni("TwoToneMode",          Owner->Builder.Settings.TwoToneMode,          false) );
    Install( ToIni("TwoToneFrequency",     Owner->Builder.Settings.TwoToneFrequency,     1.01f) );
    Install( ToIni("SingleChannelMode",    Owner->Builder.Settings.SingleChannelMode,    false) );
    Install( ToIni("SingleChannelChannel", Owner->Builder.Settings.SingleChannelChannel, 0) );
    //  ..Other
    Install( ToIni("Debug Script",         DebugScript,  std::string("")) );
    Install( ToIni("DebugVerbosity",       DebugVerbosity,  5) );   // vNormal

    // Rx
    Install( ToIni("Rx.ExternalTrigger",        Rx.ExternalTrigger,             0)  );
    Install( ToIni("Rx.EdgeTrigger",            Rx.EdgeTrigger,                 0)  );
    Install( ToIni("Rx.Framed",                 Rx.Framed,                      0)  );
    Install( ToIni("Rx.FrameSize",              Rx.FrameSize,                   0x4000)  );
    Install( ToIni("Rx.PulseEnable",            Rx.Pulse.Enable,                false)  );
    Install( ToIni("Rx.PulsePeriod",            Rx.Pulse.Period,                10.0e6f)  );
    Install( ToIni("Rx.PulseDelay",             Rx.Pulse.Delay,                 0.0f)  );
    Install( ToIni("Rx.PulseWidth",             Rx.Pulse.Width,                 1.0e6f)  );
    Install( ToIni("Rx.Pulse2Delay",            Rx.Pulse.Delay2,                0.0f)  );
    Install( ToIni("Rx.Pulse2Width",            Rx.Pulse.Width2,                1.0e6f)  );
    Install( ToIni("Rx.TriggerDelay",           Rx.TriggerDelayPeriod,          1)  );
    Install( ToIni("Rx.DecimationEnable",       Rx.DecimationEnable,            false)  );
    Install( ToIni("Rx.DecimationFactor",       Rx.DecimationFactor,            1)  );
    Install( ToIni("Rx.ActiveChannels", "Ch",   Rx.ActiveChannels,              char(0) ));
    Install( ToIni("Rx.PacketSize",             Rx.PacketSize,                  0x10000)  );
    Install( ToIni("Rx.ForceSize",              Rx.ForceSize,                   false)  );
    Install( ToIni("Rx.TestGenEnable",          Rx.TestCounterEnable,           false)  );
    Install( ToIni("Rx.TestGenMode",            Rx.TestGenMode,                 0)  );
    Install( ToIni("Rx.MergeParseEnable",       Rx.MergeParseEnable,            false)  );
    Install( ToIni("Rx.MergePacketSize",        Rx.MergePacketSize,             0x10000u)  );

	//  Streaming
    Install( ToIni("Rx.LoggerEnable",           Rx.LoggerEnable,                true)  );
    Install( ToIni("Rx.PlotEnable",             Rx.PlotEnable,                  true)  );
    Install( ToIni("Rx.OverwriteBdd",           Rx.OverwriteBdd,                true)  );
    Install( ToIni("Rx.SamplesToLog",           Rx.SamplesToLog,                100000u)  );
    Install( ToIni("Rx.AutoStop",               Rx.AutoStop,                    true)  );

    Load();
    //
    //  Sanity Check on Target
    if (Target < 0)
        Target = 0;

}

//------------------------------------------------------------------------
//  ApplicationSettings::~ApplicationSettings() --  Dtor, save to INI file
//------------------------------------------------------------------------

ApplicationSettings::~ApplicationSettings()
{
    //
    //  Sanity Check on Target
    if (Target < 0)
        Target = 0;

    Save();
}
