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

//FTDI
#ifdef _WIN32
#include "windows.h"
#include "ftd2xx_win.h"
#define EXPORT __declspec(dllexport)
#else
#include "ftd2xx.h"
#define EXPORT
#endif


#include "Waveform.h"
#include "LinkList.h"
#include "Channel.h"
#include "APS.h"
#include "logger.h"
#include "APSRack.h"
#include "FTDI.h"

//CONSTANTS

#define MAX_APS_CHANNELS 4
#define MAX_APS_BANKS 2

#define APS_WAVEFORM_UNIT_LENGTH 4

#define MAX_WAVEFORM_LENGTH 8192

#define NUM_BITS 13

#define MAX_WF_VALUE (pow(2,NUM_BITS)-1)

#define MAX_APS_DEVICES 10





#endif /* HEADINGS_H_ */
