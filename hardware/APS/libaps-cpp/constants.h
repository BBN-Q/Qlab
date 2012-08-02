/*
 * constants.h
 *
 *  Created on: Jul 3, 2012
 *      Author: cryan
 */

#ifndef CONSTANTS_H_
#define CONSTANTS_H_


static const int  MAX_APS_CHANNELS = 4;
static const int  MAX_APS_BANKS = 2;

static const int  APS_WAVEFORM_UNIT_LENGTH = 4;

static const int  MAX_WAVEFORM_LENGTH = 8192;

static const int  NUM_BITS = 13;

static const int  MAX_WF_VALUE = (pow(2,NUM_BITS)-1);

static const int  MAX_APS_DEVICES = 10;

static const int APS_READTIMEOUT = 1000;
static const int APS_WRITETIMEOUT = 500;

static const int  APS_PGM01_BIT = 1;
static const int  APS_PGM23_BIT = 2;
static const int  APS_PGM_BITS = (APS_PGM01_BIT | APS_PGM23_BIT);

static const int  APS_FRST01_BIT = 0x4;
static const int  APS_FRST23_BIT = 0x8;
static const int  APS_FRST_BITS = (APS_FRST01_BIT | APS_FRST23_BIT);

static const int  APS_DONE01_BIT = 0x10;
static const int  APS_DONE23_BIT = 0x20;
static const int  APS_DONE_BITS = (APS_DONE01_BIT | APS_DONE23_BIT);

static const int  APS_INIT01_BIT = 0x40;
static const int  APS_INIT23_BIT = 0x80;
static const int  APS_INIT_BITS = (APS_INIT01_BIT | APS_INIT23_BIT);


static const int  APS_FPGA_IO = 0;
static const int  APS_FPGA_ADDR = (1<<4);
static const unsigned int  APS_DAC_SPI = (2<<4);
static const int  APS_PLL_SPI = (3<<4);
static const int  APS_VCXO_SPI = (4<<4);
static const int  APS_CONF_DATA = (5<<4);
static const int  APS_CONF_STAT = (6<<4);
static const int  APS_STATUS_CTRL = (7<<4);
static const int  APS_CMD = (0x7<<4);

static const int  LSB_MASK = 0xFF;

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


static const int APS_OSCEN_BIT = 0x10;


// Register Locations
static const int FPGA_ADDR_REGWRITE = 0x0000;

static const int  FPGA_OFF_CSR 	  =   0x0;
static const int  FPGA_OFF_TRIGLED  =   0x1;
static const int  FPGA_OFF_CHA_OFF   =   0x2;
static const int  FPGA_OFF_CHA_SIZE  =   0x3;
static const int  FPGA_OFF_CHB_OFF   =   0x4;
static const int  FPGA_OFF_CHB_SIZE  =   0x5;
static const int  FPGA_OFF_VERSION  =   0x6;
static const int  FPGA_OFF_LLCTRL	=     0x7;


static const int FPGA_OFF_CHA_LL_A_CTRL = 0x7;  // A Control Register
static const int FPGA_OFF_CHA_LL_B_CTRL = 0x8;  // B Control Register
static const int FPGA_OFF_CHA_LL_REPEAT = 0x9;  // Repeat Count
static const int FPGA_OFF_CHB_LL_A_CTRL = 0xA;  // A Control Register
static const int FPGA_OFF_CHB_LL_B_CTRL = 0xB;  // B Control Register
static const int FPGA_OFF_CHB_LL_REPEAT = 0xC;  // Repeat Count
static const int FPGA_OFF_DATA_CHECKSUM = 0xD;  // Data Checksum Register
static const int FPGA_OFF_ADDR_CHECKSUM = 0xE;  // Address Checksum Register
static const int FPGA_OFF_CHA_ZERO = 0x10; // DAC0/2 zero offset register
static const int FPGA_OFF_CHB_ZERO = 0x11; // DAC1/3 zero offset register
static const int FPGA_OFF_CHA_TRIG_DELAY = 0x12; // DAC0/2 trigger delay
static const int FPGA_OFF_CHB_TRIG_DELAY = 0x13; // DAC1/3 trigger delay



