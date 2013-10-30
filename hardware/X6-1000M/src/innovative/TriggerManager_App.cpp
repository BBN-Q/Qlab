//---------------------------------------------------------------------------

#include "TriggerManager_App.h"

namespace Innovative
{
//==============================================================================
//  CLASS TriggerManager -- class to manage Software Trigger
//==============================================================================
//------------------------------------------------------------------------------
//  constructor for class TriggerManager -- 
//------------------------------------------------------------------------------

TriggerManager::TriggerManager()
    :  FTriggered(false), FDelayedTrigger(false), FExternalTrigger(false),
	   FMultiTrigger(false), FManualTrigger(false), FRetriggerCount(0), FCount(0),
       FTriggerDelaySeconds(1), DelaySeconds(0) 
{

}

//------------------------------------------------------------------------------
//  destructor for class TriggerManager -- 
//------------------------------------------------------------------------------

TriggerManager::~TriggerManager()
{
}

//------------------------------------------------------------------------------
//  TriggerManager::Init() -- Start of run initialization
//------------------------------------------------------------------------------

void  TriggerManager::Init()
{
    FTriggered = false;
    FCount = 0;
    DelaySeconds = FTriggerDelaySeconds;
}

//------------------------------------------------------------------------------
//  TriggerManager::AtConfigure() -- Operations at configuration time
//------------------------------------------------------------------------------

void  TriggerManager::AtConfigure()
{
    Init();
	
	// Disable trigger now
    OpenWire::NotifyEvent e;
    OnDisableTrigger.Execute(e);
}

//------------------------------------------------------------------------------
//  TriggerManager::AtStreamStart() -- Operations at start of stream
//------------------------------------------------------------------------------

void  TriggerManager::AtStreamStart()
{
    Init();

    if (FDelayedTrigger || FManualTrigger)
        return;
    //
    //  If we don't delay trigger, trigger at once
    if (FExternalTrigger==false)
        {
        OpenWire::NotifyEvent e;        
        OnSoftwareTrigger.Execute(e);
        }
	else 
		{
        OpenWire::NotifyEvent e;        
        OnExternalTrigger.Execute(e);
		}
}

//------------------------------------------------------------------------------
//  TriggerManager::AtTimerTick() -- Delayed Trigger 'first time' trigger
//------------------------------------------------------------------------------

void  TriggerManager::AtTimerTick()
{
    if (FManualTrigger)
        return;

    if (FDelayedTrigger && FTriggered==false)
        {
        if (DelaySeconds)
            --DelaySeconds;

        if (DelaySeconds != 0)   // If still in delay, move on
            return;

        FTriggered = true;
        if (FExternalTrigger==false)
            {
            OpenWire::NotifyEvent e;
            OnSoftwareTrigger.Execute(e);
            }
		else
			{
			OpenWire::NotifyEvent e;        
			OnExternalTrigger.Execute(e);
			}
        }
}

//------------------------------------------------------------------------------
//  TriggerManager::AtBlockProcess() -- Multi-Trigger 'Retrigger' activator
//------------------------------------------------------------------------------

void  TriggerManager::AtBlockProcess(unsigned int data_size_ints)
{
    if (FMultiTrigger==false)
        return;

    FCount += data_size_ints;
    if (FCount>=FRetriggerCount)
        {
        FCount=0;
        if (FExternalTrigger==false)
            {
            OpenWire::NotifyEvent e;
            OnSoftwareTrigger.Execute(e);
            }
        }
}

//------------------------------------------------------------------------------
//  TriggerManager::AtStreamStop() -- Stream Stop 'disable trigger' action
//------------------------------------------------------------------------------

void  TriggerManager::AtStreamStop()
{
    OpenWire::NotifyEvent e;
    OnDisableTrigger.Execute(e);
}

//------------------------------------------------------------------------------
//  TriggerManager::Trigger() -- Manual triggering
//------------------------------------------------------------------------------

void  TriggerManager::Trigger(bool state)
{
    ManualTriggerEvent e(state);        
    OnManualTrigger.Execute(e);
}

//------------------------------------------------------------------------------
//  TriggerManager::ActivateExternalTrigger() --
//------------------------------------------------------------------------------

void  TriggerManager::ActivateExternalTrigger(bool state)
{
    if (FExternalTrigger==false)
        return;

    if (state)
        {
        OpenWire::NotifyEvent e;
	    OnExternalTrigger.Execute(e);
        }
    else
        {
        OpenWire::NotifyEvent e;
        OnDisableTrigger.Execute(e);
        }
}

//------------------------------------------------------------------------------
//  TriggerManager::SetActiveTrigger() --  Set the trigger in use right now
//------------------------------------------------------------------------------

void  TriggerManager::SetActiveTrigger(bool state)
{
    if (FExternalTrigger)
        {
        ActivateExternalTrigger(state);
        }
    else
        {
        Trigger(state);
        }
}


}


