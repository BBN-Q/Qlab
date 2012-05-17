/*
 * threads.c
 *
 *  Created on: Mar 30, 2012
 *      Author: bdonovan
 */

// Implements PThreads based management of channel link lists
// Currently had to get pthreadGC2.dll files from http://sourceforge.net/apps/trac/mingw-w64/wiki/Compile%20pthreads

#include "libaps.h"
#include "threads.h"
#include "apserrors.h"
#include "common.h"

pthread_t threadHandles[MAX_APS_DEVICES][MAX_APS_CHANNELS];
linkListThreadData_t linkListThreadData[MAX_APS_DEVICES][MAX_APS_CHANNELS];

void *logCounter(void * threadid) {
	long tid;
	tid = (long)threadid;
	while(1) {
		dlog(DEBUG_INFO,"Thread: %i Hello World\n", threadid);
		sleep(1);
	}
	pthread_exit(NULL);
}


int APS_InitLinkListThreads() {
	int dev,chan;
	for (dev = 0; dev < MAX_APS_DEVICES; dev++) {
		for(chan = 0; chan < MAX_APS_CHANNELS; chan++) {
			linkListThreadData[dev][chan].runThread = 0;
			linkListThreadData[dev][chan].dev = dev;
			linkListThreadData[dev][chan].channel = chan;
			linkListThreadData[dev][chan].waveform = 0;
		}
	}
	return 0;
}

void * APS_LinkListThread(void * data) {
	linkListThreadData_t *threadData;
	threadData = (linkListThreadData_t *) data;
	bank_t *firstBankData, *loadBankData;
	int currentBankID, pollBankID;
	int validate = 0;

	currentBankID  = APS_ReadLinkListStatus(threadData->dev, threadData->channel);
	while(threadData->runThread) {
				// poll for current bank to see if bank has switched
		pollBankID = APS_ReadLinkListStatus(threadData->dev, threadData->channel);
		dlog(DEBUG_INFO,"Dev: %i  Channel: %i Current Bank: Addr: 0x%x\n", threadData->dev, threadData->channel, pollBankID);

		if (pollBankID != currentBankID) {
			dlog("Dev: %i  Channel: %i Loading Bank: %i\n", threadData->dev, threadData->channel, currentBankID);
			loadBankData = &(threadData->waveform->linkListBanks[currentBankID]);
			LoadLinkList_ELL(threadData->dev, loadBankData->offset, loadBankData->count, loadBankData->trigger,
							 loadBankData->repeat, loadBankData->length, threadData->channel,currentBankID,validate);
			currentBankID = pollBankID;
			pollBankID = APS_ReadLinkListStatus(threadData->dev, threadData->channel);
			if (pollBankID != currentBankID) {
				dlog(DEBUG_INFO,"WARNING: Channel: %i BANK Swapped during load of link list\n", threadData->channel);
			}
		}
		usleep(100);

	}
	pthread_exit(NULL);
}

EXPORT int APS_StartLinkListThread(int device, int channel) {
	pthread_t * channelThread;
	linkListThreadData_t * threadData;

	APS_Init();

	if (device < 0 || device >= MAX_APS_DEVICES) return APSERR_INVALID_DEVICE;

	if (channel < 0 || channel >= MAX_APS_CHANNELS) return APSERR_INVALID_CHANNEL;

	channelThread = &(threadHandles[device][channel]);
	threadData = &(linkListThreadData[device][channel]);

	threadData->runThread = 1;
	threadData->waveform = APS_GetWaveform(device,channel);

	dlog(DEBUG_INFO,"Starting thread for device: %i channel: %i data addr: 0x%x\n", device, channel, threadData);

	int rc;
	rc = pthread_create(channelThread,NULL,APS_LinkListThread, (void *) threadData);
	if (rc) {
		dlog(DEBUG_INFO,"Error creating thread for device: %i channel: %i\n", device,channel);
	}
	return 0;
}

EXPORT int APS_StopLinkListThread(int device, int channel) {
	if (device < 0 || device >= MAX_APS_DEVICES) return APSERR_INVALID_DEVICE;

	if (channel < 0 || channel >= MAX_APS_CHANNELS) return APSERR_INVALID_CHANNEL;

	dlog(DEBUG_INFO,"Stopping thread for device: %i channel: %i\n", device, channel);
	linkListThreadData[device][channel].runThread = 0;
	return 0;
}
