#include "APSEthernet.h"

/* PUBLIC methods */

APSEthernet::~APSEthernet() {
    pcap_close(pcapHandle_);
}

EthernetError APSEthernet::init(string nic) {
	vector<EthernetDevInfo> pcapDevices = get_network_devices();
	set_network_device(pcapDevices, nic);
    //Create a new pcap filter to capture the replies
    char errbuf[PCAP_ERRBUF_SIZE];
    pcapHandle_ = pcap_open_live(device_.name.c_str(), // name of the device
                                  1500,                      // portion of the packet to capture
                                  false,                     // promiscuous mode
                                  pcapTimeoutMS,             // read timeout
                                  errbuf                     // error buffer
                                  );
    // filter for APS protocol and host destination
    string filterStr = create_pcap_filter();
    apply_filter(filterStr);

    //Setup broadcast mapping 
    serial_to_MAC_["broadcast"] = MACAddr("FF:FF:FF:FF:FF:FF");

    //Setup incoming loop 
    msgQueues_["unknown"] = queue<APSEthernetPacket>();
    // pcap_loop(pcapHandle_, -1, wrapper_pcap_callback, nullptr);

    return SUCCESS;
}

vector<string> APSEthernet::enumerate() {
	/*
	 * Look for all APS units that respond to the broadcast packet
	 */
	FILE_LOG(logDEBUG1) << "APSEthernet::enumerate";

    APSEthernetPacket broadcastPacket = APSEthernetPacket::create_broadcast_packet();
    send("broadcast", broadcastPacket);
    vector<APSEthernetPacket> msgs = receive("unknown");
    vector<string> deviceSerials;
    for (auto m : msgs) {
    	// get src MAC address and serial from each packet and add to the map
    	serial_to_MAC_[m.header.src.to_string()] = m.header.src;
    	MAC_to_serial_[m.header.src] = m.header.src.to_string();
    	deviceSerials.push_back(m.header.src.to_string());
    	FILE_LOG(logINFO) << "Found device: " << deviceSerials.back();
    }
    return deviceSerials;
}

EthernetError APSEthernet::connect(string serial) {
	msgQueues_[serial] = queue<APSEthernetPacket>();
	return SUCCESS;
}

EthernetError APSEthernet::disconnect(string serial) {
	msgQueues_.erase(serial);
	return SUCCESS;
}

EthernetError APSEthernet::send(string serial, APSEthernetPacket msg){
    send(serial, vector<APSEthernetPacket>(1, msg));
}

EthernetError APSEthernet::send(string serial, vector<APSEthernetPacket> msg) {
    //Fill out the destination and source MAC address
    for (auto & packet : msg){
        packet.header.dest = serial_to_MAC_[serial];
        packet.header.src = srcMAC_;
    }

    //Send a single packet with pcap_sendpacket
    if (msg.size() == 1){
        if (pcap_sendpacket(pcapHandle_, msg[0].serialize().data(), msg[0].numBytes()) != 0) {
            FILE_LOG(logERROR) << "Error sending command: " << string(pcap_geterr(pcapHandle_));
        }
    }
    return SUCCESS;
}

vector<APSEthernetPacket> APSEthernet::receive(string serial, size_t timeoutSeconds) {

    pcap_dispatch(pcapHandle_, 1, wrapper_pcap_callback, nullptr);
    //Read the packets coming back in up to the timeout
    std::chrono::time_point<std::chrono::steady_clock> start, end;

    start = std::chrono::steady_clock::now();
    int elapsedTime = 0;

    vector<APSEthernetPacket> outVec;

    while ( elapsedTime < timeoutSeconds){
        if (!msgQueues_[serial].empty()){
            outVec.push_back(msgQueues_[serial].front());
            msgQueues_[serial].pop();
            return outVec;
        }
        end = std::chrono::steady_clock::now();
        elapsedTime =  std::chrono::duration_cast<std::chrono::seconds>(end-start).count();
    }
    FILE_LOG(logWARNING) << "Timed out on receive!";
    return outVec;
}

void APSEthernet::wrapper_pcap_callback(u_char * args, const struct pcap_pkthdr * header, const u_char * packet){
    //Grab a refernece to our own singleton
    APSEthernet & myInstance = get_instance();
    myInstance.pcap_callback(*header, packet);
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
        if (d->addresses != NULL) devInfo.macAddr = MACAddr::MACAddr_from_devName(devInfo.name);

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
    bool foundDev = false;
    for (auto & dev : pcapDevices) {
    	if ((dev.name.compare(nic) == 0) || (dev.description.compare(nic) == 0) || (dev.description2.compare(nic) == 0)) {
    		device_ = dev;
            foundDev = true;
	    	break;
	    }
    }
    if (foundDev){
        srcMAC_ = device_.macAddr;
        return SUCCESS;
    }
    else{
        return INVALID_NETWORK_DEVICE;
    } 
}

string APSEthernet::create_pcap_filter() {
    std::ostringstream filter;
    filter << "ether dst " << srcMAC_.to_string();
    filter << " and ether proto " << APS_PROTO;
    return filter.str();
}

EthernetError APSEthernet::apply_filter(string & filter) {

    FILE_LOG(logDEBUG3) << "Setting filter to: " << filter << endl;

    u_int netmask=0xffffff; // ignore netmask 
    struct bpf_program filterCode;

    if (pcap_compile(pcapHandle_, &filterCode, filter.c_str(), true, netmask) < 0 ) {
        cout << "Error to compiling enumerate packet filter. Check the syntax" << endl;
        return INVALID_PCAP_FILTER;
    }

    // set filter
    if (pcap_setfilter(pcapHandle_, &filterCode) < 0) {
         cout << "Error setting the filter" << endl;
        /* Free the device list */
        return INVALID_PCAP_FILTER;
    }
    return SUCCESS;
}

void APSEthernet::pcap_callback(const struct pcap_pkthdr & header, const u_char * packet){

	APSEthernetPacket myPacket = APSEthernetPacket(packet, header.caplen);

    //Now sort out where it's going
    if(MAC_to_serial_.find(myPacket.header.src) == MAC_to_serial_.end()){
        msgQueues_["unknown"].emplace(myPacket);
    }
    else{
        msgQueues_[MAC_to_serial_[myPacket.header.src]].push(myPacket);
    }
}
