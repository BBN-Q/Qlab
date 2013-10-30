// Thunker_Con.h
//
//    INNOVATIVE INTEGRATION CORPORATION PROPRIETARY INFORMATION
//  This software is supplied under the terms of a license agreement or nondisclosure
//  agreement with Innovative Integration Corporation and may not be copied or
//  disclosed except in accordance with the terms of that agreement.
//  Copyright (c) 2000..2005 Innovative Integration Corporation.
//  All Rights Reserved.
//

#ifndef Thunker_QtH
#define Thunker_QtH

//#include <string>
#include <ThunkerIntf_Mb.h>
#include <Event_Mb.h>
#include <ThreadSafeQueue_Mb.h> 

namespace Innovative
{

//=============================================================================
//  CLASS Thunker  --  "Thunk" call into UI thread, unlocked with caller
//=============================================================================

class Thunker : public ThunkerIntf
{
public:
    // Ctor
    Thunker();
    virtual ~Thunker();

    static Event MainLoopEvent; 
   	static ThreadSafeQueue<Thunker *> MainLoopQueue; 

    // Methods
    virtual bool    Notify();
    virtual void    Dispatch();
    virtual bool    CanThunk();

};

	
} // Innovative

#endif

