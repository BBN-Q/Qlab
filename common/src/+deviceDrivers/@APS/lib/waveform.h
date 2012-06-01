/*
 * waveform.h
 *
 *  Created on: Aug 24, 2011
 *      Author: bdonovan
 */

#ifndef WAVEFORM_H_
#define WAVEFORM_H_

#include <stdint.h>
#include <math.h>

#define MAX_APS_CHANNELS 4
#define MAX_APS_BANKS 2

#define APS_WAVEFORM_UNIT_LENGTH 4

#define MAX_WAVEFORM_LENGTH 8192

#define NUM_BITS 13

#define MAX_WF_VALUE (pow(2,NUM_BITS)-1)

typedef struct {
  uint16_t *offset;
  uint16_t *count;
  uint16_t *trigger;
  uint16_t *repeat;
  unsigned int length;
  int isLoaded;
} bank_t;

enum waveformDataType_t {
	WAVEFORM_INT_DATA = 1,
	WAVEFORM_FLOAT_DATA = 2
};

typedef struct {
  void * pData;
  uint16_t * pFormatedData;
  float offset;
  float scale;
  int allocatedLength;
  int isLoaded;
  enum waveformDataType_t dataType;
  bank_t linkListBanks[MAX_APS_BANKS]; // TODO change from array to link list
} waveform_t;

waveform_t * WF_Init();
void   WF_Destroy(waveform_t * wfArray);
int    WF_SetWaveform(waveform_t * wfArray, int channel, void * data, int length, int dataType);
int    WF_Free(waveform_t * wfArray, int channel);
void   WF_SetOffset(waveform_t * wfArray, int channel, float offset);
float  WF_GetOffset(waveform_t * wfArray, int channel);
void   WF_SetScale(waveform_t * wfArray, int channel, float scale);
float  WF_GetScale(waveform_t * wfArray, int channel);
void   WF_Prep(waveform_t * wfArray, int channel);

uint16_t * WF_GetDataPtr(waveform_t * wfArray, int channel);
int16_t WF_Getlength(waveform_t * wfArray, int channel);

int WF_SetLinkList(waveform_t * wfArray, int channel,
    uint16_t *OffsetData, uint16_t *CountData,
    uint16_t *TriggerData, uint16_t *RepeatData,
    int length, int bank);
void WF_FreeBank(bank_t * bank);
bank_t * WF_GetLinkListBank(waveform_t * wfArray, int channel, unsigned int bank);

int WF_SaveCache(waveform_t * wfArray, char * fileNameHeader);
int WF_LoadCache(waveform_t * wfArray, char * fileNameHeader);

#endif /* WAVEFORM_H_ */
