#!/usr/bin/env python

import ctypes
import platform
import sys
import os

import numpy as np
import h5py

class APS (object):
    # implements interface to libaps
    
    # class properties
    device_id = 0
    device_serial = ''

    expected_bit_file_ver = 0x10
    Address = 0

    is_open = False
    #bit_file_programmed = False
    
    # constants 
    RUN_SEQUENCE = 1
    RUN_WAVEFORM = 0
    
    CONTINUOUS = 0
    ONESHOT = 1
    
    TRIGGER_SOFTWARE = 1
    TRIGGER_HARDWARE = 2
    
    ALL_DACS = -1    
    VALID_FREQUENCIES = [1200,600,300,100,40]

    
    lastSeqFile = ''
    
    #DAC2 devices use a different bit file
    DAC2Serials = ('A6UQZB7Z', 'A6001nBU', 'A6001ixV', 'A6001nBT', 'A6001nBS')

    APS_ROOT = '/../'

    def __init__(self):
        #Load the approriate library with some platform/architecture checks
        #Check for 32bit 64bit python from sys.maxsize
        #We do this because we can run 32bit programs on 64bit architectures so
        #platform.achitecture() might give misleading results
        str64bit = '64' if sys.maxsize > 2147483647 else ''
        extDict = {'Windows':'.dll', 'Linux':'.so', 'Darwin':'.dylib'}        
        libName = 'libaps' + str64bit + extDict[platform.system()]
        
        scriptPath = os.path.dirname(os.path.realpath( __file__ ))
        self.APS_ROOT = scriptPath + self.APS_ROOT
        
        if str64bit == '64':
            libPath = self.APS_ROOT + 'libaps-cpp/build64/'
        else:
            libPath = self.APS_ROOT + 'libaps-cpp/build32/'
        
            
        print 'Loading', libPath  + libName
        #Add the library folder to the path so we can load all the dependencies
        os.environ['PATH'] += ';'+libPath
        self.lib = ctypes.cdll.LoadLibrary(libPath  + libName)
        # set up argtypes and restype for functions with arguments that aren't ints or strings
        self.lib.set_channel_scale.argtypes = [ctypes.c_int, ctypes.c_int, ctypes.c_float]
        self.lib.get_channel_scale.restype = ctypes.c_float
        self.lib.set_channel_offset.argtypes = [ctypes.c_int, ctypes.c_int, ctypes.c_float]
        self.lib.get_channel_offset.restype = ctypes.c_float

        # initialize DLL
        self.lib.init()
        
    
    def __del__(self):
        if self.is_open:
            self.disconnect()
        
    def enumerate(self):
        #List the number of devices attached and their serial numbers
        
        #First get the number of devices        
        numDevices = self.lib.get_numDevices()

        deviceSerials = []
        #Now, for each device, get the associated serial number
        charBuffer = ctypes.create_string_buffer(64)
        for ct in range(numDevices):
            self.lib.get_deviceSerial(ct,charBuffer)
            deviceSerials.append(charBuffer.value)

        return numDevices, deviceSerials
        
    def connect(self, address):
        # Experiment framework function for connecting to an APS
        if type(address) is int:
            self.open(address)
        else:
            self.openBySerialNum(address)
            
    def disconnect(self):
        self.lib.disconnect_by_ID(self.device_id)
        self.is_open = 0
        
    def open(self, ID):
        # populate list of device id's and serials
        numDevices, deviceSerials = self.enumerate()
        if ID + 1 > numDevices:
            print 'APS Device: ', ID, 'not found'
            return 2

        if self.is_open:
            if self.device_id != ID:
                self.disconnect()
            else:
                return 0

        self.device_id = ID
        self.device_serial = deviceSerials[ID]
        
        val = self.lib.connect_by_ID(self.device_id)
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
        ID = self.lib.serial2ID(serialNum);
        return self.open(ID)
        
    def readBitFileVersion(self):
        return self.librarycall('read_bitfile_version')

    def getDefaultBitFileName(self):
        #Check whether we have a DACII or APS device
        if self.device_serial in self.DAC2Serials:
            return os.path.abspath(self.APS_ROOT + 'bitfiles/mqco_dac2_latest.bit')
        else:
            return os.path.abspath(self.APS_ROOT + 'bitfiles/mqco_aps_latest.bit')        

    def init(self, force = False, filename = None):
        if not self.is_open:
            print 'APS unit is not open'
            return -1
        
        if filename is None:
            filename = self.getDefaultBitFileName()
        
        self.librarycall('initAPS', filename, force)
        
    def loadWaveform(self, ch, waveform):
        # inputs:
        # ch - integer (1-4)
        # waveform - assume nparray with dtype = int16 data in range (-8191, 8191) or dtype=float64 data in range (-1.0, 1.0)
        if not self.is_open:
            print 'APS unit is not open'
            return -1
            
        if waveform.dtype == np.dtype('int16') or waveform.dtype == np.dtype('int32'):
            waveform = waveform.astype('int16')
            c_int_p = ctypes.POINTER(ctypes.c_int16)
            waveform_p = waveform.ctypes.data_as(c_int_p) 
            val = self.librarycall('set_waveform_int', ch-1, waveform_p, waveform.size)
            
        elif waveform.dtype == np.dtype('float32') or waveform.dtype == np.dtype('float64'):
            # libaps-cpp expects float rather than double
            waveform = waveform.astype('float32')
            c_float_p = ctypes.POINTER(ctypes.c_float)
            waveform_p = waveform.ctypes.data_as(c_float_p)
            val = self.librarycall('set_waveform_float', ch-1, waveform_p, waveform.size)
        else:
            raise NameError('Unhandled waveform data type. Use int16 or float64')

        self.set_enabled(ch, True)

        if val < 0:
            print 'loadWaveform returned an error code of:', val
        return val
        
    def add_LL_bank(self, ch, offsets, counts, repeat, trigger, length):
        if not self.is_open:
            print 'APS unit is not open'
            return -1
        
        #TODO: we are assuming the arrays are contiguous should we check this?
        
        # convert each array to uint16 pointer
        c_uint16_p = ctypes.POINTER(ctypes.c_uint16)
        
        offsets = offsets.astype(np.uint16)
        offsets_p = offsets.ctypes.data_as(c_uint16_p)
        
        counts = counts.astype(np.uint16)
        counts_p = counts.ctypes.data_as(c_uint16_p)
        
        repeat = repeat.astype(np.uint16)
        repeat_p = repeat.ctypes.data_as(c_uint16_p)
        
        trigger = trigger.astype(np.uint16)
        trigger_p = trigger.ctypes.data_as(c_uint16_p)
        
        val = self.librarycall('add_LL_bank', ch-1, length, offsets_p, counts_p, repeat_p, trigger_p)
        
        if val < 0:
            print 'add_LL_bank returned an error code of:', val
        
    def librarycall(self, functionName,  *args):
        if not self.is_open:
            print 'APS unit is not open'
            return -1
        methodCall = getattr(self.lib, functionName)
        return methodCall(self.device_id, *args)
        
    def triggerFpga_debug(self, fpga, trigger_type):
        return self.librarycall('trigger_fpga_debug', fpga, trigger_type)
        
    def disableFpga_debug(self, fpga):                           
        return self.librarycall('disable_fpga_debug', fpga)

    def setRunMode(self, ch, mode):
        # ch : DAC channel (1-4)
        # mode : 1 = sequence, 0 = waveform
        self.librarycall('set_run_mode', ch-1, mode)

    def setRepeatMode(self, ch, mode):
        # ch : DAC channel (1-4)
        # mode : 1 = one-shot, 0 = continous
        self.librarycall('set_repeat_mode', ch-1, mode)
        
    def setLinkListRepeat(self, ID, repeat):
        # TODO
        pass
        #self.librarycall('Dac: %i Link List Repeat: %i' % (ID, repeat),
        #                       'APS_SetLinkListRepeat',repeat,ID)
    
    @property
    def samplingRate(self):
        return self.librarycall('get_sampleRate')
    
    @samplingRate.setter
    def samplingRate(self, freq):
        self.librarycall('set_sampleRate', freq)
    
    @property
    def triggerSource(self):
        valueMap = {self.TRIGGER_SOFTWARE: 'internal', self.TRIGGER_HARDWARE: 'external'}
        return valueMap[self.librarycall('get_trigger_source')]
    
    @triggerSource.setter
    def triggerSource(self, source):
        allowedValues = {'internal': self.TRIGGER_SOFTWARE, 'external': self.TRIGGER_HARDWARE}
        assert source in allowedValues, 'Unrecognized trigger source.'
        self.librarycall('set_trigger_source', allowedValues[source])
    
    def read_PLL_status(self):
        # TODO
        ##Read FPGA1
        #val1 = self.librarycall('Read PLL Sync FPGA1','APS_ReadPllStatus', 1)
        ##Read FPGA2
        #val2 = self.librarycall('Read PLL Sync FPGA2','APS_ReadPllStatus', 2)
        ## functions return 0 on success
        #return val1 and val2
        pass
        
    def set_offset(self, ch, offset):
        return self.librarycall('set_channel_offset', ch-1, offset)

    def set_amplitude(self, ch, amplitude):
        return self.librarycall('set_channel_scale', ch-1, amplitude)
    
    def set_enabled(self, ch, enabled):
        return self.librarycall('set_channel_enabled', ch-1, enabled)
        
    def set_trigger_delay(self, ch, delay):
        return self.librarycall('set_channel_trigDelay', ch-1, delay)
        
    def load_config(self, filename):
        '''
        Load a complete 4 channel configuration file
        '''

        #Pass through to C
        self.librarycall('load_sequence_file', str(filename));

    def load_waveform_from_file(self, ch, filename):
        '''
        Loads a single channel waveform from an HDF5 file
        Expects data in variable 'WFVec'
        '''
        with h5py.File(filename, 'r') as FID:
            self.loadWaveform(ch, FID['WFVec'].value)
                
    def setAll(self, settings):
        '''
        Again mimicing the Matlab driver to load all the settings from a dictionary.
        '''
        
        #First load all the channel offsets, scalings, enabled
        CHANNELNAMES = ('chan_1','chan_2','chan_3','chan_4')
        for ch, channelName in enumerate(CHANNELNAMES):
            self.set_amplitude(ch+1, settings[channelName]['amplitude'])
            self.set_offset(ch+1, settings[channelName]['offset'])
            self.set_enabled(ch+1, settings[channelName]['enabled'])
            self.setRepeatMode(ch+1, settings['repeatMode'])
            if 'seqfile' in settings[channelName] and settings[channelName]['seqfile']:
                self.load_waveform_from_file(ch+1, settings[channelName]['seqfile'])
       
        #Load the sequence file information
        if 'chAll' in settings and settings['chAll']['seqfile']:
            self.load_config(settings['chAll']['seqfile'])
        self.samplingRate = settings['frequency']
        self.triggerSource = settings['triggerSource']
 
    def run(self):
        '''
        Set the trigger and start things going.
        '''
        self.librarycall('run')

    def stop(self):
        ''' Stop everything '''
        self.librarycall('stop')
    
    def set_log_level(self, level):
        '''
        set logging level (info = 2, debug = 3, debug1 = 4, debug2 = 5)
        '''
        self.lib.set_logging_level(level)

        
    def unitTestBasic(self):
        self.connect(0)
        print "Initializing"
        self.init(False)
        print "Current Bit File Version: ", self.readBitFileVersion()
        
        wf = np.hstack((np.zeros((2000),dtype=np.float64), 0.7*np.ones((2000),dtype=np.float64)))
        
        for ct in range(4):
            self.loadWaveform(ct+1, wf)
            self.setRunMode(ct+1, self.RUN_WAVEFORM)
            self.set_amplitude(ct+1, 1.0)

        print 'Done with load Waveform'
        self.run()
        print 'Done with Trigger'
        raw_input("Press Enter to continue...")
        self.stop()
        
        self.samplingRate = 1200

        aps.load_config(self.APS_ROOT + '/libaps-cpp/UnitTest.h5');
        aps.triggerSource = 'external';
        self.run()
        raw_input("Press Enter to continue...")
        self.stop()
        self.disconnect();


if __name__ == '__main__':
    aps = APS()
    aps.unitTestBasic()