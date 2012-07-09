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

	int set_waveform(const vector<float> &);
	int set_waveform(const vector<short> &);
	vector<short> prep_waveform() const;

	friend class APS;

private:
	vector<float> waveform_;
	LinkList linkList_;
	float offset_;
	float scale_;
	bool enable_;
};

#endif /* CHANNEL_H_ */
