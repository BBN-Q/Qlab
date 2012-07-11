/*
 * test.cpp
 *
 *  Created on: Jun 24, 2012
 *      Author: cryan
 */

#include "headings.h"


int main(int argc, char** argv) {

	//Initialize the APSRack from the DLL
	init();

	//Connect to device
	connect_by_ID(0);

	initAPS(0);


	cout << "Got here!" << endl;

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


