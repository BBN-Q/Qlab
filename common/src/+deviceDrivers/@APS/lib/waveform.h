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

#define APS_WAVEFORM_UNIT_LENGTH 4

#define MAX_WAVEFORM_LENGTH 8192

#define NUM_BITS 13

#define MAX_WF_VALUE pow(2,NUM_BITS)-1

typedef struct {
  float * pData;
  uint16_t * pFormatedData;
  float offset;
  float scale;
  int allocatedLength;
  int isLoaded;
} waveform_t;

waveform_t * WF_Init();
void   WF_Destroy(waveform_t * wfArray);
int    WF_SetWaveform(waveform_t * wfArray, int channel, float * data, int length);
int    WF_Free(waveform_t * wfArray, int channel);
void   WF_SetOffset(waveform_t * wfArray, int channel, float offset);
float  WF_GetOffset(waveform_t * wfArray, int channel);
void   WF_SetScale(waveform_t * wfArray, int channel, float scale);
float  WF_GetScale(waveform_t * wfArray, int channel);
void   WF_Prep(waveform_t * wfArray, int channel);

uint16_t * WF_GetDataPtr(waveform_t * wfArray, int channel);
int16_t WF_Getlength(waveform_t * wfArray, int channel);

#endif /* WAVEFORM_H_ */
