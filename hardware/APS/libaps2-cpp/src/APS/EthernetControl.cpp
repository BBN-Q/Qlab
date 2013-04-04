#include "EthernetControl.h"
#include "pcap.h"
#include "logger.h"

#include <winsock2.h>

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

	 /* Retrieve the device list from the local machine */
    if (pcap_findalldevs(&alldevs, errbuf) == -1) {
    	string err(errbuf);
        cout << "Error in pcap_findalldevs_ex: " << err;
    }

    /* store list in map */
    for(d= alldevs; d != NULL; d= d->next) {
        if (!findDeviceInfo(d->description)) {
            pcapDevices.push_back({d->name, d->description, false});
            FILE_LOG(logINFO) << "New PCAP Device: " << " "<< d->description << " -> " << d->name;
        }   
    }
    pcap_freealldevs(alldevs);
}

EthernetControl::EthernetDevInfo * EthernetControl::findDeviceInfo(string device) {
    for (vector<EthernetDevInfo>::iterator it = pcapDevices.begin();
        it != pcapDevices.end(); ++it) {
        if (it->description.compare(device) == 0) return &(*it);
    }
    return NULL;
}

vector<string> EthernetControl::get_network_devices_names() {
    get_network_devices();
    vector<string> devNames;
    for(vector<EthernetDevInfo>::iterator it = pcapDevices.begin();
        it != pcapDevices.end(); ++it) {
        devNames.push_back(it->description);
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
    if (!di) 
        return INVALID_NETWORK_DEVICE;
    
    di->isActive = isActive;
    return SUCCESS;
}

string EthernetControl::print_ethernetAddress(uint8_t * addr) {
    ostringstream ss;
    for(int cnt = 0; cnt < 5; cnt++) {
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


