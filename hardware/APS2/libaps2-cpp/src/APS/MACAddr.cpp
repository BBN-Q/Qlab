#include "MACAddr.h"

#ifdef _WIN32
    #include <iphlpapi.h>
#endif

MACAddr::MACAddr() : addr(MAC_ADDR_LEN, 0){}

MACAddr::MACAddr(const string & macStr){
	addr.resize(6,0);
    std::istringstream macStream(macStr);
    for (uint8_t & macByte : addr){
        int byte;
        char colon;
        macStream >> std::hex >> byte >> colon;
        macByte = byte;
    }
}

MACAddr::MACAddr(const uint8_t * macAddrBytes){
	addr.clear();
    for (size_t ct=0; ct<6; ct++){
        addr.push_back(macAddrBytes[ct]);
    }
}

string MACAddr::to_string() const{
    std::ostringstream ss;
    for(const uint8_t curByte : addr){
        ss << std::hex << std::setfill('0') << std::setw(2) << static_cast<int>(curByte) << ":";
    }
    //remove the trailing ":"
    string myStr = ss.str();
    myStr.pop_back();
    return myStr;
}
