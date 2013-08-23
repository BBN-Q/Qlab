#include "EthernetControl.h"
#include "pcap.h"
#include "logger.h"

#ifdef _WIN32
    #include <winsock2.h>
    #include <iphlpapi.h>
#else
	#include <arpa/inet.h>
#endif

#include <iostream>
#include <fstream>
#include <iomanip>
#include <chrono>
#include <set>
#include <algorithm>

using std::cout;
using std::endl;
using std::min;

#include <ctime>
#include <cstring>
#include <cmath>

vector<EthernetControl::EthernetDevInfo>  EthernetControl::pcapDevices_;
std::set<string> EthernetControl::APSunits_;
std::map<string, EthernetControl::EthernetDevInfo> EthernetControl::APS2device_;

APSEthernetPacket::APSEthernetPacket() : header{{0}, {0}, EthernetControl::APS_PROTO, 0, {0}, 0}, payload(0){};

APSEthernetPacket::APSEthernetPacket(const EthernetControl & controller, const APSCommand_t & command, const uint32_t & addr) :
		header{{controller.apsMac_[0],controller.apsMac_[1],controller.apsMac_[2],controller.apsMac_[3],controller.apsMac_[4],controller.apsMac_[5]},
		       {controller.pcapDevice_->macAddr[0],controller.pcapDevice_->macAddr[1],controller.pcapDevice_->macAddr[2],controller.pcapDevice_->macAddr[3],controller.pcapDevice_->macAddr[4],controller.pcapDevice_->macAddr[5] },
               EthernetControl::APS_PROTO, controller.seqNum_, command, addr}, payload(0){};

bool EthernetControl::pcapRunning = false;

EthernetControl::EthernetControl() :  seqNum_{0}, apsHandle_{0}{
    FILE_LOG(logINFO) << "New EthernetControl";
	// get list of interfaces from pcap
	get_network_devices();
}

bool EthernetControl::isvalidMACAddress(string deviceID) {
    // validates against XX:XX:XX:XX:XX:XX
    
    static const int MAC_STR_LEN = 17;

    // test length
    if (deviceID.length() != MAC_STR_LEN) return false;

    // test characters
    for(int cnt; cnt < MAC_STR_LEN; cnt++) {
        if ((cnt + 1)  % 3 == 0 && deviceID[cnt] != ':') {
            return false;
        }
    }
    return true;
}

void EthernetControl::parseMACAddress(string macString, uint8_t * macBuffer) {
    for(int cnt = 0; cnt < MAC_ADDR_LEN; cnt++) {
        // copy mac address from string
        sscanf(macString.substr(3*cnt,2).c_str(), "%x", &macBuffer[cnt]);
    }
}

EthernetControl::ErrorCodes EthernetControl::connect(string deviceID) {
    FILE_LOG(logDEBUG) << "Connecting to device: " << deviceID;

    if (!isvalidMACAddress(deviceID)) {
        return INVALID_APS_ID;
    }

    if (APSunits_.find(deviceID) == APSunits_.end()) {
        return INVALID_APS_ID;
    }

    // double check to make sure device is in map
    if (APS2device_.find(deviceID) == APS2device_.end()) {
        return INVALID_APS_ID; 
    }

    deviceID_ = deviceID;

    set_network_device(APS2device_[deviceID].name);

    // set apsMAC to device ID
    parseMACAddress(deviceID, apsMac_);

    // build filter
    filter_ =  getPointToPointFilter(pcapDevice_->macAddr, apsMac_);

    FILE_LOG(logDEBUG1) << "Using filter " << filter_;

    apsHandle_ = start_capture(pcapDevice_->name, filter_);

    if (!apsHandle_) {
         FILE_LOG(logERROR) << "Error starting capture: " << string(pcap_geterr(apsHandle_));
     return INVALID_APS_ID;
    }

	return SUCCESS;
}

size_t EthernetControl::write(APSCommand_t & command, uint32_t addr,  vector<uint32_t> & data ) {
    vector<uint8_t> bytes = words2bytes(data);
    return write(command,addr, bytes ); 
}

vector<APSEthernetPacket> EthernetControl::framer(const APSCommand_t & command, uint32_t addr, const vector<uint8_t> & data){
    /* Load data into custom UDP ethernet frames.
     Each Ethernet frame carries 1500-10 bytes of payload so may have to split across multiple packets
    */
    static const size_t MAX_FRAME_PAYLOAD = 1500 - 10 ; // 2 bytes seqnum; 4 bytes command; 4 bytes address

	vector<APSEthernetPacket> outVec;

    auto dataItterator = data.begin();
	size_t bytesRemaining = data.size();

    while (bytesRemaining > 0){
        //Create a new packet
        APSEthernetPacket newPacket(*this, command, addr);
        size_t bytesToSend = min(bytesRemaining, MAX_FRAME_PAYLOAD);
        //TODO: align payload at 32bit boundaries and set count in command
        //Fill the payload
        newPacket.payload.reserve(bytesToSend);
        std::copy(dataItterator, dataItterator + bytesToSend, newPacket.payload.begin());

        //Push it onto the output vector
        outVec.push_back(newPacket);

        addr += bytesToSend;
        bytesRemaining -= bytesToSend;
    }

    return outVec;
};

