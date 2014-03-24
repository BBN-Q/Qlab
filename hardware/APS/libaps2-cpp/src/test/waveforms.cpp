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

vector<uint32_t> read_seq_file(string fileName) {
  std::ifstream FID (fileName, std::ios::in);
  if (!FID.is_open()){
    throw runtime_error("Unable to open file.");
  }
  vector<uint32_t> data;
  string line;
  while (FID >> line) {
    data.push_back(std::stoul(line.substr(16, 8), NULL, 16));
    data.push_back(std::stoul(line.substr(8, 8), NULL, 16));
    data.push_back(std::stoul(line.substr(0, 8), NULL, 16));
    data.push_back(0);
  }
  FID.close();
  return data;
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

  // check that memory map was written
  uint32_t testInt;
  read_memory(deviceSerial.c_str(), WFA_OFFSET_ADDR, &testInt, 1);
  cout << "wfA offset: " << testInt - MEMORY_ADDR << endl;
  read_memory(deviceSerial.c_str(), WFB_OFFSET_ADDR, &testInt, 1);
  cout << "wfB offset: " << testInt - MEMORY_ADDR << endl;
  read_memory(deviceSerial.c_str(), SEQ_OFFSET_ADDR, &testInt, 1);
  cout << "seq offset: " << testInt - MEMORY_ADDR << endl;

  // stop pulse sequencer and cache controller
  stop(deviceSerial.c_str());
  testInt = 0;
  write_memory(deviceSerial.c_str(), CACHE_CONTROL_ADDR, &testInt, 1);

  read_memory(deviceSerial.c_str(), CACHE_CONTROL_ADDR, &testInt, 1);
  cout << "Initial cache control reg: " << hexn<8> << testInt << endl;
  read_memory(deviceSerial.c_str(), CACHE_STATUS_ADDR, &testInt, 1);
  cout << "Initial cache status reg: " << hexn<8> << testInt << endl;
  read_memory(deviceSerial.c_str(), PLL_STATUS_ADDR, &testInt, 1);
  cout << "Initial DMA status reg: " << hexn<8> << testInt << endl;

  // upload test waveforms to A and B

  // square waveforms of increasing amplitude
  vector<short> wfmA;
  for (short a = 0; a < 8; a++) {
    for (int ct=0; ct < 32; ct++) {
      wfmA.push_back(a*1000);
    }
  }
  cout << concol::RED << "Uploading square waveforms to Ch A" << concol::RESET << endl;
  set_waveform_int(deviceSerial.c_str(), 0, wfmA.data(), wfmA.size());

  read_memory(deviceSerial.c_str(), CACHE_STATUS_ADDR, &testInt, 1);
  cout << "Cache status reg after wfA write: " << hexn<8> << testInt << endl;
  read_memory(deviceSerial.c_str(), PLL_STATUS_ADDR, &testInt, 1);
  cout << "DMA status reg after wfA write: " << hexn<8> << testInt << endl;
  
  // ramp waveform
  vector<short> wfmB;
  for (short ct=0; ct < 256; ct++) {
    wfmB.push_back(31*ct);
  }
  cout << concol::RED << "Uploading ramp waveform to Ch B" << concol::RESET << endl;
  set_waveform_int(deviceSerial.c_str(), 1, wfmB.data(), wfmB.size());

  read_memory(deviceSerial.c_str(), CACHE_STATUS_ADDR, &testInt, 1);
  cout << "Cache status reg after wfB write: " << hexn<8> << testInt << endl;
  read_memory(deviceSerial.c_str(), PLL_STATUS_ADDR, &testInt, 1);
  cout << "DMA status reg after wfB write: " << hexn<8> << testInt << endl;

  // check that cache controller was enabled
  read_memory(deviceSerial.c_str(), CACHE_CONTROL_ADDR, &testInt, 1);
  cout << "Cache control reg: " << hexn<8> << testInt << endl;

  // this data should appear in the cache a few microseconds later... read back the cache data??

  // uint32_t offset = 0xC6000000;
  uint32_t offset;

  // test wfA cache
  size_t numRight = 0;
  // offset = 0xC6000000u;
  offset = 0xC0000000u;
  for (size_t ct = 0; ct < 64; ct++)
  {
    read_memory(deviceSerial.c_str(), offset + 4*ct, &testInt, 1);
    if ( testInt != ((wfmA[ct*2] << 16) | wfmA[ct*2+1]) ) {
      cout << concol::RED << "Failed read test at offset " << ct << concol::RESET << endl;
    }
    else{
      numRight++;
    }
  }
  cout << concol::RED << "Waveform A single word write/read " << 100*static_cast<double>(numRight)/64 << "% correct" << concol::RESET << endl;;
  
  // test wfB cache
  // offset = 0xC6000400u;
  offset = 0xC2000000u;
  numRight = 0;
  for (size_t ct = 0; ct < 64; ct++)
  {
    read_memory(deviceSerial.c_str(), offset + 4*ct, &testInt, 1);
    if ( testInt != ((wfmB[ct*2] << 16) | wfmB[ct*2+1]) ) {
      cout << concol::RED << "Failed read test at offset " << ct << concol::RESET << endl;
    }
    else{
      numRight++;
    }
  }
  cout << concol::RED << "Waveform B single word write/read " << 100*static_cast<double>(numRight)/64 << "% correct" << concol::RESET << endl;;
  
  cout << concol::RED << "Writing sequence data" << concol::RESET << endl;

  vector<uint32_t> seq = read_seq_file("../../examples/simpleSeq.dat");
  write_sequence(deviceSerial.c_str(), seq.data(), seq.size());

  read_memory(deviceSerial.c_str(), CACHE_STATUS_ADDR, &testInt, 1);
  cout << "Cache status reg after seq write: " << hexn<8> << testInt << endl;
  read_memory(deviceSerial.c_str(), PLL_STATUS_ADDR, &testInt, 1);
  cout << "DMA status reg after seq write: " << hexn<8> << testInt << endl;

  // test sequence cache
  // offset = 0xC6000400u;
  offset = 0xC4000000u;
  numRight = 0;
  for (size_t ct = 0; ct < seq.size(); ct++)
  {
    read_memory(deviceSerial.c_str(), offset + 4*ct, &testInt, 1);
    if ( testInt != seq[ct] ) {
      cout << concol::RED << "Failed read test at offset " << ct << concol::RESET << endl;
    }
    else{
      numRight++;
    }
  }
  cout << concol::RED << "Sequence single word write/read " << 100*static_cast<double>(numRight)/seq.size() << "% correct" << concol::RESET << endl;;

  cout << concol::RED << "Starting" << concol::RESET << endl;

  run(deviceSerial.c_str());

  std::this_thread::sleep_for(std::chrono::seconds(1));

  read_memory(deviceSerial.c_str(), CACHE_STATUS_ADDR, &testInt, 1);
  cout << "Cache status reg after pulse sequencer enable: " << hexn<8> << testInt << endl;
  read_memory(deviceSerial.c_str(), PLL_STATUS_ADDR, &testInt, 1);
  cout << "DMA status reg after pulse sequencer enable: " << hexn<8> << testInt << endl;

  read_memory(deviceSerial.c_str(), PHASE_COUNT_A_ADDR, &testInt, 1);
  cout << "Pulse sequencer command top: " << hexn<8> << testInt << endl;
  read_memory(deviceSerial.c_str(), PHASE_COUNT_B_ADDR, &testInt, 1);
  cout << "Pulse sequencer command bottom: " << hexn<8> << testInt << endl;


  // cout << concol::RED << "Stopping" << concol::RESET << endl;

  // stop(deviceSerial.c_str());

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
