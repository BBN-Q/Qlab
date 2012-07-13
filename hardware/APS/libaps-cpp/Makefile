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
CFLAGS=-Wall -std=c++11 -stdlib=libc++ -g
OBJFLAGS=-c
OBJEXT=o
LIBEXT=dylib
EXFLAGS=-Wl
LIBFLAGS=-dynamiclib -o libaps.dylib
LIBS=-lftd2xx -lhdf5 -lhdf5_cpp
CC=clang
else
####### Linux ####### 
ifeq (${OS},Linux)
CFLAGS=-Wall -fPIC -std=c++11 -g
OBJFLAGS=-c
OBJEXT=o
LIBEXT=so
EXFLAGS=-Wl
LIBFLAGS=-shared -o libaps.so
LIBS=-lftd2xx -lhdf5 -lhdf5_cpp
CC=g++-4.7
else
####### Windows #######
#CFLAGS=/EHsc /nologo 
#OBJFLAGS=/c /Fo
#OBJEXT=obj
#LIBEXT=dll
#LIBNAME64=libaps64.dll
#LIBS=ftd2xx.lib
#LIBFLAGS=/LD
#CC=cl

CFLAGS=-Wall -std=c++11 -g
OBJFLAGS=-c
OBJEXT=o
LIBEXT=dll
EXFLAGS=-Wl
LIBFLAGS=-shared -o libaps.dll
#LIBS=ftd2xx.lib -LC:/cygwin/home/qlab/lib -lhdf5 -lhdf5_cpp
LIBS=ftd2xx.lib
LFLAGS=
CC=g++
endif
endif


OBJECTS=APSRack.$(OBJEXT) APS.$(OBJEXT) FTDI.$(OBJEXT) Channel.$(OBJEXT) LLBank.$(OBJEXT) FPGA.$(OBJEXT)

all: $(OBJECTS) libaps test

libaps: $(OBJECTS) libaps.cpp
	$(CC) $(CFLAGS) $(LIBFLAGS) libaps.cpp $(OBJECTS) $(LIBS) 

%.$(OBJEXT):%.cpp
	$(CC) $(CFLAGS) $(OBJFLAGS) $<

test: $(OBJECTS) test.cpp
	$(CC) $(CFLAGS) -o test test.cpp $(OBJECTS) $(LIBS) -L. -laps	

clean:
	rm -f *.$(OBJEXT)
	rm -f test.exe
	rm -f a.out
	rm -f libaps.$(LIBEXT)

tidy:
	rm -f *.$(OBJEXT)
