
#include "headings.h"

#include <X6_1000M_Mb.h>
#include <VitaPacketStream_Mb.h>
#include <SoftwareTimer_Mb.h>
#include <Application/TriggerManager_App.h>
#include <HardwareRegister_Mb.h>
#include <BufferDatagrams_Mb.h> // for ShortDG

#ifndef X6_1000_H_
#define X6_1000_H_

using std::vector;
using std::string;



/**
 * X6_1000 Class: Provides interface to Innovative Illustrations X6_1000 card
 *
 * The expectation is that this class will support a custom FPGA image for digitzer usage.
 *
 * This interface utilizes the II [Malibu library](www.innovative-dsp.com/products.php?product=Malibu)
 */

class Accumulator;


class X6_1000 
{
public:

	enum ErrorCodes {
    	SUCCESS = 0,
    	MODULE_ERROR = -1,
    	NOT_IMPLEMENTED = -2,
    	INVALID_FREQUENCY = -3,
    	INVALID_CHANNEL = -4,
    	INVALID_INTERVAL = -5,
    	INVALID_FRAMESIZE = -6
	};

	enum ExtInt {
		EXTERNAL = 0,   /**< External Input */
		INTERNAL        /**< Internal Generation */
	};

	enum ExtSource {
		FRONT_PANEL = 0, /**< Front panel input */
		P16              /**< P16 input */
	};

	enum TriggerSource {
		SOFTWARE_TRIGGER = 0,    /**< Software generated trigger */
		EXTERNAL_TRIGGER         /**< External trigger */
	};

	X6_1000();
	~X6_1000();

	/** getBoardCount()
	 *  \returns Number of boards reported by Malibu driver
	 */
	static unsigned int getBoardCount();

	float get_logic_temperature();
	float get_logic_temperature_by_reg(); // second test method to get temp using WB register

	int read_firmware_version(int &, int &);

	/** Set reference source and frequency
	 *  \param ref EXTERNAL || INTERNAL
	 *  \param frequency Frequency in Hz
	 *  \returns SUCCESS || INVALID_FREQUENCY
	 */
	ErrorCodes set_reference(ExtInt ref = INTERNAL, float frequency = 10e6);

	ExtInt get_reference();

	/** Set clock source and frequency
	 *  \param src EXTERNAL || INTERNAL
	 *  \param frequency Frequency in Hz
	 *  \param extSrc FRONT_PANEL || P16
	 *  \returns SUCCESS || INVALID_FREQUENCY
	 */
	ErrorCodes set_clock(ExtInt src = INTERNAL, 
		                 float frequency = 1e9, 
		                 ExtSource extSrc = FRONT_PANEL);

	/** Set up clock and trigger routes
	 * \returns SUCCESS
	 */
	ErrorCodes set_routes();

	/** Set Trigger source
	 *  \param trgSrc SOFTWARE_TRIGGER || EXTERNAL_TRIGGER
	 */
	ErrorCodes set_trigger_src(TriggerSource trgSrc = EXTERNAL_TRIGGER);
	TriggerSource get_trigger_src() const;

	ErrorCodes set_trigger_delay(float delay = 0.0);

	/** Set Decimation Factor (current for both Tx and Rx)
	 * \params enabled set to true to enable
	 * \params factor Decimaton factor
	 * \returns SUCCESS
	 */
	ErrorCodes set_decimation(bool enabled = false, int factor = 1);
	int get_decimation();

	ErrorCodes set_frame(int recordLength);
	ErrorCodes set_averager_settings(const int & recordLength, const int & numSegments, const int & waveforms,  const int & roundRobins);

	ErrorCodes set_channel_enable(int channel, bool enabled);
	bool get_channel_enable(int channel);

	/** retrieve PLL frequnecy
	 *  \returns Actual PLL frequnecy (in MHz) returned from board
	 */
	double get_pll_frequency();

	unsigned int get_num_channels();

	ErrorCodes open(int deviceID);
	ErrorCodes close();

	ErrorCodes acquire();
	ErrorCodes stop();
	bool       get_is_running();

	ErrorCodes transfer_waveform(int, int64_t *, size_t);

	ErrorCodes write_wishbone_register(uint32_t baseAddr, uint32_t offset, uint32_t data);
	ErrorCodes write_wishbone_register(uint32_t offset, uint32_t data);

	uint32_t read_wishbone_register(uint32_t baseAddr, uint32_t offset) const;
	uint32_t read_wishbone_register(uint32_t offset) const;

