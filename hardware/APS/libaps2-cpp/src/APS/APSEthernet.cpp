#include "APSEthernet.h"

APSEthernet::APSEthernet() : socket_(ios_) {
    //Setup the socket to the APS_PROTO port and enable broadcasting for enumerating
    std::error_code ec;
    socket_.open(udp::v4(), ec);
    if (ec) {FILE_LOG(logERROR) << "Failed to open socket.";}
    socket_.bind(udp::endpoint(asio::ip::address::from_string("192.168.5.1"), APS_PROTO), ec);
    if (ec) {FILE_LOG(logERROR) << "Failed to bind to socket.";}

    socket_.set_option(asio::socket_base::broadcast(true));

    //io_service will return immediately so post receive task before .run()
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
    socket_.async_receive_from(
        asio::buffer(receivedData, 2048), senderEndpoint,
        [this](std::error_code ec, std::size_t bytesReceived)
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
    FILE_LOG(logDEBUG3) << "Sending " << msg.size() << " packets to " << serial;
    for (auto & packet : msg){
        FILE_LOG(logDEBUG4) << "Packet command: " << print_APSCommand(packet.header.command);
        packet.header.dest = serial_to_MAC_[serial];
        socket_.send_to(asio::buffer(packet.serialize()), endpoints_[serial]);
    }

    return SUCCESS;
}

vector<APSEthernetPacket> APSEthernet::receive(string serial, size_t numPackets, size_t timeoutMS) {
    //Read the packets coming back in up to the timeout
    //Defaults: receive(string serial, size_t numPackets = 1, size_t timeoutMS = 1000);
    std::chrono::time_point<std::chrono::steady_clock> start, end;

    start = std::chrono::steady_clock::now();
    size_t elapsedTime = 0;

    vector<APSEthernetPacket> outVec;

    while (elapsedTime < timeoutMS){
        if (!msgQueues_[serial].empty()){
            mLock_.lock();
            outVec.push_back(msgQueues_[serial].front());
            msgQueues_[serial].pop();
            mLock_.unlock();
            FILE_LOG(logDEBUG4) << "Received packet for " << serial << " with command header: " << print_APSCommand(outVec.back().header.command);
            if (outVec.size() == numPackets){
                FILE_LOG(logDEBUG3) << "Received " << numPackets << " packets for " << serial;
                return outVec;
            }
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
        end = std::chrono::steady_clock::now();
        elapsedTime =  std::chrono::duration_cast<std::chrono::milliseconds>(end-start).count();
    }

    throw runtime_error("Timed out on receive");
}

