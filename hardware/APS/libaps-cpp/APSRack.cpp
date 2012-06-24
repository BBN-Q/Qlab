/*
 * APSRack.cpp
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#include "APSRack.h"

APSRack::APSRack() {
	// TODO Auto-generated constructor stub

}

APSRack::~APSRack() {
	// TODO Auto-generated destructor stub
}

//Initialize the rack by polling for devices and serial numbers
int APSRack::Init() {

	//Create the logger
	logging::init_log_to_

	//Load the FTDI USB library
	#ifdef WIN32

		hdll = LoadLibrary("ftd2xx.dll");
		if ((uintptr_t)hdll <= HINSTANCE_ERROR) {
			dlog(DEBUG_INFO,"Error opening ftd2xx.dll library\n");
			return -1;
		}

	#else
		hdll = dlopen(LIBFILE,RTLD_LAZY);
		if (hdll == 0) {
			dlog(DEBUG_INFO,"Error opening ftd2 library: %s\n",dlerror());
			return -1;
		}
	#endif



}
