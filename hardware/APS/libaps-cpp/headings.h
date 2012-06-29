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
#include <math.h>
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

static const int  MAX_APS_CHANNELS = 4;
static const int  MAX_APS_BANKS = 2;

static const int  APS_WAVEFORM_UNIT_LENGTH = 4;

static const int  MAX_WAVEFORM_LENGTH = 8192;

static const int  NUM_BITS = 13;

static const int  MAX_WF_VALUE = (pow(2,NUM_BITS)-1);

static const int  MAX_APS_DEVICES = 10;

static const int APS_READTIMEOUT = 1000;
static const int APS_WRITETIMEOUT = 500;

static const int  APS_PGM01_BIT = 1;
static const int  APS_PGM23_BIT = 2;
static const int  APS_PGM_BITS = (APS_PGM01_BIT | APS_PGM23_BIT);

static const int  APS_FRST01_BIT = 0x4;
static const int  APS_FRST23_BIT = 0x8;
static const int  APS_FRST_BITS = (APS_FRST01_BIT | APS_FRST23_BIT);

static const int  APS_DONE01_BIT = 0x10;
static const int  APS_DONE23_BIT = 0x20;
static const int  APS_DONE_BITS = (APS_DONE01_BIT | APS_DONE23_BIT);

static const int  APS_INIT01_BIT = 0x40;
static const int  APS_INIT23_BIT = 0x80;
static const int  APS_INIT_BITS = (APS_INIT01_BIT | APS_INIT23_BIT);


static const int  APS_FPGA_IO = 0;
static const int  APS_FPGA_ADDR = (1<<4);
static const int  APS_DAC_SPI = (2<<4);
static const int  APS_PLL_SPI = (3<<4);
static const int  APS_VCXO_SPI = (4<<4);
static const int  APS_CONF_DATA = (5<<4);
static const int  APS_CONF_STAT = (6<<4);
static const int  APS_STATUS_CTRL = (7<<4);
static const int  APS_CMD = (0x7<<4);

static const int  LSB_MASK = 0xFF;


// Register Locations
static const int  FPGA_OFF_CSR 	  =   0x0;
static const int  FPGA_OFF_TRIGLED  =   0x1;
static const int  FPGA_OFF_ENVOFF   =   0x2;
static const int  FPGA_OFF_ENVSIZE  =   0x3;
static const int  FPGA_OFF_PHSOFF   =   0x4;
static const int  FPGA_OFF_PHSSIZE  =   0x5;
static const int  FPGA_OFF_VERSION  =   0x6;
static const int  FPGA_OFF_LLCTRL	=     0x7;

// Version 0x10 ELL Memory Map Additions
static const int  FPGA_ADDR_ELL_REGREAD =   0x8000;
static const int  FPGA_ADDR_SYNC_REGREAD =  0XF000;

static const int  FPGA_ADDR_ELL_ENVWRITE =  0x1000;
static const int  FPGA_ADDR_ELL_PHSWRITE =  0x4000;

static const int  FPGA_ADDR_ELL_ENVLL_A_WRITE = 0x3000;
static const int  FPGA_ADDR_ELL_ENVLL_B_WRITE = 0x3800;

static const int  FPGA_ADDR_ELL_PHSLL_A_WRITE = 0x6000;
static const int  FPGA_ADDR_ELL_PHSLL_B_WRITE = 0x6800;

#endif /* HEADINGS_H_ */
