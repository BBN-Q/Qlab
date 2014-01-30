#ifndef APSETHERNET_H
#define APSETHERNET_H

#include "headings.h"
#include "MACAddr.h"
#include "APSEthernetPacket.h"

#include "asio.hpp"

using asio::ip::udp;

struct EthernetDevInfo {
	string name;          // device name as set by winpcap
	string description;   // set by winpcap
	string description2;  // string MAC address
	MACAddr macAddr;
};

class APSEthernet {
public:

	enum EthernetError {
		SUCCESS = 0,
		NOT_IMPLEMENTED = -1,
		INVALID_NETWORK_DEVICE = -2,
		INVALID_PCAP_FILTER = -3,
		INVALID_APS_ID = -4,
		TIMEOUT = -5,
		INVALID_SPI_TARGET
	};

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
	vector<APSEthernetPacket> receive(string serial, size_t timeoutMS = 1000);

private:
		APSEthernet();
		APSEthernet(APSEthernet const &) = delete;

		unordered_map<string, MACAddr> serial_to_MAC_;
		unordered_map<MACAddr, string> MAC_to_serial_;
		MACAddr srcMAC_;

		map<string, udp::endpoint> endpoints_;
		map<string, queue<APSEthernetPacket>> msgQueues_;

		void reset_maps();
		// void run_receive_thread();
		void run_send_thread();

		void setup_receive();
		void sort_packet(const vector<uint8_t> &, const udp::endpoint &);


		asio::io_service ios_;
		udp::socket socket_;


		std::thread receiveThread_;
		std::atomic<bool> receiving_;
		std::mutex mLock_;


};


#endif
