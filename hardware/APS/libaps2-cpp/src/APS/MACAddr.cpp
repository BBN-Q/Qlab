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

MACAddr MACAddr::MACAddr_from_devName(const string & devName){
	//Extract a MAC address from the the pcap information. A bit of a cross-platform pain. 
#ifdef _WIN32
    
    // winpcap names are different than widows names
    // pcap - \Device\NPF_{F47ACE9E-1961-4A8E-BA14-2564E3764BFA}
    // windows - {F47ACE9E-1961-4A8E-BA14-2564E3764BFA}
    // 
    // start by triming input name to only {...}
    size_t start,end;

    start = devName.find('{');
    end = devName.find('}');

    if (start == std::string::npos || end == std::string::npos) {
        FILE_LOG(logERROR) << "getMacAddr: Invalid devInfo name";
        return MACAddr();
    }

    string winName = devName.substr(start, end-start + 1);
    
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
        return MACAddr();
    }
    
    // call GetAdaptersInfo a second time to get all adapter information
    if ((dwRetVal = GetAdaptersInfo(pAdapterInfo, &ulOutBufLen)) == NO_ERROR) {
        pAdapter = pAdapterInfo;

        // loop over adapters and match name strings
        while (pAdapter) {
            string matchName = string(pAdapter->AdapterName);
            if (winName.compare(matchName) == 0) {
                myMAC = MACAddr(pAdapter->Address);
                free(pAdapterInfo);
                return myMAC;
            }
            pAdapter = pAdapter->Next;
        }
    }

    if (pAdapterInfo) free(pAdapterInfo);
    //TODO: throw a proper error
    logERROR << "Unable to extract MAC address."
    return MACAddr("ERROR");
        
#else
    //On Linux we simply look in /sys/class/net/DEVICE_NAME/address
    std::ifstream devFile(std::string("/sys/class/net/") + devName + std::string("/address"));
	std::string macAddrStr;
	getline(devFile, macAddrStr);
	return MACAddr(macAddrStr);

#endif

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