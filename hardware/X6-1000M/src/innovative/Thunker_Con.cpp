// Thunker_Con.cpp
//
//    INNOVATIVE INTEGRATION CORPORATION PROPRIETARY INFORMATION
//  This software is supplied under the terms of a license agreement or nondisclosure
//  agreement with Innovative Integration Corporation and may not be copied or
//  disclosed except in accordance with the terms of that agreement.
//  Copyright (c) 2000..2005 Innovative Integration Corporation.
//  All Rights Reserved.
//

#include <string>
#include "Thunker_Con.h"
#include <Events_Mb.h>

namespace  Innovative
{

Event Thunker::MainLoopEvent(false, false); 
ThreadSafeQueue<Thunker *> Thunker::MainLoopQueue; 

//=============================================================================
//  CLASS Thunker  --  "Thunk" call into main thread, unlocked with caller
//=============================================================================

//---------------------------------------------------------------------------
//  constructor for class Thunker
//---------------------------------------------------------------------------

Thunker::Thunker()
{

}

//---------------------------------------------------------------------------
//  destructor for class Thunker
//---------------------------------------------------------------------------

Thunker::~Thunker()
{
}

//---------------------------------------------------------------------------
//  Thunker::Notify() --
//---------------------------------------------------------------------------

bool Thunker::Notify()
{
  if (!OnNotified.Assigned()) 
  return false; 

  if(InnovativeKernel::CurrentThreadId() == OpenWire::GetMainThreadId()) 
    { 
      // We are in the main thread, so execute and exit. 
      Dispatch(); 
      return false; 
    } 

  MainLoopQueue.push(this); 
  MainLoopEvent.Set(); 
  return true; 
}

//---------------------------------------------------------------------------
//  Thunker::Dispatch() --
//---------------------------------------------------------------------------

void Thunker::Dispatch()
{
	OpenWire::Event e;
    OnNotified.Execute(e);
}

//---------------------------------------------------------------------------
//  Thunker::CanThunk() --
//---------------------------------------------------------------------------

bool Thunker::CanThunk()
{
    return true;
}

//=============================================================================
//  Thunker Factory Methods
//=============================================================================

//---------------------------------------------------------------------------
//  NewThunker() --
//---------------------------------------------------------------------------

ThunkerIntf * NewThunker()
{
    return new Thunker;
}

//---------------------------------------------------------------------------
//  DeleteThunker() --
//---------------------------------------------------------------------------

void DeleteThunker ( ThunkerIntf * thunker )
{
    delete thunker;
}


}  // namespace
