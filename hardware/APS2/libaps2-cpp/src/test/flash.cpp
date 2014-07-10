#include <iostream>

#include "headings.h"
#include "libaps.h"
#include "constants.h"

#include <concol.h>

using namespace std;

int get_device_id() {
  cout << "Choose device ID [0]: ";
  string input = "";
  getline(cin, input);

  if (input.length() == 0) {
    return 0;
  }
  int device_id;
  stringstream mystream(input);

  mystream >> device_id;
  return device_id;
}

uint64_t get_mac_input() {
  cout << "New MAC address [ENTER to skip]: ";
  string input = "";
  getline(cin, input);

  if (input.length() == 0) {
    return 0;
  }
  stringstream mystream(input);
  uint64_t mac_addr;
  mystream >> std::hex >> mac_addr;

  cout << "Received " << hexn<12> << mac_addr << endl;
  return mac_addr;
}

string get_ip_input() {
  cout << "New IP address [ENTER to skip]: ";
  string input = "";
  getline(cin, input);
  return input;
}

bool spi_prompt() {
  cout << "Do you want to program the SPI startup sequence? [y/N]: ";
  string input = "";
  getline(cin, input);
  if (input.length() == 0) {
    return false;
  }
  stringstream mystream(input);
  char response;
  mystream >> response;
  switch (response) {
    case 'y':
    case 'Y':
      return true;
      break;
    case 'n':
    case 'N':
    default:
      return false;
  }
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

  string deviceSerial;

  if (numDevices == 1) {
    deviceSerial = string(serialBuffer[0]);
  } else {
    deviceSerial = string(serialBuffer[get_device_id()]);
  }

  cout << concol::RED << "Connecting to device serial #: " << deviceSerial << concol::RESET << endl;

  connect_APS(deviceSerial.c_str());

  double uptime = get_uptime(deviceSerial.c_str());

  cout << concol::RED << "Uptime for device " << deviceSerial << " is " << uptime << " seconds" << concol::RESET << endl;

  cout << "Programmed MAC and IP address at 0x00FF0000 are " << endl;
  cout << "MAC addr: " << hexn<12> << get_mac_addr(deviceSerial.c_str()) << endl;
  cout << "IP addr: " << get_ip_addr(deviceSerial.c_str()) << endl;

  // write a new MAC address
  uint64_t mac_addr = get_mac_input();
  if (mac_addr != 0) {
    cout << concol::RED << "Writing new MAC address" << concol::RESET << endl;
    set_mac_addr(deviceSerial.c_str(), mac_addr);
  }

  // write a new IP address
  string ip_addr = get_ip_input();
  if (ip_addr != "") {
    cout << concol::RED << "Writing new IP address" << concol::RESET << endl;
    set_ip_addr(deviceSerial.c_str(), ip_addr.c_str());
  }

  // read SPI setup sequence
  uint32_t setup[32];
  read_flash(deviceSerial.c_str(), 0x0, 32, setup);
  cout << "Programmed setup SPI sequence:" << endl;
  for (size_t ct=0; ct < 32; ct++) {
    cout << hexn<8> << setup[ct] << " ";
    if (ct % 4 == 3) cout << endl;
  }

  // write new SPI setup sequence
  if (spi_prompt()) {
    cout << concol::RED << "Writing SPI startup sequence" << concol::RESET << endl;
    write_SPI_setup(deviceSerial.c_str());
  }
  /*
  cout << concol::RED << "Reading flash addr 0x00FA0000" << concol::RESET << endl;
  uint32_t buffer[4] = {0, 0, 0, 0};
  read_flash(deviceSerial.c_str(), 0x00FA0000, 4, buffer);
  cout << "Received " << hexn<8> << buffer[0] << " " << hexn<8> << buffer[1];
  cout << " " << hexn<8> << buffer[2] << " " << hexn<8> << buffer[3] << endl;

  cout << concol::RED << "Erasing/writing flash addr 0x00FA0000 (128 words)" << concol::RESET << endl;
  vector<uint32_t> testData;
  for (size_t ct=0; ct<128; ct++){
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
  */

  disconnect_APS(deviceSerial.c_str());

  delete[] serialBuffer;

  cout << concol::RED << "Finished!" << concol::RESET << endl;

  return 0;
}