static const int  FPGA_ADDR_REGREAD =   0x8000;
static const int  FPGA_ADDR_SYNC_REGREAD =  0XF000;

static const int  FPGA_ADDR_CHA_WRITE =  0x1000;
static const int  FPGA_ADDR_CHB_WRITE =  0x4000;

static const int  FPGA_ADDR_CHA_LL_A_WRITE = 0x3000;
static const int  FPGA_ADDR_CHA_LL_B_WRITE = 0x3800;

static const int  FPGA_ADDR_CHB_LL_A_WRITE = 0x6000;
static const int  FPGA_ADDR_CHB_LL_B_WRITE = 0x6800;

static const int FPGA_PLL_RESET_ADDR = 0x0;

//PLL bits
static const int PLL_GLOBAL_XOR_BIT = 15;
static const int PLL_02_XOR_BIT = 14;
static const int PLL_13_XOR_BIT = 13;
static const int PLL_02_LOCK_BIT = 12;
static const int PLL_13_LOCK_BIT = 11;
static const int REFERENCE_PLL_LOCK_BIT = 10;
static const int MAX_PHASE_TEST_CNT = 40;
static const int FIRMWARE_VERSION =  0X010;


//Each FPGA has a CHA/B associated with it
static const int CSRMSK_CHA_SMRST = 0x1; // state machine reset
static const int CSRMSK_CHA_PLLRST = 0x2; // pll reset
static const int CSRMSK_CHA_DDR = 0x4; // DDR enable
static const int CSRMSK_CHA_MEMLCK = 0x8; // waveform memory lock (1 = locked, 0 = unlocked)
static const int CSRMSK_CHA_TRIGSRC = 0x10; // trigger source (1 = external, 0 = internal)
static const int CSRMSK_CHA_OUTMODE = 0x20; // output mode (1 = link list, 0 = waveform)
static const int CSRMSK_CHA_LLMODE = 0x40; // LL repeat mode (1 = one-shot, 0 = continuous)
static const int CSRMSK_CHA_LLSTATUS = 0x80; // LL status (1 = LL A active, 0 = LL B active)

static const int CSRMSK_CHB_SMRST = 0x100; // state machine reset
static const int CSRMSK_CHB_PLLRST = 0x200; // pll reset
static const int CSRMSK_CHB_DDR = 0x400; // DDR enable
static const int CSRMSK_CHB_MEMLCK = 0x800;
static const int CSRMSK_CHB_TRIGSRC = 0x1000;
static const int CSRMSK_CHB_OUTMODE = 0x2000;
static const int CSRMSK_CHB_LLMODE = 0x4000;
static const int CSRMSK_CHB_LLSTATUS = 0x8000;

static const int TRIGLEDMSK_CHA_SWTRIG = 0x1; // Channel 0/2 internal trigger (1 = enabled, 0 = disabled)
static const int TRIGLEDMSK_CHB_SWTRIG = 0x2; // Channel 1/3 internal trigger (1 = enabled, 0 = disabled)
static const int TRIGLEDMSK_WFMTRIG02 = 0x4; // Waveform trigger output channel 0/2 (1 = enabled, 0 = disabled)
static const int TRIGLEDMSK_WFMTRIG13 = 0x8; // Waveform trigger output channel 1/3 (1 = enabled, 0 = disabled)
static const int TRIGLEDMSK_MODE = 0x10; // LED mode (0 = PLL sync, 1 = statement machine enabled)
static const int TRIGLEDMSK_SWLED0 = 0x20; // internal LED 0
static const int TRIGLEDMSK_SWLED1 = 0x40; // internal LED 1

enum {
	SOFTWARE_TRIGGER=1,
	HARDWARE_TRIGGER
};

typedef enum {INVALID_FPGA=0, FPGA1, FPGA2, ALL_FPGAS} FPGASELECT;

typedef enum {LED_PLL_SYNC=1, LED_RUNNING} LED_MODE;

typedef enum {RUN_WAVEFORM=0, RUN_SEQUENCE} RUN_MODE;

static const int MAX_WFLENGTH = 8192;
static const int MAX_WFAMP = 8191;
static const int WF_MODULUS = 4;
static const int MAX_LL_LENGTH = 512;



#endif /* CONSTANTS_H_ */
