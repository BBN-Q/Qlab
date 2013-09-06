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

