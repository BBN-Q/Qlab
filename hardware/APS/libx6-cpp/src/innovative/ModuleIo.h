// ModuleIo.h
//
// Board-specific module operations

#ifndef ModuleIoH
#define ModuleIoH

#include <X6_1000M_Mb.h>
#include <Ficl/FiclSystem_Mb.h>
#include <DataLogger_Mb.h>
#include <BinView_Mb.h>

//===========================================================================
//  Information Functions
//===========================================================================
//  NOTE - these are often used in constructors so cannot depend on objects
//         without due care taken
//
//   General Info
inline std::string ModuleNameStr()
            {  return  "X6-1000M PCIe Module";  }

//
//   Analog Out Info

inline int    AnalogOutChannels()
        {  return 4;  }
inline int    AnalogOutAlerts()
          {  return 5;  }
inline float  MaxOutRateMHz()
          {  return 1000.0;  }     // In MHz
//
//   Analog In Info
inline int    AnalogInChannels()
          {  return 2;  }
inline int    AnalogInAlerts()
          {  return 6;  }
inline float  MaxInRateMHz()
          {  return 1000.0;  }     // In MHz

//
//   Application Feature Presence  -- used to hide GUI Portions

inline bool   HasClockMux()
        {  return true; }
inline bool   HasProgrammableReference()
        {  return true; }
inline bool   HasTestModeControl()
        {  return true; }
inline bool   HasFiclSupport()
        {  return true; }
inline bool   HasLowSpeedAnalogIn()
        {  return true; }
inline bool   HasExtClockSrcSelectMux()
        {  return true; }
inline bool   HasExtTriggerSrcSelectMux()
        {  return true; }
inline bool   HasPulseTrigger()
        {  return true; }


typedef std::vector<std::string> StringArray;
StringArray  ExtClockSrcSelectStrings();
StringArray  ExtTriggerSrcSelectStrings();
StringArray  TxTestModeStrings();
StringArray  RxTestModeStrings();

StringArray  AlertStrings();

//===========================================================================
//  CLASS ModuleIo  -- Hardware Access and Application Io Class
//===========================================================================

class ModuleIo
{
public:
    ModuleIo();
    ~ModuleIo();

    //  Module Aliases
    Innovative::X6_1000M & operator() ()
        {  return Module;  }
    Innovative::X6_1000M & Ref()
        {  return Module;  }
    Innovative::IFiclTarget *  FiclTarget()
            {   return &Module;  }

    OpenWire::ThunkedEventHandler<Innovative::ProcessStatusEvent>  OnLog;

    //
    //  App System Methods
    void  FiclConnectTo(Innovative::FiclSystem & ficl);
    std::string Help() const;

    //
    //  Module Methods
    void  HookAlerts();

    void  ConfigureGraphs(unsigned int idx,
                          Innovative::DataLogger & logr, Innovative::BinView & bv);

    void  ConfigureAlerts(std::vector<char> & AlertEnable);
    void  SetInputPacketDataSize(unsigned int size);
    void  SetInputSoftwareTrigger(bool state);

    void  SetOutputPacketDataSize(unsigned int size);
    void  SetOutputSoftwareTrigger(bool state);

    void  SetOutputTestConfiguration( bool enable, int mode_idx );
    void  SetInputTestConfiguration( bool enable, int mode_idx );

    void  DacTestStatus();
    void  ClearDacTestStatus();
    typedef std::vector<float> PulseSettingArray;
    void  SetInputPulseTriggerConfiguration(bool enable, float period, const std::vector<float> &delay, const std::vector<float> &width );
    void  SetOutputPulseTriggerConfiguration(bool enable, float period, const std::vector<float> &delay, const std::vector<float> &width );

    void PreOpen();

    std::vector<int>   VitaStreamIdVector();
    std::vector<int>   AllInputVitaStreamIdVector();
    
protected:
    void  Log(const std::string & msg);

private:
	Innovative::X6_1000M  Module;

    void  HandleTimestampRolloverAlert(Innovative::AlertSignalEvent & event);
    void  HandleSoftwareAlert(Innovative::AlertSignalEvent & event);
    void  HandleWarningTempAlert(Innovative::AlertSignalEvent & event);
    void  HandleInputFifoOverrunAlert(Innovative::AlertSignalEvent & event);
    void  HandleInputOverrangeAlert(Innovative::AlertSignalEvent & event);
    void  HandleOutputFifoUnderflowAlert(Innovative::AlertSignalEvent & event);
    void  HandleTriggerAlert(Innovative::AlertSignalEvent & event);
    void  HandleOutputOverrangeAlert(Innovative::AlertSignalEvent & event);

    std::string Elapsed(size_t timestamp);
        
};
#endif
