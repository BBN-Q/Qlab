OS=$(shell uname)

####### Mac OS X #######
ifeq (${OS},Darwin)
CFLAGS=-dynamiclib 
LIBEXT=dylib
EXFLAGS=-Wl
LFLAGS=
CC=g++
else
####### Linux ####### 
ifeq (${OS},Linux)
CFLAGS=-Wall -fPIC
LIBEXT=so
EXFLAGS=-Wl
LIBFLAGS=-shared
LFLAGS=
CC=g++
else
####### Windows #######
CFLAGS=/EHsc
OBJFLAGS=/c /Fo
OBJEXT=obj
LIBEXT=dll
LIBNAME64=libaps64.dll
EXFLAGS=-Wl,--out-implib,libaps.a
LIBFLAGS=ftd2xx.lib
CC=cl
endif
endif


OBJECTS=APSRack.$(OBJEXT) APS.$(OBJEXT) FTDI.$(OBJEXT)

all: $(OBJECTS) test

#libaps: $(OBJECTS)
#	$(CC) $(CFLAGS) $(LIBFLAGS) $(OBJECTS) libaps.cpp

APS.$(OBJEXT): APS.cpp
	$(CC) $(CFLAGS) $(OBJFLAGS) APS.cpp 
	
APSRack.$(OBJEXT): APSRack.cpp
	$(CC) $(CFLAGS) $(OBJFLAGS) APSRack.cpp 

FTDI.$(OBJEXT): FTDI.cpp
	$(CC) $(CFLAGS) $(OBJFLAGS) FTDI.cpp  

test: test.cpp $((OBJECTS)
	$(CC) $(CFLAGS) test.cpp $(OBJECTS) $(LIBFLAGS)  	

clean:
	rm -rf *.$(OBJEXT)
	rm test.exe


