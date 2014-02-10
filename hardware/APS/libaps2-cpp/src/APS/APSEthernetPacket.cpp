#include "APSEthernetPacket.h"

#ifndef _WIN32
#include "arpa/inet.h"
#endif

APSEthernetPacket::APSEthernetPacket() : header{{}, {}, APS_PROTO, 0, {0}, 0}, payload(0){};

APSEthernetPacket::APSEthernetPacket(const APSCommand_t & command) :
		header{{}, {}, APS_PROTO, 0, command, 0}, payload(0){};

APSEthernetPacket::APSEthernetPacket(const APSCommand_t & command, const uint32_t & addr) :
		header{{}, {}, APS_PROTO, 0, command, addr}, payload(0){};

APSEthernetPacket::APSEthernetPacket(const MACAddr & destMAC, const MACAddr & srcMAC, APSCommand_t command, const uint32_t & addr) :
		header{destMAC, srcMAC, APS_PROTO, 0, command, addr}, payload(0){};

APSEthernetPacket::APSEthernetPacket(const vector<uint8_t> & packetData){
	/*
	Create a packet from a byte array returned by pcap.
	*/
	//Helper function to turn two network bytes into a uint16_t or uint32_t assuming big-endian network byte order
	auto bytes2uint16 = [&packetData](size_t offset) -> uint16_t {return (packetData[offset] << 8) + packetData[offset+1];};
	auto bytes2uint32 = [&packetData](size_t offset) -> uint32_t {return (packetData[offset] << 24) + (packetData[offset+1] << 16) + (packetData[offset+2] << 8) + packetData[offset+3] ;};

	std::copy(packetData.begin(), packetData.begin()+6, header.dest.addr.begin());
	std::copy(packetData.begin()+6, packetData.begin()+12, header.src.addr.begin());
	header.frameType = bytes2uint16(12);
	header.seqNum = bytes2uint16(14);
	header.command.packed = bytes2uint32(16);

	size_t myOffset;
	//not all return packets have an address; if-block on command type and whether it is an acknowledge
	if (!header.command.ack && needs_address(APS_COMMANDS(header.command.cmd))){
		header.addr = bytes2uint32(20);
		myOffset = 24;
	}
	else{
		myOffset = 20;
	}
	payload.clear();
	payload.reserve((packetData.size() - myOffset)/4);
	while(myOffset < packetData.size()){
		payload.push_back(bytes2uint32(myOffset));
		myOffset += 4;
	}
}

vector<uint8_t> APSEthernetPacket::serialize() const {
	/*
	 * Serialize a packet to a vector of bytes for transmission.
	 * Handle host to network byte ordering here
	 */
	vector<uint8_t> outVec;
	outVec.resize(numBytes(), 0);

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
	//TODO: command count field
	uint32_t myuint32;
	start = reinterpret_cast<uint8_t*>(&myuint32);
	myuint32 = htonl(header.command.packed);
	std::copy(start, start+4, insertPt); insertPt += 4;

	//Address
	if (needs_address(APS_COMMANDS(header.command.cmd))){
		myuint32 = htonl(header.addr);
		std::copy(start, start+4, insertPt); insertPt += 4;
	}

	//Data
	for (auto word : payload){
		myuint32 = htonl(word);
		std::copy(start, start+4, insertPt); insertPt += 4;
	}

	return outVec;
}

size_t APSEthernetPacket::numBytes() const{
	size_t trueSize = needs_address(APS_COMMANDS(header.command.cmd)) ? NUM_HEADER_BYTES + 4*payload.size() : NUM_HEADER_BYTES - 4 + 4*payload.size() ;
	return std::max(trueSize, static_cast<size_t>(64)); 
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
	myPacket.header.command.cmd = static_cast<uint32_t>(APS_COMMANDS::STATUS);
	myPacket.header.command.mode_stat = APS_STATUS_HOST;
	myPacket.header.command.cnt = 0x00;

	return myPacket;
}



string print_APSCommand(const APSCommand_t & cmd) {
    std::ostringstream ret;

    ret << std::hex << cmd.packed << " =";
    ret << " ACK: " << cmd.ack;
    ret << " SEQ: " << cmd.seq;
    ret << " SEL: " << cmd.sel;
    ret << " R/W: " << cmd.r_w;
    ret << " CMD: " << cmd.cmd;
    ret << " MODE/STAT: " << cmd.mode_stat;
    ret << std::dec << " cnt: " << cmd.cnt;
    return ret.str();
}