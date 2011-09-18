/*
 * common.c
 *
 *  Created on: Aug 24, 2011
 *      Author: bdonovan
 */

#include "common.h"
#include <stdio.h>
#include <stdarg.h>


int gDebugLevel = DEBUG_VERBOSE; // access global debug level

void dlog(int level, char * fmt, ...) {
  // wrap fprintf to force a flush after every write

  if (level > gDebugLevel) return;

  va_list args;
  va_start(args,fmt);
  vfprintf(stderr, fmt,args);
  fflush(stderr);
  va_end(args);
}

void setDebugLevel(int level) {
  gDebugLevel = level;
}

int getDebugLevel() {return gDebugLevel;}
