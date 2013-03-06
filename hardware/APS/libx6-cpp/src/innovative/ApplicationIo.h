// ApplicationIo.h
//
//  Board-specific software layer
//
//

#ifndef ApplicationIoH
#define ApplicationIoH

#include "ModuleIo.h"
#include <ProcessEvents_Mb.h>
#include <VitaPacketStream_Mb.h>
#include <BinView_Mb.h>
#include <Benchmark_Mb.h>
#include <SoftwareTimer_Mb.h>
#include <DataPlayer_Mb.h>

#include <Application/FiclIo_App.h>
#include <Application/IniSaver_App.h>
#include <Application/TriggerManager_App.h>
#include <Application/StaticWaveform_App.h>
#include <Application/BinviewPlotter_App.h>


class ApplicationIo;
    
typedef std::vector<char>   BoolArray;
typedef std::vector<float>  FloatArray;

////////////
//  Struct PulseD
////////////   
struct PulseD
{
    bool   Enable;
    float  Period;
    float  Delay;
    float  Width;
    float  Delay2;
    float  Width2;
};

//==============================================================================
//  CLASS RxSettings
//==============================================================================
struct RxSettings
{
    RxSettings() : ActiveChannels(AnalogInChannels()),
      Gain(AnalogInChannels()), Offset(AnalogInChannels())
    {}

    int             BusmasterSize;

    //  Trigger
    int             ExternalTrigger;
    int             EdgeTrigger;
    int             Framed;
    int             FrameSize;
	int             TriggerDelayPeriod;
    PulseD          Pulse;
    BoolArray       ActiveChannels;
    bool            DecimationEnable;
    int             DecimationFactor;

    //  Streaming
	int             PacketSize;
    bool            ForceSize;
    // Testing
    bool            TestCounterEnable;
    int             TestGenMode;
    //  Logging
    bool            LoggerEnable;
    bool            PlotEnable;
    bool            MergeParseEnable;
    unsigned int    SamplesToLog;
    bool            OverwriteBdd;
    bool            AutoStop;
    unsigned int    MergePacketSize;
    //
    //  Not saved in INI file
    //  ..Eeprom
    FloatArray      Gain;
    FloatArray      Offset;
    bool            Calibrated;
};

////////////
//  Struct PlayFromFileD
////////////
struct PlayFromFileD
{
    bool         Enable;
    std::string  Filename;
};

//==============================================================================
//  CLASS TxSettings
//==============================================================================
struct TxSettings
{
    TxSettings() : ActiveChannels(AnalogOutChannels()),
      Gain(AnalogOutChannels()), Offset(AnalogOutChannels())
    {}

    int             BusmasterSize;

    //  Trigger
    int             ExternalTrigger;
    int             EdgeTrigger;
    int             Framed;
    int             FrameSize;
	int             TriggerDelayPeriod;
    PulseD          Pulse;
    BoolArray       ActiveChannels;
    bool            DecimationEnable;
    int             DecimationFactor;

    bool            TestGenEnable;
    int             TestGenMode;
    double          TestFrequencyMHz;
    //  Streaming
	int             PacketSize;
    PlayFromFileD   PlayFromFile;

    //
    //  Not saved in INI file
    //  ..Eeprom
    FloatArray      Gain;
    FloatArray      Offset;
    bool            Calibrated;
};

//==============================================================================
//  CLASS ApplicationSettings
//==============================================================================

class ApplicationSettings : public Innovative::IniSaver
{
public:

    typedef std::vector<int>    IntArray;
    

    // Ctor
    ApplicationSettings( ApplicationIo * owner );
    ~ApplicationSettings();

    //
    //  Board Settings
    int             Target;


    //  Config Data
    //  Clock
    int             ExtClockSrcSelection;
    int             ReferenceClockSource;
    float           ReferenceRate;
    int             SampleClockSource;
    float           SampleRate;

    int             ExtTriggerSrcSelection;

    //  Analog
    BoolArray       AlertEnable;
    bool            AutoPreconfig;

    //  Log Page Data
    //  Eeprom
    //  Wave Gen
    int             WaveType;
	float 			WaveformFrequency;
	float 			WaveformAmplitude;
    std::string     WaveFile;
	FloatArray		TestFrequency;
    //  Other
    std::string     DebugScript;

    // Data
    int             DebugVerbosity;

    //  Debug Log Page Data
    struct LogD
    {
        std::vector<int> LogData;
        std::vector<int> IsrStatusData;
        std::vector<int> VppData;
    };

    LogD    Log;
    //
    //  Not saved in INI file
    //  ..Eeprom
    std::string     ModuleName;
    std::string     ModuleRevision;
    
    RxSettings      Rx;
    TxSettings      Tx;
private:

    ApplicationIo *   Owner;
};


//===========================================================================
//  CLASS IUserInteface  -- Interface for callbacks to UI from App Logic
//===========================================================================

class IUserInterface : public IFicl_UserInterface
{
public:
    virtual ~IUserInterface()  {  }
    virtual void  Log(const std::string & a_string) = 0;
    virtual void  GetSettings() = 0;
    virtual void  SetSettings() = 0;
    virtual void  AfterStreamStop() = 0;
    virtual void  PeriodicStatus() = 0;
};

