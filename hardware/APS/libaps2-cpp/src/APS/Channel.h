/*
 * Channel.h
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */


#ifndef CHANNEL_H_
#define CHANNEL_H_

#include "headings.h"
#include "LLBank.h"

class Channel {
public:
	Channel();
	Channel(int);
	~Channel();
	int number;

	int set_offset(const float &);
	float get_offset() const;
	int set_scale(const float &);
	float get_scale() const;
	int set_enabled(const bool &);
	bool get_enabled() const;

	int set_waveform(const vector<float> &);
	int set_waveform(const vector<int16_t> &);
	vector<int16_t> prep_waveform() const;

	int clear_data();

	int write_state_to_hdf5( H5::H5File & , const string & );
	int read_state_from_hdf5(H5::H5File & , const string & );

	friend class APS2;
	friend class BankBouncerThread;

private:
	float offset_;
	float scale_;
	bool enabled_;
	vector<float> waveform_;
	vector<uint32_t> LLBank_;
	int trigDelay_;
};

#endif /* CHANNEL_H_ */
