/*
 * constants.h
 *
 *  Created on: Jul 3, 2012
 *      Author: cryan
 */

#ifndef CONSTANTS_H_
#define CONSTANTS_H_

//Some maximum sizes of things we can fit
static const int X6_READTIMEOUT = 1000;
static const int X6_WRITETIMEOUT = 500;

//Command byte bits
static const int LSB_MASK = 0xFF;

//Registers we read from
static const int  WB_ADDR_VERSION  = 0x10; // UPDATE ME
static const int  WB_OFFSETR_VERSION  = 0x01; // UPDATE ME

//Expected version
static const int FIRMWARE_VERSION =  0x1;

typedef enum {INTERNAL=0, EXTERNAL} TRIGGERSOURCE;

typedef enum {DIGITIZE=0, AVERGAGE, FILTER, FILTER_AND_AVERAGE} DIGITIZER_MODE;


#endif /* CONSTANTS_H_ */