int EthernetControl::send_packet(const APSEthernetPacket & packet){
    //Platform independent way to send a single packet
    FILE_LOG(logDEBUG2) << "Write Frame";
    FILE_LOG(logDEBUG2) << " Src: " << print_ethernetAddress(packet.header.src)
                        << " Dest: " << print_ethernetAddress(packet.header.dest);
    FILE_LOG(logDEBUG2) << " Seqnum " << packet.header.seqNum << " Command: " << APS2::printAPSCommand(packet.header.command)
                        << " + " <<  packet.payload.size() << " Bytes";

    if (pcap_sendpacket(apsHandle_, packet.serialize().data(), packet.numBytes()) != 0) {
        FILE_LOG(logERROR) << "Error sending command: " << string(pcap_geterr(apsHandle_));
     }
    return 0;
}

APSCommand_t EthernetControl::wait_for_ack(){

	APSCommand_t response;
	//Wait for the acknowledge packet back from the APS and log any errors.
	FILE_LOG(logDEBUG) << "Wait for ACK";
	read(nullptr, 0, &response);
	FILE_LOG(logDEBUG) << "RECV ACK " << APS2::printAPSCommand(response);
	if (!response.ack) {
		FILE_LOG(logERROR) << "APS FPGA Write command acknowlege expected";
	} else {

	}
	if (response.mode_stat == 0x1) {
		FILE_LOG(logERROR) << "APS FPGA Write: Invalid CNT";
	}
	if (response.mode_stat == 0x2) {
		FILE_LOG(logERROR) << "APS FPGA Write: Invalid starting offset";
	}
	return response;
}

int EthernetControl::send_packets(const vector<APSEthernetPacket>::iterator & start, const vector<APSEthernetPacket>::iterator & stop){
    //Send a group of packets
    //With pcap it is important to queue the packets for performance
    //TODO: needs to be checked
    //Allocate the queue
    size_t queueSize = 0;
    for (auto packetIter = start; packetIter != stop; ++packetIter) queueSize += packetIter->numBytes();
    pcap_send_queue * myQueue = pcap_sendqueue_alloc(queueSize)

    //Load the packets
    pcap_pkthdr dummyHeader;
    dummyHeader.ts = 0;
    for (auto packetIter = start; packetIter != stop; ++packetIter){
        dummyHeader.caplen = (*packetIter).numBytes();
        dummyHeader.len = (*packetIter).numBytes();
        pcap_sendqueue_queue(myQueue, &dummyHeader, packet.seralize());
    }

    //We're not setting timestamps so sync parameter is zero
    pcap_sendqueue_transmit(apsHandle_, myQueue, 0);

    //Free the queue memory
    pcap_sendqueue_destroy(myQueue);

    //For now just send the packets one at a time
    for (auto packetIter = start; packetIter != stop; ++packetIter) send_packet(*packetIter);

    return 0;
}

size_t EthernetControl::write(APSCommand_t & command, uint32_t addr, vector<uint8_t> & data) {

    //Convert the data to a vector custom ethernet frames
    vector<APSEthernetPacket> framesToSend = framer(command, addr, data)

    //Send them out. The APS2 has a buffer for 22 frames.  The framer asks for an acknowledge every 11.
    //Send 22 then wait for an acknowledge then send another 11 and repeat. 

    //Send the first 11 to get things started
    size_t numFramesLeft = framesToSend.size();
    auto nextFrame = framesToSend.begin();
    if (numFramesLeft > 11){
        send_packets(nextFrame, nextFrame + 11);
        nextFrame += 11;    
        numFramesLeft -= 11;
    }

    while (numFramesLeft > 11) {
        //Send out a group of 11 of packets
        send_packets(nextFrame, nextFrame + 11);
        nextFrame += 11;
        numFramesLeft -= 11;

        //Wait for acknowledge from the previous set
        wait_for_ack();
    }

    //Send the final bunch
    if (numFramesLeft > 0){
        send_packets(nextFrame, nextFrame + numFramesLeft);
    }
    //Wait for final acknowledgment
    wait_for_ack();

	return SUCCESS;
}

