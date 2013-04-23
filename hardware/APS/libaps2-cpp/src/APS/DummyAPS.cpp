#include "DummyAPS.h"

#include <iostream>
#include <cstring>
#include "EthernetControl.h"

using std::cout;
using std::endl;

DummyAPS::DummyAPS( string dev ) {


	memset(&statusRegs_, 0, sizeof(struct APS_Status_Registers));

	statusRegs_.hostFirmwareVersion = 0x000A0001;
	statusRegs_.userFirmwareVersion = 0x00000001;
	statusRegs_.configurationSource = BASELINE_IMAGE;
	
    EthernetControl::debugAPSEcho(dev,  this);
}

unsigned char * DummyAPS::packetCallback(const void * data, size_t & length) {

	APSEthernetHeader * eh = (APSEthernetHeader *) data;
    APSEthernetHeader * dh = (APSEthernetHeader *) outboundPacket_;

    // copy inbound packet to outbound
    memcpy(outboundPacket_, data, length);

	cout << "Recv Src: " << EthernetControl::print_ethernetAddress(eh->src);
    cout << " Dest: " << EthernetControl::print_ethernetAddress(eh->dest);
    cout << " Command: " << APS2::printAPSCommand(&(eh->command)) << endl;

    // update sequece number information
    
    if (eh->seqNum != 0) {
        if (eh->seqNum == seqnum_) statusRegs_.sequenceDupCount++;
        if (eh->seqNum > (seqnum_ + 1)) statusRegs_.sequenceSkipCount++;
        seqnum_ = eh->seqNum;
    }

    statusRegs_.receivePacketCount++;

    if (dh->command.cmd == APS_COMMAND_USERIO_ACK || 
        dh->command.cmd == APS_COMMAND_FPGACONFIG_ACK ) {
        dh->command.ack = 1;
    }

    if (eh->command.cmd == APS_COMMAND_RESET) {
    	length = reset();
    } 

    if (length > 0) {
        // packet will be sent so update count
        statusRegs_.sendPacketCount++;
    }

    return outboundPacket_;

}

size_t DummyAPS::reset() {

    cout << "DummyAPS::reset()" << endl;

    APSEthernetHeader * dh = (APSEthernetHeader *) outboundPacket_;

    // reset status register values
    
    statusRegs_.sendPacketCount = 0;
    statusRegs_.receivePacketCount = 0;
    statusRegs_.sequenceSkipCount = 0;
    statusRegs_.sequenceDupCount = 0;
    statusRegs_.uptime = 0;

    bootTime_ = std::chrono::steady_clock::now();

    // copy status registers
    memcpy(getPayloadPtr(outboundPacket_), &statusRegs_, sizeof(struct APS_Status_Registers));
    
    return sizeof(struct APSEthernetHeader) + sizeof(struct APS_Status_Registers);
}

unsigned int DummyAPS::uptime() {
    std::chrono::time_point<std::chrono::steady_clock> t;
    t = std::chrono::steady_clock::now();
    return std::chrono::duration_cast<std::chrono::milliseconds>(t - bootTime_).count();
}

