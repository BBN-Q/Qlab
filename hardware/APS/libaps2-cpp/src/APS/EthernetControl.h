
#ifndef ETHERNETCONTROL_H_
#define ETHERNETCONTROL_H_

#include <vector>
#include <string>
#include <cstdio>
#include <map>
#include <sstream>
#include <set>

#include "aps2.h"
#include "pcap.h"

#ifdef DEBUGAPS	
#include "DummyAPS.h"
#endif

using std::vector;
using std::string;
using std::map;
using std::ostringstream;

using namespace APS2;

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
    	INVALID_PCAP_FILTER = -3,
    	INVALID_APS_ID = -4,
    	TIMEOUT = -5
	};

	typedef void (*DebugPacketCallback)(const void * data, unsigned int length);  

	static const unsigned int MAC_ADDR_LEN = 6;
	
	static const uint16_t APS_PROTO = 0xBBAE;

	static const uint16_t MAX_PAYLOAD_LEN = 1468;
	static const uint16_t MIN_PAYLOAD_LEN = 36;

	struct EthernetDevInfo {
		string name;          // device name as set by winpcap
		string description;   // set by winpcap
		string description2;  // set by getMacAddr
		uint8_t macAddr[MAC_ADDR_LEN];
		bool isActive;
	};


	EthernetControl();
	~EthernetControl() {};

	ErrorCodes connect(string deviceID);
	ErrorCodes disconnect();

	ErrorCodes set_network_device(string description);

	size_t Write(APSCommand & command) { Write(command, 0, 0, 0);}
	size_t Write(APSCommand & command, uint32_t addr) { Write(command, addr, 0, 0);}
	size_t Write(APSCommand & command, uint32_t addr,  void * data, size_t length);
	size_t Read(void * data, size_t packetLength, APSCommand * command = nullptr);

	size_t program_FPGA(vector<UCHAR> fileData, uint32_t addr = 0);
	ErrorCodes   select_FPGA_image(uint32_t addr = 0);

	bool isOpen();
	static bool isOpen(int deviceID);
	static ErrorCodes get_device_serials(vector<string> & testSerials);
	static unsigned int get_num_devices();

	static vector<string> get_network_devices_names();

	static void get_network_devices();
	static ErrorCodes set_device_active(string, bool);
	static void enumerate(unsigned int timeoutSeconds = 5, unsigned int broadcastPeriodSeconds = 1);

#ifdef DEBUGAPS	
	static void debugAPSEcho(string device, DummyAPS * aps = 0);
#endif

	static string print_ethernetAddress(uint8_t * addr);

private:

	EthernetDevInfo *pcapDevice_;
	string deviceID_;
	string filter_;
	uint8_t apsMac_[MAC_ADDR_LEN];
	pcap_t *apsHandle_;

	uint16_t seqNum_;

	static const unsigned int pcapTimeoutMS = 1000;

	static EthernetDevInfo * findDeviceInfo(string device);
	static void getMacAddr(struct EthernetDevInfo & devInfo) ;

	static bool pcapRunning;

	static std::set<string> APSunits_;
	static std::map<string, EthernetDevInfo> APS2device_;
	static vector<EthernetDevInfo> pcapDevices_;

	static bool isvalidMACAddress(string deviceID);
	static void parseMACAddress(string macString, uint8_t * macBuffer_);
	
	static void packetHTON(APSEthernetHeader *);

	static string getPointToPointFilter(uint8_t * localMacAddr, uint8_t *apsMacAddr);
	static string getEnumerateFilter(uint8_t * localMacAddr);
	static string getWatchFilter();
	static ErrorCodes applyFilter(pcap_t * capHandle, string & filter);

	
	static pcap_t * start_capture(string & devName, string & filter);

};

#endif
