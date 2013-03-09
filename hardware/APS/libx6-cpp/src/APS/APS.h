/*
 * APS.h
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#include "headings.h"

#ifndef APS_H_
#define APS_H_

class APS {


public:
	//Constructors
	APS();
	APS(int, string);
	//Move-ctor
	APS(APS&&);

	~APS();

	int connect();
	int disconnect();


	int init(const string &, const bool &);
	int reset() const;

/*
	int setup_VCXO() const;
	int setup_PLL() const;
	int setup_DACs() const;

	int program_FPGA(const string &, const int &) const;
	int read_bitFile_version() const;
*/
	int set_sampleRate(const float &);
	double get_sampleRate() const;


	int set_trigger_source(const TRIGGERSOURCE &);
	TRIGGERSOURCE get_trigger_source() const;

/*
	int set_trigger_interval(const double &);
	double get_trigger_interval() const;
*/

	int set_channel_enabled(const int &, const bool &);
	bool get_channel_enabled(const int &) const;
/*
	int set_channel_offset(const int &, const float &);
	float get_channel_offset(const int &) const;
	int set_channel_scale(const int &, const float &);
	float get_channel_scale(const int &) const;
	int set_offset_register(const int &, const float &);

	int set_miniLL_repeat(const USHORT &);


	template <typename T>
	int set_waveform(const int & dac, const vector<T> & data){
		channels_[dac].set_waveform(data);
		return write_waveform(dac, channels_[dac].prep_waveform());
	}

	int set_run_mode(const int &, const RUN_MODE &);
	int set_repeat_mode(const int &, const bool &);

	int set_LLData_IQ(const WordVec &, const WordVec &, const WordVec &, const WordVec &, const WordVec &);
	int clear_channel_data();

	int load_sequence_file(const string &);

	int run();
	int stop();
*/

	float get_logic_temperature();

	//The owning APSRack needs access to some private members
	friend class APSRack;
	friend class BankBouncerThread;


	//Whether the FTDI connection is open
	bool isOpen;

private:
	const unsigned int numFPGAs = 1;
	const unsigned int numChannels = 2;

	//Since the APS contains non-copyable mutexs and atomic members then explicitly prevent copying
	APS(const APS&) = delete;
	APS& operator=(const APS&) = delete;

	int deviceID_;
	string deviceSerial_;
	X6_1000 handle_; 
	vector<Channel> channels_;
	CheckSum checksum_;
	int samplingRate_;
	vector<UCHAR> writeQueue_;
	vector<size_t> offsetQueue_;
	//vector<BankBouncerThread> myBankBouncerThreads_;  // TODO: Remove Stale Reference
	//Flag for whether streaming is up and running
	std::atomic<bool> streaming_;
	//A mutex to control access to the APS unit during streaming
	//Since mutexs are non-copyable and non-movable we use an unique_ptr
	std::unique_ptr<std::mutex> mymutex_;

/*
	int write(const unsigned int & addr, const USHORT & data, const bool & queue = false);
	int write(const unsigned int & addr, const vector<USHORT> & data, const bool & queue = false);

	int flush();
	int reset_status_ctrl();
	int clear_status_ctrl();
	UCHAR read_status_ctrl();

	int setup_PLL();
	int set_PLL_freq(const int &);
	int test_PLL_sync(const int & numRetries = 2);
	int read_PLL_status(const int & regAddr = FPGA_ADDR_REGREAD | FPGA_ADDR_PLL_STATUS, const vector<int> & pllLockBits = std::initializer_list<int>({PLL_02_LOCK_BIT, PLL_13_LOCK_BIT, REFERENCE_PLL_LOCK_BIT}));
*/
	double get_PLL_freq() const;

/*
	int setup_VCXO();

	int setup_DAC(const int &) const;
	int enable_DAC_FIFO(const int &) const;
	int disable_DAC_FIFO(const int &) const;


	int trigger();
	int disable();

	int reset_checksums();
	bool verify_checksums();

	int write_waveform(const int &, const vector<short> &);

	int write_LL_data_IQ(const ULONG &, const size_t &, const size_t &, const bool &);
	int set_LL_data_IQ( const WordVec &, const WordVec &, const WordVec &, const WordVec &, const WordVec &);
	int stream_LL_data(const int);
	int read_LL_addr();
	int read_LL_addr(const int &);
	int read_miniLL_startAddr();




	int save_state_file(string &);
	int read_state_file(string &);
	int write_state_to_hdf5(  H5::H5File & , const string & );
	int read_state_from_hdf5( H5::H5File & , const string & );
	*/
};


#endif /* APS_H_ */
