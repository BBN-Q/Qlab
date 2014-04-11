#include <iostream>

#include "headings.h"
#include "libaps.h"
#include "constants.h"

#include <concol.h>

using namespace std;

enum MODE {DRAM, EPROM};

MODE get_mode() {
  cout << concol::RED << "Programming options:" << concol::RESET << endl;
  cout << "1) Upload DRAM image" << endl;
  cout << "2) Update EPROM image" << endl << endl;
  cout << "Choose option [1]: ";

  char input;
  cin.get(input);
  switch (input) {
    case '1':
    default:
      return DRAM;
      break;
    case '2':
      return EPROM;
      break;
  }
}

vector<uint32_t> read_bit_file(string fileName) {
  std::ifstream FID (fileName, std::ios::in|std::ios::binary);
  if (!FID.is_open()){
    throw runtime_error("Unable to open file.");
  }

  //Get the file size in bytes
  FID.seekg(0, std::ios::end);
  size_t fileSize = FID.tellg();
  FILE_LOG(logDEBUG1) << "Bitfile is " << fileSize << " bytes";
  FID.seekg(0, std::ios::beg);

  //Copy over the file data to the data vector
  vector<uint32_t> packedData;
  packedData.resize(fileSize/4);
  FID.read(reinterpret_cast<char *>(packedData.data()), fileSize);

  //Convert to big endian byte order - basically because it will be byte-swapped again when the packet is serialized
  for (auto & packet : packedData) {
    packet = htonl(packet);
  }

  cout << "Bit file is " << packedData.size() << " 32-bit words long" << endl;
  return packedData;
}

int write_image(string deviceSerial, string fileName) {
  vector<uint32_t> data;
  try {
    data = read_bit_file(fileName);
  } catch (std::exception &e) {
    cout << concol::RED << "Unable to open file." << concol::RESET << endl;
    return -1;
  }
  write_flash(deviceSerial.c_str(), EPROM_USER_IMAGE_ADDR, data.data(), data.size());
  //verify the write
  vector<uint32_t> buffer(256);
  uint32_t numWords = 256;
  cout << "Verifying:" << endl;
  for (size_t ct=0; ct < data.size(); ct+=256) {
    if (ct % 1000 == 0) {
      cout << "\r" << 100*ct/data.size() << "%" << flush;
    }
    if (std::distance(data.begin() + ct, data.end()) < 256) {
      numWords = std::distance(data.begin() + ct, data.end());
    }
    read_flash(deviceSerial.c_str(), EPROM_USER_IMAGE_ADDR + 4*ct, numWords, buffer.data());
    if (!std::equal(buffer.begin(), buffer.begin()+numWords, data.begin()+ct)) {
      cout << endl << "Mismatched data at offset " << hexn<8> << ct << endl;
      return -2;
    }
  }
  cout << "\r100%" << endl;
  return reset(deviceSerial.c_str(), static_cast<int>(APS_RESET_MODE_STAT::RECONFIG_EPROM));
}

int main (int argc, char* argv[])
{

  concol::concolinit();
  cout << concol::RED << "BBN AP2 Programming Executable" << concol::RESET << endl;


  int dbgLevel = 4;
  set_logging_level(dbgLevel);

  string bitFile(argv[1]);
  
  cout << concol::RED << "Attempting to initialize libaps" << concol::RESET << endl;

  init();
  set_log("stdout");

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

  MODE mode = get_mode();

  switch (mode) {
    case EPROM:
      cout << concol::RED << "Reprogramming EPROM image" << concol::RESET << endl;
      write_image(deviceSerial, bitFile);
      break;

    case DRAM:
      cout << concol::RED << "Reprogramming DRAM image" << concol::RESET << endl;
      program_FPGA(deviceSerial.c_str(), bitFile.c_str());
      break;
  }

  disconnect_APS(deviceSerial.c_str());

  delete[] serialBuffer;
  
  cout << concol::RED << "Finished!" << concol::RESET << endl;

  return 0;
}