EthernetControl::ErrorCodes EthernetControl::read(void * data, size_t readLength, APSCommand_t * command) {
    struct pcap_pkthdr *header;
    const unsigned char *pkt_data;

    if (!apsHandle_) return INVALID_APS_ID;

    int retries = 0;

    do {
        int res = pcap_next_ex( apsHandle_, &header, &pkt_data);
    
        if(res > 0) {
            // have packet so process
            APSEthernetHeader * eh = (APSEthernetHeader *) pkt_data;

            packetNTOH(eh);

            size_t payloadLen = header->len - sizeof(APSEthernetHeader);
            size_t copyLen = eh->command.cnt * sizeof(uint32_t);

            if (payloadLen > copyLen && payloadLen > MIN_PAYLOAD_LEN_BYTES) {
                FILE_LOG(logWARNING) << "EthernetControl::Read received larger ethernet frame than expected from command cnt";
                FILE_LOG(logWARNING) << "payloadLen = " << payloadLen << " copyLen = " << copyLen;
            }

            copyLen = min(copyLen, readLength);
            copyLen = min(copyLen, payloadLen);
            
            uint8_t * start = const_cast<uint8_t *>(pkt_data);
            start += sizeof(APSEthernetHeader);

            // if APS command exists copy out for caller
            if (command) {
                *command = eh->command;
            }

            FILE_LOG(logDEBUG2) << "Read Frame: ";
            FILE_LOG(logDEBUG2) << " Src: " << print_ethernetAddress(eh->src) 
                               << " Dest: " << print_ethernetAddress(eh->dest);
            FILE_LOG(logDEBUG2) << " Seqnum " << eh->seqNum << " Command: " << APS2::printAPSCommand(eh->command)
                                << " + " << copyLen << " bytes";

            std::copy(start, start + copyLen, static_cast<uint8_t*>(data) );
            return SUCCESS;
        } else {
            FILE_LOG(logWARNING) << "Read Frame TIMEOUT retries = " << retries;
        }
    } while (++retries < 5);
	return TIMEOUT;
}

EthernetControl::ErrorCodes EthernetControl::set_network_device(string device) {
    FILE_LOG(logDEBUG1) << "EthernetControl::set_network_device: " << device;
    EthernetDevInfo * di = findDeviceInfo(device);
    if (!di) 
        return INVALID_NETWORK_DEVICE;
    pcapDevice_ = di;
    pcapDevice_->isActive = true;
    return SUCCESS;
}

/*******************************************************************************
 * Static Methods 
 *******************************************************************************/

EthernetControl::ErrorCodes EthernetControl::disconnect() {
	return EthernetControl::NOT_IMPLEMENTED;
}

EthernetControl::ErrorCodes EthernetControl::get_device_serials(vector<string> & testSerials) {
    // copy set of APS ethernet addresses as device serial numbers
    testSerials.clear();
    for ( string serial : APSunits_) {
        testSerials.push_back(serial);
    }
    return SUCCESS;
}

unsigned int EthernetControl::get_num_devices() {
    enumerate();
    return APSunits_.size();
}

bool EthernetControl::isOpen(int deviceID) {
	return false;
}

void EthernetControl::get_network_devices() {
	pcap_if_t *alldevs;
	pcap_if_t *d;
    char errbuf[PCAP_ERRBUF_SIZE];
    int i = 0;
    char macAddr[6];

    struct pcap_addr *addr;
    struct sockaddr * saddr;
    struct sockaddr_in *addrIn;

    FILE_LOG(logDEBUG) << "Getting Network Devices";

	/* Retrieve the device list from the local machine */
    if (pcap_findalldevs(&alldevs, errbuf) == -1) {
    	string err(errbuf);
        cout << "Error in pcap_findalldevs_ex: " << err;
    }

    /* store list in map */
    FILE_LOG(logDEBUG1) << "Initializing PCAP Devices:";
    for(d= alldevs; d != NULL; d= d->next) {
        if (!findDeviceInfo(d->name)) {
            
            struct EthernetDevInfo devInfo;
            devInfo.name = string(d->name);
            devInfo.description = string(d->description);
            devInfo.isActive = false;
            getMacAddr(devInfo);
            

            pcapDevices_.push_back(devInfo);
            FILE_LOG(logDEBUG2) << "New PCAP Device:";
            FILE_LOG(logDEBUG2) << "\t" << devInfo.description;
            FILE_LOG(logDEBUG2) << "\t" << devInfo.description2;
            FILE_LOG(logDEBUG2) << "\t" << devInfo.name;
            FILE_LOG(logDEBUG2) << "\t" << print_ethernetAddress(devInfo.macAddr);
            
            // IP address may be obtained here if interested
            // addr = d->addresses;
            
            //while(addr) {
            //    addr = addr->next;
            //}

        }   
    }
    pcap_freealldevs(alldevs);
}

