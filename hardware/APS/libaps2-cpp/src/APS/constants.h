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


//Some bitfield unions for packing/unpacking the commands words
//APS Command Protocol 
//ACK SEQ SEL R/W CMD<3:0> MODE/STAT CNT<15:0>
//31 30 29 28 27..24 23..16 15..0
//ACK .......Acknowledge Flag. Set in the Acknowledge Packet returned in response to a
// Command Packet. Must be zero in a Command Packet.
// SEQ............Set for Sequence Error. MODE/STAT = 0x01 for skip and 0x00 for duplicate.
// SEL........Channel Select. Selects target for commands with more than one target. Zero
// if not used. Unmodified in the Acknowledge Packet.
// R/W ........Read/Write. Set for read commands, cleared for write commands. Unmodified
// in the Acknowledge Packet.
// CMD<3:0> ....Specifies the command to perform when the packet is received by the APS
// module. Unmodified in the Acknowledge Packet. See section 3.8 for
// information on the supported commands.
// MODE/STAT....Command Mode or Status. MODE bits modify the operation of some
// commands. STAT bits are returned in the Acknowledge Packet to indicate
// command completion status. A STAT value of 0xFF indicates an invalid or
// unrecognized command. See individual command descriptions for more
// information.
// CNT<15:0> ...Number of 32-bit data words to transfer for a read or a write command. Note
// that the length does NOT include the Address Word. CNT must be at least 1.
// To meet Ethernet packet length limitations, CNT must not exceed 366.
typedef union {
	struct {
	uint32_t cnt : 16;
	uint32_t mode_stat : 8;
	uint32_t cmd : 4;
	uint32_t r_w : 1;
	uint32_t sel : 1;
	uint32_t seq : 1;
	uint32_t ack : 1;
	};
	uint32_t packed;
} APSCommand_t;

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

enum RESET_MODE_STAT {
	RESET_RECONFIG_BASELINE_EPROM = 0,
	RESET_RECONFIG_USER_EPROM     = 1,
	RESET_SOFT_RESET_HOST_USER    = 2,
	RESET_SOFT_RESET_USER_ONLY    = 3
};

enum USERIO_MODE_STAT {
	USERIO_SUCCESS = APS_SUCCESS,
	USERIO_INVALID_CNT = APS_INVALID_CNT,
	USERIO_USER_LOGIC_TIMEOUT = 2,
	USERIO_RESERVED = 3,
};

enum EPROMIO_MODE_STAT {
	EPROM_RW_256B = 0,
	EPROM_ERASE_64K = 1,
	EPROM_SUCCESS = 0,
	EPROM_INVALID_CNT = 1,
	EPROM_OPPERATION_FAILED = 4
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
	CHIPCONFIG_IO_TARGET_DAC_0_MULTI  = 0xC0, // multiple byte length in SPI cnt
	CHIPCONFIG_IO_TARGET_DAC_1_MULTI  = 0xC1, // multiple byte length in SPI cnt
	CHIPCONFIG_IO_TARGET_PLL_MULTI    = 0xD0, // multiple byte length in SPI cnt
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

typedef enum {INVALID_FPGA=0, FPGA1, FPGA2, ALL_FPGAS} FPGASELECT;

typedef enum {LED_PLL_SYNC=1, LED_RUNNING} LED_MODE;

typedef enum {RUN_WAVEFORM=0, RUN_SEQUENCE} RUN_MODE;


//APS ethernet type
static const uint16_t APS_PROTO = 0xBB4E;



#endif /* CONSTANTS_H_ */
