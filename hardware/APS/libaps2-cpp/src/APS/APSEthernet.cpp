#include "APSEthernet.h"

APSEthernet::APSEthernet() : socket_(ios_) {
    //Setup the socket to the APS_PROTO port and enable broadcasting for enumerating
    std::error_code ec;
    socket_.open(udp::v4(), ec);
    if (ec) {FILE_LOG(logERROR) << "Failed to open socket.";}
    socket_.bind(udp::endpoint(udp::v4(), APS_PROTO), ec);
    if (ec) {FILE_LOG(logERROR) << "Failed to bind to socket.";}

    socket_.set_option(asio::socket_base::broadcast(true));

    setup_receive();

    //Setup the asio service to run on a background thread
    receiveThread_ = std::thread([&](){ ios_.run(); });

};

APSEthernet::~APSEthernet() {
    //Stop the receive thread
    receiving_ = false;
    ios_.stop();
    receiveThread_.join();
}

void APSEthernet::setup_receive(){
    udp::endpoint senderEndpoint;
    uint8_t receivedData[2048];
    socket_.async_receive_from(
        asio::buffer(receivedData, 2048), senderEndpoint,
        [&](std::error_code ec, std::size_t bytesReceived)
        {
            //If there is anything to look at hand it off to the sorter
            if (!ec && bytesReceived > 0)
            {
                vector<uint8_t> packetData(receivedData, receivedData + bytesReceived);
                sort_packet(packetData, senderEndpoint);
            }
            //Start the receiver again
            setup_receive();
    });
}

void APSEthernet::sort_packet(const vector<uint8_t> & packetData, const udp::endpoint & sender){
    //If we have the endpoint address then add it to the queue
    string senderIP = sender.address().to_string();
    if(msgQueues_.find(senderIP) == msgQueues_.end()){
        //We are probably seeing an enumerate status response so add the endpoint to the set
        if (packetData.size() == 84) {
            if ( endpoints_.find(senderIP) == endpoints_.end()){
                endpoints_[senderIP] = sender;
                APSEthernetPacket packet = APSEthernetPacket(packetData);
                serial_to_MAC_[senderIP] = packet.header.src;
                FILE_LOG(logINFO) << "Found MAC addresss: " << serial_to_MAC_[senderIP].to_string();
            }

        } 
    }
    else{
        APSEthernetPacket packet = APSEthernetPacket(packetData);
        mLock_.lock();
        msgQueues_[senderIP].emplace(packet);
        mLock_.unlock();
    }
}

/* PUBLIC methods */

APSEthernet::EthernetError APSEthernet::init(string nic) {
    /*
    --Nothing doing for now
    TODO: Should eventually bind to particular NIC here?
    */ 
    reset_maps();

    return SUCCESS;
}

set<string> APSEthernet::enumerate() {
	/*
	 * Look for all APS units that respond to the broadcast packet
	 */

	FILE_LOG(logDEBUG1) << "APSEthernet::enumerate";

    reset_maps();

    //Put together the broadcast status request
    APSEthernetPacket broadcastPacket = APSEthernetPacket::create_broadcast_packet();
    udp::endpoint broadCastEndPoint(asio::ip::address_v4::broadcast(), APS_PROTO);
    socket_.send_to(asio::buffer(broadcastPacket.serialize()), broadCastEndPoint);

    vector<asio::ip::address> IPs;


    std::this_thread::sleep_for(std::chrono::milliseconds(1000));

    set<string> deviceSerials;
    for (auto & kv : endpoints_) {
        FILE_LOG(logINFO) << "Found device: " << kv.first;
        deviceSerials.insert(kv.first);
    }
    return deviceSerials;
}

void APSEthernet::reset_maps() {
    serial_to_MAC_.clear();
    serial_to_MAC_["broadcast"] = MACAddr("FF:FF:FF:FF:FF:FF");
    msgQueues_.clear();
    endpoints_.clear();
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
    //Fill out the destination  MAC address
    for (auto & packet : msg){
        FILE_LOG(logINFO) << "Sending to MAC addresss: " << serial_to_MAC_[serial].to_string();
        packet.header.dest = serial_to_MAC_[serial];
        // socket_.send_to(asio::buffer(packet.serialize()), endpoints_[serial]);
        udp::endpoint broadCastEndPoint(asio::ip::address_v4::broadcast(), APS_PROTO);
        socket_.send_to(asio::buffer(packet.serialize()), broadCastEndPoint);
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

// void APSEthernet::run_receive_thread(){
//     /*
//     * Setup a background thread to pool for packets and parse into appropriate queues.
//     */
//     //Setup a new handle
//     char errbuf[PCAP_ERRBUF_SIZE];
//     pcap_t *recHandle;
//     recHandle = pcap_open_live(device_.name.c_str(), // name of the device
//                                   1522,                      // portion of the packet to capture
//                                   false,                     // promiscuous mode
//                                   pcapTimeoutMS,             // read timeout
//                                   errbuf                     // error buffer
//                                   );
//     // filter for APS protocol and host destination
//     string filterStr = create_pcap_filter();
//     apply_filter(filterStr, recHandle);

//     // start looping while we're up and running
//     receiving_ = true;
//     while(receiving_){
//         struct pcap_pkthdr *packetHeader;
//         const u_char *packetData;
//         int result =  pcap_next_ex( recHandle, &packetHeader, &packetData);
//         if (result > 0){
//             //We have a packet so deal with it
//             //First convert the byte stream into a packet
//             APSEthernetPacket myPacket = APSEthernetPacket(packetData, packetHeader->caplen);

//             //Now sort out to which queue it's going
//             mLock_.lock();
//             if(MAC_to_serial_.find(myPacket.header.src) == MAC_to_serial_.end()){
//                 msgQueues_["unknown"].emplace(myPacket);
//             }
//             else{
//                 msgQueues_[MAC_to_serial_[myPacket.header.src]].push(myPacket);
//             }
//             mLock_.unlock();
//         }
//         else if (result < 0){
//             FILE_LOG(logERROR) << "Error trying to read packets: " << pcap_geterr(recHandle);
//         }
//         std::this_thread::sleep_for(std::chrono::milliseconds(1));
//     }

//     //close up
//     pcap_close(recHandle);

// }