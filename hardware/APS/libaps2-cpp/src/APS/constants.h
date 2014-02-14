/*
 * constants.h
 *
 *  Created on: Jul 3, 2012
 *      Author: cryan
 */

#ifndef CONSTANTS_H_
#define CONSTANTS_H_

//Some maximum sizes of things we can fit
static const int  MAX_APS_CHANNELS = 2;

static const int  APS_WAVEFORM_UNIT_LENGTH = 4;

static const int  MAX_APS_DEVICES = 10;

static const int MAX_WF_LENGTH = 32768;
static const int MAX_WF_AMP = 8191;
static const int WF_MODULUS = 4;
static const size_t MAX_LL_LENGTH = 8192;

static const int APS_READTIMEOUT = 1000;
static const int APS_WRITETIMEOUT = 500;



//Chip config SPI commands for setting up DAC,PLL,VXCO
//Possible target bytes
// 0x00 ............Pause commands stream for 100ns times the count in D<23:0>
// 0xC0/0xC8 .......DAC Channel 0 Access (AD9736)
// 0xC1/0xC9 .......DAC Channel 1 Access (AD9736)
// 0xD0/0xD8 .......PLL Clock Generator Access (AD518-1)
// 0xE0 ............VCXO Controller Access (CDC7005)
// 0xFF ............End of list
typedef union  {
	struct {
	uint32_t instr : 16; // SPI instruction for DAC, PLL instruction, or 0
	uint32_t spicnt_data: 8; // data byte for single byte or SPI insruction
	uint32_t target : 8; 
	};
	uint32_t packed;
} APSChipConfigCommand_t;

//PLL commands 
// INSTR<12..0> ......ADDR. Specifies the address of the register to read or write.
// INSTR<14..13> .....W<1..0>. Specified transfer length. 00 = 1, 01 = 2, 10 = 3, 11 = stream
// INSTR<15> .........R/W. Read/Write select. Read = 1, Write = 0.
typedef union  {
	struct {
	uint16_t addr : 13;
	uint16_t W  :  2;
	uint16_t r_w : 1;
	};
	uint16_t packed;
} PLLCommand_t;

//DAC Commands
// INSTR<4..0> ......ADDR. Specifies the address of the register to read or write.
// INSTR<6..5> ......N<1..0>. Specified transfer length. Only 00 = single byte mode supported.
// INSTR<7> ..........R/W. Read/Write select. Read = 1, Write = 0.
typedef union {
	struct {
	uint8_t addr : 5;
	uint8_t N  :  2;
	uint8_t r_w : 1;
	};
	uint8_t packed;
} DACCommand_t;

static const uint16_t NUM_STATUS_REGISTERS = 16;

enum class APS_COMMANDS : uint32_t {
	RESET           = 0x0,
	USERIO_ACK      = 0x1,
	USERIO_NACK     = 0x9,
	EPROMIO         = 0x2,
	CHIPCONFIGIO    = 0x3,
	RUNCHIPCONFIG   = 0x4,
	FPGACONFIG_ACK  = 0x5,
	FPGACONFIG_NACK = 0xD,
	FPGACONFIG_CTRL = 0x6,
	STATUS          = 0x7
};

//Helper function to decide if aps command needs address
inline bool needs_address(APS_COMMANDS cmd){
	switch (cmd) {
		case APS_COMMANDS::RESET:
		case APS_COMMANDS::STATUS:
		case APS_COMMANDS::CHIPCONFIGIO:
		case APS_COMMANDS::RUNCHIPCONFIG:
			return false;
		default:
			return true;
	}
}

enum APS_STATUS {
	APS_STATUS_HOST   = 0,
	APS_STATUS_VOLT_A = 1,
	APS_STATUS_VOLT_B = 2,
	APS_STATUS_TEMP   = 3
};

enum APS_ERROR_CODES {
	APS_SUCCESS = 0,
	APS_INVALID_CNT = 1,
};

enum class APS_RESET_MODE_STAT : uint32_t {
	RECONFIG_BASELINE_EPROM = 0,
	RECONFIG_USER_EPROM     = 1,
	SOFT_RESET_HOST_USER    = 2,
	SOFT_RESET_USER_ONLY    = 3
};

enum USERIO_MODE_STAT {
	USERIO_SUCCESS = APS_SUCCESS,
	USERIO_INVALID_CNT = APS_INVALID_CNT,
	USERIO_USER_LOGIC_TIMEOUT = 2,
	USERIO_RESERVED = 3,
};

