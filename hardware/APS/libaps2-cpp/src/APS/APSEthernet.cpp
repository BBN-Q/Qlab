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
    ios_.stop();
    receiveThread_.join();
}

void APSEthernet::setup_receive(){
    socket_.async_receive_from(
        asio::buffer(receivedData_, 2048), senderEndpoint_,
        [this](std::error_code ec, std::size_t bytesReceived)
        {
            //If there is anything to look at hand it off to the sorter
            if (!ec && bytesReceived > 0)
            {
                vector<uint8_t> packetData(receivedData_, receivedData_ + bytesReceived);
                sort_packet(packetData, senderEndpoint_);
            }

            //Start the receiver again
            setup_receive();
    });
}

void APSEthernet::sort_packet(const vector<uint8_t> & packetData, const udp::endpoint & sender){
    //If we have the endpoint address then add it to the queue
    string senderIP = sender.address().to_string();
    if(msgQueues_.find(senderIP) == msgQueues_.end()){
        //If it isn't in our list of APSs then perhaps we are seeing an enumerate status response
        //If so add the device info to the set
        if (packetData.size() == 84) {
            devInfo_[senderIP].endpoint = sender;
            //Turn the byte array into a packet to extract the MAC address
            //Not strictly necessary as we could just use the broadcast MAC address
            APSEthernetPacket packet = APSEthernetPacket(packetData);
            devInfo_[senderIP].macAddr = packet.header.src;
            FILE_LOG(logDEBUG1) << "Added device with IP " << senderIP << " and MAC addresss " << devInfo_[senderIP].macAddr.to_string();
        } 
    }
    else{
        //Turn the byte array into an APSEthernetPacket
        APSEthernetPacket packet = APSEthernetPacket(packetData);
        //Grab a lock and push the packet into the message queue
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
    for (auto kv : devInfo_) {
        FILE_LOG(logINFO) << "Found device: " << kv.first;
        deviceSerials.insert(kv.first);
    }
    return deviceSerials;
}

void APSEthernet::reset_maps() {
    devInfo_.clear();
    msgQueues_.clear();
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

APSEthernet::EthernetError APSEthernet::send(string serial, vector<APSEthernetPacket> msg, unsigned ackEvery /* see header for default */) {
    //Fill out the destination  MAC address
    FILE_LOG(logDEBUG3) << "Sending " << msg.size() << " packets to " << serial;
    unsigned ackct, packetct, retryct = 0;

    while (packetct < msg.size()){
        auto packet = msg[packetct];

        // insert the target MAC address - not really necessary anymore because UDP does filtering
        packet.header.dest = devInfo_[serial].macAddr;
        packet.header.seqNum = ackct;

        ackct++;
        //Apply acknowledge flag if necessary
        bool ackFlag = (ackct % ackEvery == 0) || (packetct == msg.size()-1);
        if( ackFlag ){
            packet.header.command.ack = 1;
        }
        FILE_LOG(logDEBUG4) << "Packet command: " << print_APSCommand(packet.header.command);
        socket_.send_to(asio::buffer(packet.serialize()), devInfo_[serial].endpoint);

        //Wait for acknowledge if we need to
        //TODO: how to check response mode/stat for success?
        if (ackFlag){
            try{
                auto response = receive(serial)[0];
            }
            catch (std::exception& e) {
               if (retryct++ < 3) {
                    FILE_LOG(logDEBUG) << "No acknowledge received, retrying ...";
                    //Reset the acknowledge count
                    ackct = 0;
                    //Go back to the last acknowledged packet
                    packetct -= (ackct % ackEvery == 0) ? ackEvery : ackct % ackEvery ;
                }
                else {
                    return TIMEOUT;
                }
            }
        }
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
            FILE_LOG(logDEBUG4) << "Received packet command: " << print_APSCommand(outVec.back().header.command);
            if (outVec.size() == numPackets){
                FILE_LOG(logDEBUG3) << "Received " << numPackets << " packets from " << serial;
                return outVec;
            }
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
        end = std::chrono::steady_clock::now();
        elapsedTime =  std::chrono::duration_cast<std::chrono::milliseconds>(end-start).count();
    }

    throw runtime_error("Timed out on receive");
}

