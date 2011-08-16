#!/usr/bin/python

# script to load APS GUI linklist files

import numpy
import h5py
try:
    import matplotlib.pyplot as plt
    haveMatplotlib = True
except:
    haveMatplotlib = False
    
    

class APSMatlabFile:
    APS_UNITSIZE = 4
    TYPE_LINKLIST = 0
    TYPE_WAVEFORM = 1
    
    MAX_AMP_VALUE = 8191
    
    def readFile(self,fileName):
        print 'Loading File', fileName
        try:
            f = h5py.File(fileName,'r')
        except:
            print 'Error could not open file.'
            print '\tThe matlab file may need to be saved using a recent'
            print '\tversion of matlab to be a HDF5 file.'
        
        self.file_type = None
        
        # wave
        self.waveform = None
        
        # link list variables
        self.linkList16 = None
        self.bankA = None
        self.repeatCount = None
        
        if 'linkList16' in f:
            self.file_type = self.TYPE_LINKLIST
            self.linkList16 = f['linkList16']
            
            required = ['bankA','waveformLibrary','repeatCount']
            valid = True
            for el in required:
                if el not in self.linkList16:
                    valid = False
            
            if valid:                
                self.bankA = self.linkList16['bankA']
                self.bankA = self.unpackLinkListBank(self.bankA)
                self.waveform = self.linkList16['waveformLibrary']
                self.repeatCount = (self.linkList16['repeatCount'][:]).astype(numpy.int)
                # strange work around to get single integer from dataset
                # there is hopefully a better way to do this
        
                self.repeatCount = int(self.repeatCount[0][0])
                if 'bankB' in self.linkList16:
                    self.bankB = numpy.array(self.linkList16['bankB'])
                    self.bankB = self.unpackLinkListBank(self.bankB)
                else:
                    self.bankB = None
            else:
                print "Error loading link list file: Invalid format"
                
            self.isLinkList = True
        
        if 'WFVec' in f:
            self.waveform = f['WFVec']
            self.isLinkList = False

    def unpackLinkListBank(self,bank):
        required = ['offset', 'count','trigger','repeat','length']
        for r in required:
            if r not in bank:
                print 'Error bank is invalid %s not found' % (r)
                return None
            
        unPackedBank = {}        
        for r in required[0:-1]:
            cmd = "unPackedBank['%s'] = numpy.array(bank['%s'])" % (r,r)
            exec(cmd)
            
        # strange work around to get single integer from dataset
        # there is hopefully a better way to do this
        tmp =(bank['length'][:]).astype(numpy.int)
        unPackedBank['length'] = int(tmp[0][0])
        return unPackedBank
        
            
    def get_vector(self,scale_factor = 1.0, offset = 0.0):
        
        data = numpy.array(self.waveform)
        
        if self.isLinkList:
            return data
        
        if data.size % self.APS_UNITSIZE != 0:
            NSamples = self.APS_UNITSIZE - (data.size % self.APS_UNITSIZE)
            numpy.append(data,numpy.zeros(NSamples))
            
        scale = scale_factor * 1.0 /  numpy.abs(data).max()
        scale = scale * self.MAX_AMP_VALUE
        
        offset = offset * self.MAX_AMP_VALUE
        
        data = data * scale + offset
        
        data = data.astype('int16')
        
        data[data > self.MAX_AMP_VALUE] = self.MAX_AMP_VALUE
        
        return data
            
    def plotWaveformLibrary(self):
        if haveMatplotlib:
            plt.plot(self.waveform)
            plt.show()
        else:
            print 'Matplotlib is unavailable'
           
    @classmethod
    def unitTest(cls):
        filename = "pulse4000.mat"
        llfile = APSMatlabFile()
        llfile.readFile(filename)
        #llfile.plotWaveformLibrary()
        plt.plot(llfile.get_vector())
        plt.show()
        
        
            
if __name__ == '__main__':
    APSMatlabFile.unitTest()
    