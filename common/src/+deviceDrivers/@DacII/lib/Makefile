##############################################
# Module Name : libdacii Makefile
#
# Author/Date : B.C. Donovan / 21-Oct-08
#
# Description : Makefile for building libdacii with cygwin
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
# CVS header info.
# ----------------
# $CVSfile$
# $Author: bdonovan $
# $Date: 2008/12/03 15:47:57 $
# $Locker:  $
# $Name:  $
# $Revision: 103 $
#
# $Log: Makefile,v $
# Revision 1.7  2008/12/03 15:47:57  bdonovan
# Added support for multiple DAC boxes to libdacii. Updated dacii.m for new api.
#
# Revision 1.1  2008/10/23 20:41:35  bdonovan
# First version of CMD Builder GUI that uses C dll to communicate with DACII board.
#
# C library to communicate with board is in ./lib.
#
# Matlab code has been reorganized into classes. GUI is not edited with the guide command
# in matlab.
#
# Independent triggering of each of the 4 DACs has been confirmed for both software
#  and hardware triggering with cbl_dac2_r3beta.bit
#
#
# Copyright (C) BBN Technologies Corp. 2008
##############################################

OS=$(shell uname)

ifeq (${OS},Darwin)
CFLAGS=-dynamiclib 
CFLAGS2=
LIBNAME=libdacii.dylib
EXFLAGS=-Wl
LFLAGS=
else 
ifeq (${OS},Linux)
CFLAGS=
CFLAGS2=
LIBNAME=libdacii.so
EXFLAGS=-Wl
LFLAGS=-ldl
else
CFLAGS=
CFLAGS2=-mno-cygwin -DBUILD_DLL -I./include
LIBNAME=libdacii.dll
EXFLAGS=-Wl,--out-implib,libdacii.a
LFLAGS=
endif
endif

all: ${LIBNAME} test
	
${LIBNAME}: dacii.o fpga.o
	gcc-3  ${CFLAGS} ${CFLAGS2} -shared  -o ${LIBNAME} dacii.o fpga.o ${EXFLAGS}
	
dacii.o: libdacii.c dacii.h
	gcc-3  ${CFLAGS2} -c  libdacii.c -o dacii.o
	
fpga.o: fpga.c fpga.h dacii.h
	gcc-3  ${CFLAGS2} -c  fpga.c -o fpga.o
	
clean:
	rm -f *.o *.dylib *.dll test *.exe *.a
	
test: test.c
	gcc-3 ${OSFLAG} ${LFLAGS} -I./include -o test test.c
	
