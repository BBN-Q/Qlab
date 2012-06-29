/*
 * FTDI.h
 *
 * Hide most of the FTDI interaction here
 *
 *  Created on: Jun 25, 2012
 *      Author: cryan
 */

#ifndef FTDI_H_
#define FTDI_H_

#include "headings.h"

namespace FTDI {

	void get_device_serials(vector<string> &);

	int connect(const int &, FT_HANDLE &);
	int disconnect(FT_HANDLE &);

}



#endif /* FTDI_H_ */
