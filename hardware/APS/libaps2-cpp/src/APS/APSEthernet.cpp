#include "APSEthernet.h"

class BroadcastServer {
public:
    BroadcastServer(asio::io_service& io_service, uint16_t port, vector<asio::ip::address>& IPs) : 
        socket_(io_service, udp::endpoint(udp::v4(), port)), port_(port) {
        socket_.set_option(asio::socket_base::broadcast(true));
        setup_receive(IPs);
    };

    ~BroadcastServer(){
        socket_.close();
    }
    void setup_receive(vector<asio::ip::address>& IPs){
        //When a packet comes back in from an APS add the IP/MAC address pair to the list
        socket_.async_receive_from(
            asio::buffer(data_, 2048), senderEndpoint_,
            [this, &IPs](std::error_code ec, std::size_t bytes_recvd)
            {
              if (!ec && bytes_recvd > 0)
              {
                IPs.push_back(senderEndpoint_.address());
              }
              //Start the receiver again
              setup_receive(IPs);
        });
    }

    void send_broadcast(){
        //Put together the broadcast status request
        APSEthernetPacket broadcastPacket = APSEthernetPacket::create_broadcast_packet();
        udp::endpoint broadCastEndPoint(asio::ip::address_v4::broadcast(), port_);
        socket_.send_to(asio::buffer(broadcastPacket.serialize()), broadCastEndPoint);
    };

private:
    udp::socket socket_;
    udp::endpoint senderEndpoint_;
    uint16_t port_;
    uint8_t data_[2048];

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
    TODO: Should eventually bind to particular NIC here?
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


    vector<asio::ip::address> IPs;
    asio::io_service io_service;
    BroadcastServer bs(io_service, 47950, IPs);
    bs.send_broadcast();

    std::thread myThread([&io_service](){ io_service.run(); });

    std::this_thread::sleep_for(std::chrono::milliseconds(1000));

    io_service.stop();
    myThread.join();
    
    set<string> deviceSerials;
    for (auto ip : IPs) {
        FILE_LOG(logINFO) << "Found device: " << ip.to_string();
        deviceSerials.insert(ip.to_string());
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