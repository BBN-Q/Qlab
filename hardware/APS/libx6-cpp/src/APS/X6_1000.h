
#include "headings.h"

#include <string>
#include <vector>

#include <X6_1000M_Mb.h>

#ifndef X6_1000_H_
#define X6_1000_H_

using std::vector;
using std::string;


class X6_1000 
{
public:
	X6_1000();
	~X6_1000();


	unsigned int    getBoardCount();

	void get_device_serials(vector<string> &);

	int set_deviceID(unsigned int deviceID);

	float get_logic_temperature();
	
	int            Open();
    bool           isOpen();
    int            Close();

    const int SUCCESS = 0;
    const int MODULE_ERROR = -1;
    const int NOT_IMPLEMENTED = -2;

    const int BusmasterSize = 4; // Rx & Tx BusMaster size in MB

private:
	Innovative::X6_1000M module_;

	unsigned int deviceID_;

	// State Variables
	bool                            isOpened_;

};

#endif