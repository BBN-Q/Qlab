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

using std::cout;
using std::endl;

#include <ctime>

vector<EthernetControl::EthernetDevInfo>  EthernetControl::pcapDevices;

bool EthernetControl::pcapRunning = false;

EthernetControl::EthernetControl() {
    cout << "New EthernetControl" << endl;
	// get list of interfaces from pcap
	get_network_devices();
}

EthernetControl::ErrorCodes EthernetControl::connect(int deviceID) {
	return EthernetControl::NOT_IMPLEMENTED;
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

EthernetControl::ErrorCodes EthernetControl::get_device_serials(vector<string> testSerials){
	return EthernetControl::NOT_IMPLEMENTED;
}

unsigned int EthernetControl::get_num_devices() {
    return 0;
}

bool EthernetControl::isOpen(int deviceID) {
	return false;
}

void EthernetControl::get_network_devices() {
    cout << "get_network_devices" << endl;
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
            

            pcapDevices.push_back(devInfo);
            FILE_LOG(logINFO) << "New PCAP Device:";
            FILE_LOG(logINFO) << "\t" << devInfo.description;
            FILE_LOG(logINFO) << "\t" << devInfo.description2;
            FILE_LOG(logINFO) << "\t" << devInfo.name;
            FILE_LOG(logINFO) << "\t" << print_ethernetAddress(devInfo.macAddr);
            
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
        cout << "Error allocating memory needed to call GetAdaptersinfo" << endl;
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
    for (vector<EthernetDevInfo>::iterator it = pcapDevices.begin();
        it != pcapDevices.end(); ++it) {
        if (it->name.compare(device) == 0) return &(*it);
        if (it->description.compare(device) == 0) return &(*it);
        if (it->description2.compare(device) == 0) return &(*it);
    }
    return NULL;
}

vector<string> EthernetControl::get_network_devices_names() {
    get_network_devices();
    vector<string> devNames;
    for(vector<EthernetDevInfo>::iterator it = pcapDevices.begin();
        it != pcapDevices.end(); ++it) {
        devNames.push_back(it->name);
    }
    return devNames;
}

void EthernetControl::enumerate(unsigned int timeoutSeconds, unsigned int broadcastPeriodSeconds) {
    cout << "enumerate" << endl;
    cout << "sizeof command: " << sizeof(struct APSCommand);
    pcap_t *capHandle;
    char errbuf[PCAP_ERRBUF_SIZE];

    static const int broadcastPacketLen = 40;
    uint8_t broadcastPacket[broadcastPacketLen];
    APSEthernetHeader *bph;

    int res;
    struct pcap_pkthdr *header;
    const unsigned char *pkt_data;

    struct tm ltime;


    get_network_devices();
    for (vector<EthernetDevInfo>::iterator it = pcapDevices.begin();
        it != pcapDevices.end(); ++it) {
        if (!it->isActive) continue;
        
        capHandle = pcap_open_live(it->name.c_str(),          // name of the device
                              1500,            // portion of the packet to capture
                              true,    // promiscuous mode
                              pcapTimeoutMS,             // read timeout
                              errbuf            // error buffer
                              );
        if (!capHandle) {
            FILE_LOG(logERROR) << "Error open pcap for device: " << it->description;
            continue;
        }

        if (pcap_datalink(capHandle) != DLT_EN10MB) {
            FILE_LOG(logERROR) << "Network Device is not Ethernet" << endl;
        }

        // build broadcast packet
        std::fill(broadcastPacket, broadcastPacket + broadcastPacketLen, 0);    
        bph = reinterpret_cast< APSEthernetHeader * >(broadcastPacket);
        std::fill(bph->dest, bph->dest + MAC_ADDR_LEN, 0xFF);
        std::copy(it->macAddr, it->macAddr + MAC_ADDR_LEN,  bph->src);
        bph->frameType = APS_PROTO;
        bph->command.cmd = APS_COMMAND_STATUS;
        bph->command.mode_stat = APS_STATUS_TEMP;
        bph->command.cnt = 0x10;

        cout << "Enumerate Packet: " << print_APS_command(&(bph->command)) << endl;

        packetHTON(bph); // swap bytes to network order

        // applfy filter to only get reply directed from APS to local machine
        applyFilter(capHandle, getEnumerateFilter(it->macAddr));
        
        std::chrono::time_point<std::chrono::steady_clock> start, end, lastBroadcast;

        start = std::chrono::steady_clock::now();

        int totalElapsed = 0;
        int broadcastElapsed = 100; // force broadcast first time through
        while (totalElapsed < timeoutSeconds ) {

            if (broadcastElapsed > broadcastPeriodSeconds) {
                // send enum packet
                cout << "Sending Enumerate Packet:" << endl;
                
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

                cout << "Src: " << print_ethernetAddress(eh->src);
                cout << " Dest: " << print_ethernetAddress(eh->dest);
                cout << " Frame Type: 0x" << std::hex << std::setfill('0') << std::setw(4) << eh->frameType << endl;
            }

            end = std::chrono::steady_clock::now();
            totalElapsed =  std::chrono::duration_cast<std::chrono::seconds>(end-start).count();
            broadcastElapsed =  std::chrono::duration_cast<std::chrono::seconds>(end-lastBroadcast).count();
        } 
    
    }
}

EthernetControl::ErrorCodes EthernetControl::set_device_active(string device, bool isActive) {
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
    filter << "broadcast ether proto " << APS_PROTO;
    return filter.str();
    
}

EthernetControl::ErrorCodes EthernetControl::applyFilter(pcap_t * capHandle, string filter) {

    cout << "Setting filter to: " << filter << endl;

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

string EthernetControl::print_APS_command(struct EthernetControl::APSCommand * cmd) {
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

