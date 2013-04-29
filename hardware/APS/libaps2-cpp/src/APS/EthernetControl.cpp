#include "EthernetControl.h"
#include "pcap.h"
#include "logger.h"

#ifdef _WIN32
    #include <winsock2.h>
    #include <iphlpapi.h>
#endif

#include <iostream>
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

bool EthernetControl::pcapRunning = false;

EthernetControl::EthernetControl() {
    cout << "New EthernetControl" << endl;
	// get list of interfaces from pcap
    seqNum_ = 0;
    apsHandle_ = 0;
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

bool isOpen() {
	return false;
}

size_t EthernetControl::Write(APSCommand & commmand, uint32_t addr, void * data, size_t length) {
    static const int MAX_FRAME_LEN = 1500;
    uint8_t frame[MAX_FRAME_LEN];
    APSEthernetHeader * bph;
    
    FILE_LOG(logDEBUG1) << "Sending Command: " << APS2::printAPSCommand(&(commmand));
    FILE_LOG(logDEBUG1) << "Sending " << length << " Bytes";

    // build frame
    std::fill(frame, frame + 1500, 0);    
    bph = reinterpret_cast< APSEthernetHeader * >(frame);
    std::copy(apsMac_, apsMac_ + MAC_ADDR_LEN, bph->dest);
    std::copy(pcapDevice_->macAddr, pcapDevice_->macAddr + MAC_ADDR_LEN,  bph->src);

    bph->frameType = APS_PROTO;
    bph->command = commmand;
    bph->addr = addr;

    uint8_t * start = frame;
    start += sizeof(APSEthernetHeader);

    uint8_t * source = static_cast<uint8_t *>(data);

    size_t bytesRemaining = length;
    bool sent = false;

    if (!apsHandle_) return INVALID_APS_ID;

    size_t headerLen = sizeof(APSEthernetHeader);

    while (bytesRemaining > 0 || !sent) {

        size_t bytesSend = min(bytesRemaining, MAX_FRAME_LEN - headerLen);
        
        if (bytesSend > 0) {
            // copy data into packet
            std::copy(source, source + bytesSend, start);
            source += bytesSend;
        }
        bytesRemaining -= bytesSend;

        bytesSend += headerLen;

        ++seqNum_;
        if (seqNum_ == 0) {
            seqNum_ = 1;
        }

        FILE_LOG(logDEBUG1) << "Src: " << print_ethernetAddress(bph->src);
        FILE_LOG(logDEBUG1) << "Dest: " << print_ethernetAddress(bph->dest);
        FILE_LOG(logDEBUG1) << "Command: " << APS2::printAPSCommand(&bph->command);
        FILE_LOG(logDEBUG1) << "bytesSend: " << bytesSend;

        bph->seqNum = seqNum_;

        packetHTON(bph); // swap bytes to network order

        if (pcap_sendpacket(apsHandle_, frame, bytesSend) != 0) {
            FILE_LOG(logERROR) << "Error sending command: " << string(pcap_geterr(apsHandle_));
         } 
         
         sent = true;      
    }

	return SUCCESS;
}

size_t EthernetControl::Read(void * data, size_t readLength, APSCommand * command) {
    struct pcap_pkthdr *header;
    const unsigned char *pkt_data;

    if (!apsHandle_) return INVALID_APS_ID;

    int res = pcap_next_ex( apsHandle_, &header, &pkt_data);
    
    if(res > 0) {
        // have packet so process
        APSEthernetHeader * eh = (APSEthernetHeader *) pkt_data;

        packetHTON(eh);

        FILE_LOG(logDEBUG) << "Read Frame: ";
        FILE_LOG(logDEBUG1) << "Src: " << print_ethernetAddress(eh->src);
        FILE_LOG(logDEBUG1) << "Dest: " << print_ethernetAddress(eh->dest);
        FILE_LOG(logDEBUG1) << "Command: " << APS2::printAPSCommand(&eh->command);

        size_t payloadLen = header->len - sizeof(APSEthernetHeader);
        size_t copyLen = eh->command.cnt * sizeof(uint32_t);

        if (payloadLen > copyLen && payloadLen > MIN_PAYLOAD_LEN) {
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

        std::copy(start, start + copyLen, static_cast<uint8_t*>(data) );
        return SUCCESS;
    }
	return TIMEOUT;
}

EthernetControl::ErrorCodes EthernetControl::set_network_device(string device) {
    FILE_LOG(logDEBUG1) << "EthernetControl::set_network_device: " << device;
    EthernetDevInfo * di = findDeviceInfo(device);
    if (!di) 
        return INVALID_NETWORK_DEVICE;
    pcapDevice_ = di;
    pcapDevice_->isActive = true;
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

	/* Retrieve the device list from the local machine */
    if (pcap_findalldevs(&alldevs, errbuf) == -1) {
    	string err(errbuf);
        cout << "Error in pcap_findalldevs_ex: " << err;
    }

    /* store list in map */
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
    #error "getMacAddr only implemented for WIN32"
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

        FILE_LOG(logDEBUG1) << "Enumerate Packet: " << APS2::printAPSCommand(&(bph->command));

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

                packetHTON(eh);

                FILE_LOG(logDEBUG3) << "Src: " << print_ethernetAddress(eh->src);
                FILE_LOG(logDEBUG3) << " Dest: " << print_ethernetAddress(eh->dest);
                FILE_LOG(logDEBUG3) << " Command: " << APS2::printAPSCommand(&eh->command);

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

string EthernetControl::print_ethernetAddress(uint8_t * addr) {
    ostringstream ss;
    for(int cnt = 0; cnt < (MAC_ADDR_LEN - 1); cnt++) {
        ss << std::hex << std::setfill('0') << std::setw(2) << static_cast<int>(addr[cnt]) << ":";
    }
    ss <<  std::hex << std::setfill('0') << std::setw(2) <<  static_cast<int>(addr[5]) ;
    return ss.str();
}

void EthernetControl::packetHTON(APSEthernetHeader * frame) {

    frame->frameType = htons(frame->frameType);
    if (frame->frameType != APS_PROTO || frame->frameType != htons(APS_PROTO) ) {
        // packet is not an APS packet do not swap 
        return;
    }
    frame->packedCommand = htonl(frame->packedCommand);
    frame->addr    = htonl(frame->addr);
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

            packetHTON(eh); // swap to host

            sendLength =  header->len;

            if (aps)  {
                outbound_pkt = aps->packetCallback(pkt_data, sendLength); // sendLength should change
                dh = (APSEthernetHeader *) outbound_pkt;
            } else {
                cout << "Src: " << print_ethernetAddress(eh->src);
                cout << " Dest: " << print_ethernetAddress(eh->dest);
                cout << " Command: " << APS2::printAPSCommand(&(eh->command)) << endl;

            }

            // continue if there is no packet to send back
            if (sendLength == 0) continue; 

            // copy send length
            dh->command.cnt = ceil( 1.0 * sendLength / sizeof(uint32_t));

            // set src to dest
            std::copy(eh->src, eh->src + MAC_ADDR_LEN, dh->dest);
            // set source
            std::copy(di->macAddr, di->macAddr + MAC_ADDR_LEN,  dh->src);
            
            cout << "Send Src: " << print_ethernetAddress(dh->src);
            cout << " Dest: " << print_ethernetAddress(dh->dest);
            cout << " Len: " << sendLength;
            cout << " Command: " << APS2::printAPSCommand(&(dh->command)) << endl;

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

size_t EthernetControl::program_FPGA(vector<UCHAR> fileData, uint32_t addr) {

    UCHAR buffer[MAX_PAYLOAD_LEN];

    APSCommand command;
    APSCommand response;

    FILE_LOG(logDEBUG) << "program_FPGA: " << fileData.size() << " Bytes @ " << addr;

    const size_t max_fpga_payload_len = MAX_PAYLOAD_LEN - sizeof(uint32_t);

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
        zeroAPSCommand(&command);
        command.cmd = APS_COMMAND_FPGACONFIG_NACK;
        command.mode_stat = 0;

        copyCount = min(dataRemaining, static_cast<size_t>(MAX_PAYLOAD_LEN));
        command.cnt = copyCount / sizeof(uint32_t); // set equal to number of words to be written
        for (int copyIdx = 0; copyIdx < copyCount; copyIdx++)
            buffer[copyIdx] = fileData[dataOffset++];

        FILE_LOG(logDEBUG) << "Writing frame " << frameCnt << "/" << numFrames;

        Write(command, addr, buffer, copyCount);

        dataRemaining -= copyCount;
        addr += copyCount / sizeof(uint32_t);

        // wait for ack
        if (command.cmd == APS_COMMAND_FPGACONFIG_ACK) {
            FILE_LOG(logDEBUG) << "Wait for ACK";
            Read(nullptr, 0, &response);
            FILE_LOG(logDEBUG) << "RECV ACK " << APS2::printAPSCommand(&(response));
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

        }

    }
    return SUCCESS;
}

EthernetControl::ErrorCodes EthernetControl::select_FPGA_image(uint32_t addr) {

    FILE_LOG(logDEBUG) << "select_fpga_image addr = " << addr;

    APSCommand command;
    zeroAPSCommand(&command);
    command.cmd = APS_COMMAND_FPGACONFIG_CTRL;
    Write(command, addr);

    // wait for reset acknowlege 
    struct APS_Status_Registers statusRegs;
    int retries = 0;
    int response = TIMEOUT;
    while (retries < 5 && response != SUCCESS) {
        response = Read(&statusRegs, sizeof(struct APS_Status_Registers));
    }
}

