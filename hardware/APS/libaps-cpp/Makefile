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
LIBS=ftd2xx.lib
LIBFLAGS=/LD
CC=cl
endif
endif


OBJECTS=APSRack.$(OBJEXT) APS.$(OBJEXT) FTDI.$(OBJEXT) Channel.$(OBJEXT) Waveform.$(OBJEXT) LinkList.$(OBJEXT)

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


