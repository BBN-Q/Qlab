
#ifndef APSETHERNETPACKET_H_
#define APSETHERNETPACKET_H_

#include "MACAddr.h"

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
	vector<uint8_t> payload;

	APSEthernetPacket();
	APSEthernetPacket(const MACAddr &, const MACAddr &, APSCommand_t, const uint32_t &);

	static const size_t NUM_HEADER_BYTES = 24;

	vector<uint8_t> serialize() const ;
	inline size_t numBytes() const {return NUM_HEADER_BYTES + payload.size();};
};

#endif //APSETHERNETPACKET_H_