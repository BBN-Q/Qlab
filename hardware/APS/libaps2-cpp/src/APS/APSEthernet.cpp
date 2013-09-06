#include APSEthernet.h

/* PUBLIC methods */
EthernetError APSEthernet::init(string nic) {
	vector<EthernetDevInfo> pcapDevices = get_network_devices();
	set_network_device(pcapDevices, nic);
    //Create a new pcap filter to capture the replies
    char errbuf[PCAP_ERRBUF_SIZE];
    pcap_handle_ = pcap_open_live(device_->name.c_str(), // name of the device
                                  1500,                      // portion of the packet to capture
                                  false,                     // promiscuous mode
                                  pcapTimeoutMS,             // read timeout
                                  errbuf                     // error buffer
                                  );
    // filter for APS protocol and host destination
    string filterStr = create_enumerate_filter(srcMAC_);
    apply_filter(capHandle, filterStr);

    return SUCCESS;
}

vector<string> APSEthernet::enumerate() {
	/*
	 * Look for all APS units that respond to the broadcast packet
	 */
	FILE_LOG(logDEBUG1) << "APSEthernet::enumerate";

    APSEthernetPacket broadcastPacket = create_broadcast_packet(srcMAC_);
    send(broadcastPacket);
    vector<APSEthernetPacket> msgs = receive();

    for (auto m: msgs) {
    	// get src MAC address and serial from each packet and add to the map
    	serial_to_MAC_[get_serial(m.payload)] = m.header.src;
    	MAC_to_serial[m.header.src] = get_serial(m.payload);
    }
}

EthernetError APSEthernet::connect(string serial) {
	msgQueue_[serial] = queue<APSEthernetPacket>;
	return SUCCESS;
}

EthernetError APSEthernet::disconnect(string serial) {
	msgQueue_.erase(serial);
	return SUCCESS;
}

EthernetError APSEthernet::send(vector<APSEthernetPacket> msg) {

}

EthernetError APSEthernet::send(string serial, vector<APSEthernetPacket> msg) {

}

vector<APSEthernetPacket> APSEthernet::receive(string serial) {

}

/* PRIVATE methods */
vector<EthernetDevInfo> APSEthernet::get_network_devices() {
	/*
	 * Finds all the devices that the pcap library sees and returns their info in the pcapDevices vector
	 */
	pcap_if_t *alldevs;
	pcap_if_t *d;
    char errbuf[PCAP_ERRBUF_SIZE];

    FILE_LOG(logDEBUG) << "Getting Network Devices";

	/* Retrieve the device list from the local machine */
    if (pcap_findalldevs(&alldevs, errbuf) == -1) {
    	string err(errbuf);
        cout << "Error in pcap_findalldevs_ex: " << err;
    }

    /* build list */
    FILE_LOG(logDEBUG1) << "Enumerating PCAP Devices:";
    vector<EthernetDevInfo> pcapDevices;
    for(d= alldevs; d != NULL; d= d->next) {
        struct EthernetDevInfo devInfo;
        devInfo.name = string(d->name);
        if (d->description != NULL) devInfo.description = string(d->description);
        devInfo.isActive = false;
        if (d->addresses != NULL) devInfo.macAddr = MACAddr(devInfo);

        pcapDevices.push_back(devInfo);
        FILE_LOG(logDEBUG2) << "New PCAP Device:";
        FILE_LOG(logDEBUG2) << "\t" << devInfo.description;
        FILE_LOG(logDEBUG2) << "\t" << devInfo.description2;
        FILE_LOG(logDEBUG2) << "\t" << devInfo.name;
        FILE_LOG(logDEBUG2) << "\t" << devInfo.macAddr.to_string();
    }
    pcap_freealldevs(alldevs);
    return pcapDevices;
}

EthernetError APSEthernet::set_network_device(vector<EthernetDevInfo> pcapDevices, string nic) {
	/*
	 * Attach the APSEthernet instance to a particular device.
	 */
    FILE_LOG(logDEBUG1) << "APSEthernet::set_network_device: " << nic;
    for (auto dev : pcapDevices) {
    	if (dev.name.compare(nic) == 0) || (dev.description.compare(nic) == 0) || (dev.description2.compare(nic) == 0) {
    		device_ = dev;
	    	break;
	    } else if (dev == pcapDevices.last())
	    	return INVALID_NETWORK_DEVICE;
	    }
    }

    srcMAC_ = device_.macAddr;
    return SUCCESS;
}

string APSEthernet::create_enumerate_filter() {
    ostringstream filter;
    filter << "ether dst " << srcMAC_.to_string();
    filter << " and ether proto " << APS_PROTO;
    return filter.str();
}

EthernetError APSEthernet::apply_filter(string & filter) {

    FILE_LOG(logDEBUG3) << "Setting filter to: " << filter << endl;

    u_int netmask=0xffffff; // ignore netmask 
    struct bpf_program filterCode;

    if (pcap_compile(pcap_handle_, &filterCode, filter.c_str(), true, netmask) < 0 ) {
        cout << "Error to compiling enumerate packet filter. Check the syntax" << endl;
        return INVALID_PCAP_FILTER;
    }

    // set filter
    if (pcap_setfilter(pcap_handle_, &filterCode) < 0) {
         cout << "Error setting the filter" << endl;
        /* Free the device list */
        return INVALID_PCAP_FILTER;
    }
    return SUCCESS;
}

/* MACAddr class */
MACAddr::MACAddr() : addr(MAC_ADDR_LEN, 0){}

MACAddr::MACAddr(const string & macStr){
	addr.resize(6,0);
	for(int cnt = 0; cnt < MAC_ADDR_LEN; cnt++) {
		// copy mac address from string
		sscanf(macStr.substr(3*cnt,2).c_str(), "%x", addr.begin()+cnt);
	}
}

MACAddr::MACAddr(const int & macAddrInt){
	//TODO
}

MACAddr::MACAddr(const EthernetDevInfo &){
	//Extract a MAC address from the the pcap information. A bit of a cross-platorm pain. 
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
	return MACAddr(macAddrStr);

#endif

}

string MACAddr::to_string() const{
    ostringstream ss;
    for(const uint8_t curByte : addr){
        ss << std::hex << std::setfill('0') << std::setw(2) << static_cast<int>(curByte) << ":";
    }
    //remove the trailing ":"
    string myStr = ss.str();
    myStr.pop_back();
    return myStr;
}