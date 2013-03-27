
#include "headings.h"

#include <string>
#include <vector>

#include <X6_1000M_Mb.h>
#include <VitaPacketStream_Mb.h>
#include <SoftwareTimer_Mb.h>
#include <Application/TriggerManager_App.h>
#include "Thunker_Con.h"

#ifndef X6_1000_H_
#define X6_1000_H_

using std::vector;
using std::string;

/**
 * X6_1000 Class: Provides interface to Innovative Illustrations X6_1000 card
 *
 * The expectation is that this class will support a custom FPGA image for APS
 * opperatiions.
 *
 * This interface is utilizes the II [Malibu library](www.innovative-dsp.com/products.php?product=Malibu)
 */



class X6_1000 
{
public:

	enum ErrorCodes {
    	SUCCESS = 0,
    	MODULE_ERROR = -1,
    	NOT_IMPLEMENTED = -2,
    	INVALID_FREQUENCY = -3,
    	INVALID_CHANNEL = -4,
    	INVALID_INTERVAL = -5
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

	enum FPGAWaveformType {
		WAVEFORM_RAMP = 0,    
		WAVEFORM_SINE         
	};

	/** Default constructor targets board 0
	 *
	 */
	X6_1000();

	/** Alternate constructor with identified target board
	 */
	X6_1000(unsigned int);


	/** Default destructor.
	 *  Will close open board.
	 */
	~X6_1000();

	/** getBoardCount()
	 *  \return Number of boards reported by Malibu driver
	 */
	static unsigned int    getBoardCount();

	/** retrives device serial number
	 *  currently generates a fake serial number S# where # is the device number
	 *  \returns device serial numbers
	 */
	static void get_device_serials(vector<string> &);


	/** Sets device ID number for class to work with.
	 *  This sets the Malibu module target used during open.
	 *  \returns SUCCESS || MODULE_ERROR a board is already open
	 */
	ErrorCodes set_deviceID(unsigned int deviceID);

	float get_logic_temperature();

	/** Set reference source and frequency
	 *  \param ref EXTERNAL || INTERNAL
	 *  \param frequency Frequency in MHz
	 *  \returns SUCCESS || INVALID_FREQUENCY
	 */
	ErrorCodes set_reference(ExtInt ref = INTERNAL, float frequency = 10.0);

	/** Set clock source and frequency
	 *  \param ref EXTERNAL || INTERNAL
	 *  \param frequency Frequency in MHz
	 *  \param extSrc FRONT_PANEL || P16
	 *  \returns SUCCESS || INVALID_FREQUENCY
	 */
	ErrorCodes set_clock(ExtInt src = INTERNAL, 
		                 float frequency = 1000.0, 
		                 ExtSource extSrc = FRONT_PANEL);

	/** Set External Trigger source for both Input and Output
	 * \oaram extSrc FRONT_PANEL || P16
	 * \returns SUCESS
	 */
	ErrorCodes set_ext_trigger_src(ExtSource extSrc = FRONT_PANEL);

    /** Set Trigger source
     *  \param trgSrc SOFTWARE_TRIGGER || EXTERNAL_TRIGGER
     */
	ErrorCodes set_trigger_src(TriggerSource trgSrc = SOFTWARE_TRIGGER,
							   bool framed = false,
							   bool edgeTrigger = false,
							   unsigned int frameSize = 0x4000);

	TriggerSource get_trigger_src();

	ErrorCodes set_trigger_interval(const double & interval);

	double get_trigger_interval() const; 

	/** Set Decimation Factor (current for both Tx and Rx)
	 * \params enabled set to true to enable
	 * \params factor Decimaton factor
	 * \returns SUCCESS
	 */
	ErrorCodes set_decimation(bool enabled = false, int factor = 1);

	ErrorCodes set_channel_enable(int channel, bool enabled);
	bool get_channel_enable(int channel);
	

