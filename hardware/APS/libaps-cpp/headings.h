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
#include <stdio.h>
#include <map>
#include <stdexcept>
#include <algorithm>
using std::vector;
using std::string;
using std::cout;
using std::endl;
using std::map;
using std::runtime_error;



//Deal with some Windows/Linux difference
#ifdef _WIN32
#include "windows.h"
#include "ftd2xx_win.h"
#define EXPORT __declspec(dllexport)

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


#include "Waveform.h"
#include "LinkList.h"
#include "Channel.h"
#include "APS.h"
#include "logger.h"
#include "APSRack.h"
#include "FTDI.h"
#include "FPGA.h"

//CONSTANTS

#define MAX_APS_CHANNELS 4
#define MAX_APS_BANKS 2

#define APS_WAVEFORM_UNIT_LENGTH 4

#define MAX_WAVEFORM_LENGTH 8192

#define NUM_BITS 13

#define MAX_WF_VALUE (pow(2,NUM_BITS)-1)

#define MAX_APS_DEVICES 10


#define APS_PGM01_BIT 1
#define APS_PGM23_BIT 2
#define APS_PGM_BITS (APS_PGM01_BIT | APS_PGM23_BIT)

#define APS_FRST01_BIT 0x4
#define APS_FRST23_BIT 0x8
#define APS_FRST_BITS (APS_FRST01_BIT | APS_FRST23_BIT)

#define APS_DONE01_BIT 0x10
#define APS_DONE23_BIT 0x20
#define APS_DONE_BITS (APS_DONE01_BIT | APS_DONE23_BIT)

#define APS_INIT01_BIT 0x40
#define APS_INIT23_BIT 0x80
#define APS_INIT_BITS (APS_INIT01_BIT | APS_INIT23_BIT)


#define APS_FPGA_IO 0
#define APS_FPGA_ADDR (1<<4)
#define APS_DAC_SPI (2<<4)
#define APS_PLL_SPI (3<<4)
#define APS_VCXO_SPI (4<<4)
#define APS_CONF_DATA (5<<4)
#define APS_CONF_STAT (6<<4)
#define APS_STATUS_CTRL (7<<4)
#define APS_CMD (0x7<<4)

#define LSB_MASK 0xFF;


// Register Locations
#define FPGA_OFF_CSR 	    0x0
#define FPGA_OFF_TRIGLED    0x1
#define FPGA_OFF_ENVOFF     0x2
#define FPGA_OFF_ENVSIZE    0x3
#define FPGA_OFF_PHSOFF     0x4
#define FPGA_OFF_PHSSIZE    0x5
#define FPGA_OFF_VERSION    0x6
#define FPGA_OFF_LLCTRL	    0x7

// Version 0x10 ELL Memory Map Additions
#define FPGA_ADDR_ELL_REGREAD   0x8000
#define FPGA_ADDR_SYNC_REGREAD  0XF000

#define FPGA_ADDR_ELL_ENVWRITE  0x1000
#define FPGA_ADDR_ELL_PHSWRITE  0x4000

#define FPGA_ADDR_ELL_ENVLL_A_WRITE 0x3000
#define FPGA_ADDR_ELL_ENVLL_B_WRITE 0x3800

#define FPGA_ADDR_ELL_PHSLL_A_WRITE 0x6000
#define FPGA_ADDR_ELL_PHSLL_B_WRITE 0x6800

#endif /* HEADINGS_H_ */
