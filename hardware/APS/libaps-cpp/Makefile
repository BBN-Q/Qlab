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
CFLAGS=
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


OBJECTS=aps.o


all: libaps.$(LIBEXT) 

libaps.$(LIBEXT): $(OBJECTS)
	$(CC) $(CFLAGS) 

aps.o: aps.cpp
	$(CC) $(CFLAGS) -c aps.cpp -o aps.o
	


