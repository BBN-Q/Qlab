#ifndef APSETHERNET_H
#define APSETHERNET_H

#include "headings.h"
#include "MACAddr.h"
#include "APSEthernetPacket.h"

#include "asio.hpp"

using asio::ip::udp;

struct EthernetDevInfo {
	MACAddr macAddr;
	udp::endpoint endpoint;
	uint16_t seqNum;
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

	//APSEthernet is a singleton instance for the driver
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
	EthernetError send(string serial, vector<APSEthernetPacket> msg, unsigned int ackEvery=1);
	vector<APSEthernetPacket> receive(string serial, size_t numPackets = 1, size_t timeoutMS = 10000);

private:
	APSEthernet();
	APSEthernet(APSEthernet const &) = delete;

	MACAddr srcMAC_;

	//Keep track of all the device info with a map from I.P. addresses to devInfo structs
	unordered_map<string, EthernetDevInfo> devInfo_;

	unordered_map<string, queue<APSEthernetPacket>> msgQueues_;

	void reset_maps();

	void setup_receive();
	void sort_packet(const vector<uint8_t> &, const udp::endpoint &);

	asio::io_service ios_;
	udp::socket socket_;

	// storage for received packets
 	uint8_t receivedData_[2048];
	udp::endpoint senderEndpoint_;

	std::thread receiveThread_;
	std::mutex mLock_;
};


#endif