void EthernetControl::getMacAddr(struct EthernetDevInfo & devInfo) {
    /* looks up MAC Address based on device name obtained from winpcap
     * copies mac address into devInfo structure
     * copies a second description string into devInfo structure
     *
     * WARNING: Currently implemented only for windows
     */

    // clear address
    std::fill(devInfo.macAddr,devInfo.macAddr + MAC_ADDR_LEN, 0 );

#ifdef _WIN32
    
    // winpcap names are different than widows names
    // pcap - \Device\NPF_{F47ACE9E-1961-4A8E-BA14-2564E3764BFA}
    // windows - {F47ACE9E-1961-4A8E-BA14-2564E3764BFA}
    // 
    // start by triming input name to only {...}
    size_t start,end;

    start = devInfo.name.find('{');
    end = devInfo.name.find('}');

    if (start == std::string::npos || end == std::string::npos) {
        FILE_LOG(logERROR) << "getMacAddr: Invalid devInfo name";
        return;
    }

    string winName = devInfo.name.substr(start, end-start + 1);
    
    // look up mac addresses using GetAdaptersInfo
    // http://msdn.microsoft.com/en-us/library/windows/desktop/aa365917%28v=vs.85%29.aspx
        
    PIP_ADAPTER_INFO pAdapterInfo;
    PIP_ADAPTER_INFO pAdapter = NULL;
    DWORD dwRetVal = 0;

    ULONG ulOutBufLen = 0;

    // call GetAdaptersInfo with length of 0 to get required buffer size in 
    // ulOutBufLen
    GetAdaptersInfo(pAdapterInfo, &ulOutBufLen);
            
    // allocated memory for all adapters
    pAdapterInfo = (IP_ADAPTER_INFO *) malloc(ulOutBufLen);
    if (!pAdapterInfo) {
        FILE_LOG(logERROR) << "Error allocating memory needed to call GetAdaptersinfo" << endl;
        return;
    }
    
    // call GetAdaptersInfo a second time to get all adapter information
    if ((dwRetVal = GetAdaptersInfo(pAdapterInfo, &ulOutBufLen)) == NO_ERROR) {
        pAdapter = pAdapterInfo;

        // loop over adapters and match name strings
        while (pAdapter) {
            string matchName = string(pAdapter->AdapterName);
            if (winName.compare(matchName) == 0) {
                // copy address
                std::copy(pAdapter->Address, pAdapter->Address + MAC_ADDR_LEN, devInfo.macAddr);
                devInfo.description2 = string(pAdapter->Description);
                //cout << "Adapter Name: " << string(pAdapter->AdapterName) << endl;
                //cout << "Adapter Desc: " << string(pAdapter->Description) << endl;
                //cout << "Adpater Addr: " << print_ethernetAddress(pAdapter->Address) << endl;
            }
            pAdapter = pAdapter->Next;

        }
    }

    if (pAdapterInfo) free(pAdapterInfo);
        
#else
    //On Linux we simply look in /sys/class/net/DEVICE_NAME/address
    std::ifstream devFile(std::string("/sys/class/net/") + devInfo.name + std::string("/address"));
	std::string macAddrStr;
	getline(devFile, macAddrStr);
	parseMACAddress(macAddrStr, devInfo.macAddr);

#endif

}


EthernetControl::EthernetDevInfo * EthernetControl::findDeviceInfo(string device) {
    // find device info based on device name, description or description2
    for (auto it = pcapDevices_.begin();
        it != pcapDevices_.end(); ++it) {
        if (it->name.compare(device) == 0) return &(*it);
        if (it->description.compare(device) == 0) return &(*it);
        if (it->description2.compare(device) == 0) return &(*it);
    }
    return NULL;
}

vector<string> EthernetControl::get_network_devices_names() {
    get_network_devices();
    vector<string> devNames;
    for(auto it = pcapDevices_.begin();
        it != pcapDevices_.end(); ++it) {
        devNames.push_back(it->name);
    }
    return devNames;
}

