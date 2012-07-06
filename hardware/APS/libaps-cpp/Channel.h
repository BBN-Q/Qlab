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

	int set_waveform(const vector<float> &);
	int set_waveform(const vector<short> &);
	int set_offset(const float &);
	int set_scale(const float &);

	vector<short> prep_waveform();

	friend class APS;

private:
	vector<float> _waveform;
	LinkList _linkList;
	float _offset;
	float _scale;
};

#endif /* CHANNEL_H_ */
