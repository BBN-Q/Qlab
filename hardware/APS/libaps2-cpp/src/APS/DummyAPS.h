
#ifndef DUMMYAPS_H_
#define DUMMYAPS_H_

#include <vector>
#include <string>
#include <cstdio>
#include <map>
#include <sstream>
#include <set>
#include <chrono>

#include "aps2.h"

using std::vector;
using std::string;
using std::map;
using std::ostringstream;

using namespace APS2;

class DummyAPS
{
public:
	
	unsigned char * packetCallback(const void * data, size_t & length);  

	DummyAPS( string dev);
	~DummyAPS() {};

	
private:
	unsigned char outboundPacket_[1500];
	struct APS_Status_Registers statusRegs_;

	uint16_t seqnum_;

	std::chrono::time_point<std::chrono::steady_clock> bootTime_;

	size_t reset();

	unsigned int uptime();

	size_t recv_fpga_file(const void * data,  size_t & length);
	size_t select_fpga_program();

};

#endif
