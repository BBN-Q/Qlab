/*
 * Channel.h
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#ifndef CHANNEL_H_
#define CHANNEL_H_

#include "headings.h"

class Channel {
public:
	Channel();
	Channel(int, FT_HANDLE);
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
	FT_HANDLE _handleAPS;

};

#endif /* CHANNEL_H_ */
