##############################################
# Module Name : libaps Makefile
#
# Author/Date : B.C. Donovan / 21-Oct-08
#
# Description : Makefile for building libaps with cygwin
#
# Restrictions/Limitations :
#
# Change Descriptions :
#
# Classification : Unclassified
#
# References :
#
#    Modified    By    Reason
#    --------    --    ------
#                BCD
#
# $Author: bdonovan $
# $Date$
# $Locker:  $
# $Name:  $
# $Revision$
# Copyright (C) BBN Technologies Corp. 2008-2011
##############################################

OS=$(shell uname)

ifeq (${OS},Darwin)
CFLAGS=-dynamiclib 
CFLAGS2=
LIBNAME=libaps.dylib
EXFLAGS=-Wl
LFLAGS=
CC=gcc
else 
ifeq (${OS},Linux)
CFLAGS=
CFLAGS2=
LIBNAME=libaps.so
EXFLAGS=-Wl
LFLAGS=-ldl
CC=gcc-3
else
CFLAGS=
CFLAGS2=-mno-cygwin -DBUILD_DLL -I./include -Wunused-variable
CFLAGS3=-mno-cygwin -I./include
LIBNAME=libaps.dll
EXFLAGS=-Wl,--out-implib,libaps.a
LFLAGS=
CC=gcc-3
endif
endif

all: ${LIBNAME} test
	
${LIBNAME}: aps.o fpga.o sha1.o
	${CC}  ${CFLAGS} ${CFLAGS2} -shared  -o ${LIBNAME} aps.o fpga.o sha1.o ${EXFLAGS} 
	
sha1.o: sha1.c sha1.h
	${CC}  ${CFLAGS2} -c  sha1.c -o sha1.o 
	
aps.o: libaps.c aps.h
	${CC}  ${CFLAGS2} -c  libaps.c -o aps.o
	
fpga.o: fpga.c fpga.h aps.h
	${CC}  ${CFLAGS2} -c  fpga.c -o fpga.o
	
pyaps: aps.i aps.o
	swig -python aps.i
	${CC} ${CFLAGS3} -c aps_wrap.c -I/usr/include/python2.6 -I/usr/lib/python2.6/config/ -I/usr/include
	
clean:
	rm -f *.o *.dylib *.dll test *.exe *.a
	
test: test.c ${LIBNAME}
	${CC} ${CFLAGS3} ${LFLAGS} -o test test.c
	
