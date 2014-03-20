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

  double uptime = get_uptime(deviceSerial.c_str());

  cout << concol::RED << "Uptime for device " << deviceSerial << " is " << uptime << " seconds" << concol::RESET << endl;

  // force initialize device
  initAPS(deviceSerial.c_str(), 1);

  // upload test waveforms to A and B

  // square waveforms of increasing amplitude
  vector<short> wfmA;
  for (int a = 0; a < 8; a++) {
    for (int ct=0; ct < 16; ct++) {
      wfmA.push_back((a/8)*8000);
    }
  }
  cout << concol::RED << "Uploading square waveforms to Ch A" << concol::RESET << endl;
  set_waveform_int(deviceSerial.c_str(), 0, &wfmA[0], wfmA.size());
  
  // ramp waveform
  vector<short> wfmB;
  for (int ct=0; ct < 128; ct++) {
    wfmB.push_back(8000*(ct/128));
  }
  cout << concol::RED << "Uploading ramp waveform to Ch B" << concol::RESET << endl;
  set_waveform_int(deviceSerial.c_str(), 1, &wfmB[0], wfmB.size());

  // this data should appear in the cache a few microseconds later... read back the cache data??

  // uint32_t offset = std::stoul("80000000",0 ,16);
  uint32_t offset = 0xC6000000;
  uint32_t testInt;

  // test wfA cache
  size_t numRight = 0;
  for (size_t ct = 0; ct < 64; ct++)
  {
    read_memory(deviceSerial.c_str(), offset + 4*ct, 1, &testInt);
    if ( testInt != ((wfmA[ct/2] << 16) & wfmA[ct/2]) ) {
      cout << concol::RED << "Failed read test at offset " << ct << concol::RESET << endl;
    }
    else{
      numRight++;
    }
  }
  cout << concol::RED << "Waveform A single word write/read " << 100*static_cast<double>(numRight)/64 << "% correct" << concol::RESET << endl;;
  
  // test wfB cache
  numRight = 0;
  for (size_t ct = 0; ct < 64; ct++)
  {
    read_memory(deviceSerial.c_str(), offset + 1024 + 4*ct, 1, &testInt);
    if ( testInt != ((wfmB[ct/2] << 16) & wfmB[ct/2]) ) {
      cout << concol::RED << "Failed read test at offset " << ct << concol::RESET << endl;
    }
    else{
      numRight++;
    }
  }
  cout << concol::RED << "Waveform B single word write/read " << 100*static_cast<double>(numRight)/64 << "% correct" << concol::RESET << endl;;
  
  // load sequence data
  // TODO...

  cout << concol::RED << "Starting" << concol::RESET << endl;

  run(deviceSerial.c_str());

  std::this_thread::sleep_for(std::chrono::seconds(1));

  cout << concol::RED << "Stopping" << concol::RESET << endl;

  stop(deviceSerial.c_str());

  disconnect_APS(deviceSerial.c_str());
  delete[] serialBuffer;
  
  cout << concol::RED << "Finished!" << concol::RESET << endl;
  /*
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

  // rc = disconnect_by_ID(0);

  // cout << "disconnect_by_ID(0) returned " << rc << endl;
*/
  return 0;
}
