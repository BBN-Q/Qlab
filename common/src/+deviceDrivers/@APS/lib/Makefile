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
else 
ifeq (${OS},Linux)
CFLAGS=
CFLAGS2=
LIBNAME=libaps.so
EXFLAGS=-Wl
LFLAGS=-ldl
else
CFLAGS=
CFLAGS2=-mno-cygwin -DBUILD_DLL -I./include
LIBNAME=libaps.dll
EXFLAGS=-Wl,--out-implib,libaps.a
LFLAGS=
endif
endif

all: ${LIBNAME} test
	
${LIBNAME}: aps.o fpga.o
	gcc-3  ${CFLAGS} ${CFLAGS2} -shared  -o ${LIBNAME} aps.o fpga.o ${EXFLAGS} 
	
aps.o: libaps.c aps.h
	gcc-3  ${CFLAGS2} -c  libaps.c -o aps.o
	
fpga.o: fpga.c fpga.h aps.h
	gcc-3  ${CFLAGS2} -c  fpga.c -o fpga.o
	
clean:
	rm -f *.o *.dylib *.dll test *.exe *.a
	
test: test.c ${LIBNAME}
	gcc-3 ${OSFLAG} ${LFLAGS} -I./include -o test test.c
	
