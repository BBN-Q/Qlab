##############################################
# Module Name : libaps Makefile
#
# Author/Date : B.C. Donovan / 21-Oct-08
#
# Description : Makefile for building libaps with cygwin
#
# $Author: bdonovan $
# $Date$
# $Locker:  $
# $Name:  $
# $Revision$
# Copyright (C) BBN Technologies Corp. 2008-2012
########################################################

OS=$(shell uname)

####### Mac OS X #######
ifeq (${OS},Darwin)
CFLAGS=-dynamiclib 
LIBNAME=libaps.dylib
EXFLAGS=-Wl
LFLAGS=
CC=gcc
else
####### Linux ####### 
ifeq (${OS},Linux)
CFLAGS=
LIBNAME=libaps.so
EXFLAGS=-Wl
LFLAGS=-ldl
CC=gcc-3
else
####### Windows #######
CFLAGS=-mno-cygwin -D__CYGWIN__ -DBUILD_DLL -I./include -Wunused-variable
CFLAGS_STATIC=-mno-cygwin -D__CYGWIN__ -I./include -Wunused-variable
LIBNAME=libaps.dll
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

OBJECTS=aps.o fpga.o sha1.o common.o waveform.o threadedll.o
OBJECTS64=aps64.o fpga64.o sha164.o common64.o waveform64.o threadedll64.o

######################## Default Build ########################################


all: ${LIBNAME} test testLocal ${GLOBAL_ALL}

${LIBNAME}: ${OBJECTS}
	${CC}  ${CFLAGS}  -shared  -o ${LIBNAME} ${OBJECTS} ${EXFLAGS} -lpthread

waveform.o: waveform.c waveform.h
	${CC}  ${CFLAGS} -c  waveform.c -o waveform.o

sha1.o: sha1.c sha1.h
	${CC}  ${CFLAGS} -c  sha1.c -o sha1.o 

aps.o: libaps.c aps.h
	${CC}  ${CFLAGS} -c  libaps.c -o aps.o

fpga.o: fpga.c fpga.h aps.h
	${CC}  ${CFLAGS} -c  fpga.c -o ${BUILD}fpga.o

common.o: common.c common.h	
	${CC}  ${CFLAGS} -c  common.c -o ${BUILD}common.o
	
threadedll.o: threadedll.c threadedll.h	
	${CC}  ${CFLAGS} -c  threadedll.c -o ${BUILD}threadedll.o

test: test.c ${LIBNAME}
	${CC} ${CFLAGS} ${LFLAGS} -ggdb -o test test.c
	
testLocal: test.c 
	${CC} ${CFLAGS_STATIC} ${LFLAGS} -ggdb -o testLocal *.c -lpthread
	

######################## 64-Bit ########################################

all64: ${LIBNAME64} test64 testLocal64

${LIBNAME64}: ${OBJECTS64}
	${CC64}  ${CFLAGS} -shared  -o ${LIBNAME64} ${OBJECTS64} ${EXFLAGS} -lpthread

waveform64.o: waveform.c waveform.h
	${CC64}  ${CFLAGS} -c  waveform.c -o waveform64.o

sha164.o: sha1.c sha1.h
	${CC64}  ${CFLAGS} -c  sha1.c -o sha164.o 

aps64.o: libaps.c aps.h
	${CC64}  ${CFLAGS} -c  libaps.c -o aps64.o

fpga64.o: fpga.c fpga.h aps.h
	${CC64}  ${CFLAGS} -c  fpga.c -o fpga64.o

common64.o: common.c common.h	
	${CC64}  ${CFLAGS}  -c  common.c -o common64.o

threadedll64.o: threadedll.c threadedll.h	
	${CC64}  ${CFLAGS}  -c  threadedll.c -o ${BUILD}threadedll64.o	
	
test64: test.c ${LIBNAME64}
	${CC64} ${CFLAGS} ${LFLAGS} -ggdb -o test64 test.c
	
testLocal64: test.c 
	${CC64} ${CFLAGS_STATIC} ${LFLAGS} -ggdb -o testLocal64 *.c -lpthread
	
######################## Misc ########################################
	
clean:
	rm -f *.o *.dylib *.dll test *.exe *.a
	
