
#ifndef ETHERNETCONTROL_H_
#define ETHERNETCONTROL_H_

#include <vector>
#include <string>
#include <cstdio>
#include <map>
#include <sstream>

using std::vector;
using std::string;
using std::map;
using std::ostringstream;

struct EthernetDevInfo {
	string name_;
	string description_;
	bool isActive_;
};

class EthernetControl 
{
public:
	enum ErrorCodes {
    	SUCCESS = 0,
    	NOT_IMPLEMENTED = -1,
    	INVALID_NETWORK_DEVICE = -2
	};

	struct EthernetDevInfo {
		string name;
		string description;
		bool isActive;
	};

	struct APSEthernetHeader {
		uint8_t  dest[6];
		uint8_t  src[6];
		uint16_t frameType;
		uint16_t seqNum;
		uint32_t command;
		uint32_t addr;
	};


	EthernetControl();
	~EthernetControl() {};

	ErrorCodes connect(int deviceID);
	ErrorCodes disconnect();

	ErrorCodes set_network_device(string description);

	size_t Write(void * data, size_t length);
	size_t Read(void * data, size_t packetLength);

	bool isOpen();
	static bool isOpen(int deviceID);
	static ErrorCodes get_device_serials(vector<string> testSerials);
	static unsigned int get_num_devices();

	static vector<string> get_network_devices_names();

	static void get_network_devices();
	static ErrorCodes set_device_active(string, bool);
	static void enumerate();

private:

	EthernetDevInfo *pcapDevice;

	static EthernetDevInfo * findDeviceInfo(string device);

	static bool pcapRunning;

	static vector<EthernetDevInfo> pcapDevices;

	static string print_ethernetAddress(uint8_t * addr);
	static void packetHTON(APSEthernetHeader *);
	
};

#endif
