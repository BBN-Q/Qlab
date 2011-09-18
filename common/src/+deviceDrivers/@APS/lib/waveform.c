/*
 * waveform.c
 *
 *  Created on: Aug 24, 2011
 *      Author: bdonovan
 */

#include "waveform.h"
#include "common.h"
#include <stdint.h>

waveform_t * WF_Init() {
  waveform_t * wfArray;

  wfArray = (waveform_t *) malloc (MAX_APS_CHANNELS * sizeof(waveform_t));

  if (!wfArray) {
    dlog(DEBUG_INFO,"Failed to allocate memory for waveform array\n");
  }

  int cnt;

  for (cnt = 0; cnt < MAX_APS_CHANNELS; cnt++) {
    wfArray[cnt].pData = 0;
    wfArray[cnt].pFormatedData = 0;
    wfArray[cnt].offset = 0.0;
    wfArray[cnt].scale = 1.0;
    wfArray[cnt].allocatedLength = 0;
    wfArray[cnt].isLoaded = 0;
  }

  return wfArray;
}

void WF_Destroy(waveform_t * wfArray) {
  int cnt;

  if (!wfArray) return; // waveform array does not exist

  // free memory for each channel
  for (cnt = 0; cnt < MAX_APS_CHANNELS; cnt++) {
    WF_Free(wfArray,cnt);
  }

  // free channel array memory
  free(wfArray);
  return;
}

int    WF_SetWaveform(waveform_t * wfArray, int channel, float * data, int length) {
  if (!wfArray) return;

  // free any memory associated with channel if it exists
  WF_Free(wfArray,channel);

  // allocate memory

  int allocatedLength;

  // trim length to maximum allowed
  if (length > MAX_WAVEFORM_LENGTH) {
    dlog(DEBUG_INFO,"Warning trimming channel %i length to %i\n", channel, MAX_WAVEFORM_LENGTH);
    length =  MAX_WAVEFORM_LENGTH;
  }

  allocatedLength = length + (length % APS_WAVEFORM_UNIT_LENGTH);

  wfArray[channel].pData = (float *) malloc(allocatedLength * sizeof(float));
  if (!wfArray[channel].pData) {
    dlog(DEBUG_INFO,"Error allocating data pointer for channel: %i", channel);
    return -1;
  }

  wfArray[channel].pFormatedData = (int16_t *) malloc(allocatedLength * sizeof(int16_t));
  if (!wfArray[channel].pFormatedData) {
    dlog(DEBUG_INFO,"Error allocating formated data pointer for channel: %i", channel);
    return -1;
  }

  memset(wfArray[channel].pData,         0,  allocatedLength * sizeof(float));
  memset(wfArray[channel].pFormatedData, 0,  allocatedLength * sizeof(int16_t));

  memcpy(wfArray[channel].pData, data, length * sizeof(float));

  wfArray[channel].allocatedLength = allocatedLength;
  wfArray[channel].isLoaded = 0;
  WF_Prep(wfArray,channel);

}

int    WF_Free(waveform_t * wfArray, int channel) {
  if (!wfArray) return;

  if (wfArray[channel].pData) free(wfArray[channel].pData);
  if (wfArray[channel].pFormatedData) free(wfArray[channel].pFormatedData);

}

void  WF_SetOffset(waveform_t * wfArray,int channel, float offset) {
  if (!wfArray) return;
  wfArray[channel].offset = offset;
}

float    WF_GetOffset(waveform_t * wfArray, int channel) {
  if (!wfArray) return 0;
  return wfArray[channel].offset;
}

void    WF_SetScale(waveform_t * wfArray, int channel, float scale) {
  if (!wfArray) return;
  wfArray[channel].scale = scale;
}

float  WF_GetScale(waveform_t * wfArray, int channel) {
  if (!wfArray) return 0;
  return wfArray[channel].scale;
}

uint16_t * WF_GetDataPtr(waveform_t * wfArray, int channel) {
  if (!wfArray) return 0;

  return wfArray[channel].pFormatedData;
}

uint16_t WF_GetLength(waveform_t * wfArray, int channel) {
  if (!wfArray) return 0;

  return wfArray[channel].allocatedLength;
}

int WF_GetIsLoaded(waveform_t * wfArray, int channel) {
  if (!wfArray) return 0;

    return wfArray[channel].isLoaded;
}

void WF_SetIsLoaded(waveform_t * wfArray,  int channel, int loaded) {
  if (!wfArray) return;

  wfArray[channel].isLoaded = loaded;
}

void   WF_Prep(waveform_t * wfArray, int channel) {
  if (!wfArray) return;

  int cnt;
  int prepValue;

  float scale;
  float maxAbsValue;
  float offset;

  for (cnt = 0; cnt < wfArray[channel].allocatedLength; cnt++) {
    if (abs(wfArray[channel].pData[cnt]) > maxAbsValue)
        maxAbsValue = abs(wfArray[channel].pData[cnt]);
  }

  scale = wfArray[channel].scale * 1.0 / maxAbsValue;
  scale = scale * MAX_WF_VALUE;

  offset = wfArray[channel].offset * MAX_WF_VALUE;

  for (cnt = 0; cnt < wfArray[channel].allocatedLength; cnt++) {
    prepValue = wfArray[channel].pData[cnt];

    // multiply by scale and add dc offset
    prepValue = round(prepValue * scale + offset);

    // clip to min max value
    if (prepValue > MAX_WF_VALUE) prepValue = MAX_WF_VALUE;
    if (prepValue < -MAX_WF_VALUE) prepValue = -MAX_WF_VALUE;

    // convert to int16
    wfArray[channel].pFormatedData[cnt] = (int16_t) prepValue;
  }

}