	/** retrieve PLL frequnecy
	 *  \returns Actual PLL frequnecy (in MHz) returned from board
	 */
	double get_pll_frequency();

	/** debug example uses FPGA streamer 
	 */
	ErrorCodes enable_test_generator(FPGAWaveformType wfType, float frequencyMHz);
	ErrorCodes disable_test_generator();
	
	ErrorCodes write_waveform(const int & channel, const vector<short> & wfData);\

	unsigned int get_num_channels();

	ErrorCodes   Open();
    bool  isOpen();
    ErrorCodes   Close();

    ErrorCodes 	 Start();
    ErrorCodes	 Stop();

    static void set_threading_enable(bool enable) {/*enableThreading_ = enable;*/}

    const int BusmasterSize = 4; /**< Rx & Tx BusMaster size in MB */
    const int MHz = 1e6;         /**< Constant for converting MHz */
    const int Meg = 1024 * 1024;
 
private:
	Innovative::X6_1000M            module_; /**< Malibu module */
	Innovative::TriggerManager      trigger_;   /**< Malibu trigger manager */
	Innovative::VitaPacketStream    stream_;
	Innovative::SoftwareTimer       timer_;
	Innovative::VeloBuffer       	outputPacket_;


	unsigned int numBoards_;      /**< cached number of boards */
	unsigned int deviceID_;       /**< board ID (aka target number) */

	double triggerDelayPeriod_ = 0;	  /**< Trigger Delay */
	TriggerSource triggerSource_ = SOFTWARE_TRIGGER; /**< cached trigger source */
	map<int,bool> activeChannels_;

	// State Variables
	bool isOpened_;				  /**< cached flag indicaing board was openned */
	static bool enableThreading_;		  /**< enabled threading support */

	double triggerInterval_; 	  /**< trigger inverval in milliseconds */

	ErrorCodes set_active_channels();
	void set_defaults();
	void log_card_info();


	void setHandler(OpenWire::EventHandler<OpenWire::NotifyEvent> &event, 
    				void (X6_1000:: *CallBackFunction)(OpenWire::NotifyEvent & Event),
    				bool useSyncronizer = true);

	// Malibu Event handlers
	
	void HandleDisableTrigger(OpenWire::NotifyEvent & Event);
	void HandleExternalTrigger(OpenWire::NotifyEvent & Event);
    void HandleSoftwareTrigger(OpenWire::NotifyEvent & Event);

	void HandleBeforeStreamStart(OpenWire::NotifyEvent & Event);
    void HandleAfterStreamStart(OpenWire::NotifyEvent & Event);
    void HandleAfterStreamStop(OpenWire::NotifyEvent & Event);

	void HandleDataRequired(Innovative::VitaPacketStreamDataEvent & Event);
    void HandleDataAvailable(Innovative::VitaPacketStreamDataEvent & Event);
    void HandlePackedDataAvailable(Innovative::VitaPacketPackerDataAvailable & Event);

	void HandleTimer(OpenWire::NotifyEvent & Event);

	// Module Alerts
	void HandleTimestampRolloverAlert(Innovative::AlertSignalEvent & event);
    void HandleSoftwareAlert(Innovative::AlertSignalEvent & event);
    void HandleWarningTempAlert(Innovative::AlertSignalEvent & event);
    void HandleInputFifoOverrunAlert(Innovative::AlertSignalEvent & event);
    void HandleInputOverrangeAlert(Innovative::AlertSignalEvent & event);
    void HandleOutputFifoUnderflowAlert(Innovative::AlertSignalEvent & event);
    void HandleTriggerAlert(Innovative::AlertSignalEvent & event);
    void HandleOutputOverrangeAlert(Innovative::AlertSignalEvent & event);

    void LogHandler(string handlerName);

    thread *threadHandle;

	void  VMPDataAvailable(Innovative::VeloMergeParserDataAvailable & Event);

	FPGAWaveformType wfType_;	 /**< cached test waveform generator */

	map<int, vector<short>> chData_;

};

#endif