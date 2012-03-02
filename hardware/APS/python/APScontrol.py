#!/usr/bin/python

import sys
import os.path

from PySide import QtGui, QtCore, QtUiTools

import APS

libPath = '../../../common/src/+deviceDrivers/@APS/lib/'

class LoadBitFileRunner(QtCore.QThread):

    messageSignal = QtCore.Signal(str)
    
    def __init__(self, bitFileName, aps, apsNum):
        super(LoadBitFileRunner, self).__init__()
        self.bitFileName = bitFileName
        self.aps = aps
        self.apsNum = apsNum

    #Overwrite the destructor to make sure it doesn't get GC'd before it is finished
    def __del__(self):
        self.wait()
        
    def run(self):
        self.messageSignal.emit('Programming FPGA bitfile....')
        self.aps.connect(self.apsNum)
        self.aps.loadBitFile(self.bitFileName)
        self.messageSignal.emit('Loaded firmware version {0}'.format(self.aps.readBitFileVersion()))
        self.aps.disconnect()
   
class APScontrol(object):
    _bitFileName = ''
    def __init__(self):

        #Dynamically load the ui file
        loader = QtUiTools.QUiLoader()
        file = QtCore.QFile(os.path.join(os.path.dirname(sys.argv[0]), 'APS.ui'))
        file.open(QtCore.QFile.ReadOnly)
        self.ui = loader.load(file)
        file.close()

        #Connect UI element to signals
        self.ui.runButton.clicked.connect(self.run)
        self.ui.stopButton.clicked.connect(self.stop)

        self.ui.ch1fileOpen.clicked.connect(lambda : self.waveformDialog(self.ui.ch1file))
        self.ui.ch2fileOpen.clicked.connect(lambda : self.waveformDialog(self.ui.ch2file))
        self.ui.ch3fileOpen.clicked.connect(lambda : self.waveformDialog(self.ui.ch3file))
        self.ui.ch4fileOpen.clicked.connect(lambda : self.waveformDialog(self.ui.ch4file))
        self.ui.chAllfileOpen.clicked.connect(lambda : self.waveformDialog(self.ui.chAllfile))
        
        self.ui.chAllOnOff.toggled.connect(self.update_channel_enablers)
        
        self.ui.actionLoad_Bit_File.triggered.connect(self.bitFileDialog)
        self.ui.actionTest_PLL_Sync.triggered.connect(self.test_PLL_sync)
        
        #Set some validators for the scale factor / offset values so we don't have to error check later
        for channelct in range(1,5):
            #First the scale to anything
            tmpLineEdit = getattr(self.ui, 'ch{0}scale'.format(channelct))
            tmpLineEdit.setValidator(QtGui.QDoubleValidator())
            
            #Then the offset to +/-1 because it is of the full scale
            tmpLineEdit = getattr(self.ui, 'ch{0}offset'.format(channelct))
            tmpLineEdit.setValidator(QtGui.QDoubleValidator())
            tmpLineEdit.validator().setRange(-1,1,4)
            
        #Create an APS class instance for interacting with the instrument
        self.aps = APS.APS(libPath)

        
        #Enumerate the number of connected APS devices and fill out the combo box
        (numAPS, deviceSerials) = self.aps.enumerate()
        self.printMessage('Found {0} APS units'.format(numAPS))
        
        #Fill out the device ID combo box
        self.ui.deviceIDComboBox.clear()
        if numAPS > 0:
            self.ui.deviceIDComboBox.insertItems(0,['{0} ({1})'.format(num, deviceSerials[num]) for num in range(numAPS)])
            self._bitfilename = self.aps.getDefaultBitFileName()

        self.ui.show()
        
    def connect(self):
        #Connect to the specified APS
        apsNum = self.ui.deviceIDComboBox.currentIndex()
        self.printMessage('Opening connection to APS {0}'.format(apsNum))
        self.aps.connect(apsNum)
        self.printMessage("Firmware version: {0}".format(self.aps.readBitFileVersion()))
        
    def printMessage(self, message):
        self.ui.messageLog.append(message)
    
    #A slot to recieve log messages from threads.
    @QtCore.Slot(str)
    def printFromThread(self, message):
        self.printMessage(message)

    def bitFileDialog(self):
        #Launch a dialog to poll the user for the file name       
        self._bitFileName = QtGui.QFileDialog.getOpenFileName(self.ui, 'Open File', '', 'Bit files (*.bit)')[0]
        #Check that file exists
        if not os.path.isfile(self._bitFileName):
            self.printMessage("Error bitfile not found: %s" % self.bitFileName.text() )
            return
        #If it does then create a thread (loading the bit file takes a few seconds)
        #Have to keep a reference around otherwise it gets deleted to early        
        self.bitFileLoader = LoadBitFileRunner(self._bitFileName, self.aps, self.ui.deviceIDComboBox.currentIndex())
        self.bitFileLoader.messageSignal.connect(self.printFromThread)
        #Disable the run button while we are programming        
        self.ui.runButton.setEnabled(0)
        self.bitFileLoader.finished.connect(lambda : self.ui.runButton.setEnabled(1))
        self.bitFileLoader.start()
        print('Started thread...')
        
    def waveformDialog(self, textBox):
        fileName, fileFilter = QtGui.QFileDialog.getOpenFileName(self.ui, 'Open File', '', 'Matlab Files (*.mat);;Waveform files (*.m);;Sequence files (*.seq)')
        textBox.setText(fileName)
        
      
    def update_channel_enablers(self):
        '''
        Update the single channel entries based on whether 4-channel mode is activiated.
        '''
        fourChanMode = self.ui.chAllOnOff.isChecked()
        for ct in range(1,5):
            getattr(self.ui,'ch{0}file'.format(ct)).setEnabled(not fourChanMode)
        self.ui.chAllfile.setEnabled(fourChanMode)
            
        
    def run(self):
        self.ui.runButton.setEnabled(0)
        self.ui.stopButton.setEnabled(1)

        #Pull the settings from the gui
        settings = {}
        
        #Sampling frequency frequencies
        settings['frequency'] = self.aps.VALID_FREQUENCIES[self.ui.sampleRate.currentIndex()];
        self.printMessage('Set frequency to {0}'.format(settings['frequency']))

        #Get the run mode
        if self.ui.sequencerMode.currentIndex() == 0:
            self.printMessage('Continous Mode')
            settings['runMode'] = self.aps.LL_CONTINUOUS
        else:
            self.printMessage('One Shot Mode')
            settings['runMode'] = self.aps.LL_ONESHOT
        

        #Check to see how to trigger
        if self.ui.triggerType.currentIndex() == 0:  # Internal (aka Software Trigger)
            settings['triggerSource'] = self.aps.TRIGGER_SOFTWARE
            self.printMessage('Sofware trigger.')
        else: # External (aka Software Trigger):
            self.printMessage('Hardware trigger.')
            settings['triggerSource'] = self.aps.TRIGGER_HARDWARE
        
        
        #Get the four channel mode stuff
        settings['fourChannelMode'] = bool(self.ui.chAllOnOff.isChecked())
        if settings['fourChannelMode']:
            settings['chAll'] = {}
            settings['chAll']['seqfile'] = self.ui.chAllfile.text()

        #Pull out specific channel properties
        for ct,channelName in enumerate(self.aps.CHANNELNAMES):
            settings[channelName] = {}
            settings[channelName]['amplitude'] = float(getattr(self.ui,'ch{0}scale'.format(ct+1)).text())
            settings[channelName]['offset'] = float(getattr(self.ui,'ch{0}offset'.format(ct+1)).text())
            settings[channelName]['enabled'] = bool(getattr(self.ui,'ch{0}enable'.format(ct+1)).isChecked())
            settings[channelName]['seqfile'] = getattr(self.ui,'ch{0}file'.format(ct+1)).text()
            #Do a check whether the file exists
            if (not settings['fourChannelMode']) and settings[channelName]['enabled'] and (not os.path.isfile(settings[channelName]['seqfile'])):
                QtGui.QMessageBox.warning(self.ui, 'Oops!', 'Channel {0} is enabled with a non-existent file.'.format(ct+1))
                self.stop()
                raise
            
        try:
            self.connect()
            self.aps.init()
            self.aps.setAll(settings)
            self.aps.run()
            self.printMessage('Running')
        except:
            self.printMessage('WARNING: Could not get APS running!')
            self.stop()
            raise
        
   
    def stop(self):
        self.ui.stopButton.setEnabled(0)
        self.ui.runButton.setEnabled(1)
        
        self.aps.stop()
        self.aps.disconnect()
        self.printMessage('Stopped')
    
            
    def setScaleFactor(self,channel,value):
        value = '%.2f' % value
        if channel in range(1,5):
            textBox = getattr(self, 'ch%iscale' % channel)
            textBox.setText(value)
        else:
            print 'Unknown channel', channel
            
    def setOffset(self,channel,value):
        value = '%.2f' % value
        if channel in range(1,5):
            textBox = getattr(self, 'ch%ioffset' % channel)
            textBox.setText(value)
        else:
            print 'Unknown channel', channel
            
    def test_PLL_sync(self):
        self.connect()
        status = self.aps.test_PLL_sync(0)
        self.printMessage('PLL Sync Test for DAC {0} returned {1}'.format(0, status))
        status = self.aps.test_PLL_sync(2)
        self.printMessage('PLL Sync Test for DAC {0} returned {1}'.format(2, status))
        self.aps.disconnect()
        
if __name__ == '__main__':
    # create the Qt application
    app = QtGui.QApplication(sys.argv)
    frame = APScontrol()
    sys.exit(app.exec_())
