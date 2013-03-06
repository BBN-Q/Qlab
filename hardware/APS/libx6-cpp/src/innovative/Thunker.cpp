// Innovative Integration Thinker example taken from
// http://www.innovative-dsp.com/forum/viewtopic.php?t=653&highlight=newthunker
// Thunker for console application

#include <ThunkerIntf_Mb.h>
#include <CommandLineIntf_Mb.h>
#include <SystemSupport_Mb.h>

using namespace std;
using namespace Innovative;

namespace   Innovative
{
//
class Thunker : public ThunkerIntf
{
    friend class Dispatcher;

public:
    // Ctor
    Thunker(){};
    virtual ~Thunker(){};
   
    // Methods
    virtual bool    Notify(){return true;};
    virtual void    Dispatch(){};

private:
   //Dispatcher      Messenger;
};

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

void DeleteThunker(ThunkerIntf * thunker)
{ 
    delete thunker;
}

CommandLineArguments GetCommandLineArguments()
{
   return CommandLineArguments();
}

} //namespace Innovative 