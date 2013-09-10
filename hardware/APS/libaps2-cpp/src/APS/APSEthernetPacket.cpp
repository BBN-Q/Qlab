#include "APSEthernetPacket.h"

APSEthernetPacket::APSEthernetPacket() : header{{}, {}, APSEthernet::APS_PROTO, 0, {0}, 0}, payload(0){};

APSEthernetPacket::APSEthernetPacket(const MACAddr & destMAC, const MACAddr & srcMAC, APSCommand_t command, const uint32_t & addr) :
		header{destMAC, srcMAC, APSEthernet::APS_PROTO, 0, command, addr}, payload(0){};

APSEthernetPacket::APSEthernetPacket(const u_char * packet, size_t packetLength){
	/*
	Create a packet from a byte array returned by pcap.
	*/
	//TODO: check byte ordering
	payload.resize(packetLength - NUM_HEADER_BYTES,0);
	std::copy(packet, packet+6, header.dest.addr.begin());
	std::copy(packet+6, packet+12, header.src.addr.begin());
	std::copy(packet+12, packet+14, reinterpret_cast<uint8_t*>(&header.frameType));
	std::copy(packet+14, packet+16, reinterpret_cast<uint8_t*>(&header.seqNum));
	std::copy(packet+16, packet+20, reinterpret_cast<uint8_t *>(&header.command));
	std::copy(packet+20, packet+24, reinterpret_cast<uint8_t*>(&header.addr));
	payload.resize(packetLength - NUM_HEADER_BYTES,0);
	std::copy(reinterpret_cast<const uint8_t*>(packet)+24, reinterpret_cast<const uint8_t*>(packet)+25, payload.begin());
}

vector<uint8_t> APSEthernetPacket::serialize() const {
	/*
	 * Serialize a packet to a vector of bytes for transmission.
	 * Handle host to network byte ordering here
	 */
	vector<uint8_t> outVec;
	outVec.resize(NUM_HEADER_BYTES + payload.size());

	//Push on the destination and source mac address
	auto insertPt = outVec.begin();
	std::copy(header.dest.addr.begin(), header.dest.addr.end(), insertPt); insertPt += 6;
	std::copy(header.src.addr.begin(), header.src.addr.end(), insertPt); insertPt += 6;

	//Push on ethernet protocol
	uint16_t myuint16;
	uint8_t * start;
	start = reinterpret_cast<uint8_t*>(&myuint16);
	myuint16 = htons(header.frameType);
	std::copy(start, start+2, insertPt); insertPt += 2;

	//Sequence number
	myuint16 = htons(header.seqNum);
	std::copy(start, start+2, insertPt); insertPt += 2;

	//Command
	uint32_t myuint32;
	start = reinterpret_cast<uint8_t*>(&myuint32);
	myuint32 = htonl(header.command.packed);
	std::copy(start, start+4, insertPt); insertPt += 4;

	//Address
	myuint32 = htonl(header.addr);
	std::copy(start, start+4, insertPt); insertPt += 4;

	//Data
	std::copy(payload.begin(), payload.end(), insertPt);

	return outVec;
}

APSEthernetPacket APSEthernetPacket::create_broadcast_packet(){
	/*
	 * Helper function to put together a broadcast status packet that all APS units should respond to.
	 */
	APSEthernetPacket myPacket;

	//Put the broadcast FF:FF:FF:FF:FF:FF in the MAC destination address
	std::fill(myPacket.header.dest.addr.begin(), myPacket.header.dest.addr.end(), 0xFF);

	//Fill out the host register status command
	myPacket.header.command.ack = 0;
	myPacket.header.command.r_w = 1;
	myPacket.header.command.cmd = APS_COMMAND_STATUS;
	myPacket.header.command.mode_stat = APS_STATUS_HOST;
	myPacket.header.command.cnt = 0x10; //minimum length packet

	return myPacket;
}

