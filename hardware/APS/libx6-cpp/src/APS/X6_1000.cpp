#include "X6_1000.h"

// default constructor
X6_1000::X6_1000() {
	int numBoards = getBoardCount();

	deviceID_ = 0;

	isOpened_ = false;
	
}

X6_1000::~X6_1000()
{
	if (isOpened_)	Close();   
}

int X6_1000::set_deviceID(unsigned int deviceID) {
	if (!isOpened_)
		deviceID_ = deviceID;
	else
		return MODULE_ERROR;
}


unsigned int  X6_1000::getBoardCount() {
	return static_cast<unsigned int>(module_.BoardCount());
}

void X6_1000::get_device_serials(vector<string> & deviceSerials) {
	deviceSerials.clear();

	int numBoards = getBoardCount();

	// TODO: Identify a way to get serial number from X6 board if possible otherwise get slot id etc
	for (int cnt = 0; cnt < numBoards; cnt++) {

		// SNAFU work around for compiler on MQCO11 reporting that to_string is not part of std
		std::stringstream out;
		out << "S" << cnt;

		deviceSerials.push_back(out.str());
	}
}

 bool X6_1000::isOpen() {
 	return isOpened_;
 }

 int X6_1000::Open() {
 	// open function based on Innovative Stream Example ApplicationIO.cpp


 	// TODO: Setup Event Handlers

 	//Trig.OnDisableTrigger.SetEvent(this, &ApplicationIo::HandleDisableTrigger);
    //Trig.OnExternalTrigger.SetEvent(this, &ApplicationIo::HandleExternalTrigger);
    //Trig.OnSoftwareTrigger.SetEvent(this, &ApplicationIo::HandleSoftwareTrigger);
    //Trig.DelayedTrigger(true); // trigger delayed after start
    
    
    //  TODO Set Module Event Handlers
    // Module().OnBeforeStreamStart.SetEvent(this, &ApplicationIo::HandleBeforeStreamStart);
    // Module().OnBeforeStreamStart.Synchronize();
    // Module().OnAfterStreamStart.SetEvent(this, &ApplicationIo::HandleAfterStreamStart);
    // Module().OnAfterStreamStart.Synchronize();
    // Module().OnAfterStreamStop.SetEvent(this, &ApplicationIo::HandleAfterStreamStop);
    // Module().OnAfterStreamStop.Synchronize();

    //
    //  Alerts
    //Module.HookAlerts();

    //
    //  Configure Stream Event Handlers
    // Stream.OnVeloDataRequired.SetEvent(this, &ApplicationIo::HandleDataRequired);
    // Stream.DirectDataMode(false);
    // Stream.OnVeloDataAvailable.SetEvent(this, &ApplicationIo::HandleDataAvailable);

    // Stream.OnAfterStop.SetEvent(this, &ApplicationIo::HandleAfterStop);
    // Stream.OnAfterStop.Synchronize();

    //Stream.RxLoadBalancing(false);
    //Stream.TxLoadBalancing(false);

    // Timer.OnElapsed.SetEvent(this, &ApplicationIo::HandleTimer);
    // Timer.OnElapsed.Thunk();

    // Insure BM size is a multiple of four MB
    const int Meg = 1024 * 1024;
    const int RxBmSize = std::max(BusmasterSize/4, 1) * 4;
    const int TxBmSize = std::max(BusmasterSize/4, 1) * 4;
    module_.IncomingBusMasterSize(RxBmSize * Meg);
    module_.OutgoingBusMasterSize(TxBmSize * Meg);
    //module_.Target(Settings.Target);

   try
        {

        module_.Open();

        //FILE_LOG(logINFO) << << "Bus master size: Input => " << RxBmSize << " MB" << " Output => " << TxBmSize << " MB";
        }
    //catch (Innovative::MalibuException & exception)
    //    {
    //    FILE_LOG(logINFO) << "Open Failure:" << exception.what();
    //    return;
    //    }
    catch(...)
        {
        FILE_LOG(logINFO) << "Module Device Open Failure!";
        return MODULE_ERROR;
        }
        
    module_.Reset();
    FILE_LOG(logINFO) << "Module Device Opened Successfully...";
    isOpened_ = true;

    //
    //  Connect Stream
    //Stream.ConnectTo(&(Module.Ref()));
    //FStreamConnected = true;
    //FILE_LOG(logINFO) << "Stream Connected..." << endl;

    //PrefillPacketCount = Stream.PrefillPacketCount();
    
    //
    //  Initialize VeloMergeParse
    //VMP.OnDataAvailable.SetEvent(this, &ApplicationIo::VMPDataAvailable);
    //std::vector<int> sids = Module.AllInputVitaStreamIdVector();
    //VMP.Init( sids );

    //DisplayLogicVersion();
    return SUCCESS;
 }

 
int X6_1000::Close() {

	//Stream.Disconnect();
module_.Close();

isOpened_ = true;

FILE_LOG(logINFO) << "Stream Disconnected...";

	return SUCCESS;
}

float X6_1000::get_logic_temperature() {
    return static_cast<float>(module_.Thermal().LogicTemperature());
}