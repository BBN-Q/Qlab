/*
 * test.cpp
 *
 *  Created on: Jun 24, 2012
 *      Author: cryan
 */

#include "headings.h"

#include "libaps.h"


int main(int argc, char** argv) {

	cout << "Got here!" << endl;

	//Initialize the APSRack from the DLL
	init();

	//Connect to device
	connect_by_ID(0);

	//Bit file location
	string bitFile = "C:\\Users\\qlab\\Qlab Software\\common\\src\\+deviceDrivers\\@APS\\mqco_aps_latest.bit";

	initAPS(0, const_cast<char*>(bitFile.c_str()), true);

	disconnect_by_ID(0);


//	APSRack	myRack;
//
//	myRack.init();
//	myRack.connect(0);
//	myRack.set_sampleRate(0, 0, 1200, false);
//	cout << myRack.get_sampleRate(0,0) << endl;
//	myRack.disconnect(0);

	APS tmpAPS;
	tmpAPS.load_sequence_file("RamseyBBNAPS34.h5");

	cout << "Made it through!" << endl;

	return 0;

}


