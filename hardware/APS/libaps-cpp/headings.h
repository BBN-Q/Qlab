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
#include <thread>
using std::vector;
using std::string;
using std::cout;
using std::endl;
using std::map;
using std::runtime_error;
using std::thread;

//HDF5 library
#include "H5Cpp.h"

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

//Simple structure for pairs of address/data checksums
struct CheckSum {
	WORD address;
	WORD data;
};

//PLL routines go through sets of address/data pairs
typedef std::pair<ULONG, UCHAR> PLLAddrData;


//Load all the constants
#include "constants.h"

#include "FTDI.h"
#include "FPGA.h"

#include "LLBank.h"
#include "Channel.h"
#include "APS.h"
#include "APSRack.h"


#include "logger.h"

//Helper function for hex formating with the 0x out front
inline std::ios_base&
myhex(std::ios_base& __base)
{
  __base.setf(std::ios_base::hex, std::ios_base::basefield);
  __base.setf(std::ios::showbase);
  return __base;
}

//Helper function for loading 1D dataset from H5 files
template <typename T>
vector<T> h5array2vector(const H5::H5File * h5File, const string & dataPath, const H5::DataType & dt = H5::PredType::NATIVE_DOUBLE)
 {
   // Initialize to dataspace, to find the indices we are looping over
   H5::DataSet h5Array = h5File->openDataSet(dataPath);
   H5::DataSpace arraySpace = h5Array.getSpace();

   // Initialize vector and allocate enough space
   vector<T> vecOut(arraySpace.getSimpleExtentNpoints());

  // Read in data from file to memory
   h5Array.read(&vecOut.front(), dt);

   h5Array.close();

   return vecOut;
 };

#endif /* HEADINGS_H_ */


