//---------------------------------------------------------------------------

#ifndef TriggerManager_AppH
#define TriggerManager_AppH

#include <Events_Mb.h>

//---------------------------------------------------------------------------
namespace Innovative
{
//===========================================================================
// CLASS ManualTriggerEvent  --  Event fired when manually triggers
//===========================================================================

class ManualTriggerEvent : public OpenWire::Event
{
public:
    bool State;

public:
    ManualTriggerEvent( bool state )
        :  State( state )
        {
        }
};

//==============================================================================
//  CLASS TriggerManager -- class to manage Software Trigger
//==============================================================================

class TriggerManager
{
public:
    TriggerManager();
    ~TriggerManager();

    void  ExternalTrigger(bool et_state)
            {  FExternalTrigger = et_state;  }
    void  DelayedTrigger(bool dt_state)
            {  FDelayedTrigger = dt_state;  }
    void  DelayedTriggerPeriod(unsigned int seconds)
            {  FTriggerDelaySeconds = seconds;  }
    void  MultiTrigger(bool mt_state)
            {  FMultiTrigger = mt_state;  }
    void  ManualTrigger(bool mt_state)
            {  FManualTrigger = mt_state;  }
    void  RetriggerCount(unsigned int count)
            {  FRetriggerCount = count;  }

    void  AtConfigure();
    void  AtStreamStart();
    void  AtTimerTick();
    void  AtBlockProcess(unsigned int data_size_ints = 1);
    void  AtStreamStop();

    void  Trigger(bool state);                  // Set "Manual" trigger
    void  ActivateExternalTrigger(bool state);  // Set "External" trigger state
    void  SetActiveTrigger(bool state);         // Set the trigger in use now

    OpenWire::EventHandler<OpenWire::NotifyEvent>  OnSoftwareTrigger;
    OpenWire::EventHandler<OpenWire::NotifyEvent>  OnDisableTrigger;
    OpenWire::EventHandler<OpenWire::NotifyEvent>  OnExternalTrigger;
    OpenWire::EventHandler<ManualTriggerEvent>     OnManualTrigger;

private:
    bool         FTriggered;
    bool         FDelayedTrigger;
    bool         FExternalTrigger;
    bool         FMultiTrigger;
    bool         FManualTrigger;
    unsigned int FRetriggerCount;
    unsigned int FCount;
    unsigned int FTriggerDelaySeconds;
    unsigned int DelaySeconds;

    void  Init();
};


}
#endif
