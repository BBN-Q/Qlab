/*
 * libaps.cpp
 *
 * A thin wrapper around APSRack to allow calling from Matlab without name-mangling.
 *  Created on: Jun 25, 2012
 *      Author: qlab
 */

#include "headings.h"

APSRack _APSRack;

#ifdef __cplusplus
extern "C" {
#endif

EXPORT int Init() {

	_APSRack = APSRack();
	_APSRack.Init();

	return 0;
}

EXPORT int open_by_ID(int deviceID){
	//Connect to a device specified by ID
	return _APSRack.connect(deviceID);

}

#ifdef __cplusplus
}
#endif

