#include "headings.h"
#ifndef APSETHERNET_H
#define APSETHERNET_H

#include "pcap.h"

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
		EthernetError send(string serial, APSEthernetPacket msg);
		EthernetError send(string serial, vector<APSEthernetPacket> msg);
		vector<APSEthernetPacket> receive(string serial, size_t timeoutSeconds = 1);

		static const uint16_t APS_PROTO = 0xBB4E;

		static void wrapper_pcap_callback(u_char *, const struct pcap_pkthdr *, const u_char *);

	private:
		APSEthernet() {};
		APSEthernet(APSEthernet const &);
		void operator=(APSEthernet const &);

		unordered_map<string, MACAddr> serial_to_MAC_;
		unordered_map<MACAddr, string> MAC_to_serial_;
		pcap_t *pcapHandle_;
		MACAddr srcMAC_;
		EthernetDevInfo device_;
		map<string, queue<APSEthernetPacket>> msgQueues_;

		vector<EthernetDevInfo> get_network_devices();
		EthernetError set_network_device(vector<EthernetDevInfo> pcapDevices, string nic);
		string create_pcap_filter();
		EthernetError apply_filter(string & filter);

		static const unsigned int pcapTimeoutMS = 1000;

		void pcap_callback(const struct pcap_pkthdr &, const u_char *);


};

#endif
