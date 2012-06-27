##############################################
# Module Name : libaps Makefile
#
# Author/Date : Colm Ryan / June 2012
#
# Description : Makefile for building libaps with gcc or cl
#
# Copyright (C) BBN Technologies Corp. 2012
########################################################

OS=$(shell uname)

####### Mac OS X #######
ifeq (${OS},Darwin)
#Not handled yet
else
####### Linux ####### 
ifeq (${OS},Linux)
CFLAGS=-Wall -fPIC -std=c++11
OBJFLAGS=-c
OBJEXT=o
LIBEXT=so
EXFLAGS=-Wl
LIBFLAGS=-shared
LIBS=-lftd2xx
LFLAGS=
CC=g++-4.7
else
####### Windows #######
CFLAGS=/EHsc
OBJFLAGS=/c /Fo
OBJEXT=obj
LIBEXT=dll
LIBNAME64=libaps64.dll
LIBS=ftd2xx.lib
LIBFLAGS=/LD
CC=cl
endif
endif


OBJECTS=APSRack.$(OBJEXT) APS.$(OBJEXT) FTDI.$(OBJEXT) Channel.$(OBJEXT) Waveform.$(OBJEXT) LinkList.$(OBJEXT) FPGA.$(OBJEXT)

all: $(OBJECTS) test libaps

libaps: $(OBJECTS)
	$(CC) $(CFLAGS) $(LIBFLAGS) libaps.cpp $(OBJECTS) $(LIBS) 

%.$(OBJEXT):%.cpp
	$(CC) $(CFLAGS) $(OBJFLAGS) $<

test: test.cpp $((OBJECTS)
	$(CC) $(CFLAGS) test.cpp $(OBJECTS) $(LIBS)  	

clean:
	rm -rf *.$(OBJEXT)
	rm test.exe


