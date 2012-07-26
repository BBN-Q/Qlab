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


//std::thread
#include <thread>
using std::thread;
#include <chrono>


/*boost thread
#include <boost/thread.hpp>
#include <boost/chrono.hpp>
using boost::thread;
*/

//HDF5 library
#include "H5Cpp.h"

//Needed for usleep on gcc 4.7
#include <unistd.h>

//Deal with some Windows/Linux difference
#ifdef _WIN32
#include "windows.h"
#include "ftd2xx_win.h"
//Visual C++ doesn't have a usleep function so define one
/*
 inline void usleep(int waitTime) {
    long int time1 = 0, time2 = 0, freq = 0;

    QueryPerformanceCounter((LARGE_INTEGER *) &time1);
    QueryPerformanceFrequency((LARGE_INTEGER *)&freq);

    do {
        QueryPerformanceCounter((LARGE_INTEGER *) &time2);
    } while((time2-time1) < waitTime);
}
*/
#else
#include "ftd2xx.h"
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

//Helper function for saving 1D dataset from H5 files
template <typename T>
int vector2h5array(vector<T> & vectIn, const H5::H5File * h5File, const string & name, const string & dataPath, const H5::DataType & dt = H5::PredType::NATIVE_DOUBLE)
 {

	const int VECTOR_RANK = 2;
	const int ARRAY_DIM2 = 1;

	// This function written using HD5 library version 1.8.9
	// some of the data types that the HD5 C++ examples include
	// are not defined with the current header files
	// lines where the datatype has been changed to a standard datatype will be labeled

	// MISSING DEFINE: HD5:HD5std_string dataset_name(name);
	string dataset_name = name;

	hsize_t fdim[] = {vectIn.size(), ARRAY_DIM2}; // dim sizes of ds (on disk)

	// DataSpace on disk
	H5::DataSpace fspace( VECTOR_RANK, fdim );

	H5::DataSet h5Array = h5File->createDataSet(dataset_name,dt, fspace);

	h5Array.write(&vectIn[0], dt);

	h5Array.close();

	return 0;
 };

template <typename T>
int element2h5attribute(const string & name, T & element, const H5::Group * group, const H5::DataType & dt = H5::PredType::NATIVE_DOUBLE) {
	hsize_t fdim[] = {1}; // dim sizes of ds (on disk)
	// DataSpace on disk
	H5::DataSpace fspace( 1, fdim );

	FILE_LOG(logDEBUG) << "Creating Attribute: " << name << " = " << element;
	H5::Attribute tmpAttribute = group->createAttribute(name, dt,fspace);
	tmpAttribute.write(dt, &element);
	tmpAttribute.close();
	return 0;
}

template <typename T>
T h5element2element(const string & name, const H5::Group * group, const H5::DataType & dt = H5::PredType::NATIVE_DOUBLE) {
	T element;
	H5::Attribute tmpAttribute = group->openAttribute(name);
	tmpAttribute.read(dt, &element);
	tmpAttribute.close();
	FILE_LOG(logDEBUG) << "Reading Attribute: " << name << " = " << element;
	return element;
}
#endif /* HEADINGS_H_ */


