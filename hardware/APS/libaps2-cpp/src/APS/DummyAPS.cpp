#include "DummyAPS.h"

#include <iostream>
#include <fstream>
#include <cstring>
#include <cstdlib>
#include <thread>
#include "EthernetControl.h"

using std::cout;
using std::endl;
using std::ofstream;



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
    cout << " Len: " << length;
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

    
    if ((eh->command.cmd == APS_COMMAND_FPGACONFIG_ACK) || 
        (eh->command.cmd == APS_COMMAND_FPGACONFIG_NACK)
       ) {
        length = recv_fpga_file(data, length);
    }

    if (eh->command.cmd == APS_COMMAND_FPGACONFIG_CTRL) {
        length = select_fpga_program();
    }


    if (length > 0) {
        // packet will be sent so update count
        statusRegs_.sendPacketCount++;
    }

    dh->seqNum = eh->seqNum;

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

    // remove fpga bit file
    ofstream bitFile ("fpga.bit", ofstream::out | ofstream::binary);
    bitFile.close();

    // copy status registers
    memcpy(getPayloadPtr(outboundPacket_), &statusRegs_, sizeof(struct APS_Status_Registers));
    
    return sizeof(struct APSEthernetHeader) + sizeof(struct APS_Status_Registers);
}

unsigned int DummyAPS::uptime() {
    std::chrono::time_point<std::chrono::steady_clock> t;
    t = std::chrono::steady_clock::now();
    return std::chrono::duration_cast<std::chrono::milliseconds>(t - bootTime_).count();
}

size_t DummyAPS::recv_fpga_file(const void * frameData,  size_t & length) {

    ofstream bitFile ("fpga.bit", ofstream::out | ofstream::binary |  ofstream::app);

    APSEthernetHeader * eh = (APSEthernetHeader *) frameData;
    APSEthernetHeader * dh = (APSEthernetHeader *) outboundPacket_;
    std::fill(outboundPacket_, outboundPacket_ + length, 0);

    zeroAPSCommand(&(dh->command));
    dh->command.cmd = APS_COMMAND_FPGACONFIG_ACK;
    dh->command.ack = 1;

    cout << "recv_fpga_file: ";

    unsigned char *data;

    uint32_t addr;

    size_t payloadLen;

    data = (unsigned char *) frameData;
    data += sizeof(APSEthernetHeader);

    payloadLen = length - sizeof(APSEthernetHeader);

    if (payloadLen < sizeof(uint32_t)) cout << "Error payload does not contain addr" << endl;

    addr = eh->addr;

    bitFile.seekp(addr * sizeof(uint32_t));

    // convert from bytes to words
    payloadLen /= sizeof(uint32_t); 

    // test to make sure length matches
    if (payloadLen != eh->command.cnt) {
        dh->command.mode_stat = 0x01;
        cout << "Error payload length " << payloadLen << " does not match cnt " << eh->command.cnt << endl;
    }  else {
        cout << "addr = " << std::hex << addr << " len = " << std::dec << payloadLen << endl;
        bitFile.write((const char *) data, payloadLen*sizeof(uint32_t));
    }

    bitFile.close();

    // ack frame if required
    if (eh->command.cmd == APS_COMMAND_FPGACONFIG_ACK) {
        return sizeof(struct APSEthernetHeader);
    } 

    return 0;
}

size_t DummyAPS::select_fpga_program() {
    // mimic a reprogram
    
    cout << "select_fpga_program" << endl;

    // sleep random amount of time and then send host interface registers

    std::chrono::milliseconds dura( rand() % 1000 );
    std::this_thread::sleep_for( dura );

    // copy status registers
    memcpy(getPayloadPtr(outboundPacket_), &statusRegs_, sizeof(struct APS_Status_Registers));
    
    return sizeof(struct APSEthernetHeader) + sizeof(struct APS_Status_Registers);
}
