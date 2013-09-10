#ifndef APSETHERNET_H
#define APSETHERNET_H

#include "headings.h"
#include "MACAddr.h"
#include "APSEthernetPacket.h"

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
		APSEthernet& operator=(APSEthernet &rhs)  { return rhs; };

		~APSEthernet();
		EthernetError init(string nic);
		set<string> enumerate();
		EthernetError connect(string serial);
		EthernetError disconnect(string serial);
		EthernetError send(string serial, APSEthernetPacket msg);
		EthernetError send(string serial, vector<APSEthernetPacket> msg);
		vector<APSEthernetPacket> receive(string serial, size_t timeoutSeconds = 1);

	private:
		APSEthernet() {};
		APSEthernet(APSEthernet const &) = delete;

		unordered_map<string, MACAddr> serial_to_MAC_;
		unordered_map<MACAddr, string> MAC_to_serial_;
		pcap_t *pcapHandle_;
		MACAddr srcMAC_;
		EthernetDevInfo device_;
		map<string, queue<APSEthernetPacket>> msgQueues_;

		vector<EthernetDevInfo> get_network_devices();
		EthernetError set_network_device(vector<EthernetDevInfo> pcapDevices, string nic);
		string create_pcap_filter();
		void reset_mac_maps();
		static EthernetError apply_filter(string & filter, pcap_t *);

		static const unsigned int pcapTimeoutMS = 100;
		
		void run_receive_thread();

		std::thread receiveThread_;
		std::atomic<bool> receiving_;
		std::mutex mLock_;


};

#endif