enum EPROMIO_MODE_STAT {
	EPROM_RW = 0,
	EPROM_ERASE = 1,
	EPROM_SUCCESS = 0,
	EPROM_INVALID_CNT = 1,
	EPROM_OPERATION_FAILED = 4
};

enum CHIPCONFIGIO_MODE_STAT {
	CHIPCONFIG_SUCCESS = APS_SUCCESS,
	CHIPCONFIG_INVALID_CNT = APS_INVALID_CNT,
	CHIPCONFIG_INVALID_TARGET = 2,
};

enum CHIPCONFIG_IO_TARGET {
	CHIPCONFIG_TARGET_PAUSE = 0,
	CHIPCONFIG_TARGET_DAC_0 = 1,
	CHIPCONFIG_TARGET_DAC_1 = 2,
	CHIPCONFIG_TARGET_PLL = 3,
	CHIPCONFIG_TARGET_VCXO = 4
};

enum CHIPCONFIG_IO_TARGET_CMD {
	CHIPCONFIG_IO_TARGET_PAUSE        = 0,
	CHIPCONFIG_IO_TARGET_DAC_0        = 0xC0, // multiple byte length in SPI cnt
	CHIPCONFIG_IO_TARGET_DAC_1        = 0xC1, // multiple byte length in SPI cnt
	CHIPCONFIG_IO_TARGET_PLL          = 0xD0, // multiple byte length in SPI cnt
	CHIPCONFIG_IO_TARGET_DAC_0_SINGLE = 0xC8, // single byte payload
	CHIPCONFIG_IO_TARGET_DAC_1_SINGLE = 0xC9, // single byte payload
	CHIPCONFIG_IO_TARGET_PLL_SINGLE   = 0xD8, // single byte payload
	CHIPCONFIG_IO_TARGET_VCXO         = 0xE0, 
	CHIPCONFIG_IO_TARGET_EOL          = 0xFF, // end of list
};

enum RUNCHIPCONFIG_MODE_STAT {
	RUNCHIPCONFIG_SUCCESS = APS_SUCCESS,
	RUNCHIPCONFIG_INVALID_CNT = APS_INVALID_CNT,
	RUNCHIPCONFIG_INVALID_OFFSET = 2,
};

enum FPGACONFIG_MODE_STAT {
	FPGACONFIG_SUCCESS = APS_SUCCESS,
	FPGACONFIG_INVALID_CNT = APS_INVALID_CNT,
	FPGACONFIG_INVALID_OFFSET = 2,
};

enum class STATUS_REGISTERS {
	HOST_FIRMWARE_VERSION = 0,
	USER_FIRMWARE_VERSOIN = 1,
	CONFIGURATION_SOURCE = 2,
	USER_STATUS = 3,
	DAC0_STATUS = 4,
	DAC1_STATUS = 5,
	PLL_STATUS = 6,
	VCXO_STATUS = 7,
	SEND_PACKET_COUNT = 8,
	RECEIVE_PACKET_COUNT = 9,
	SEQUENCE_SKIP_COUNT = 0xA,
	SEQUENCE_DUP_COUNT = 0xB,
	FCS_OVERRUN_COUNT = 0xC,
	PACKET_OVERRUN_COUNT = 0xD,
	UPTIME_SECONDS = 0xE,
	UPTIME_NANOSECONDS = 0xF,
};

typedef union {
	struct  {
		uint32_t hostFirmwareVersion;
		uint32_t userFirmwareVersion;
		uint32_t configurationSource;
		uint32_t userStatus;
		uint32_t dac0Status;
		uint32_t dac1Status;
		uint32_t pllStatus;
		uint32_t vcxoStatus;
		uint32_t sendPacketCount;
		uint32_t receivePacketCount;
		uint32_t sequenceSkipCount;
		uint32_t sequenceDupCount;
		uint32_t fcsOverrunCount;
		uint32_t packetOverrunCount;
		uint32_t uptimeSeconds;
		uint32_t uptimeNanoSeconds;
	};
	uint32_t array[16];
} APSStatusBank_t;

enum CONFIGURATION_SOURCE {
	BASELINE_IMAGE = 0xBBBBBBBB,
	USER_EPROM_IMAGE = 0xEEEEEEEE
};

//PLL routines go through sets of address/data pairs
typedef std::pair<uint16_t, uint8_t> AddrData;


//FPGA registers
//TODO: update for new memory map
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
//Expected version
static const int FIRMWARE_VERSION =  0x3;

