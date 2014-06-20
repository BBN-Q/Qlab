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
//#include <math.h>
#include <cmath>
#include <stdexcept>
#include <algorithm>
#include <queue>
using std::vector;
using std::string;
using std::cout;
using std::endl;
using std::map;
using std::runtime_error;

#include <thread>
// #include <mutex>
// #include <atomic>
#include <utility>
#include <chrono>

//Needed for usleep on gcc 4.7
#include <unistd.h>

#include "logger.h"

//Load all the constants
#include "constants.h"

//Helper function for hex formating with the 0x out front
inline std::ios_base&
myhex(std::ios_base& __base)
{
  __base.setf(std::ios_base::hex, std::ios_base::basefield);
  __base.setf(std::ios::showbase);
  return __base;
}

inline int mymod(int a, int b) {
	int c = a % b;
	if (c < 0)
		c += b;
	return c;
}

#endif /* HEADINGS_H_ */


