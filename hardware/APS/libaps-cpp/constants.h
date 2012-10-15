/*
 * constants.h
 *
 *  Created on: Jul 3, 2012
 *      Author: cryan
 */

#ifndef CONSTANTS_H_
#define CONSTANTS_H_

//Some maximum sizes of things we can fit
static const int  MAX_APS_CHANNELS = 4;
static const int  MAX_APS_BANKS = 2;

static const int  APS_WAVEFORM_UNIT_LENGTH = 4;

static const int  MAX_APS_DEVICES = 10;

static const int MAX_WF_LENGTH = 16384;
static const int MAX_WF_AMP = 8191;
static const int WF_MODULUS = 4;
static const size_t MAX_LL_LENGTH = 4096;

static const int APS_READTIMEOUT = 1000;
static const int APS_WRITETIMEOUT = 500;


//FPGA programming bits
static const int APS_PGM01_BIT = 1;
static const int APS_PGM23_BIT = 2;
static const int APS_PGM_BITS = (APS_PGM01_BIT | APS_PGM23_BIT);
                 
static const int APS_FRST01_BIT = 0x4;
static const int APS_FRST23_BIT = 0x8;
static const int APS_FRST_BITS = (APS_FRST01_BIT | APS_FRST23_BIT);
                 
static const int APS_DONE01_BIT = 0x10;
static const int APS_DONE23_BIT = 0x20;
static const int APS_DONE_BITS = (APS_DONE01_BIT | APS_DONE23_BIT);
                 
static const int APS_INIT01_BIT = 0x40;
static const int APS_INIT23_BIT = 0x80;
static const int APS_INIT_BITS = (APS_INIT01_BIT | APS_INIT23_BIT);

static const int APS_OSCEN_BIT = 0x10;


//Command byte bits
static const int APS_FPGA_IO = 0;
static const int APS_FPGA_ADDR = (1<<4);
static const int APS_DAC_SPI = (2<<4);
static const int APS_PLL_SPI = (3<<4);
static const int APS_VCXO_SPI = (4<<4);
static const int APS_CONF_DATA = (5<<4);
static const int APS_CONF_STAT = (6<<4);
static const int APS_STATUS_CTRL = (7<<4);
static const int APS_CMD = (0x7<<4);

static const int LSB_MASK = 0xFF;

//Clock bits
static const int FPGA1_PLL_CYCLES_ADDR =  0x190;
static const int FPGA1_PLL_BYPASS_ADDR = 0x191;
static const int DAC0_ENABLE_ADDR = 0xF0;
static const int DAC1_ENABLE_ADDR = 0xF1;
static const int FPGA1_PLL_ADDR = 0xF2;

static const int FPGA2_PLL_CYCLES_ADDR = 0x196;
static const int FPGA2_PLL_BYPASS_ADDR = 0x197;
static const int DAC2_ENABLE_ADDR = 0xF5;
static const int DAC3_ENABLE_ADDR = 0xF4;
static const int FPGA2_PLL_ADDR = 0xF3;


// configRegister Locations
//read-write is signified by the most highest bit in the address
static const int FPGA_ADDR_REGWRITE = 0;
static const int FPGA_ADDR_REGREAD =  (1 << 31);

//The next three highest bits signify the bank selection
static const int FPGA_BANKSEL_CSR = (0 << 28);
static const int FPGA_BANKSEL_WF_CHA = (1 << 28);
static const int FPGA_BANKSEL_WF_CHB = (2 << 28);
static const int FPGA_BANKSEL_LL_CHA = (3 << 28);
static const int FPGA_BANKSEL_LL_CHB = (4 << 28);

//Registers we write to
static const int FPGA_ADDR_CSR 	  =   FPGA_BANKSEL_CSR | 0x0;
static const int FPGA_ADDR_TRIG_INTERVAL = FPGA_BANKSEL_CSR | 0x1;
static const int FPGA_ADDR_CHA_WF_LENGTH =  FPGA_BANKSEL_CSR | 0x3;
static const int FPGA_ADDR_CHB_WF_LENGTH =  FPGA_BANKSEL_CSR | 0x4;
static const int FPGA_ADDR_CHA_LL_LENGTH =  FPGA_BANKSEL_CSR | 0x5;
static const int FPGA_ADDR_CHB_LL_LENGTH =  FPGA_BANKSEL_CSR | 0x6;
static const int FPGA_ADDR_CHA_ZERO = FPGA_BANKSEL_CSR | 0x7; // DAC0/2 zero offset register
static const int FPGA_ADDR_CHB_ZERO = FPGA_BANKSEL_CSR | 0x8; // DAC1/3 zero offset register
static const int FPGA_ADDR_LL_REPEAT = FPGA_BANKSEL_CSR | 0x9;


//Registers we read from
static const int  FPGA_ADDR_VERSION  =   FPGA_BANKSEL_CSR | 0x10;

static const int FPGA_ADDR_PLL_STATUS = FPGA_BANKSEL_CSR | 0x11;
static const int FPGA_ADDR_CHA_LL_CURADDR = FPGA_BANKSEL_CSR | 0x12;
static const int FPGA_ADDR_CHB_LL_CURADDR = FPGA_BANKSEL_CSR | 0x13;


//PLL bits
static const int PLL_GLOBAL_XOR_BIT = 15;
static const int PLL_02_XOR_BIT = 14;
static const int PLL_13_XOR_BIT = 13;
static const int PLL_02_LOCK_BIT = 12;
static const int PLL_13_LOCK_BIT = 11;
static const int REFERENCE_PLL_LOCK_BIT = 10;
static const int MAX_PHASE_TEST_CNT = 40;

//Expected version
static const int FIRMWARE_VERSION =  0x1;

//Each FPGA has a CHA/B CSR with some configuration bits
static const int CSRMSK_CHA_SMRSTN = 0x1; // state machine reset
static const int CSRMSK_CHA_PLLRST = 0x2; // pll reset
static const int CSRMSK_CHA_DDR = 0x4; // DDR enable
static const int CSRMSK_CHA_TRIGSRC = 0x10; // trigger source (1 = external, 0 = internal)
static const int CSRMSK_CHA_OUTMODE = 0x20; // output mode (1 = link list, 0 = waveform)
static const int CSRMSK_CHA_REPMODE = 0x40; // LL repeat mode (1 = one-shot, 0 = continuous)

static const int CSRMSK_CHB_SMRST = 0x100; // state machine reset
static const int CSRMSK_CHB_PLLRST = 0x200; // pll reset
static const int CSRMSK_CHB_DDR = 0x400; // DDR enable
static const int CSRMSK_CHB_TRIGSRC = 0x1000;
static const int CSRMSK_CHB_OUTMODE = 0x2000;
static const int CSRMSK_CHB_REPMODE = 0x4000;

typedef enum {INTERNAL=0, EXTERNAL} TRIGGERSOURCE;

typedef enum {INVALID_FPGA=0, FPGA1, FPGA2, ALL_FPGAS} FPGASELECT;

typedef enum {LED_PLL_SYNC=1, LED_RUNNING} LED_MODE;

typedef enum {RUN_WAVEFORM=0, RUN_SEQUENCE} RUN_MODE;


#endif /* CONSTANTS_H_ */
