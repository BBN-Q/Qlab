/*
 * APS2.h
 *
 * APS2 Specfic Structures and tools
 */


#ifndef APS2_H
#define APS2_H

#include <cstdint>
#include <string>

using std::string;

namespace APS2 {
	struct APSCommand {
		uint32_t cnt : 16;
		uint32_t mode_stat : 8;
		uint32_t cmd : 4;
		uint32_t r_w : 1;
		uint32_t sel : 1;
		uint32_t seq : 1;
		uint32_t ack : 1;
	};

	static const uint16_t NUM_STATUS_REGISTERS = 16;

	enum APS_COMMANDS {
		APS_COMMAND_RESET           = 0x0,
		APS_COMMAND_USERIO_ACK      = 0x1,
		APS_COMMAND_USERIO_NACK     = 0x9,
		APS_COMMAND_EPROMIO         = 0x2,
		APS_COMMAND_CHIPCONFIGIO    = 0x3,
		APS_COMMAND_RUNCHIPCONFIG   = 0x4,
		APS_COMMAND_FPGACONFIG_ACK  = 0x5,
		APS_COMMAND_FPGACONFIG_NACK = 0xD,
		APS_COMMAND_FPGACONFIG_CTRL = 0x6,
		APS_COMMAND_STATUS          = 0x7
	};

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

	enum CHIPCONFIGIO_TARGET {
		CHIPCONFIGIO_TARGET_PAUSE        = 0,
		CHIPCONFIGIO_TARGET_DAC_0_MULTI  = 0xC0, // multiple byte length in SPI cnt
		CHIPCONFIGIO_TARGET_DAC_1_MULTI  = 0xC1, // multiple byte length in SPI cnt
		CHIPCONFIGIO_TARGET_PLL_MULTI    = 0xD0, // multiple byte length in SPI cnt
		CHIPCONFIGIO_TARGET_DAC_0_SINGLE = 0xC8, // single byte payload
		CHIPCONFIGIO_TARGET_DAC_1_SINGLE = 0xC9, // single byte payload
		CHIPCONFIGIO_TARGET_PLL_SINGLE   = 0xD8, // single byte payload
		CHIPCONFIGIO_TARGET_VCXO         = 0xE0, 
		CHIPCONFIGIO_TARGET_EOL          = 0xFF, // end of list
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

	enum STATUS_REGISTERS {
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
		UPTIME = 0xC,
		RESERVED1 = 0xD,
		RESERVED2 = 0xE,
		RESERVED3 = 0xF,
	};

	struct APS_Status_Registers {
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
		uint32_t uptime;
		uint32_t reserved1;
		uint32_t reserved2;
		uint32_t reserved3;
	};

	enum CONFIGURATION_SOURCE {
		BASELINE_IMAGE = 0xBBBBBBBB,
		USER_EPROM_IMAGE = 0xEEEEEEEE
	};

	struct APSEthernetHeader {
		uint8_t  dest[6];
		uint8_t  src[6];
		uint16_t frameType;
		uint16_t seqNum;
		union {
			uint32_t packedCommand;
			struct APSCommand command;
		};
		uint32_t addr;
	};

	uint8_t * getPayloadPtr(uint8_t * packet);

	string printStatusRegisters(const APS_Status_Registers & status);
	string printAPSCommand(APSCommand * command);
	void zeroAPSCommand(APSCommand * command);
	
} //end namespace APS2




#endif /* APS2_H_ */