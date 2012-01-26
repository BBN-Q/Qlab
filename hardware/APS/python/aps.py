#!/usr/bin/env python

import ctypes
import platform
import sys
import os

import numpy

libPathDebug = '../libaps/'

class APS:
    # implements interface to libaps
    
    # class properties
    device_id = 0
    num_devices = 0
    bit_file_path = ''
    bit_file = 'mqco_dac2_latest.bit'
    expected_bit_file_ver = 0x10
    Address = 0
    verbose = False
    
    mock_aps = False

    is_open = False
    bit_file_programmed = False
    
    # constants 
    max_waveform_points = 4096
    max_ll_length = 64
    
    ELL_VERSION = 0x10
    
    ADDRESS_UNIT = 4
    
    ELL_MAX_WAVEFORM = 8192
    ELL_MAX_LL = 512
    
    # ELL Linklist Masks and Contants
    ELL_ADDRESS            = 0x07FF
    ELL_TIME_AMPLITUDE     = 0x8000
    ELL_LL_TRIGGER         = 0x8000
    ELL_ZERO               = 0x4000
    ELL_VALID_TRIGGER      = 0x2000
    ELL_FIRST_ENTRY        = 0x1000
    ELL_LAST_ENTRY         = 0x800
    ELL_TA_MAX             = 0xFFFF
    ELL_TRIGGER_DELAY      = 0x3FFF
    ELL_TRIGGER_MODE_SHIFT = 14
    ELL_TRIGGER_DELAY_UNIT = 3.333e-9
    
    LL_ENABLE = 1
    LL_DISABLE = 1
    LL_CONTINUOUS = 0
    LL_ONESHOT = 1
    LL_DC = 1
    
    TRIGGER_SOFTWARE = 1
    TRIGGER_HARDWARE = 2
    
    BOTH_FPGAS = 3
    
    BANKA, BANKB = [0,1]
    
    ALL_DACS = -1
    FORCE_OPEN = 1
    FPGA0,FPGA1 = [0,2]
    
    VALID_FREQUENCIES = [1200,600,300,100,40];

    def __init__(self,libPath= libPathDebug, bitFilePath = ''):
        #Load the approriate library with some platform/architecture checks
        #Check for 32bit 64bit python from sys.maxsize
        #We do this because we can run 32bit programs on 64bit architectures so
        #platform.achitecture() might give misleading results
        str64bit = '64' if sys.maxsize > 2147483647 else ''
        extDict = {'Windows':'.dll', 'Linux':'.so', 'Darwin':'.dylib'}        
        libName = 'libaps' + str64bit + extDict[platform.system()]
        
        if len(libPath) == 0:
            # build path for library
            scriptPath = os.path.dirname(os.path.realpath( __file__ ))
            libPath = scriptPath + '/lib/'
            
        print 'Loading', libPath  + libName
        self.lib = ctypes.cdll.LoadLibrary(libPath  + libName)
        print 'Loaded: ', self.readLibraryVersion()
        
        if len(bitFilePath) == 0:
            # build path for bit file
            # see: http://code.activestate.com/recipes/474083-get-the-path-of-the-currently-executing-python-scr/
            scriptPath = libPath
            extendedPath = 'APS'
            try:
                baseIdx = scriptPath.index(extendedPath)
                self.bit_file_path = scriptPath[0:baseIdx+len(extendedPath)] + '/'
            except ValueError:
                print 'Error finding bit file path in: ', scriptPath
        
    def readLibraryVersion(self):
        strLen = 30
        charBuffer =  ctypes.create_string_buffer(strLen)
        self.lib.APS_ReadLibraryVersion(charBuffer,strLen)
        return charBuffer.value
        
    def enumerate(self):
        numDevices = self.lib.APS_NumDevices()
        return numDevices
        
    def connect(self, address):
        # Experiment framework function for connecting to an APS
        
        if type(address) is int:
            self.open(address)
        else:
            self.openBySerialNum(address)
            
    def disconnect(self):
        self.close()
        
    def setAll(self, init_params):
        print 'APS.setALL is not yet implemented in Python'
        
        
    def open(self,ID,force = 0):
        self.deviceId = ID
        val = self.lib.APS_Open(self.deviceId,force)
        if val == 0:
            self.is_open = 1
            print 'Openned device:', ID
        elif val == -1 or val == 1:
            print 'Could not open device:', ID
            print 'Device may be open in a different process'
        elif val == 2:
            print 'APS Device: ', ID, 'not found'
        else:
            print 'Unknown return value', val
            
    def openBySerialNum(self,serialNum):
        cstr = ctypes.create_string_buffer(serialNum)
        val = self.lib.APS_OpenBySerialNum(cstr)
        if val >= 0:
            self.is_open = 1
            self.device_id = val
        elif val == -1:
            print 'Could not open device: ', serialNum
        elif val == -2:
            print 'APS Device: ', serialNum, 'not found.'
        else:
            print 'Unknown return: ', val
            
    def close(self):
        self.lib.APS_close(self.device_id)
        self.is_open = 0
        
    def readBitFileVersion(self):
        ver = self.lib.APS_ReadBitFileVersion(self.device_id)
        self.bit_file_version = ver
        if ver >= self.ELL_VERSION:
            self.max_waveform_points = self.ELL_MAX_WAVEFORM;
            self.max_ll_length = self.ELL_MAX_LL
        return ver
            
    def dbgForceELLMode(self):
        self.max_waveform_points = self.ELL_MAX_WAVFORM
        self.max_ll_points = self.ELL_MAX_LL
        
    def programFPGA(self,data,bytecount, sel):
        if not self.is_open and not self.mock_aps:
            print 'APS unit is not open'
            return -1
        print "APS Program FPGA"
        val = self.lib.APS_ProgramFpga(self.device_id,data,bytecount,sel)
        if val < 0:
            print 'APS_ProgramFPGA returned an error code of:', val
        else:
            print "[Done]"
        return val

    def getDefaultBitFileName(self):
        return os.path.abspath(self.bit_file_path + self.bit_file)
        
    def loadBitFile(self,filename = ''):
        if len(filename) == 0:
            filename = self.getDefaultBitFileName()
            
        if not self.is_open and not self.mock_aps:
            print 'APS unit is not open'
            return -1
        
        self.setupVCX0()
        self.setupPLL()
        
        Sel = 3 # write to both FPGAs at the same time
        
        print 'Loading bit file:', filename
        if not os.path.isfile(filename):
            print "Error => File Not Found", filename
        
        data = open(filename,'rb').read()
        
        print 'Read', len(data), 'bytes'
        self.programFPGA(data,len(data),Sel)
        
    def loadWaveform(self, ID, waveform, offset = 0, validate = 0, useSlowWrite = 0):
        if not self.is_open and not self.mock_aps:
            print 'APS unit is not open'
            return -1
            
        print 'Loading waveform length: %i into DAC%i' % ( len(waveform), ID)
        
        waveform = waveform.astype(numpy.int16)
        c_int_p = ctypes.POINTER(ctypes.c_int16)
        waveform_p = waveform.ctypes.data_as(c_int_p) 
        
        val = self.lib.APS_LoadWaveform(self.device_id, waveform_p, len(waveform), 
                                        offset, ID, validate, useSlowWrite)
        print 'Done'
        if val < 0:
            print 'APS_LoadWaveform returned an error code of:', val
        return val
        
    def loadLinkList(self, ID, offsets, counts, ll_len):
        repeat = trigger = None
        bank = 0
        self.loadLinkListELL(self.device_id, offsets,counts, trigger, repeat, ll_len, bank)
        
    def loadLinkListELL(self, ID, offsets, counts, trigger, repeat, ll_len, bank, validate = 0):
        print 'loadLinkListELL'
        if not self.is_open and not self.mock_aps:
            print 'APS unit is not open'
            return -1
            
        print 'Loading Link List length %i into DAC%i bank %i' % (ll_len,ID,bank)
        
        # convert each array to int16 pointer
        c_int_p = ctypes.POINTER(ctypes.c_int16)
        
        offsets = offsets.astype(numpy.int16)
        offsets_p = offsets.ctypes.data_as(c_int_p)
        
        counts = counts.astype(numpy.int16)
        counts_p = counts.ctypes.data_as(c_int_p)
        
        trigger = trigger.astype(numpy.int16)
        trigger_p = trigger.ctypes.data_as(c_int_p)
        
        repeat = repeat.astype(numpy.int16)
        repeat_p = repeat.ctypes.data_as(c_int_p)
        
        val = self.lib.APS_LoadLinkList(self.device_id, offsets_p, counts_p, trigger_p,
                                        repeat_p, ll_len, ID, bank, validate)
        
        if val < 0:
            print 'APS_LoadLinkList returned an error code of:', val
        print 'Done'
        
    def librarycall(self, logStr, functionName,  *args):
        if not self.is_open and not self.mock_aps:
            print 'APS unit is not open'
            return -1
        methodCall = getattr(self.lib,functionName)
        if logStr:
            print logStr
        if len(args) == 0:
            methodCall(self.device_id)
        elif len(args) == 1:
            a1 = args[0]
            methodCall(self.device_id,a1)
        elif len(args) == 2:
            a1, a2 = args
            methodCall(self.device_id,a1, a2)
        elif len(args) == 3:
            a1, a2, a3 = args
            methodCall(self.device_id,a1, a2, a3)
        else:
            print 'Error: library call does not support more that 3 arguments'
        
    def clearLinkListELL(self,ID):
        self.librarycall(None,'APS_ClearLinkListELL',ID,0);  # bank 0 
        self.librarycall(None,'APS_ClearLinkListELL',ID,1);  # bank 1
        
        
    def triggerWaveform(self,ID,trigger_type):
        val = self.librarycall('Trigger Waveform %i Type %i' % (ID, trigger_type), 
                         'APS_TriggerDac',ID,trigger_type)
        
    def pauseWaveform(self,ID):
        val = self.librarycall('Pause Waveform %i' % (ID), 'APS_PauseDac',ID)
        
    def disableWaveform(self,ID):
        val = self.librarycall('Disable Waveform %i' % (ID), 'APS_DisableDac',ID)
        
    def triggerFpga(self,ID,trigger_type):
        val = self.librarycall('Trigger Waveform %i Type: %i' %(ID, trigger_type), 
                               'APS_TriggerFpga',ID,trigger_type)
                               
    def pauseFpga(self,ID):                           
        val = self.librarycall('Pause FPGA %i' % (ID), 'APS_PauseFpga',ID)
        
    def disableFpga(self,ID):                           
        val = self.librarycall('Disable FPGA %i' % (ID), 'APS_DisableFpga',ID)

    def setLinkListMode(self,ID, enable,dc):
        val = self.librarycall('Dac: %i Link List Enable: %i Mode: %i' % (ID, enable,dc), 
                               'APS_SetLinkListMode',enable,dc,ID);
        
        
    def setLinkListRepeat(self,ID, repeat):
        val = self.librarycall('Dac: %i Link List Repeat: %i' % (ID, repeat),
                               'APS_SetLinkListRepeat',repeat,ID)
        
    def setFrequency(self,ID, freq):
        testLock = 1;
        val = self.librarycall('Dac: %i Freq : %i' % (ID, freq), 'APS_SetPllFreq',ID,freq,testLock);
        if val: 
            print 'Warning: APS::setFrequency returned', val

    def setupPLL(self):
        val = self.librarycall('Setup PLL', 'APS_SetupPLL');
        
    def setupVCX0(self):
        val = self.librarycall('Setup VCX0', 'APS_SetupVCXO');
    
        
    def readAllRegisters(self):
        val = self.librarycall('Read Registers', 'APS_ReadAllRegisters');
        
    def testWaveformMemory(self, ID, numBytes):
            val = self.librarycall('Test WaveformMemory','APS_TestWaveformMemory',ID,numBytes);
        
    def readLinkListStatus(self,ID):
        return self.librarycall('Read Link List Status', 'APS_ReadLinkListStatus',ID);
        
    def buildWaveformLibrary(self,waveforms,useVarients = True):
        print 'buildWaveformLibrary not yet implemented in Python'
        return None
        
    def entryToOffsetCount(self,entry,library,firstEntry,lastEntry):
        print 'entryToOffsetCount not yet implemented in Python'
        return None
        
    def entryToTrigger(self,entry):
        print 'entryToOffsetCount not yet implemented in Python'
        return None       
        
    def convertLinkListFormat(self,pattern, useVarients, waveformLibrary, miniLinkRepeat):
        print 'convertLinkListFormat not yet implemented in Python'
        return None       
        
    def linkListToPattern(self,wf,banks):
        print 'linkListToPattern not yet implemented in Python'
        return None   
    
    def unifySequenceLibraryWaveforms(self,sequences):
        print 'unifySequenceLibraryWaveforms not yet implemented in Python'
        return None  
        
    def getNewWaveform(self):
        print 'getNewWaveform not yet implemented in Python'
        return None
        
    def unitTestBasic(self):
        self.open(0)
        self.mock_aps = True
        print "Current Bit File Version: ", self.readBitFileVersion()
        print "Loading bit file"
        if self.readBitFileVersion() != 16:
            self.loadBitFile()
            print "Current Bit File Version: ", self.readBitFileVersion()
        
        self.setFrequency(0,1200)
        
        import APSMatlabFile
        fileData = APSMatlabFile.APSMatlabFile()
        fileData.readFile('pulse4000.mat')
        print 'Done Loading File'
        self.loadWaveform(0,fileData.get_vector())

        print 'Done with load Waveform'
        self.triggerWaveform(0,1)
        print 'Done with Trigger'
        
if __name__ == '__main__':
    aps = APS(libPathDebug)
    aps.unitTestBasic()