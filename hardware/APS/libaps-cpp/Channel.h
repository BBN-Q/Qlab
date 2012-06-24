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
	virtual ~Channel();

private:
	Waveform waveform;
	LinkList linkLists;
};

#endif /* CHANNEL_H_ */
