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

  //Do a soft reset
  // cout << concol::RED << "Soft reset of all logic..." << concol::RESET << endl;

  // reset(deviceSerial.c_str(), static_cast<int>(APS_RESET_MODE_STAT::SOFT_RESET_HOST_USER));

  // cout << concol::RED << "Reset finished." << concol::RESET << endl;

  // uptime = get_uptime(deviceSerial.c_str());

  // cout << concol::RED << "Uptime for device " << deviceSerial << " is " << uptime << " seconds" << concol::RESET << endl;


  //Test single word read/write
  size_t numTests = 100;
  size_t maxAddr = 131072;
  vector<uint32_t> testAddrs, testWords;

  for (size_t ct = 0; ct < numTests; ++ct)
  {
    testAddrs.push_back(rand() % maxAddr);
    testWords.push_back(rand() % 4294967296);
  }

  // cout << concol::RED << "Testing single word write/read on Waveform A" << concol::RESET << endl;;

  uint32_t offset = std::stoul("c0000000",0 ,16);
  uint32_t testInt;

  size_t numRight = 0;
  for (size_t ct = 0; ct < numTests; ++ct)
  {
    memory_write(deviceSerial.c_str(), offset + 4*testAddrs[ct], 1, &testWords[ct]);
    memory_read(deviceSerial.c_str(), offset + 4*testAddrs[ct], 1, &testInt);
    // cout << "Address: " << testAddrs[ct] << " Wrote: " << testWords[ct] << " Read: " << testInt << endl;
    if (testInt != testWords[ct]){
      cout << concol::RED << "Failed write/read test!" << concol::RESET << endl;
    }
    else{
      numRight++;
    }
  }
  cout << concol::RED << "Waveform A single word write/read " << 100*static_cast<double>(numRight)/numTests << "% correct" << concol::RESET << endl;;
  
  cout << concol::RED << "Testing single word write/read on Waveform B" << concol::RESET << endl;;

  offset = std::stoul("c2000000",0 ,16);
  
  numRight = 0;
  for (size_t ct = 0; ct < numTests; ++ct)
  {
    memory_write(deviceSerial.c_str(), offset + 4*testAddrs[ct], 1, &testWords[ct]);
    memory_read(deviceSerial.c_str(), offset + 4*testAddrs[ct], 1, &testInt);
    // cout << "Address: " << testAddrs[ct] << " Wrote: " << testWords[ct] << " Read: " << testInt << endl;
    if (testInt != testWords[ct]){
      cout << concol::RED << "Failed write/read test!" << concol::RESET << endl;
    }
    else{
      numRight++;
    }
  }
  cout << concol::RED << "Waveform B single word write/read " << 100*static_cast<double>(numRight)/numTests << "% correct" << concol::RESET << endl;;

  //Multi-word write/read tests
  //Start somewhere in the lower half of a memory block and write a random amount from a quarter to half the RAM
  testWords.clear();
  // size_t testSize = (maxAddr/4) + rand() % (maxAddr/2);
  size_t testSize = 65536;
  testWords.reserve(testSize);
  for (size_t ct = 0; ct < testSize ; ++ct)
  {
    testWords.push_back(rand() % 4294967296);
  }
  uint32_t startAddr = rand() % (maxAddr/2);

  std::chrono::time_point<std::chrono::steady_clock> start, end;

  start = std::chrono::steady_clock::now();

  memory_write(deviceSerial.c_str(), offset + 4*startAddr, testSize, testWords.data());

  end = std::chrono::steady_clock::now();
  size_t elapsedTime =  std::chrono::duration_cast<std::chrono::milliseconds>(end-start).count();

  cout << concol::RED << "Long write took " << static_cast<double>(elapsedTime)/1000 << concol::RESET << endl;

  //Now make a few random reads to confirm
  for (size_t ct = 0; ct < 100; ++ct)
  {
    uint32_t testAddr = startAddr + rand() % testSize;
    memory_read(deviceSerial.c_str(), offset + 4*testAddr, 1, &testInt);
    if (testInt != testWords[testAddr-startAddr]){
      cout << concol::RED << "Failed write/read test!" << concol::RESET << endl;
    }
  }

  disconnect_APS(deviceSerial.c_str());

  delete[] serialBuffer;
  

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
