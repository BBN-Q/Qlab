#ifndef MACADDR_H_
#define MACADDR_H_

struct EthernetDevInfo;

class MACAddr{
public:

	MACAddr();
	MACAddr(const int &);
	MACAddr(const string &);
	MACAddr(const EthernetDevInfo &);

	string to_string() const;

	static bool is_valid(const string &);
	static const unsigned int MAC_ADDR_LEN = 6;

	vector<uint8_t> addr;

};

#endif