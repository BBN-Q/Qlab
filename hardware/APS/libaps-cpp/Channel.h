/*
 * Channel.h
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#include "headings.h"

#ifndef CHANNEL_H_
#define CHANNEL_H_

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
	int set_waveform(const vector<short> &);
	vector<short> prep_waveform() const;

	int reset_LL_banks();
	int add_LL_bank(const vector<unsigned short> &, const vector<unsigned short> &, const vector<unsigned short> &, const vector<unsigned short> &);

	int clear_data();

	int write_state_to_hdf5( H5::H5File & , const string & );
	int read_state_from_hdf5(H5::H5File & , const string & );

	friend class APS;

private:
	float offset_;
	float scale_;
	bool enabled_;
	vector<float> waveform_;
	vector<LLBank> banks_;
	int trigDelay_;
};

#endif /* CHANNEL_H_ */
