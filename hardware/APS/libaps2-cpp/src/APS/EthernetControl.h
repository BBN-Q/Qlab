
#include "headings.h"

#ifndef ETHERNETCONTROL_H_
#define ETHERNETCONTROL_H_

#include <cstdio>
#include <sstream>
#include <set>

#include "pcap.h"

#ifdef DEBUGAPS	
#include "DummyAPS.h"
#endif

using std::vector;
using std::string;
using std::map;
using std::ostringstream;

struct EthernetDevInfo {
	string name_;
	string description_;
	bool isActive_;
};

struct APSEthernetHeader {
	uint8_t  dest[6];
	uint8_t  src[6];
	uint16_t frameType;
	uint16_t seqNum;
	APSCommand_t command;
	uint32_t addr;
};


//Custom UDP style ethernet packets for APS
class EthernetControl;
class APSEthernetPacket{
public:
	APSEthernetHeader header;
	vector<uint8_t> payload;

	APSEthernetPacket();
	APSEthernetPacket(const EthernetControl &, APSCommand_t, const uint32_t &);

	static const size_t NUM_HEADER_BYTES = 24;

	vector<uint8_t> serialize() const ;
	inline size_t numBytes() const {return 24 + payload.size();};
	void set_MAC(uint8_t *, uint8_t *);
};



class EthernetControl 
{
public:
	friend class APSEthernetPacket;
	enum ErrorCodes {
    	SUCCESS = 0,
    	NOT_IMPLEMENTED = -1,
    	INVALID_NETWORK_DEVICE = -2,
    	INVALID_PCAP_FILTER = -3,
    	INVALID_APS_ID = -4,
    	TIMEOUT = -5,
    	INVALID_SPI_TARGET
	};

	typedef void (*DebugPacketCallback)(const void * data, unsigned int length);  

	static const unsigned int MAC_ADDR_LEN = 6;
	
	static const uint16_t APS_PROTO = 0xBBAE;

	static const uint16_t MAX_PAYLOAD_LEN_BYTES = 1468;
	static const uint16_t MAX_PAYLOAD_LEN_WORDS = MAX_PAYLOAD_LEN_BYTES / sizeof(uint32_t);
	static const uint16_t MIN_PAYLOAD_LEN_BYTES = 36;

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

	size_t write(APSCommand_t & command, uint32_t addr = 0) { auto data = vector<uint8_t>(); return write(command, addr, data);};
	size_t write(APSCommand_t & command, uint32_t addr,  vector<uint8_t> & data );
	size_t write(APSCommand_t & command, uint32_t addr,  vector<uint32_t> & data );
	ErrorCodes read(void * data, size_t packetLength, APSCommand_t * command = nullptr) const;

	ErrorCodes write_register(uint32_t addr, uint32_t data);	
	ErrorCodes write_register(int addr, uint32_t data) {return write_register(static_cast<uint32_t>(addr), data);}
	ErrorCodes read_register(uint32_t addr, uint32_t & data);	
	ErrorCodes read_register(int addr, uint32_t & data) {return read_register(static_cast<uint32_t>(addr), data);}	
	uint32_t   read_register(uint32_t addr) { uint32_t value; read_register(addr,value); return value;}
	uint32_t   read_register(int addr) { uint32_t value; read_register(static_cast<uint32_t>(addr),value); return value;}

	ErrorCodes read_SPI( CHIPCONFIG_IO_TARGET target, uint16_t addr, uint8_t & data) const;

	ErrorCodes write_SPI(CHIPCONFIG_IO_TARGET target, const vector<AddrData> & data);
	ErrorCodes write_SPI(CHIPCONFIG_IO_TARGET target, uint16_t address, uint8_t data);
	ErrorCodes write_SPI(CHIPCONFIG_IO_TARGET target, uint16_t address, vector<uint8_t> data);

	size_t load_bitfile(vector<uint8_t> fileData, uint32_t addr = 0);
	ErrorCodes select_FPGA_image(uint32_t addr = 0);



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

	static string print_ethernetAddress(const uint8_t * addr);

private:

	EthernetDevInfo *pcapDevice_;
	string deviceID_;
	string filter_;
	uint8_t apsMac_[MAC_ADDR_LEN];
	pcap_t *apsHandle_;

	uint16_t seqNum_;

	static const unsigned int pcapTimeoutMS = 1000;

	static vector<uint8_t> words2bytes(vector<uint32_t> & words);

	vector<APSEthernetPacket> framer(APSCommand_t const & , uint32_t  , const vector<uint8_t> &);

	int send_packet(const APSEthernetPacket & );
	int send_packets(const vector<APSEthernetPacket>::iterator & , const vector<APSEthernetPacket>::iterator & );
	APSCommand_t wait_for_ack();

	static EthernetDevInfo * findDeviceInfo(string device);
	static void getMacAddr(struct EthernetDevInfo & devInfo) ;

	static bool pcapRunning;

	static std::set<string> APSunits_;
	static std::map<string, EthernetDevInfo> APS2device_;
	static vector<EthernetDevInfo> pcapDevices_;

	static bool isvalidMACAddress(string deviceID);
	static void parseMACAddress(string macString, uint8_t * macBuffer_);
	
	static void packetHTON(APSEthernetHeader *);
	static void packetNTOH(APSEthernetHeader *);

	static string getPointToPointFilter(uint8_t * localMacAddr, uint8_t *apsMacAddr);
	static string getEnumerateFilter(uint8_t * localMacAddr);
	static string getWatchFilter();
	static ErrorCodes applyFilter(pcap_t * capHandle, string & filter);

	
	static pcap_t * start_capture(string & devName, string & filter);

};



#endif //ETHERNETCONTROL_H_
