#include <iostream>

#include "libaps.h"
#include "constants.h"
#include <thread>
#include <string>
#include <algorithm>

#include <concol.h> 

using namespace std;

// command options functions taken from:
// http://stackoverflow.com/questions/865668/parse-command-line-arguments
string getCmdOption(char ** begin, char ** end, const std::string & option)
{
  char ** itr = std::find(begin, end, option);
  if (itr != end && ++itr != end)
  {
    return string(*itr);
  }
  return "";
}

bool cmdOptionExists(char** begin, char** end, const std::string& option)
{
  return std::find(begin, end, option) != end;
}


int main (int argc, char* argv[])
{

  concol::concolinit();
  cout << concol::RED << "BBN AP2 Test Executable" << concol::RESET << endl;


  int dbgLevel = 8;
  if (argc >= 2) {
    dbgLevel = atoi(argv[1]);
  }

  set_logging_level(dbgLevel);

  // lookup based on device name
  //string dev("\\Device\\NPF_{F47ACE9E-1961-4A8E-BA14-2564E3764BFA}");
  
  // lookup based on description
  // string dev("Intel(R) 82579LM Gigabit Network Connection");
  string dev("eth0");
  
  cout << concol::RED << "Attempting to initialize libaps" << concol::RESET << endl;

  init(const_cast<char*>(dev.c_str()));

  int numDevices = get_numDevices();

  cout << concol::RED << numDevices << " APS device" << (numDevices > 1 ? "s": "")  << " found" << concol::RESET << endl;

  if (numDevices < 1)
  	return 0;
  
  cout << concol::RED << "Attempting to get serials" << concol::RESET << endl;

  char serialBuffer[100];

  for (int cnt; cnt < numDevices; cnt++) {
  	get_deviceSerial(cnt, serialBuffer);
  	cout << concol::RED << "Device " << cnt << " serial #: " << serialBuffer << concol::RESET << endl;
  }


  int rc;
  rc = connect_by_ID(0);

  cout << concol::RED << "connect_by_ID(0) returned " << rc << concol::RESET << endl;

  rc = initAPS(0, const_cast<char *>("../dummyBitfile.bit"), 0);

  cout << concol::RED << "initAPS(0) returned " << rc << concol::RESET << endl;
  

  cout << "Set sample rate " << endl;

  set_sampleRate(0,100);

  cout << "current PLL frequency = " << get_sampleRate(0) << " MHz" << endl;

  cout << "setting trigger source = EXTERNAL" << endl;

  set_trigger_source(0, EXTERNAL);

  cout << "get trigger source returns " << ((get_trigger_source(0) == INTERNAL) ? "INTERNAL" : "EXTERNAL") << endl;

  cout << "setting trigger source = INTERNAL" << endl;

  set_trigger_source(0, INTERNAL);

  cout << "get trigger source returns " << ((get_trigger_source(0) == INTERNAL) ? "INTERNAL" : "EXTERNAL") << endl;

  cout << "get channel(0) enable: " << get_channel_enabled(0,0) << endl;

  cout << "set channel(0) enabled = 1" << endl;

  set_channel_enabled(0,0,true);

  const int wfs = 1000;
  short wf[wfs];
  for (int cnt = 0; cnt < wfs; cnt++)
    wf[cnt] = (cnt < wfs/2) ? 32767 : -32767;

  cout << "loading waveform" << endl;

  set_waveform_int(0, 0, wf, wfs);

  cout << "Running" << endl;

  set_sampleRate(0,50);

  run(0);

  std::this_thread::sleep_for(std::chrono::seconds(10));

  cout << "Stopping" << endl;

  stop(0);

  set_channel_enabled(0,0,false);

  cout << "get channel(0) enable: " << get_channel_enabled(0,0) << endl;

  rc = disconnect_by_ID(0);

  cout << "disconnect_by_ID(0) returned " << rc << endl;

  return 0;
}
