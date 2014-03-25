#include <iostream>

#include "headings.h"
#include "libaps.h"
#include "constants.h"

#include <concol.h> 

using namespace std;

int main (int argc, char* argv[])
{

  concol::concolinit();
  cout << concol::RED << "BBN AP2 Programming Executable" << concol::RESET << endl;


  int dbgLevel = 4;
  set_logging_level(dbgLevel);

  string bitFile(argv[1]);

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

  cout << concol::RED << "Reprogramming FPGA" << concol::RESET << endl;

  program_FPGA(deviceSerial.c_str(), bitFile.c_str());

  std::this_thread::sleep_for(std::chrono::seconds(4));

  int retrycnt = 0;
  bool success = false;
  while (!success && (retrycnt < 3)) {
    try {
      // poll uptime to see device reset
      double uptime = get_uptime(deviceSerial.c_str());
      cout << concol::RED << "Uptime for device " << deviceSerial << " is " << uptime << " seconds" << concol::RESET << endl;
    } catch (std::exception &e) {
      cout << concol::RED << "Status timeout; retrying..." << concol::RESET << endl;
      retrycnt++;
      continue;
    }
    success = true;
  }

  disconnect_APS(deviceSerial.c_str());

  delete[] serialBuffer;
  
  cout << concol::RED << "Finished!" << concol::RESET << endl;

  return 0;
}
