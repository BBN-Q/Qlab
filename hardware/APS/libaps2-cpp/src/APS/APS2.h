/*
 * APS2.h
 *
 * APS2 Specfic Structures and tools
 */

#ifndef APS2_H
#define APS2_H

#include "headings.h"
#include "APSEthernet.h"
#include "Channel.h"

class APS2 {

public:

	static const int NUM_CHANNELS = 2;

	//Constructors
	APS2();
	APS2(string);
	~APS2();

	APSEthernet::EthernetError connect();
	APSEthernet::EthernetError disconnect();

	int init(const bool & = false, const int & bitFileNum = 0);
	int reset(const APS_RESET_MODE_STAT & resetMode = APS_RESET_MODE_STAT::RECONFIG_USER_EPROM);

	int load_bitfile(const string &, const int &);
	int program_FPGA(const int &);
	int get_bitfile_version() const;

	int setup_VCXO() const;
	int setup_PLL() const;
	int setup_DACs();

	APSStatusBank_t read_status_registers();
	uint32_t read_status_register(const STATUS_REGISTERS &);

	double get_uptime();

	int set_sampleRate(const int &);
	int get_sampleRate() const;

	int set_trigger_source(const TRIGGERSOURCE &);
	TRIGGERSOURCE get_trigger_source();
	int set_trigger_interval(const double &);
	double get_trigger_interval();

	int set_channel_enabled(const int &, const bool &);
	bool get_channel_enabled(const int &) const;
	int set_channel_offset(const int &, const float &);
	float get_channel_offset(const int &) const;
	int set_channel_scale(const int &, const float &);
	float get_channel_scale(const int &) const;
	int set_offset_register(const int &, const float &);

	template <typename T>
	int set_waveform(const int & dac, const vector<T> & data){
		channels_[dac].set_waveform(data);
		return write_waveform(dac, channels_[dac].prep_waveform());
	}

	int set_run_mode(const int &, const RUN_MODE &);

	int set_LLData_IQ(const WordVec &, const WordVec &, const WordVec &, const WordVec &, const WordVec &);
	int clear_channel_data();

	int load_sequence_file(const string &);

	int run();
	int stop();

	//The owning APSRack needs access to some private members
	friend class APSRack;

	//Whether the APS connection is open
	bool isOpen;

	bool running;

	//Pretty printers
	static string print_status_bank(const APSStatusBank_t & status);
	static string printAPSCommand(const APSCommand_t & command);
	static string printAPSChipCommand(APSChipConfigCommand_t & command);

private:

	string deviceSerial_;
	vector<Channel> channels_;
	int samplingRate_;
	vector<APSEthernetPacket> writeQueue_;
	MACAddr macAddr_;

	//Queued writing
	int write(const APSCommand_t &, const bool & queue = false);
	int write(const unsigned int & addr, const uint32_t & data, const bool & queue = false);
	int write(const unsigned int & addr, const vector<uint32_t> & data, const bool & queue = false);

	vector<APSEthernetPacket> read(const size_t &);

	//Single packet query
	vector<APSEthernetPacket> query(const APSCommand_t &);



	int flush_write_queue();

	int setup_PLL();
	int set_PLL_freq(const int &);
	int test_PLL_sync(const int & numRetries = 2);
	int read_PLL_status(const int & regAddr = FPGA_ADDR_PLL_STATUS, const vector<int> & pllLockBits = std::initializer_list<int>({PLL_02_LOCK_BIT, PLL_13_LOCK_BIT, REFERENCE_PLL_LOCK_BIT}));
	int get_PLL_freq() const;


	int setup_VCXO();

	int setup_DAC(const int &);
	int enable_DAC_FIFO(const int &);
	int disable_DAC_FIFO(const int &);

	// int trigger();
	// int disable();

	int write_waveform(const int &, const vector<short> &);

	int write_LL_data_IQ(const uint32_t &, const size_t &, const size_t &, const bool &);
	int set_LL_data_IQ(const WordVec &, const WordVec &, const WordVec &, const WordVec &, const WordVec &);

	int save_state_file(string &);
	int read_state_file(string &);
	int write_state_to_hdf5(  H5::H5File & , const string & );
	int read_state_from_hdf5( H5::H5File & , const string & );

	
}; //end class APS2




#endif /* APS2_H_ */
