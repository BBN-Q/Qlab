#include "EthernetControl.h"
#include "pcap.h"
#include "logger.h"

#ifdef _WIN32
    #include <winsock2.h>
    #include <iphlpapi.h>
#endif

#include <iostream>
#include <iomanip>
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
    memset(devInfo.macAddr,0, MAC_ADDR_LEN);

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

void EthernetControl::enumerate() {
    cout << "enumerate" << endl;
    pcap_t *capHandle;
    char errbuf[PCAP_ERRBUF_SIZE];

    int res;
    struct pcap_pkthdr *header;
    const unsigned char *pkt_data;

    struct tm ltime;

    get_network_devices();
    for (vector<EthernetDevInfo>::iterator it = pcapDevices.begin();
        it != pcapDevices.end(); ++it) {
        if (!it->isActive) continue;
        
        capHandle = pcap_open_live(it->name.c_str(),          // name of the device
                              65536,            // portion of the packet to capture
                                                // 65536 guarantees that the whole packet will be captured on all the link layers
                              true,    // promiscuous mode
                              1000,             // read timeout
                              errbuf            // error buffer
                              );
        if (!capHandle) {
            FILE_LOG(logERROR) << "Error open pcap for device: " << it->description;
            continue;
        }

        if (pcap_datalink(capHandle) != DLT_EN10MB) {
            FILE_LOG(logERROR) << "Network Device is not Ethernet" << endl;
        }


        // send broadcast packet
        
           /* Retrieve the packets */
        int cnt = 0;
        while((res = pcap_next_ex( capHandle, &header, &pkt_data)) >= 0) {

            if(res == 0) {
                /* Timeout elapsed */
                continue;
            }
        
            APSEthernetHeader * eh = (APSEthernetHeader *) pkt_data;

            packetHTON(eh);

            cout << "Src: " << print_ethernetAddress(eh->src);
            cout << " Dest: " << print_ethernetAddress(eh->dest);
            cout << " Frame Type: 0x" << std::hex << std::setfill('0') << std::setw(4) << eh->frameType << endl;
            cnt++;
            if (cnt > 10) break;
        }
 
        // TODO add filter for BBN APS Packet 
    
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
    if (frame->frameType != 0xBB4E || frame->frameType != 0x4EBB ) {
        // packet is not an APS packet do not swap 
        return;
    }
    frame->command = htonl(frame->command);
    frame->addr    = htonl(frame->addr);
}


