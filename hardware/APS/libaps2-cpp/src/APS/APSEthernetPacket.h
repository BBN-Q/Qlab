
#ifndef APSETHERNETPACKET_H_
#define APSETHERNETPACKET_H_

#include "headings.h"
#include "MACAddr.h"

#ifndef _WIN32
	#include <arpa/inet.h>
#endif


struct APSEthernetHeader {
	MACAddr  dest;
	MACAddr  src;
	uint16_t frameType;
	uint16_t seqNum;
	APSCommand_t command;
	uint32_t addr;
};

class APSEthernetPacket{
public:
	APSEthernetHeader header;
	vector<uint32_t> payload;

	APSEthernetPacket();

	APSEthernetPacket(const APSCommand_t &);
	APSEthernetPacket(const APSCommand_t &, const uint32_t &);
	APSEthernetPacket(const MACAddr &, const MACAddr &, APSCommand_t, const uint32_t &);

	APSEthernetPacket(const vector<uint8_t> &);
	
	static const size_t NUM_HEADER_BYTES = 24;

	vector<uint8_t> serialize() const ;
	size_t numBytes() const; 

	static APSEthernetPacket create_broadcast_packet();
};

#endif //APSETHERNETPACKET_H_
