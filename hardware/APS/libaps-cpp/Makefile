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
LIBS=-L. -L/usr/local/hdf5/lib -L/usr/local/lib -lftd2xx -lhdf5_cpp -lhdf5
TESTLIBS=-laps
CC=xcrun clang++
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

##MSVC
#CFLAGS=/EHsc /nologo 
#OBJFLAGS=/c /Fo
#OBJEXT=obj
#LIBEXT=dll
#LIBNAME64=libaps64.dll
#LIBS=ftd2xx.lib
#LIBFLAGS=/LD
#CC=cl

##mingw
CFLAGS=-Wall -std=c++11 -I'C:\MinGW\msys\1.0\local\include\cpp' -I'C:\MinGW\msys\1.0\local\include'
OBJFLAGS=-c
OBJEXT=o
LIBEXT=dll
EXFLAGS=-Wl
LIBFLAGS=-shared -o libaps.dll 
LIBS=-L'C:\MinGW\msys\1.0\local\lib'
TESTLIBS=-L.
LFLAGS=
CC=g++

ifeq ($(target), 32)
	CFLAGS += -m32
	LIBS += -lftd2xx_32 -lhdf5_cpp_32 -lhdf5_32
	LIBFLAGS=-shared -o libaps.dll
	TESTLIBS += -laps
	TESTOBJS = libaps.$(OBJEXT)
else
	LIBS += -lftd2xx -lhdf5_cpp -lhdf5
	LIBFLAGS=-shared -o libaps64.dll
	TESTLIBS += -laps64
	TESTOBJS = libaps.$(OBJEXT)
endif

endif
endif

ifeq ($(mode), debug)
	CFLAGS += -g
else
	CFLAGS += -Os
endif

OBJECTS=APSRack.$(OBJEXT) APS.$(OBJEXT) FTDI.$(OBJEXT) Channel.$(OBJEXT) LLBank.$(OBJEXT) FPGA.$(OBJEXT)

all: $(OBJECTS) libaps test

libaps: $(OBJECTS) libaps.cpp
	$(CC) $(CFLAGS) $(LIBFLAGS) libaps.cpp $(OBJECTS) $(LIBS)

%.$(OBJEXT):%.cpp %.h headings.h
	$(CC) $(CFLAGS) $(OBJFLAGS) $<

test: $(OBJECTS) $(TESTOBJS) test.cpp
	$(CC) $(CFLAGS) -o test test.cpp $(OBJECTS) $(TESTOBJS) $(LIBS)

clean:
	rm -f *.$(OBJEXT)
	rm -f test.exe
	rm -f a.out
	rm -f libaps.$(LIBEXT)
	rm -f libaps64.$(LIBEXT)

tidy:
	rm -f *.$(OBJEXT)
