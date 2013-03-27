#include <iostream>

#include "libaps.h"
#include "constants.h"
#include <thread>

using namespace std;

int main ()
{
  cout << "BBN X6-1000 Test Executable" << endl;

  set_logging_level(5);

  int numDevices;
  numDevices = get_numDevices();

  cout << numDevices << " X6 device" << (numDevices > 1 ? "s": "")  << " found" << endl;

  if (numDevices < 1)
  	return 0;

  char s[] = "stdout";
  set_log(s);

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

  cout << "setting trigger source = EXTERNAL" << endl;

  set_trigger_source(0, EXTERNAL);

  cout << "get trigger source returns " << ((get_trigger_source(0) == INTERNAL) ? "INTERNAL" : "EXTERNAL") << endl;

  cout << "setting trigger source = INTERNAL" << endl;

  set_trigger_source(0, INTERNAL);

  cout << "get trigger source returns " << ((get_trigger_source(0) == INTERNAL) ? "INTERNAL" : "EXTERNAL") << endl;

  cout << "get channel(0) enable: " << get_channel_enabled(0,0) << endl;

  cout << "set channel(0) enabled = 1" << endl;

  set_channel_enabled(0,0,true);

  cout << "enable ramp output" << endl;
  
  enable_test_generator(0,0,0.001);

  std::this_thread::sleep_for(std::chrono::seconds(5));


  cout << "enable sine wave output" << endl;

  disable_test_generator(0);
  enable_test_generator(0,1,0.001);

  std::this_thread::sleep_for(std::chrono::seconds(5));

  cout << "disabling channel" << endl;
  disable_test_generator(0);
  set_channel_enabled(0,0,false);

  cout << "get channel(0) enable: " << get_channel_enabled(0,0) << endl;

  rc = disconnect_by_ID(0);

  cout << "disconnect_by_ID(0) returned " << rc << endl;

  return 0;
}