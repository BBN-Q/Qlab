
#ifndef ETHERNETCONTROL_H_
#define ETHERNETCONTROL_H_

#include <vector>
#include <string>
#include <cstdio>
#include <map>
#include <sstream>
#include <set>

#include "pcap.h"

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
    	INVALID_NETWORK_DEVICE = -2,
    	INVALID_PCAP_FILTER = -3
	};

	enum APS_COMMANDS {
		APS_COMMAND_RESET = 0x0,
		APS_COMMAND_USERIO_ACK = 0x1,
		APS_COMMAND_USERIO_NACK = 0x9,
		APS_COMMAND_EPROMIO = 0x2,
		APS_COMMAND_CHIPCONFIGIO = 0x3,
		APS_COMMAND_RUNCHIPCONFIG = 0x4,
		APS_COMMAND_FPGACONFIG_ACK = 0x5,
		APS_COMMAND_FPGACONFIG_NACK = 0xD,
		APS_COMMAND_FPGACONFIG_CTRL = 0x6,
		APS_COMMAND_STATUS = 0x7
	};

	enum APS_STATUS {
		APS_STATUS_HOST = 0,
		APS_STATUS_VOLT_A = 1,
		APS_STATUS_VOLT_B = 2,
		APS_STATUS_TEMP  = 3
	};

	static const unsigned int MAC_ADDR_LEN = 6;
	
	static const uint16_t APS_PROTO = 0xBBAE;
	//static const uint16_t APS_PROTO = 0x0800; // get IP packets for testing

	struct EthernetDevInfo {
		string name;          // device name as set by winpcap
		string description;   // set by winpcap
		string description2;  // set by getMacAddr
		uint8_t macAddr[MAC_ADDR_LEN];
		bool isActive;
	};



	struct APSCommand {
		uint32_t cnt : 16;
		uint32_t mode_stat : 8;
		uint32_t cmd : 4;
		uint32_t r_w : 1;
		uint32_t sel : 1;
		uint32_t seq : 1;
		uint32_t ack : 1;
	};

	struct APSEthernetHeader {
		uint8_t  dest[MAC_ADDR_LEN];
		uint8_t  src[MAC_ADDR_LEN];
		uint16_t frameType;
		uint16_t seqNum;
		union {
			uint32_t packedCommand;
			struct APSCommand command;
		};
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
	static ErrorCodes get_device_serials(vector<string> & testSerials);
	static unsigned int get_num_devices();

	static vector<string> get_network_devices_names();

	static void get_network_devices();
	static ErrorCodes set_device_active(string, bool);
	static void enumerate(unsigned int timeoutSeconds = 5, unsigned int broadcastPeriodSeconds = 1);
	static void debugAPSEcho(string device);

private:

	static const unsigned int pcapTimeoutMS = 500;

	EthernetDevInfo *pcapDevice;

	static EthernetDevInfo * findDeviceInfo(string device);
	static void getMacAddr(struct EthernetDevInfo & devInfo) ;

	static bool pcapRunning;

	static std::set<string> APSunits_;

	static vector<EthernetDevInfo> pcapDevices;

	static string print_ethernetAddress(uint8_t * addr);
	static void packetHTON(APSEthernetHeader *);

	static string getPointToPointFilter(uint8_t * localMacAddr, uint8_t *apsMacAddr);
	static string getEnumerateFilter(uint8_t * localMacAddr);
	static string getWatchFilter();
	static ErrorCodes applyFilter(pcap_t * capHandle, string filter);

	static string print_APS_command(struct APSCommand * cmd);

};

#endif
