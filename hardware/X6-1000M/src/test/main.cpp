#include <iostream>

#include "libx6adc.h"
#include "constants.h"

using namespace std;

int main ()
{
  cout << "BBN X6-1000 Test Executable" << endl;

  set_logging_level(5);

  int numDevices;
  numDevices = get_num_devices();

  cout << numDevices << " X6 device" << (numDevices > 1 ? "s": "")  << " found" << endl;

  if (numDevices < 1)
  	return 0;

  char s[] = "stdout";
  set_log(s);

  cout << "Attempting to initialize libaps" << endl;

  init();

  int rc;
  rc = connect_by_ID(0);

  cout << "connect(0) returned " << rc << endl;

  cout << "current logic temperature method 1 = " << get_logic_temperature(0, 0) << endl;
  cout << "current logic temperature method 2 = " << get_logic_temperature(0, 1) << endl;

  cout << "Set sample rate " << endl;

  set_sampleRate(0,100e6);

  cout << "current PLL frequency = " << get_sampleRate(0)/1e6 << " MHz" << endl;

  cout << "setting trigger source = EXTERNAL" << endl;

  set_trigger_source(0, EXTERNAL);

  cout << "get trigger source returns " << ((get_trigger_source(0) == INTERNAL) ? "INTERNAL" : "EXTERNAL") << endl;

  cout << "setting trigger source = INTERNAL" << endl;

  set_trigger_source(0, INTERNAL);

  cout << "get trigger source returns " << ((get_trigger_source(0) == INTERNAL) ? "INTERNAL" : "EXTERNAL") << endl;

  cout << "Acquiring" << endl;

  acquire(0);
  wait_for_acquisition(0, 10);

  unsigned short buffer[1024];
  transfer_waveform(0, 1, buffer, 1024);

  cout << "Stopping" << endl;

  stop(0);

  rc = disconnect(0);

  cout << "disconnect(0) returned " << rc << endl;

  return 0;
}