void EthernetControl::enumerate(unsigned int timeoutSeconds, unsigned int broadcastPeriodSeconds) {
    FILE_LOG(logDEBUG1) << "EthernetControl::enumerate";

    pcap_t *capHandle;

    static const int broadcastPacketLen = 40;
    uint8_t broadcastPacket[broadcastPacketLen];
    APSEthernetHeader *bph;

    int res;
    struct pcap_pkthdr *header;
    const unsigned char *pkt_data;

    get_network_devices();
    for (auto it = pcapDevices_.begin(); it != pcapDevices_.end(); ++it) {
        EthernetDevInfo dev = *it;
        if (!dev.isActive) continue;
        
        string filter = getEnumerateFilter(dev.macAddr);
        capHandle = start_capture(dev.name, filter);

        if (!capHandle) continue;
        
        // build broadcast packet
        std::fill(broadcastPacket, broadcastPacket + broadcastPacketLen, 0);    
        bph = reinterpret_cast< APSEthernetHeader * >(broadcastPacket);
        std::fill(bph->dest, bph->dest + MAC_ADDR_LEN, 0xFF);
        std::copy(dev.macAddr, dev.macAddr + MAC_ADDR_LEN,  bph->src);
        bph->frameType = APS_PROTO;
        bph->command.cmd = APS_COMMAND_STATUS;
        bph->command.mode_stat = APS_STATUS_TEMP;
        bph->command.cnt = 0x10;

        FILE_LOG(logDEBUG1) << "Enumerate Packet: " << APS2::printAPSCommand(bph->command);

        packetHTON(bph); // swap bytes to network order
        
        std::chrono::time_point<std::chrono::steady_clock> start, end, lastBroadcast;

        start = std::chrono::steady_clock::now();

        int totalElapsed = 0;
        int broadcastElapsed = 100; // force broadcast first time through
        while (totalElapsed < timeoutSeconds ) {

            if (broadcastElapsed > broadcastPeriodSeconds) {
                // send enum packet
                FILE_LOG(logDEBUG1) << "Sending Enumerate Packet:";
                
                if (pcap_sendpacket(capHandle, broadcastPacket, broadcastPacketLen) != 0) {
                    FILE_LOG(logERROR) << "Error sending the packet: " << string(pcap_geterr(capHandle));
                }       

                lastBroadcast = std::chrono::steady_clock::now();
            }
            // get available packets

            int res = pcap_next_ex( capHandle, &header, &pkt_data);

            if(res > 0) {
                // have packet so process
                APSEthernetHeader * eh = (APSEthernetHeader *) pkt_data;

                packetNTOH(eh);

                FILE_LOG(logDEBUG3) << "Src: " << print_ethernetAddress(eh->src);
                FILE_LOG(logDEBUG3) << " Dest: " << print_ethernetAddress(eh->dest);
                FILE_LOG(logDEBUG3) << " Command: " << APS2::printAPSCommand(eh->command);

                string devString = print_ethernetAddress(eh->src);
                APSunits_.insert(devString);
                APS2device_[devString] = dev;
            }

            end = std::chrono::steady_clock::now();
            totalElapsed =  std::chrono::duration_cast<std::chrono::seconds>(end-start).count();
            broadcastElapsed =  std::chrono::duration_cast<std::chrono::seconds>(end-lastBroadcast).count();
        } 
    
    }


    for (string aps : APSunits_) {
        FILE_LOG(logINFO) << "Found APS Unit: " << aps;
    }

}

EthernetControl::ErrorCodes EthernetControl::set_device_active(string device, bool isActive) {
    get_network_devices();
    EthernetDevInfo * di = findDeviceInfo(device);
    if (!di) {
        FILE_LOG(logERROR) << "Device: " << device << " not found";
        return INVALID_NETWORK_DEVICE;
    } else {
        FILE_LOG(logDEBUG1) << "Device: " << device << " FOUND";
    }
    
    di->isActive = isActive;
    return SUCCESS;
}

string EthernetControl::print_ethernetAddress(const uint8_t * addr){
    ostringstream ss;
    for(int cnt = 0; cnt < (MAC_ADDR_LEN - 1); cnt++) {
        ss << std::hex << std::setfill('0') << std::setw(2) << static_cast<int>(addr[cnt]) << ":";
    }
    ss <<  std::hex << std::setfill('0') << std::setw(2) <<  static_cast<int>(addr[5]) ;
    return ss.str();
}

void EthernetControl::packetHTON(APSEthernetHeader * frame) {

    if (frame->frameType != APS_PROTO ) {
        // packet is not an APS packet do not swap 
        return;
    }
    frame->frameType = htons(frame->frameType);
    frame->seqNum = htons(frame->seqNum);
    frame->command.packed = htonl(frame->command.packed);
    frame->addr    = htonl(frame->addr);
}

void EthernetControl::packetNTOH(APSEthernetHeader * frame) {
    frame->frameType = ntohs(frame->frameType);
    if (frame->frameType != APS_PROTO ) {
        // packet is not an APS packet do not swap 
        return;
    }
    frame->seqNum = ntohs(frame->seqNum);
    frame->command.packed = ntohl(frame->command.packed);
    frame->addr    = ntohl(frame->addr);
}


// winpcap filters
// see: http://www.winpcap.org/docs/docs_41b5/html/group__language.html

string EthernetControl::getPointToPointFilter(uint8_t * localMacAddr, uint8_t *apsMacAddr) {

    ostringstream filter;

    // build filter
    filter << "ether src " << print_ethernetAddress(apsMacAddr);
    filter << " and ether dst " << print_ethernetAddress(localMacAddr);
    filter << " and ether proto " << APS_PROTO;

    return filter.str();
}

string EthernetControl::getEnumerateFilter(uint8_t * localMacAddr) {
    ostringstream filter;
    // build filter
    filter << "ether dst " << print_ethernetAddress(localMacAddr);
    filter << " and ether proto " << APS_PROTO;
    return filter.str();
}

string EthernetControl::getWatchFilter() {
    
    ostringstream filter;
    
    // build filter
    filter << "broadcast and ether proto " << APS_PROTO;
    return filter.str();
    
}