//===========================================================================
//  CLASS ApplicationIo  -- Hardware Access and Application Io Class
//===========================================================================

class ApplicationIo : public FiclIo
{
public:
    // Ctor
    ApplicationIo(IUserInterface * gui);
    ~ApplicationIo();

    ModuleIo &  ModIo()   {  return Module;  }

    // Methods
    unsigned int    BoardCount();

    void            Open();
    bool            IsOpen()  {  return FOpened;  }
    void            Close();
	void            StreamPreconfigure();
	bool            StartStreaming();
    void            StopStreaming();
    bool            IsStreaming()   {  return Timer.Enabled();  }

    void            WriteRom();
    void            ReadRom();

    double          TxBlockRate() const;
    unsigned int    TxBlockCount() const;
    double          RxBlockRate() const;
    unsigned int    RxBlockCount() const;

    unsigned int     OutputChannels() const        {  return AnalogOutChannels();  }
    unsigned int     InputChannels() const         {  return AnalogInChannels();  }

    void    DacTestStatus()                        {  Module.DacTestStatus();   }
    void    ClearDacTestStatus()                   {  Module.ClearDacTestStatus();   }

    float   Temperature();
    bool    PllLocked();
    bool    DacInternalCal();

    //  ...Debug page
    void    SoftwareAlert(unsigned int value);
    float SampleRate() const
        {  return static_cast<float>(Settings.SampleRate*1.e6);  }
    void    ExecuteDebugScript(const std::string & cmd)
        {  Execute(std::string("load ") + cmd);  }
    void    Help()
        {  Execute(Module.Help());  }

    void    ClockInfo();
    void    FillLogs();
    unsigned int ExtractXPak(unsigned int isr_status)
        {   return (isr_status>>4)&0x3F;   }
    unsigned int ExtractRPak(unsigned int isr_status)
        {   return (isr_status>>10)&0x3F;   }

public:  // Pseudo-protected
    // Data
    Innovative::VitaWaveBuilder     Builder;
	ApplicationSettings             Settings;

private:
    //
    //  Member Data
	ModuleIo                        Module;
	IUserInterface *                UI;
    Innovative::VitaPacketStream    Stream;
	Innovative::TriggerManager      Trig;
	Innovative::SoftwareTimer       Timer;
    Innovative::DataLogger          Logger;
    Innovative::BinView             Graph;
    Innovative::StopWatch           RunTimeSW;
    Innovative::VeloMergeParser     VMP;       // coalesce VITA packets
    Innovative::DataLogger          VMPLogger;
    Innovative::BinView             VMPGraph;

    Innovative::DataPlayer          Player;   // for "Play From File" mode
 
    // App State Variables
	bool                            FOpened;
	bool                            FStreamConnected;
    bool                            Stopped;
    int                             PrefillPacketCount;

	Innovative::VeloBuffer          WaveformPacket;
    // App Status Variables
	Innovative::AveragedRate        RxTime;
    Innovative::AveragedRate        RxBytesPerBlock;


	Innovative::AveragedRate        TxTime;
    Innovative::AveragedRate        TxBytesPerBlock;


    double                          FTxBlockRate;
    double                          FRxBlockRate;
    int                             FTxBlockCount;
    int                             FRxBlockCount;

    ii64                            FWordCount;
    int                             SamplesPerWord;
    ii64                            WordsToLog;
    int                             VMP_VeloCount;

protected:

    void  HandleDataRequired(Innovative::VitaPacketStreamDataEvent & Event);
    void  HandleDataAvailable(Innovative::VitaPacketStreamDataEvent & Event);

	void  HandleBeforeStreamStart(OpenWire::NotifyEvent & Event);
    void  HandleAfterStreamStart(OpenWire::NotifyEvent & Event);
    void  HandleAfterStreamStop(OpenWire::NotifyEvent & Event);

    void  HandleAfterStop(OpenWire::NotifyEvent & Event);

    void  HandleOnLog(Innovative::ProcessStatusEvent & Event);

    void  HandleTimer(OpenWire::NotifyEvent & Event);

    void  HandleDisableTrigger(OpenWire::NotifyEvent & Event);
	void  HandleExternalTrigger(OpenWire::NotifyEvent & Event);
    void  HandleSoftwareTrigger(OpenWire::NotifyEvent & Event);
    
    void  VMPDataAvailable(Innovative::VeloMergeParserDataAvailable & Event);

    void  Log(const std::string & msg);

    OpenWire::ThunkedEventHandler<Innovative::ProcessStatusEvent>  OnLog;

    void  SendOneBlock(Innovative::VitaPacketStream * PS);

	void  FillWaveformBuffer();
    bool  IsDataLoggingCompleted();
    void  InitBddFile(Innovative::BinView & graph);
    void  InitVMPBddFile(Innovative::BinView & graph);
	void  DisplayLogicVersion();
    void  TallyBlock(size_t bytes);
};
#endif
