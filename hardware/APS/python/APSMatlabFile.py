#!/usr/bin/python

# script to load APS GUI linklist files

import numpy as np
import h5py
    

class APSMatlabFile(object):
    APS_UNITSIZE = 4
    TYPE_LINKLIST = 0
    TYPE_WAVEFORM = 1
    
    MAX_AMP_VALUE = 8191
    
    FOURCHANNELMODE = 0;
    SINGLECHANNELMODE = 1;
    
    CHANNELNAMES = ('chan_1','chan_2','chan_3','chan_4')
    
    def __init__(self, mode=0, fileName=None):
        self.mode = mode
        if fileName is not None:
            self.readFile(fileName)
            
    def readFile(self, fileName):
        print('Loading File {0}'.format(fileName))
        try:
            FID = h5py.File(fileName,'r')
        except:
            print('Error could not open file.')

        assert FID.attrs['Version'] == 1.6, 'Oops! This code expects APS HDF5 file version 1.6.'
           
        self.WFData = {}
        self.LLData = {}
        
        #First look for all four channel data
        if self.mode == self.FOURCHANNELMODE:
            #Look for the 4 channel data
            for ct,channel in enumerate(self.CHANNELNAMES):
                if channel in FID.keys():
                    tmpChan = FID[channel]
                    self.WFData[channel] = tmpChan['waveformLib'].value
                    self.LLData[channel] = {}
                    tmpLLData = tmpChan['linkListData']
                    self.LLData[channel]['repeatCount'] = int(tmpLLData.attrs['repeatCount'][0])

                    #Here we just directly load bank1 into bankA and bank2 into bankB
                    self.LLData[channel]['bankA'] = {}
                    if 'bank1' in tmpLLData.keys(): 
                        for key,value in tmpLLData['bank1'].items():
                            self.LLData[channel]['bankA'][key] = value.value
                        self.LLData[channel]['bankA']['length'] = int(tmpLLData['bank1'].attrs['length'][0])
                    
                    if 'bank2' in tmpLLData.keys(): 
                        self.LLData[channel]['bankB'] = {}
                        for key,value in tmpLLData['bank2'].items():
                            self.LLData[channel]['bankB'][key] = value.value
                        self.LLData[channel]['bankB']['length'] = int(tmpLLData['bank2'].attrs['length'][0])
                
        else:
            if 'WFVec' in FID:
                self.waveform = FID['WFVec'].value
                self.isLinkList = False
                
        #Close the file
        FID.close()

    def get_vector(self, scale_factor=1, offset=0.0, channelName=None):
        
        #If channel is None then assume single channel data in self.waveform
        if channelName is None:
            WF = self.waveform
        else:
            WF = self.WFData[channelName]
        
        #Make sure the waveform is a multiple of 4
        if WF.size % self.APS_UNITSIZE != 0:
            NSamples = self.APS_UNITSIZE - (WF.size % self.APS_UNITSIZE)
            WF = np.append(WF,np.zeros(NSamples))

        WF = WF*scale_factor + offset*self.MAX_AMP_VALUE
        
        WF = WF.astype('int16')
        
        #Clip
        WF[WF > self.MAX_AMP_VALUE] = self.MAX_AMP_VALUE
        WF[WF < -self.MAX_AMP_VALUE] = -self.MAX_AMP_VALUE
        
        return WF
           
    @classmethod
    def unitTest(cls):
        filename = "pulse4000.mat"
        llfile = APSMatlabFile()
        llfile.readFile(filename)
        #plt.plot(llfile.get_vector())
        #plt.show()
        
        
            
if __name__ == '__main__':
    APSMatlabFile.unitTest()
    