static const int FPGA_ADDR_PLL_STATUS = FPGA_BANKSEL_CSR | 0x11;
static const int FPGA_ADDR_CHA_LL_CURADDR = FPGA_BANKSEL_CSR | 0x12;
static const int FPGA_ADDR_CHB_LL_CURADDR = FPGA_BANKSEL_CSR | 0x13;
static const int FPGA_ADDR_CHA_MINILLSTART = FPGA_BANKSEL_CSR | 0x14;

static const int FPGA_ADDR_A_PHASE = FPGA_BANKSEL_CSR | 0x15;
static const int FPGA_ADDR_B_PHASE = FPGA_BANKSEL_CSR | 0x16;

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


//PLL bits
//TODO: update
static const int PLL_GLOBAL_XOR_BIT = 15;
static const int PLL_02_XOR_BIT = 14;
static const int PLL_13_XOR_BIT = 13;
static const int PLL_02_LOCK_BIT = 12;
static const int PLL_13_LOCK_BIT = 11;
static const int REFERENCE_PLL_LOCK_BIT = 10;
static const int MAX_PHASE_TEST_CNT = 40;


typedef enum {INTERNAL=0, EXTERNAL} TRIGGERSOURCE;

typedef enum {LED_PLL_SYNC=1, LED_RUNNING} LED_MODE;

typedef enum {RUN_WAVEFORM=0, RUN_SEQUENCE} RUN_MODE;


//APS ethernet type
static const uint16_t APS_PROTO = 0xBB4E;

// Startup sequences

// PLL setup sequence (modified for 300 MHz FPGA sys_clk and 1.2 GHz DACs)
static const vector<AddrData> PLL_INIT = {
	{0x0,  0x99},  // Use SDO, Long instruction mode
	{0x10, 0x7C},  // Enable PLL , set charge pump to 4.8ma
	{0x11, 0x5},   // Set reference divider R to 5 to divide 125 MHz reference to 25 MHz
	{0x14, 0x6},   // Set B counter to 6
	{0x16, 0x5},   // Set P prescaler to 16 and enable B counter (N = P*B = 96 to divide 2400 MHz to 25 MHz)
	{0x17, 0x4},   // Selects readback of N divider on STATUS bit in Status/Control register
	{0x18, 0x60},  // Calibrate VCO with 2 divider, set lock detect count to 255, set high range
	{0x1A, 0x2D},  // Selects readback of PLL Lock status on LOCK bit in Status/Control register
	{0x1B, 0x01},  // REFMON pin control set to REF1 clock
	{0x1C, 0x7},   // Enable differential reference, enable REF1/REF2 power, disable reference switching
	{0xF0, 0x00},  // Enable un-inverted 400mV clock on OUT0 (goes to DACA)
	{0xF1, 0x00},  // Enable un-inverted 400mV clock on OUT1 (goes to DACB)
	{0xF2, 0x02},  // Disable OUT2
	{0xF3, 0x08},  // Enable un-inverted 780mV clock on OUT3 (goes to FPGA sys_clk)
	{0xF4, 0x02},  // Disable OUT4
	{0xF5, 0x00},  // Enable un-inverted 400mV clock on OUT5 (goes to FPGA mem_clk)
	{0x190, 0x00}, // channel 0: no division
	{0x191, 0x80}, // Bypass 0 divider
	{0x193, 0x11}, // channel 1: (2 high, 2 low = 1.2 GHz / 4 = 300 MHz sys_clk)
	{0x196, 0x10}, // channel 2: (2 high, 1 low = 1.2 GHz / 3 = 400 MHz mem_clk)
	{0x1E0, 0x0},  // Set VCO post divide to 2
	{0x1E1, 0x2},  // Select VCO as clock source for VCO divider
	{0x232, 0x1},  // Set bit 0 to 1 to simultaneously update all registers with pending writes.
	{0x18, 0x71},  // Initiate Calibration.  Must be followed by Update Registers Command
	{0x232, 0x1},  // Set bit 0 to 1 to simultaneously update all registers with pending writes.
	{0x18, 0x70},  // Clear calibration flag so that next set generates 0 to 1.
	{0x232, 0x1},  // Set bit 0 to 1 to simultaneously update all registers with pending writes.
};

// VCXO setup sequence
static const vector<uint8_t> VCXO_INIT = {0x8, 0x60, 0x0, 0x4, 0x64, 0x91, 0x0, 0x61};

#endif /* CONSTANTS_H_ */
