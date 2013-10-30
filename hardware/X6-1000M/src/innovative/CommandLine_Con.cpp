// CommandLine_Mb.cpp
//
//    INNOVATIVE INTEGRATION CORPORATION PROPRIETARY INFORMATION
//  This software is supplied under the terms of a license agreement or nondisclosure
//  agreement with Innovative Integration Corporation and may not be copied or
//  disclosed except in accordance with the terms of that agreement.
//  Copyright (c) 2000..2005 Innovative Integration Corporation.
//  All Rights Reserved.
//

#include "CommandLine_Con.h"

namespace   Innovative
{

//=============================================================================
//  Framework-specific retrieval of OS command-line
//=============================================================================

static CommandLineArguments * ConsoleArgs = 0;

//---------------------------------------------------------------------------
//  GetCommandLineArguments() --  Get app arguments from anywhere
//---------------------------------------------------------------------------

CommandLineArguments GetCommandLineArguments()
{
    if (!ConsoleArgs)
        {
        ConsoleArgs = new CommandLineArguments;
        ConsoleArgs->Add(const_cast<char*>("Application"));
        }

    //CommandLineArguments * a = new CommandLineArguments;

    //*a = *ConsoleArgs;

    return *ConsoleArgs;
}

//---------------------------------------------------------------------------
//  SetCommandLineArguments() --  Set app arguments from within main()
//---------------------------------------------------------------------------

void SetCommandLineArguments(int argc, char* argv[])
{
    delete ConsoleArgs;
    ConsoleArgs = new CommandLineArguments;

    for (int i = 0; i < argc; ++i)
        ConsoleArgs->Add(argv[i]);
}


}  // namespace
