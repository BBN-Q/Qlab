
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

	struct DACRegisters {
		uint8_t interrupt;
		uint8_t controller;
		uint8_t sd;
		uint8_t msdMhd;
	};

	static const int frameLenWords = 375;

	uint32_t outboundPacket_[frameLenWords];
	uint32_t *outboundPacketPtr_;
	struct APS_Status_Registers statusRegs_;

	uint16_t seqnum_;

	std::chrono::time_point<std::chrono::steady_clock> bootTime_;

	size_t reset();

	unsigned int uptime();

	size_t recv_fpga_file(uint32_t * data,  size_t & length);
	size_t select_fpga_program();
	size_t user_io(uint32_t * data,  size_t & length);
	size_t chip_config(uint32_t * data,  size_t & length);

	size_t status(uint32_t * data,  size_t & length);

	uint8_t pll_cycles_;
	uint8_t pll_bypass_;

	vector<DACRegisters> dacs;

	map<uint32_t, uint32_t> user_registers_;

};

#endif
