#include "X6_1000.h"


// default constructor
X6_1000::X6_1000() {
	int numBoards = getBoardCount();

	for(int cnt = 0; cnt < numBoards; cnt++) {
		isOpened_.push_back(false);
	}
}

unsigned int  X6_1000::getBoardCount() {
	return static_cast<unsigned int>(module_.BoardCount());
}

void X6_1000::get_device_serials(vector<string> & deviceSerials) {
	deviceSerials.clear();

	int numBoards = getBoardCount();

	// TODO: Identify a way to get serial number from X6 board if possible otherwise get slot id etc
	for (int cnt = 0; cnt < numBoards; cnt++)
		deviceSerials.push_back(std::to_string(cnt));
}

 bool X6_1000::isOpen(unsigned int deviceCnt) {
 	if (deviceCnt > isOpened_.size() - 1) 
 		return false;
 	else
 		return isOpened_[deviceCnt];
 }

 