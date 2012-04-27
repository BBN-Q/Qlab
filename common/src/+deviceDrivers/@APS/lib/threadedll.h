/*
 * threadedll.h
 *
 *  Created on: Mar 30, 2012
 *      Author: bdonovan
 */

#ifndef THREADEDLL_H_
#define THREADEDLL_H_

#include <pthread.h>
#include "waveform.h"

typedef struct {
	int runThread;
	int dev;
	int channel;
	// bank data
} linkListThreadData_t;


int startLinkListThread(int device, int channel);
int stopLinkListThread(int device, int channel);

#endif /* THREADEDLL_H_ */