EthernetControl::ErrorCodes EthernetControl::applyFilter(pcap_t * capHandle, string & filter) {

    FILE_LOG(logDEBUG3) << "Setting filter to: " << filter << endl;

    u_int netmask=0xffffff; // ignore netmask 
    struct bpf_program filterCode;

    if (pcap_compile(capHandle, &filterCode, filter.c_str(), true, netmask) < 0 ) {
        cout << "Error to compiling enumerate packet filter. Check the syntax" << endl;
        return INVALID_PCAP_FILTER;
    }

    // set filter
    if (pcap_setfilter(capHandle, &filterCode) < 0) {
         cout << "Error setting the filter" << endl;
        /* Free the device list */
        return INVALID_PCAP_FILTER;
    }
    return SUCCESS;
}

#ifdef DEBUGAPS 
void EthernetControl::debugAPSEcho(string device, DummyAPS * aps) {
    // debug routine to echo APS packets back to sender
    // used for testing of EthernetControl without APS unit
    
    cout << "Starting APS Debug Echo" << endl;
 
    pcap_t *capHandle;


    int res;
    struct pcap_pkthdr *header;
    const unsigned char *pkt_data;

    size_t sendLength;
    unsigned char * outbound_pkt;

    get_network_devices();
    EthernetDevInfo * di = findDeviceInfo(device);
    if (!di) {
        cout << "Error could not find device: " << device << endl;
        return;
    }
  
    ostringstream filter;
    // build filter
    filter << "(ether dst " << print_ethernetAddress(di->macAddr);
    filter << " or broadcast)";
    filter << " and ether proto " << APS_PROTO;
    string filterStr = filter.str();

    capHandle = start_capture(di->name, filterStr);

    if (!capHandle) return;

    while ( true ) {
       
        int res = pcap_next_ex( capHandle, &header, &pkt_data);

        if(res > 0) {
            // have packet so process
            APSEthernetHeader * eh = (APSEthernetHeader *) pkt_data;
            APSEthernetHeader * dh = eh;


            // skip packets where source and dest are the same
            bool same = true;
            for (int cnt = 0; cnt < MAC_ADDR_LEN; cnt++) {
                if (eh->src[cnt] !=  eh->dest[cnt]) same = false;
            }

            if (same) continue;

            packetNTOH(eh); // swap to host

            sendLength =  header->len;

            if (aps)  {
                outbound_pkt = aps->packetCallback(pkt_data, sendLength); // sendLength should change
                dh = (APSEthernetHeader *) outbound_pkt;
            } else {
                cout << "Src: " << print_ethernetAddress(eh->src);
                cout << " Dest: " << print_ethernetAddress(eh->dest);
                cout << " Command: " << APS2::printAPSCommand(eh->command) << endl;

            }

            // continue if there is no packet to send back
            if (sendLength == 0) continue; 

            // copy send length
            dh->command.cnt = ceil( 1.0 * sendLength / sizeof(uint32_t));

            // set src to dest
            std::copy(eh->src, eh->src + MAC_ADDR_LEN, dh->dest);
            // set source
            std::copy(di->macAddr, di->macAddr + MAC_ADDR_LEN,  dh->src);
            
            setcolor(dark_green,black);
            cout << "Send";
            setcolor(white,black);
            cout << " SeqNum: " << dh->seqNum;
            //cout << " Src: " << print_ethernetAddress(dh->src);
            //cout << " Dest: " << print_ethernetAddress(dh->dest);
            cout << " Len: " << sendLength;
            cout << " Command: " << APS2::printAPSCommand(dh->command) << endl;

            dh->frameType = APS_PROTO;

            packetHTON(dh); // swap to net

            if (pcap_sendpacket(capHandle, outbound_pkt, sendLength) != 0) {
                FILE_LOG(logERROR) << "Error sending the packet: " << string(pcap_geterr(capHandle));
            } 
        }
    } 
    
}
#endif

pcap_t * EthernetControl::start_capture(string & devName, string & filter) {
    pcap_t * capHandle;
    char errbuf[PCAP_ERRBUF_SIZE];
    capHandle = pcap_open_live(devName.c_str(),          // name of the device
                          1500,            // portion of the packet to capture
                          true,    // promiscuous mode
                          pcapTimeoutMS,             // read timeout
                          errbuf            // error buffer
                          );
    if (!capHandle) {
        cout << "Error open pcap for device: " << devName;
        return 0;;
    }

    if (pcap_datalink(capHandle) != DLT_EN10MB) {
        FILE_LOG(logERROR) << "Network Device is not Ethernet";
        return 0;
    }
    // applfy filter to only get reply directed from APS to local machine
    applyFilter(capHandle, filter);
    return capHandle;   
}

