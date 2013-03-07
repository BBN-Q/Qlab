#include <iostream>

#include "libaps.h"

using namespace std;

int main ()
{
  cout << "BBN X6-1000 Test Executable" << endl;

  int numDevices;
  numDevices = get_numDevices();

  cout << numDevices << " X6 device" << (numDevices > 1 ? "s": "")  << " found" << endl;

  if (numDevices < 1)
  	return 0;

  cout << "Attempting to initialize libaps" << endl;

  init();

  char serialBuffer[100];

  for (int cnt; cnt < numDevices; cnt++) {
  	get_deviceSerial(cnt, serialBuffer);
  	cout << "Device " << cnt << " serial #: " << serialBuffer << endl;
  }

  int rc;
  rc = connect_by_ID(0);

  cout << "connect_by_ID(0) returned " << rc << endl;

  cout << "current logic temperature = " << get_logic_temperature(0) << endl;

  cout << "current PLL frequency = " << get_sampleRate(0) << " MHz" << endl;

  rc = disconnect_by_ID(0);

  cout << "disconnect_by_ID(0) returned " << rc << endl;

  return 0;
}