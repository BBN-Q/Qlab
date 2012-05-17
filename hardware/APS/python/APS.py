#!/usr/bin/env python

import ctypes
import platform
import sys
import os

import numpy as np

import APSMatlabFile

libPathDebug = '../libaps/'

class APS:
    # implements interface to libaps
    
    # class properties
    device_id = 0
    num_devices = 0
    deviceSerials = []
    bit_file_path = ''
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
    
    MAX_WAVEFORM_VALUE = 8191
    
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
    
    VALID_FREQUENCIES = [1200,600,300,100,40]

    CHANNELNAMES = ('chan_1','chan_2','chan_3','chan_4')
    
    lastSeqFile = ''
    
    #DAC2 devices use a different bit file
    DAC2Serials = ('A6UQZB7Z', 'A6001nBU', 'A6001ixV')

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
                
        #Initialize the channel settings
        self.channelSettings = {}
        for chanName in self.CHANNELNAMES:
            self.channelSettings[chanName] = {'amplitude':1, 'offset':0, 'enabled':False, 'seqfile':None}
        
        #Initialize trigger settings
        self.triggerSource = self.TRIGGER_SOFTWARE        
        
    def readLibraryVersion(self):
        strLen = 30
        charBuffer =  ctypes.create_string_buffer(strLen)
        self.lib.APS_ReadLibraryVersion(charBuffer,strLen)
        return charBuffer.value
        
    def enumerate(self):
        #List the number of devices attached and their serial numbers
        
        #First get the number of devices        
        numDevices = self.lib.APS_NumDevices()

        self.deviceSerials = []
        #Now, for each device, get the associated serial number
        charBuffer = ctypes.create_string_buffer(64)
        for ct in range(numDevices):
            self.lib.APS_GetSerialNum(ct,charBuffer, 64)
            self.deviceSerials.append(charBuffer.value)

        return numDevices, self.deviceSerials
        
    def connect(self, address):
        # Experiment framework function for connecting to an APS
        
        if type(address) is int:
            self.open(address)
        else:
            self.openBySerialNum(address)
            
    def disconnect(self):
        self.close()
        
    def open(self,ID,force = 0):
        self.device_id = ID
        
        # populate list of device id's and serials
        num_devices = self.enumerate()
        if ID + 1 > num_devices:
            print 'APS Device: ', ID, 'not found'
            return 2

        val = self.lib.APS_Open(self.device_id,force)
        if val == 0:
            self.is_open = 1
            print 'Opened device:', ID
        elif val == -1 or val == 1:
            print 'Could not open device:', ID
            print 'Device may be open in a different process'
        elif val == 2:
            print 'APS Device: ', ID, 'not found'
        else:
            print 'Unknown return value', val
        return val
            
    def openBySerialNum(self,serialNum):
        # populate list of device id's and serials
        self.enumerate()
        if serialNum not in self.deviceSerials:
            print 'APS Device: ', serialNum, 'not found.'
            return 2
        
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
        return val
            
    def close(self):
        self.lib.APS_Close(self.device_id)
        self.is_open = 0
        
    def readBitFileVersion(self):
        ver = self.lib.APS_ReadBitFileVersion(self.device_id)
        self.bit_file_version = ver
        if ver >= self.ELL_VERSION:
            self.max_waveform_points = self.ELL_MAX_WAVEFORM
            self.max_ll_length = self.ELL_MAX_LL
        return ver
            
    def dbgForceELLMode(self):
        self.max_waveform_points = self.ELL_MAX_WAVFORM
        self.max_ll_points = self.ELL_MAX_LL
        
    def programFPGA(self, data, bytecount, sel, version):
        if not self.is_open and not self.mock_aps:
            print 'APS unit is not open'
            return -1
        print "APS Program FPGA"
        val = self.lib.APS_ProgramFpga(self.device_id, data, bytecount, sel, version)
        if val < 0:
            print 'APS_ProgramFPGA returned an error code of:', val
        else:
            print "[Done]"
        return val

    def getDefaultBitFileName(self):
        #Check whether we have a DACII or APS device
        if not self.deviceSerials:
            return None
        elif self.deviceSerials[self.device_id] in self.DAC2Serials:
            return os.path.abspath(self.bit_file_path + 'mqco_dac2_latest.bit')
        else:
            return os.path.abspath(self.bit_file_path + 'mqco_aps_latest.bit')
        
    def loadBitFile(self,filename = None):
        if filename is None:
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
        val = self.programFPGA(data, len(data), Sel, self.expected_bit_file_ver)
        
        return val
        
    def loadWaveform(self, ID, waveform, offset = 0, validate = 0, useSlowWrite = 0):
        if not self.is_open and not self.mock_aps:
            print 'APS unit is not open'
            return -1
            
        print 'Loading waveform length: %i into DAC%i' % ( len(waveform), ID)
        
        waveform = waveform.astype(np.int16)
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
            
        print('Loading Link List length {0} into DAC{1} bank {2}'.format(ll_len,ID,bank))
        
        #TODO: we are assuming the arrays are contiguous should we check this?
        
        # convert each array to uint16 pointer
        c_uint16_p = ctypes.POINTER(ctypes.c_uint16)
        
        offsets = offsets.astype(np.uint16)
        offsets_p = offsets.ctypes.data_as(c_uint16_p)
        
        counts = counts.astype(np.uint16)
        counts_p = counts.ctypes.data_as(c_uint16_p)
        
        trigger = trigger.astype(np.uint16)
        trigger_p = trigger.ctypes.data_as(c_uint16_p)
        
        repeat = repeat.astype(np.uint16)
        repeat_p = repeat.ctypes.data_as(c_uint16_p)
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
        return methodCall(self.device_id, *args)
        
    def clearLinkListELL(self,ID):
        self.librarycall(None,'APS_ClearLinkListELL',ID,0)  # bank 0 
        self.librarycall(None,'APS_ClearLinkListELL',ID,1)  # bank 1
        
        
    def triggerWaveform(self,ID,trigger_type):
        return self.librarycall('Trigger Waveform %i Type %i' % (ID, trigger_type), 
                         'APS_TriggerDac',ID,trigger_type)
        
    def pauseWaveform(self,ID):
        return self.librarycall('Pause Waveform %i' % (ID), 'APS_PauseDac',ID)
        
    def disableWaveform(self, ID):
        return self.librarycall('Disable Waveform %i' % (ID), 'APS_DisableDac',ID)
        
    def triggerFpga(self, ID, trigger_type):
        return self.librarycall('Trigger Waveform %i Type: %i' %(ID, trigger_type), 
                               'APS_TriggerFpga',ID,trigger_type)
        
    def disableFpga(self, ID):                           
        return self.librarycall('Disable FPGA %i' % (ID), 'APS_DisableFpga',ID)

    def setLinkListMode(self, ID, enable,dc):
        self.librarycall('Dac: %i Link List Enable: %i Mode: %i' % (ID, enable,dc), 
                               'APS_SetLinkListMode',enable,dc,ID)
        
    def setLinkListRepeat(self, ID, repeat):
        self.librarycall('Dac: %i Link List Repeat: %i' % (ID, repeat),
                               'APS_SetLinkListRepeat',repeat,ID)
    
    @property
    def samplingRate(self):
        '''
        Check for a uniform sampling rate for all DACs and return it if they are the same,
        otherwise return None
        '''
        samplingRates = [self.getFrequency(tmpDAC) for tmpDAC in [0, 2]]
        
        if samplingRates[0] == samplingRates[1]:
            return samplingRate[0]
        else:
            return None
    
    @samplingRate.setter
    def samplingRate(self, freq):
        if self.samplingRate ~= freq:
            self.setFrequency(0, freq, testLock=0)
            self.setFrequency(2, freq, testLock=0)
            self.resetStatusCtrl(); # in case setFrequency left the oscillator disabled
        
            # Test PLL sync on each FPGA
            status = self.test_PLL_sync(0) or self.test_PLL_sync(2)
            if status:
                raise RuntimeError('APS clocks failed to sync')
            
    def getFrequency(self, DAC):
        '''
        Helper function to get the current sampling rate for a DAC.
        '''
        return self.librarycall('Get SampleRate','APS_GetPllFreq',DAC)
        
    def setFrequency(self, ID, freq, testLock=1):
        #Check whether we actually need to change anything
        if self.getFrequency(ID) != freq:
            val = self.librarycall('Dac: %i Freq : %i' % (ID, freq), 'APS_SetPllFreq',ID,freq,testLock)
            if val: 
                print('Warning: APS::setFrequency returned: {0}'.format(val))

    def setupPLL(self):
        self.librarycall('Setup PLL', 'APS_SetupPLL')
        
    def setupVCX0(self):
        self.librarycall('Setup VCX0', 'APS_SetupVCXO')
    
    def setupDACs(self):
        self.librarycall('Setup DACs', 'APS_SetupDACs')
    
    def readAllRegisters(self, fpga):
        self.librarycall('Read Registers', 'APS_ReadAllRegisters', fpga)
        
    def testWaveformMemory(self, ID, numBytes):
        self.librarycall('Test WaveformMemory','APS_TestWaveformMemory',ID,numBytes)
        
    def readLinkListStatus(self,ID):
        return self.librarycall('Read Link List Status', 'APS_ReadLinkListStatus',ID)
        
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
        
    def test_PLL_sync(self, DACNum=0, numRetries=5):
        return self.librarycall('Test Pll Sync: DAC: {0}'.format(DACNum),'APS_TestPllSync', DACNum, numRetries)

    def read_PLL_status(self):
        #Read FPGA1
        val1 = self.librarycall('Read PLL Sync FPGA1','APS_ReadPllStatus', 1)
        #Read FPGA2
        val2 = self.librarycall('Read PLL Sync FPGA2','APS_ReadPllStatus', 2)
        # functions return 0 on success
        return val1 and val2
        
    def set_offset(self, ch, offset):
        return self.librarycall('Set channel offset','APS_SetChannelOffset', ch-1, offset*self.MAX_WAVEFORM_VALUE)
        
    def set_trigger_delay(self, ch, delay):
       return self.librarycall('Set channel trigger delay','APS_SetTriggerDelay', ch-1, delay)
        
    def load_sequence_file(self, filename, mode, channelNum=None):
        '''
        Load a complete 4 channel linklist file.close
        '''

        #Clear the old LinkList data
        for ct in range(4):
            self.clearLinkListELL(ct)
            
        #If we are in 4 channel mode then try and load the file for all four channels
        if mode == 0:        
            fileData = APSMatlabFile.APSMatlabFile(mode, filename)
            
            #Load the WF vectors and LLs into memory
            for ct,channelName in enumerate(self.CHANNELNAMES):
                tmpWF = fileData.get_vector(scale_factor=self.channelSettings[channelName]['amplitude'], offset=self.channelSettings[channelName]['offset'], channelName=channelName)
                self.loadWaveform(ct, tmpWF)

                bankA = fileData.LLData[channelName]['bankA']
                self.loadLinkListELL(ct, bankA['offset'], bankA['count'], bankA['trigger'], bankA['repeat'], bankA['length'], self.BANKA)  
                
                bankB = fileData.LLData[channelName]['bankB']
                if bankB['length'] > 0:
                    self.loadLinkListELL(ct, bankB['offset'], bankB['count'], bankB['trigger'], bankB['repeat'], bankB['length'], self.BANKB)
                    
                self.setLinkListRepeat(ct, fileData.LLData[channelName]['repeatCount'])
                            
        #Otherwise load the single channel file if it is specified
        else:
            if filename != '':
                fileData = APSMatlabFile.APSMatlabFile(mode, filename)
                channelName = self.CHANNELNAMES[channelNum]
                tmpWF = fileData.get_vector(scale_factor=self.channelSettings[channelName]['amplitude'], offset=self.channelSettings[channelName]['offset'])
                self.loadWaveform(channelNum, tmpWF)
        

    def init(self, force=False):
        '''
        A basic intialization of the APS unit following the Matlab driver.
        force determines whether to force a reload of the bitfile
        '''
        #Try to determine whether we need to program the bitfile
        curBitFileVer = self.readBitFileVersion()
        if (curBitFileVer != self.expected_bit_file_ver ) or (self.read_PLL_status()) or force:
            status = self.loadBitFile()
            print('Programmed {0} bytes.'.format(status))
            if status<0:
                raise RuntimeError('Failed to program FPGAs')
            
            # Default all channels to 1.2 GS/s
            self.setFrequency(0, 1200, testLock=0)
            self.setFrequency(2, 1200, testLock=0)
			
			# reset status/CTRL in case setFrequency screwed it up
			self.resetStatusCtrl()
            
            # Test PLL sync on each FPGA
            status = self.test_PLL_sync(0) or self.test_PLL_sync(2)
            if status:
                raise RuntimeError('APS failed to initialize')
        
			# align DAC data clock boundaries
			self.setupDACs()
			
            #Set all channel offsets to zero
            for ch in range(1,5):
                self.set_offset(ch, 0)
                
    def setAll(self, settings):
        '''
        Again mimicing the Matlab driver to load all the setttings from a dictionary.
        '''
        #First load all the channel offsets, scalings, enabled
        for channelName, tmpChan in self.channelSettings.items():
            for channelSetting in tmpChan.keys():
                self.channelSettings[channelName][channelSetting] = settings[channelName][channelSetting]
            
        
        #Now load the pulse sequence or waveform files
        if settings['fourChannelMode']:
            #Load the sequence file information
            self.load_sequence_file(settings['chAll']['seqfile'], 0)
            for ct in range(4):
                self.setLinkListMode(ct, self.LL_ENABLE, settings['runMode'])
        else:
            for channelct, channelName in enumerate(self.CHANNELNAMES):
                if self.channelSettings[channelName]['enabled']:
                    self.load_sequence_file(self.channelSettings[channelName]['seqfile'], 1, channelct)
                
         # set frequency
        self.setFrequency(self.FPGA0, settings['frequency'])
        self.setFrequency(self.FPGA1, settings['frequency'])
        
        self.triggerSource = settings['triggerSource']


    def run(self):
        '''
        Set the trigger and start things going.
        '''

        #Sort out what we need to trigger
        triggerArray = np.zeros(4, dtype=np.bool)
        for ct, channelName in enumerate(self.CHANNELNAMES):
            triggerArray[ct] = self.channelSettings[channelName]['enabled']
        triggeredFPGA = [False,False]
                
        if np.all(triggerArray):
            triggeredFPGA[0] = True
            triggeredFPGA[1] = True
            self.triggerFpga(self.ALL_DACS,self.triggerSource)
        elif triggerArray[0] and triggerArray[1]:
            triggeredFPGA[0] = True
            self.triggerFpga(self.FPGA0,self.triggerSource)
        elif triggerArray[2] and triggerArray[3]:
            triggeredFPGA[1] = True
            self.triggerFpga(self.FPGA1,self.triggerSource)
    
        #Look at individual channels.  Matlab file claims: % NOTE: Poorly defined syncronization between channels in this case
        for chan in range(0,4):
            if not triggeredFPGA[chan // 2] and triggerArray[chan]:
                self.triggerWaveform(chan,self.triggerSource)

    def stop(self):
        ''' Stop everything '''
        self.disableFpga(self.ALL_DACS)
	
	def resetStatusCtrl(self):
		self.librarycall('Reset status/ctrl', 'APS_ResetStatusCtrl')
        
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