size_t EthernetControl::load_bitfile(vector<uint8_t> fileData, uint32_t addr) {

    vector<uint8_t> buffer;

    APSCommand_t command;
    APSCommand_t response;

    FILE_LOG(logDEBUG) << "program_FPGA: " << fileData.size() << " Bytes @ " << addr;

    const size_t max_fpga_payload_len = MAX_PAYLOAD_LEN_BYTES - sizeof(uint32_t);

    // determine number of frames based on max packet length
    // extra uint32_t for offset
    size_t numFrames = fileData.size();
    numFrames = ceil(1.0 * numFrames / max_fpga_payload_len);

    size_t dataOffset = 0;
    size_t dataRemaining = fileData.size();
    size_t copyCount;
    size_t copyIdx = 0;



    for (int frameCnt = 0; frameCnt < numFrames; frameCnt++) {

        // build APS Command
        command.packed = 0;
        
        command.cmd = APS_COMMAND_FPGACONFIG_NACK;
        command.mode_stat = 0;

        copyCount = min(dataRemaining, static_cast<size_t>(MAX_PAYLOAD_LEN_BYTES));
        buffer.clear();
        command.cnt = copyCount / sizeof(uint32_t); // set equal to number of words to be written
        for (int copyIdx = 0; copyIdx < copyCount; copyIdx++)
            buffer.push_back(fileData[dataOffset++]);

        FILE_LOG(logDEBUG) << "Writing frame " << frameCnt << "/" << numFrames;

        write(command, addr, buffer);

        dataRemaining -= copyCount;
        addr += copyCount / sizeof(uint32_t);

        wait_for_ack();
    }
    return SUCCESS;
}

EthernetControl::ErrorCodes EthernetControl::select_FPGA_image(uint32_t addr) {

    FILE_LOG(logDEBUG) << "select_fpga_image addr = " << addr;

    APSCommand_t command;
    command.packed = 0;
    
    command.cmd = APS_COMMAND_FPGACONFIG_CTRL;
    write(command, addr);

    // wait for Resetting FPGA acknowlege 
    struct APS_Status_Registers statusRegs;
    int retries = 0;
    int response = TIMEOUT;
    while (retries < 5 && response != SUCCESS) {
        response = read(&statusRegs, sizeof(struct APS_Status_Registers));
    }
    return response;
}

EthernetControl::ErrorCodes EthernetControl::write_register(uint32_t addr, uint32_t data)  {

    FILE_LOG(logDEBUG) << "WriteRegister " << std::hex << addr << " = " << std::dec << data;

    APSCommand_t command;
    APSCommand_t response;
    command.packed = 0;
    command.cmd = APS_COMMAND_USERIO_ACK;
    command.cnt = 1;
    
    vector<uint32_t> d = {data};

    write(command, addr,  d);
    read(nullptr, 0, &response);

    if (response.mode_stat == 0x02) {
        FILE_LOG(logERROR) << "Invalid CNT";
    }

    if ((response.cmd == command.cmd) && response.ack == 1) {
        return SUCCESS;
    } else {
        return TIMEOUT;
    }
}

EthernetControl::ErrorCodes EthernetControl::read_register(uint32_t addr, uint32_t & data) {

    

    APSCommand_t command;
    APSCommand_t response;
    command.packed = 0;
    command.cmd = APS_COMMAND_USERIO_ACK;
    command.cnt = 1;
    command.r_w = 1;
    write(command, addr);
    read(&data, sizeof(uint32_t), &response);
    
    FILE_LOG(logDEBUG) << "ReadRegister " << std::hex << addr << " = " << std::dec << data;

    return SUCCESS;
}

