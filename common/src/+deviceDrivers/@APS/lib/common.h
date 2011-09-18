/*
 * common.h
 *
 *  Created on: Aug 24, 2011
 *      Author: bdonovan
 */

#ifndef COMMON_H_
#define COMMON_H_

#define DEBUG_INFO 0
#define DEBUG_VERBOSE 1
#define DEBUG_VERBOSE2 2

void dlog(int level, char * fmt, ...);

void setDebugLevel(int);
int getDebugLevel();

#endif /* COMMON_H_ */
