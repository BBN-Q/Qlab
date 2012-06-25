/*
 * headings.h
 *
 * Bring all the includes and constants together in one file
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */


// INCLUDES
#ifndef HEADINGS_H_
#define HEADINGS_H_

#include <string>
#include <vector>
#include <iostream>
#include <stdio.h>
#include <map>
using std::vector;
using std::string;
using std::cout;
using std::endl;
using std::map;

#include <dlfcn.h>


#include "Waveform.h"
#include "LinkList.h"
#include "Channel.h"
#include "APS.h"
#include "logger.h"
#include "APSRack.h"

//CONSTANTS

#define MAX_APS_CHANNELS 4
#define MAX_APS_BANKS 2

#define APS_WAVEFORM_UNIT_LENGTH 4

#define MAX_WAVEFORM_LENGTH 8192

#define NUM_BITS 13

#define MAX_WF_VALUE (pow(2,NUM_BITS)-1)

#define MAX_APS_DEVICES 10



//FTDI
#ifdef WIN32
#include <windows.h>
#include "ftd2xx.h"
#define LIBFILE "ftd2xx.dll"

#define GetFunction GetProcAddress

#else
#include <dlfcn.h>
#include "WinTypes.h"
#include "ftd2xx.h"
#define LIBFILE "libftd2xx.so"
#define GetFunction dlsym

#endif




#endif /* HEADINGS_H_ */