EthernetControl::ErrorCodes EthernetControl::write_SPI(CHIPCONFIG_IO_TARGET target, const vector <AddrData> & data) {
        
    // TODO: This treats all commands as singles investigate sending multi commands with multi

    // maximum number of addr / data pairs 
    unsigned int numBlocks = data.size() / MAX_PAYLOAD_LEN_WORDS ;

    APSCommand_t command;
    APSCommand_t response;

    APSChipConfigCommand_t cmd;

    vector<uint32_t> writeData;

    vector<uint32_t> payload;

    unsigned int dataElement = 0;

    for (int cnt = 0; cnt < numBlocks; cnt++) {
        command.packed = 0;
        response.packed = 0;

        command.cmd = APS_COMMAND_CHIPCONFIGIO;
        command.cnt = 2;
        command.r_w = 0;

        unsigned int maxData = min(data.size(), static_cast<size_t>(MAX_PAYLOAD_LEN_WORDS) );

        for ( int dataCnt = 0; dataCnt < maxData; dataCnt++) {
            AddrData addrData = data[dataElement++];

            cmd.packed = 0;

            if (target == CHIPCONFIG_TARGET_PLL) {
                    cmd.target = CHIPCONFIG_IO_TARGET_PLL_SINGLE;
                    PLLCommand_t pllCmd;

                    pllCmd.packed = 0;
                    pllCmd.addr = addrData.first;
            
                    cmd.spicnt_data = addrData.second;
                    cmd.instr = pllCmd.packed;
            } else if (target == CHIPCONFIG_TARGET_DAC_0 || target == CHIPCONFIG_TARGET_DAC_1) {
                cmd.target = (target == CHIPCONFIG_TARGET_DAC_0) ? CHIPCONFIG_IO_TARGET_DAC_0_SINGLE : CHIPCONFIG_IO_TARGET_DAC_1_SINGLE;
                DACCommand_t dacCmd;
                dacCmd.packed = 0;
                dacCmd.addr = addrData.first & 0xFF;

                cmd.spicnt_data = addrData.second;
                cmd.instr = dacCmd.packed;
            } else if (target == CHIPCONFIG_TARGET_VCXO) {
                cmd.target = CHIPCONFIG_IO_TARGET_VCXO;
                cmd.spicnt_data = 8;
                {
                    int numWords = data.size() / 4;
                    uint32_t element;
                    for (int cnt = 0; cnt < 4; cnt++ ) {
                        element |= (data[cnt].second << (cnt * 4));
                        payload.push_back(htonl(element));
                    }
                }
            } else {
                FILE_LOG(logERROR) << "INVALID SPI Target";
                return INVALID_SPI_TARGET;
            }

           // swap byte order
            cmd.packed = htonl(cmd.packed);
            writeData.push_back(cmd.packed);

            for (auto element : payload) {
                writeData.push_back(element);
            }
        }

        write(command, 0, writeData);
        //Read(&data, 1, &response); // docs do not specfiy a response
    }
    return SUCCESS;
}

EthernetControl::ErrorCodes EthernetControl::write_SPI(CHIPCONFIG_IO_TARGET target, uint16_t address, uint8_t data) {
    
    const vector<AddrData> update = {{address, data}};
    return  write_SPI(target, update);
}

EthernetControl::ErrorCodes EthernetControl::write_SPI(CHIPCONFIG_IO_TARGET target, uint16_t address, vector<uint8_t> data) {
    
    vector<AddrData> update;

    for (auto element : data) {
        update.push_back({address,element});
    }

    return  write_SPI(target, update);
}


EthernetControl::ErrorCodes EthernetControl::read_SPI( CHIPCONFIG_IO_TARGET target, uint16_t addr, uint8_t & data)  const {

    APSChipConfigCommand_t cmd;
    cmd.packed = 0;

    uint8_t commands[] =  {CHIPCONFIG_IO_TARGET_PAUSE,
    					  CHIPCONFIG_IO_TARGET_DAC_0_SINGLE,
    					  CHIPCONFIG_IO_TARGET_DAC_1_SINGLE,
    					  CHIPCONFIG_IO_TARGET_PLL_SINGLE,
    					  CHIPCONFIG_IO_TARGET_VCXO};

    // VCXO is write only so error if trying to read
    if (target >  CHIPCONFIG_TARGET_PLL)  return INVALID_SPI_TARGET ;

    cmd.target = commands[target];
    cmd.spicnt_data = 1; // single byte read

    switch(target)
    {
    case CHIPCONFIG_TARGET_PLL:
        {
         PLLCommand_t pllCmd = {static_cast<uint16_t>(addr & 0x1FFF), 0 , 1};
        	cmd.instr = pllCmd.packed;
        }
        break;
    case CHIPCONFIG_TARGET_DAC_0:
    case CHIPCONFIG_TARGET_DAC_1:
        {
         DACCommand_t dacCmd =   {static_cast<uint8_t>(addr & 0x1F), 0 , 1};
        cmd.instr = dacCmd.packed;
        }
        break;
    default:
        // Ignore unsupported commands
        return INVALID_SPI_TARGET;
    }

    APSCommand_t command;
    APSCommand_t response;

    command.packed = 0;
    response.packed = 0;

    command.cmd = APS_COMMAND_CHIPCONFIGIO;
    command.cnt = 1;
    command.r_w = 0;

    // byte swap to big endian
    cmd.packed = htonl(cmd.packed);

    vector<uint32_t> writeData;
    writeData.push_back(cmd.packed);

    FILE_LOG(logDEBUG2) << "Chip Config: " << printAPSChipCommand(cmd);

    write(command, 0, writeData);
    read(&data, 1, &response);

    return SUCCESS;
}

vector<uint8_t> EthernetControl::words2bytes(vector<uint32_t> & words) {

    vector<uint8_t> bytes;
    bytes.reserve(sizeof(uint32_t) * words.size());

    for( uint32_t data: words) {
        uint8_t *asBytes = (uint8_t *) &data;
        for(int cnt = 0; cnt < 4 ; cnt++)
            bytes.push_back(*(asBytes++));
    }

    return bytes;
}
