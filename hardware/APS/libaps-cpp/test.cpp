/*
 * test.cpp
 *
 *  Created on: Jun 24, 2012
 *      Author: cryan
 */

#include "headings.h"

int main(int argc, char** argv) {

	//Load an APS Rack
	cout << "Got here!" << endl;

	APSRack	silly;

	silly.init();
	silly.connect(0);
	silly.disconnect(0);

	cout << "Made it through!" << endl;

	UCHAR readByte;
	readByte = 0x10;
	cout << std::hex << setiosflags(std::ios_base::showbase) << int(readByte) << endl;
	cout << "hello " << 73 << endl;;
	return 0;

}


