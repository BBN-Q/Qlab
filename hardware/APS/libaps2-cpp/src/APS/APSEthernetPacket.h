
#ifndef APSETHERNETPACKET_H_
#define APSETHERNETPACKET_H_

#include "headings.h"
#include "MACAddr.h"

//Some bitfield unions for packing/unpacking the commands words
//APS Command Protocol 
//ACK SEQ SEL R/W CMD<3:0> MODE/STAT CNT<15:0>
//31 30 29 28 27..24 23..16 15..0
//ACK .......Acknowledge Flag. Set in the Acknowledge Packet returned in response to a
// Command Packet. Must be zero in a Command Packet.
// SEQ............Set for Sequence Error. MODE/STAT = 0x01 for skip and 0x00 for duplicate.
// SEL........Channel Select. Selects target for commands with more than one target. Zero
// if not used. Unmodified in the Acknowledge Packet.
// R/W ........Read/Write. Set for read commands, cleared for write commands. Unmodified
// in the Acknowledge Packet.
// CMD<3:0> ....Specifies the command to perform when the packet is received by the APS
// module. Unmodified in the Acknowledge Packet. See section 3.8 for
// information on the supported commands.
// MODE/STAT....Command Mode or Status. MODE bits modify the operation of some
// commands. STAT bits are returned in the Acknowledge Packet to indicate
// command completion status. A STAT value of 0xFF indicates an invalid or
// unrecognized command. See individual command descriptions for more
// information.
// CNT<15:0> ...Number of 32-bit data words to transfer for a read or a write command. Note
// that the length does NOT include the Address Word. CNT must be at least 1.
// To meet Ethernet packet length limitations, CNT must not exceed 366.
typedef union {
	struct {
	uint32_t cnt : 16;
	uint32_t mode_stat : 8;
	uint32_t cmd : 4;
	uint32_t r_w : 1;
	uint32_t sel : 1;
	uint32_t seq : 1;
	uint32_t ack : 1;
	};
	uint32_t packed;
} APSCommand_t;

string print_APSCommand(const APSCommand_t & command);

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
