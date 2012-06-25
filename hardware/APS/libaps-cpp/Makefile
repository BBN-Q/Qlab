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
LFLAGS=-ldl
CC=g++
else
####### Windows #######
CFLAGS=-mno-cygwin -D__CYGWIN__ -DBUILD_DLL -I./include -Wunused-variable
CFLAGS_STATIC=-mno-cygwin -D__CYGWIN__ -I./include -Wunused-variable
LIBEXT=dll
LIBNAME64=libaps64.dll
EXFLAGS=-Wl,--out-implib,libaps.a
LFLAGS=
####### 64-bit #######
ifeq ($(PROCESSOR_ARCHITEW6432),AMD64)
CC=i686-w64-mingw32-gcc
CC64=x86_64-w64-mingw32-gcc
GLOBAL_ALL=all64
else
####### 32-bit #######
CC=gcc
endif
endif
endif


OBJECTS=APSRack.o APS.o

all: libaps.$(LIBEXT) test

libaps.$(LIBEXT): $(OBJECTS)
	$(CC) $(CFLAGS) -shared -o libaps.$(LIBEXT) $(OBJECTS)

APS.o: APS.cpp
	$(CC) $(CFLAGS) -c APS.cpp -o APS.o
	
APSRack.o: APSRack.cpp
	$(CC) $(CFLAGS) -c APSRack.cpp -o APSRack.o
	
test: test.cpp
	$(CC) $(CFLAGS) $(OBJECTS) $(LFLAGS) -lftd2xx -Wl,-rpath /usr/local/lib -o test test.cpp 
	
clean:
	rm -rf *.o


