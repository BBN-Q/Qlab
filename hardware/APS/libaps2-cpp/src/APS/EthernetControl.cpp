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

using std::cout;
using std::endl;

#include <ctime>

vector<EthernetControl::EthernetDevInfo>  EthernetControl::pcapDevices_;
std::set<string> EthernetControl::APSunits_;
std::map<string, EthernetControl::EthernetDevInfo> EthernetControl::APS2device_;

bool EthernetControl::pcapRunning = false;

EthernetControl::EthernetControl() {
    cout << "New EthernetControl" << endl;
	// get list of interfaces from pcap
	get_network_devices();
}

EthernetControl::ErrorCodes EthernetControl::connect(string deviceID) {
    FILE_LOG(logDEBUG) << "Connecting to device: " << deviceID;

    if (APSunits_.find(deviceID) == APSunits_.end()) {
        return INVALID_APS_ID;
    }

    // double check to make sure device is in map
    if (APS2device_.find(deviceID) == APS2device_.end()) {
        return INVALID_APS_ID; 
    }

    deviceID_ = deviceID;

    set_network_device(APS2device_[deviceID].name);

    // parse string to mac addr
    int start = 0;
    for(int cnt = 0; cnt < MAC_ADDR_LEN; cnt++) {
        apsMac_[cnt] = atoi(deviceID.substr(start,2).c_str());
        start += 3;
    }
    // build filter
    filter_ =  getPointToPointFilter(pcapDevice->macAddr, apsMac_);

    FILE_LOG(logDEBUG3) << "Using filter " << filter_;

    apsHandle_ = start_capture(pcapDevice->name, filter_);

    if (!apsHandle_) return INVALID_APS_ID;

	return SUCCESS;
}

bool isOpen() {
	return false;
}

size_t EthernetControl::Write(void * data, size_t length) {
	return EthernetControl::NOT_IMPLEMENTED;
}

size_t EthernetControl::Read(void * data, size_t packetLength) {
	return EthernetControl::NOT_IMPLEMENTED;
}

EthernetControl::ErrorCodes EthernetControl::set_network_device(string device) {
    EthernetDevInfo * di = findDeviceInfo(device);
    if (!di) 
        return INVALID_NETWORK_DEVICE;
    pcapDevice = di;
    pcapDevice->isActive = true;
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

        FILE_LOG(logDEBUG1) << "Enumerate Packet: " << print_APS_command(&(bph->command));

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
                FILE_LOG(logDEBUG3) << " Command: " << print_APS_command(&eh->command);

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

string EthernetControl::print_APS_command(struct APSCommand * cmd) {
    ostringstream ret;

    uint32_t * packedCmd;

    packedCmd = reinterpret_cast<uint32_t *>(cmd);

    ret << std::hex << *packedCmd << " =";
    ret << " ACK: " << cmd->ack;
    ret << " SEQ: " << cmd->seq;
    ret << " SEL: " << cmd->sel;
    ret << " R/W: " << cmd->r_w;
    ret << " CMD: " << cmd->cmd;
    ret << " MODE/STAT: " << cmd->mode_stat;
    ret << " cnt: " << cmd->cnt;
    return ret.str();
}

void EthernetControl::debugAPSEcho(string device) {
    // debug routine to echo APS packets back to sender
    // used for testing of EthernetControl without APS unit
    
    cout << "Starting APS Debug Echo" << endl;
 
    pcap_t *capHandle;


    int res;
    struct pcap_pkthdr *header;
    const unsigned char *pkt_data;

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

            // skip packets where source and dest are the same
            bool same = true;
            for (int cnt = 0; cnt < MAC_ADDR_LEN; cnt++) {
                if (eh->src[cnt] !=  eh->dest[cnt]) same = false;
            }

            if (same) continue;

            packetHTON(eh); // swap to host

            cout << "Src: " << print_ethernetAddress(eh->src);
            cout << " Dest: " << print_ethernetAddress(eh->dest);
            cout << " Command: " << print_APS_command(&(eh->command)) << endl;

            // set src to dest
            std::copy(eh->src, eh->src + MAC_ADDR_LEN, eh->dest);
            // set source
            std::copy(di->macAddr, di->macAddr + MAC_ADDR_LEN,  eh->src);

            if (eh->command.cmd == APS_COMMAND_USERIO_ACK || 
                eh->command.cmd == APS_COMMAND_FPGACONFIG_ACK ) {
                eh->command.ack = 1;
            }

            packetHTON(eh); // swap to net
             
            if (pcap_sendpacket(capHandle, pkt_data, header->len) != 0) {
                FILE_LOG(logERROR) << "Error sending the packet: " << string(pcap_geterr(capHandle));
            } 
        }
    } 
    
}

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



