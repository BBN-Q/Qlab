#include "headings.h"

#ifndef MACADDR_H_
#define MACADDR_H_

struct EthernetDevInfo;

class MACAddr{
public:

	MACAddr();
	MACAddr(const uint8_t *);
	MACAddr(const string &);
	static MACAddr MACAddr_from_devName(const string &);

	bool operator==(const MACAddr & other) const{
		return (addr == other.addr);
	}
	string to_string() const;

	static bool is_valid(const string &);
	static const unsigned int MAC_ADDR_LEN = 6;

	vector<uint8_t> addr;

};

namespace std{

	template <>
	struct hash<MACAddr>
	{
		size_t operator()(const MACAddr & m) const{
			return hash<string>()(m.to_string());
		}
	};
}

#endif