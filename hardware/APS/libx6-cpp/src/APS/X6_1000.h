#ifndef X6_1000_H_
#define X6_1000_H_

#include <string>
#include <vector>

#include <X6_1000M_Mb.h>


using std::vector;
using std::string;

class X6_1000 
{
public:
	X6_1000();
	~X6_1000() {};


	unsigned int    getBoardCount();

	void get_device_serials(vector<string> &);

	
	
	void            Open();
    bool            isOpen(unsigned int deviceCnt);
    void            Close();

private:
	Innovative::X6_1000M module_;

	// State Variables
	vector<bool>                            isOpened_;
};

#endif