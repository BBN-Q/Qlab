#include "APSEthernet.h"


class BroadcastServer {
public:
    BroadcastServer(asio::io_service& io_service, uint16_t port, vector<asio::ip::address>& IPs) : 
        socket_(io_service, udp::endpoint(udp::v4(), port)), port_(port) {
        socket.set_option(asio::socket_base::broadcast(true));
        setup_receive(IPs);
    };

    void setup_receive(vector<asio::ip::address>& IPs){
        //When a packet comes back in from an APS add the IP/MAC address pair to the list
        socket_.async_receive_from(
            asio::buffer(data_, max_length), senderEndpoint_,
            [this](std::error_code ec, std::size_t bytes_recvd)
            {
              if (!ec && bytes_recvd > 0)
              {
                IPs.push_back(senderEndpoint_.address());
              }
              //Start the receiver again
              setup_receive(IPs)
        });
    }

    void send_broadcast(){
        //Put together the broadcast status request
        APSEthernetPacket broadcastPacket = APSEthernetPacket::create_broadcast_packet();

        udp::endpoint broadCastEndPoint(asio::ip::address_v4::broadcast(), port_);


    }

private:
    udp::socket socket_;
    udp::endpoint senderEndpoint_;
    uint16_t port_

};


/* PUBLIC methods */

APSEthernet::~APSEthernet() {
    //Stop the receive thread
    receiving_ = false;
    receiveThread_.join();
}

APSEthernet::EthernetError APSEthernet::init(string nic) {
    /*
    --Nothing doing for now
    */ 
    reset_mac_maps();
    return SUCCESS;
}

set<string> APSEthernet::enumerate() {
	/*
	 * Look for all APS units that respond to the broadcast packet
	 */

	FILE_LOG(logDEBUG1) << "APSEthernet::enumerate";

    reset_mac_maps();

    try {
        socket.
    }

 

    send("broadcast", broadcastPacket);
    vector<APSEthernetPacket> msgs = receive("unknown");
    set<string> deviceSerials;
    for (auto m : msgs) {
    	// get src MAC address and serial from each packet and add to the map
    	serial_to_MAC_[m.header.src.to_string()] = m.header.src;
    	MAC_to_serial_[m.header.src] = m.header.src.to_string();
    	deviceSerials.insert(m.header.src.to_string());
    	FILE_LOG(logINFO) << "Found device: " << m.header.src.to_string();
    }
    return deviceSerials;
}

void APSEthernet::reset_mac_maps() {
    serial_to_MAC_.clear();
    MAC_to_serial_.clear();
    serial_to_MAC_["broadcast"] = MACAddr("FF:FF:FF:FF:FF:FF");
}

APSEthernet::EthernetError APSEthernet::connect(string serial) {
    mLock_.lock();
	msgQueues_[serial] = queue<APSEthernetPacket>();
    mLock_.unlock();
	return SUCCESS;
}

APSEthernet::EthernetError APSEthernet::disconnect(string serial) {
    mLock_.lock();
	msgQueues_.erase(serial);
    mLock_.unlock();
	return SUCCESS;
}

APSEthernet::EthernetError APSEthernet::send(string serial, APSEthernetPacket msg){
    return send(serial, vector<APSEthernetPacket>(1, msg));
}

APSEthernet::EthernetError APSEthernet::send(string serial, vector<APSEthernetPacket> msg) {
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

vector<APSEthernetPacket> APSEthernet::receive(string serial, size_t timeoutMS) {

    //Read the packets coming back in up to the timeout
    std::chrono::time_point<std::chrono::steady_clock> start, end;

    start = std::chrono::steady_clock::now();
    size_t elapsedTime = 0;

    vector<APSEthernetPacket> outVec;

    while ( elapsedTime < timeoutMS){
        if (!msgQueues_[serial].empty()){
            mLock_.lock();
            outVec.push_back(msgQueues_[serial].front());
            msgQueues_[serial].pop();
            mLock_.unlock();
            return outVec;
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
        end = std::chrono::steady_clock::now();
        elapsedTime =  std::chrono::duration_cast<std::chrono::milliseconds>(end-start).count();
    }
    FILE_LOG(logWARNING) << "Timed out on receive!";
    return outVec;
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

APSEthernet::EthernetError APSEthernet::set_network_device(vector<EthernetDevInfo> pcapDevices, string nic) {
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

APSEthernet::EthernetError APSEthernet::apply_filter(string & filter, pcap_t * pcapHandle) {

    FILE_LOG(logDEBUG3) << "Setting filter to: " << filter << endl;

    u_int netmask=0xffffff; // ignore netmask 
    struct bpf_program filterCode;

    if (pcap_compile(pcapHandle, &filterCode, filter.c_str(), true, netmask) < 0 ) {
        cout << "Error to compiling enumerate packet filter. Check the syntax" << endl;
        return INVALID_PCAP_FILTER;
    }

    // set filter
    if (pcap_setfilter(pcapHandle, &filterCode) < 0) {
         cout << "Error setting the filter" << endl;
        /* Free the device list */
        return INVALID_PCAP_FILTER;
    }
    return SUCCESS;
}


void APSEthernet::run_receive_thread(){
    /*
    * Setup a background thread to pool for packets and parse into appropriate queues.
    */
    //Setup a new handle
    char errbuf[PCAP_ERRBUF_SIZE];
    pcap_t *recHandle;
    recHandle = pcap_open_live(device_.name.c_str(), // name of the device
                                  1522,                      // portion of the packet to capture
                                  false,                     // promiscuous mode
                                  pcapTimeoutMS,             // read timeout
                                  errbuf                     // error buffer
                                  );
    // filter for APS protocol and host destination
    string filterStr = create_pcap_filter();
    apply_filter(filterStr, recHandle);

    // start looping while we're up and running
    receiving_ = true;
    while(receiving_){
        struct pcap_pkthdr *packetHeader;
        const u_char *packetData;
        int result =  pcap_next_ex( recHandle, &packetHeader, &packetData);
        if (result > 0){
            //We have a packet so deal with it
            //First convert the byte stream into a packet
            APSEthernetPacket myPacket = APSEthernetPacket(packetData, packetHeader->caplen);

            //Now sort out to which queue it's going
            mLock_.lock();
            if(MAC_to_serial_.find(myPacket.header.src) == MAC_to_serial_.end()){
                msgQueues_["unknown"].emplace(myPacket);
            }
            else{
                msgQueues_[MAC_to_serial_[myPacket.header.src]].push(myPacket);
            }
            mLock_.unlock();
        }
        else if (result < 0){
            FILE_LOG(logERROR) << "Error trying to read packets: " << pcap_geterr(recHandle);
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(1));
    }

    //close up
    pcap_close(recHandle);


}