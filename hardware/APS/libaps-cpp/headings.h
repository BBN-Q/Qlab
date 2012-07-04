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

//Standard library includes
#include <string>
#include <vector>
#include <iostream>
#include <fstream>
#include <iomanip>
#include <stdio.h>
#include <map>
#include <math.h>
#include <stdexcept>
#include <algorithm>
using std::vector;
using std::string;
using std::cout;
using std::endl;
using std::map;
using std::runtime_error;
using std::hex;
using std::setiosflags;


//Deal with some Windows/Linux difference
#ifdef _WIN32
#include "windows.h"
#include "ftd2xx_win.h"
//Windows doesn't have a usleep function so define one
inline void usleep(int waitTime) {
    long int time1 = 0, time2 = 0, freq = 0;

    QueryPerformanceCounter((LARGE_INTEGER *) &time1);
    QueryPerformanceFrequency((LARGE_INTEGER *)&freq);

    do {
        QueryPerformanceCounter((LARGE_INTEGER *) &time2);
    } while((time2-time1) < waitTime);
}
#else
#include "ftd2xx.h"
//Needed for usleep on gcc 4.7
#include <unistd.h>
#define EXPORT
#endif

//Load all the constants
#include "constants.h"


#include "Waveform.h"
#include "Waveform.h"
#include "LinkList.h"
#include "Channel.h"
#include "APS.h"
#include "logger.h"
#include "APSRack.h"
#include "FTDI.h"
#include "FPGA.h"


#endif /* HEADINGS_H_ */