	const int BusmasterSize = 4; /**< Rx & Tx BusMaster size in MB */
	const int MHz = 1e6;         /**< Constant for converting MHz */
	const int Meg = 1024 * 1024;
 
private:
	// disable copying
	X6_1000(const X6_1000&) = delete;
	X6_1000& operator=(const X6_1000&) = delete;

	Innovative::X6_1000M            module_; /**< Malibu module */
	Innovative::TriggerManager      trigger_;   /**< Malibu trigger manager */
	Innovative::VitaPacketStream    stream_;
	Innovative::SoftwareTimer       timer_;
	Innovative::VeloBuffer       	outputPacket_;
	vector<Innovative::VeloMergeParser> VMPs_; /**< Utility to convert and filter Velo stream back into VITA packets*/

	// WishBone interface
	// TODO: update wbX6ADC wishbone offset  
	const unsigned int wbX6ADC_offset = 0xc00;

	unsigned int numBoards_;      /**< cached number of boards */
	// unsigned int deviceID_;       /**< board ID (aka target number) */

	TriggerSource triggerSource_ = EXTERNAL_TRIGGER; /**< cached trigger source */
	map<int,bool> activeChannels_;

	/* map for record storage
	 * ch  0-9  : physical channels
	 * ch 10-19 : demodulated channels
	 * ch 20-29 : integrated channels
	 * ch 100-199 : correlated channels
	 */
	//Some auxiliary accumlator data
	map<int, Accumulator> accumulators_;

	// State Variables
	bool isOpened_;				  /**< cached flag indicaing board was openned */
	bool isRunning_;
	int prefillPacketCount_;
	unsigned recordLength_ = 0;
	unsigned numRecords_ = 1;
	unsigned numSegments_;
	unsigned waveforms_;
	unsigned roundRobins_;

	ErrorCodes set_active_channels();
	int num_active_channels();
	void set_defaults();
	void log_card_info();
	bool check_done();


	void setHandler(OpenWire::EventHandler<OpenWire::NotifyEvent> &event, 
    				void (X6_1000:: *CallBackFunction)(OpenWire::NotifyEvent & Event));

	// Malibu Event handlers
	
	void HandleDisableTrigger(OpenWire::NotifyEvent & Event);
	void HandleExternalTrigger(OpenWire::NotifyEvent & Event);
    void HandleSoftwareTrigger(OpenWire::NotifyEvent & Event);

	void HandleBeforeStreamStart(OpenWire::NotifyEvent & Event);
    void HandleAfterStreamStart(OpenWire::NotifyEvent & Event);
    void HandleAfterStreamStop(OpenWire::NotifyEvent & Event);

    void HandleDataAvailable(Innovative::VitaPacketStreamDataEvent & Event);
    void VMPDataAvailable(Innovative::VeloMergeParserDataAvailable & Event, int offset);
    void HandlePhysicalStream(Innovative::VeloMergeParserDataAvailable & Event) {
    	VMPDataAvailable(Event, 0);
    };
    void HandleVirtualStream(Innovative::VeloMergeParserDataAvailable & Event) {
    	VMPDataAvailable(Event, 10);
    };

	void HandleTimer(OpenWire::NotifyEvent & Event);

	// Module Alerts
	void HandleTimestampRolloverAlert(Innovative::AlertSignalEvent & event);
    void HandleSoftwareAlert(Innovative::AlertSignalEvent & event);
    void HandleWarningTempAlert(Innovative::AlertSignalEvent & event);
    void HandleInputFifoOverrunAlert(Innovative::AlertSignalEvent & event);
    void HandleInputOverrangeAlert(Innovative::AlertSignalEvent & event);
    void HandleTriggerAlert(Innovative::AlertSignalEvent & event);

    void LogHandler(string handlerName);
};

class Accumulator{
friend X6_1000;

public:
	/* Helper class to accumulate/average data */
	Accumulator();
	Accumulator(const size_t &, const size_t &, const size_t &);
	//TODO: Template this for multiple return types?  
	void accumulate(const Innovative::ShortDG &);

	void init(const size_t &, const size_t &, const size_t &);
	void reset();
	void snapshot(int64_t *);

	size_t recordsTaken;

private:
	size_t idx_;
	size_t wfmCt_;
	size_t numSegments_;
	size_t numWaveforms_;
	size_t recordLength_;

	vector<int64_t> data_;

};



#endif
