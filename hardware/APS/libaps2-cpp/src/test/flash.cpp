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
  cout << concol::RED << "BBN AP2 Flash Test Executable" << concol::RESET << endl;


  int dbgLevel = 8;
  if (argc >= 2) {
    dbgLevel = atoi(argv[1]);
  }

  set_logging_level(dbgLevel);
  
  cout << concol::RED << "Attempting to initialize libaps" << concol::RESET << endl;

  init_nolog();

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

  cout << concol::RED << "Connecting to device serial #: " << serialBuffer[0] << concol::RESET << endl;

  string deviceSerial(serialBuffer[0]);

  connect_APS(deviceSerial.c_str());

  double uptime = get_uptime(deviceSerial.c_str());

  cout << concol::RED << "Uptime for device " << deviceSerial << " is " << uptime << " seconds" << concol::RESET << endl;

  cout << "Programmed MAC and IP address at 0x00FF0000 are " << endl;
  cout << "MAC addr: " << hexn<12> << get_mac_addr(deviceSerial.c_str()) << endl;
  // uint32_t ip_addr = get_ip_addr(deviceSerial.c_str());
  // cout << "IP addr: " << std::dec << (ip_addr >> 24) << "." << ((ip_addr >> 16) & 0xFF) << "." << ((ip_addr >> 8) & 0xFF) << "." << (ip_addr & 0xFF) << endl;
  cout << "IP addr: " << get_ip_addr(deviceSerial.c_str()) << endl;

  // write a new MAC address
  // cout << concol::RED << "Writing new MAC address" << concol::RESET << endl;
  // set_mac_addr(deviceSerial.c_str(), 0x4451db112233);
  // write a new IP address
  // cout << concol::RED << "Writing new IP address" << concol::RESET << endl;
  // set_ip_addr(deviceSerial.c_str(), "192.168.5.5");

  // read SPI setup sequence
  uint32_t setup[32];
  read_flash(deviceSerial.c_str(), 0x0, 32, setup);
  cout << "Programmed setup SPI sequence:" << endl;
  for (size_t ct=0; ct < 32; ct++) {
    cout << hexn<8> << setup[ct] << " ";
    if (ct % 4 == 3) cout << endl;
  }

  // write new SPI setup sequence
  // write_SPI_setup(deviceSerial.c_str());

  cout << concol::RED << "Reading flash addr 0x00FA0000" << concol::RESET << endl;
  uint32_t buffer[4] = {0, 0, 0, 0};
  read_flash(deviceSerial.c_str(), 0x00FA0000, 4, buffer);
  cout << "Received " << hexn<8> << buffer[0] << " " << hexn<8> << buffer[1];
  cout << " " << hexn<8> << buffer[2] << " " << hexn<8> << buffer[3] << endl;

  cout << concol::RED << "Erasing/writing flash addr 0x00FA0000 (64 words)" << concol::RESET << endl;
  vector<uint32_t> testData;
  for (size_t ct=0; ct<64; ct++){
    testData.push_back(0x00FA0000 + static_cast<uint32_t>(ct));
  } 
  write_flash(deviceSerial.c_str(), 0x00FA0000, testData.data(), testData.size());

  cout << concol::RED << "Reading flash addr 0x00FA0000" << concol::RESET << endl;
  read_flash(deviceSerial.c_str(), 0x00FA0000, 4, buffer);
  cout << "Received " << hexn<8> << buffer[0] << " " << hexn<8> << buffer[1];
  cout << " " << hexn<8> << buffer[2] << " " << hexn<8> << buffer[3] << endl;

  cout << concol::RED << "Erasing/writing flash addr 0x00FA0000 (2 words)" << concol::RESET << endl;
  buffer[0] = 0xBADD1234;
  buffer[1] = 0x1234F00F;
  write_flash(deviceSerial.c_str(), 0x00FA0000, buffer, 2);

  cout << concol::RED << "Reading flash addr 0x00FA0000" << concol::RESET << endl;
  read_flash(deviceSerial.c_str(), 0x00FA0000, 4, buffer);
  cout << "Received " << hexn<8> << buffer[0] << " " << hexn<8> << buffer[1];
  cout << " " << hexn<8> << buffer[2] << " " << hexn<8> << buffer[3] << endl;
  
  disconnect_APS(deviceSerial.c_str());

  delete[] serialBuffer;
  
  cout << concol::RED << "Finished!" << concol::RESET << endl;
  
  return 0;
}
