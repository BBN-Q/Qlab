#include "headings.h"
#ifndef APSETHERNET_H
#define APSETHERNET_H

#include "pcap.h"

using std::string;
using std::vector;
using std::map;

enum EthernetError {
	SUCCESS = 0,
	NOT_IMPLEMENTED = -1,
	INVALID_NETWORK_DEVICE = -2,
	INVALID_PCAP_FILTER = -3,
	INVALID_APS_ID = -4,
	TIMEOUT = -5,
	INVALID_SPI_TARGET
};

struct EthernetDevInfo {
	string name;          // device name as set by winpcap
	string description;   // set by winpcap
	string description2;  // string MAC address
	MACAddr macAddr;
};

class APSEthernet {
	public:
		static APSEthernet& get_instance(){
			static APSEthernet instance;
			return instance;
		}

		~APSEthernet();
		EthernetError init(string nic);
		vector<string> enumerate();
		EthernetError connect(string serial);
		EthernetError disconnect(string serial);
		EthernetError send(vector<APSEthernetPacket> msg);
		EthernetError send(string serial, vector<APSEthernetPacket> msg);
		vector<APSEthernetPacket> receive();
		vector<APSEthernetPacket> receive(string serial);
	private:
		APSEthernet() {};
		APSEthernet(APSEthernet const &);
		void operator=(APSEthernet const &);

		map<string, MACAddr> serial_to_MAC_;
		map<MACAddr, string> MAC_to_serial_;
		pcap_t *pcap_handle_;
		MACAddr srcMAC_;
		EthernetDevInfo device_;
		vector<MACAddr> dstMACs_;
		map<string, vector<APSEthernetPacket>> msgQueues_;

		vector<EthernetDevInfo> get_network_devices();
		EthernetError set_network_device(vector<EthernetDevInfo> pcapDevices, string nic);
		string create_enumerate_filter();
		EthernetError apply_filter(string & filter);

		static const unsigned int pcapTimeoutMS = 1000;
		static const uint16_t APS_PROTO = 0xBB4E;
};

class MACAddr{
public:

	MACAddr();
	MACAddr(const int &);
	MACAddr(const string &);
	MACAddr(const EthernetDevInfo &);

	string to_string() const;

	static bool is_valid(const string &);
	static const unsigned int MAC_ADDR_LEN = 6;

	vector<uint8_t> addr;

};

#endif