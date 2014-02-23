#include <iostream>

#include "headings.h"
#include "libaps.h"
#include "constants.h"

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

  // init doesn't use this parameter anymore... should really change the interface
  string dev("eth0");
  
  cout << concol::RED << "Attempting to initialize libaps" << concol::RESET << endl;

  init(dev.c_str());

  int numDevices = get_numDevices();

  cout << concol::RED << numDevices << " APS device" << (numDevices > 1 ? "s": "")  << " found" << concol::RESET << endl;

  if (numDevices < 1)
  	return 0;
  
  cout << concol::RED << "Attempting to get serials" << concol::RESET << endl;

  const char ** serialBuffer = new const char*[numDevices];
  get_deviceSerials(serialBuffer);

  for (int cnt=0; cnt < numDevices; cnt++) {
  	cout << concol::RED << "Device " << cnt << " serial #: " << serialBuffer[cnt] << concol::RESET << endl;
  }

  string deviceSerial(serialBuffer[0]);

  connect_APS(deviceSerial.c_str());

  reset(deviceSerial.c_str(), static_cast<int>(APS_RESET_MODE_STAT::RECONFIG_USER_EPROM));

  disconnect_APS(deviceSerial.c_str());

  delete[] serialBuffer;
  
  cout << concol::RED << "Finished!" << concol::RESET << endl;

  return 0;
}
