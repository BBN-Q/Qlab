#include "APS2.h"
#include <sstream>

using std::ostringstream;
using std::endl;


string APS2::printStatusRegisters(const APS_Status_Registers & status) {
	ostringstream ret;

	ret << "Host Firmware Version = " << std::hex << status.hostFirmwareVersion << endl;
	ret << "User Firmware Version = " << std::hex << status.userFirmwareVersion << endl;
	ret << "Configuration Source  = " << status.configurationSource << endl;
	ret << "User Status           = " << status.userStatus << endl;
	ret << "DAC 0 Status          = " << status.dac0Status << endl;
	ret << "DAC 1 Status          = " << status.dac1Status << endl;
	ret << "PLL Status            = " << status.pllStatus << endl;
	ret << "VCXO Status           = " << status.vcxoStatus << endl;
	ret << "Send Packet Count     = " << status.sendPacketCount << endl;
	ret << "Recv Packet Count     = " << status.receivePacketCount << endl;
	ret << "Seq Skip Count        = " << status.sequenceSkipCount << endl;
	ret << "Seq Dup  Count        = " << status.sequenceDupCount << endl;
	ret << "Uptime                = " << status.uptime << endl;
	ret << "Reserved 1            = " << status.reserved1 << endl;
	ret << "Reserved 2            = " << status.reserved2 << endl;
	ret << "Reserved 3            = " << status.reserved3 << endl;
	return ret.str();
}

string APS2::printAPSCommand(APSCommand_t & cmd) {
    ostringstream ret;

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

string APS2::printAPSChipCommand(APSChipConfigCommand_t & cmd) {
    ostringstream ret;

    ret << std::hex << cmd.packed << " =";
    ret << " Target: " << cmd.target;
    ret << " SPICNT_DATA: " << cmd.spicnt_data;
    ret << " INSTR: " << cmd.instr;
    return ret.str();
}



uint32_t * APS2::getPayloadPtr(uint32_t * frame) {
   frame += sizeof(APSEthernetHeader) / sizeof(uint32_t);
   return frame;
}






