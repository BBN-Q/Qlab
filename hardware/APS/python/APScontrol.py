#!/usr/bin/python

import sys
import os.path

from PySide import QtGui, QtCore, QtUiTools

import APS


class ThreadSignals(QtCore.QObject):
    message = QtCore.Signal(str)
    finished = QtCore.Signal()

class LoadBitFileRunner(QtCore.QRunnable):

    def __init__(self, bitFileName, aps, apsNum):
        super(LoadBitFileRunner, self).__init__()
        self.bitFileName = bitFileName
        self.aps = aps
        self.apsNum = apsNum
        self.signals = ThreadSignals()

    def run(self):
        self.signals.message.emit('Programming FPGA bitfile....')
        self.aps.connect(self.apsNum)
        self.aps.init(True, self.bitFileName)
        self.signals.message.emit('Loaded firmware version {0}'.format(self.aps.readBitFileVersion()))
        self.aps.disconnect()
        self.signals.finished.emit()
        
class PLLSyncTestRunner(QtCore.QRunnable):
    def __init__(self, aps, apsNum):
        super(PLLSyncTestRunner, self).__init__()
        self.aps = aps
        self.apsNum = apsNum
        self.signals = ThreadSignals()
        
    def run(self):
        self.signals.message.emit('Testing the PLL sync....')
        self.aps.connect(self.apsNum)
        self.signals.message.emit('PLL Sync Test for DAC {0} returned {1}'.format(0, self.aps.test_PLL_sync(0)))
        self.signals.message.emit('PLL Sync Test for DAC {0} returned {1}'.format(2, self.aps.test_PLL_sync(2)))
        self.aps.disconnect()
        self.signals.finished.emit()

class APSRunner(QtCore.QRunnable):
    def __init__(self, aps, apsNum, settings):
        super(APSRunner, self).__init__()
        self.aps = aps
        self.apsNum = apsNum
        self.settings = settings
        self.signals = ThreadSignals()
        
    def run(self):
        try:
            self.aps.connect(self.apsNum)
            self.signals.message.emit('Initializing APS...')            
            self.aps.init()
            self.signals.message.emit('Finished Initalization')            
            self.aps.setAll(self.settings)
            self.signals.message.emit('Finished SetAll')
            self.aps.run()
            self.signals.message.emit('Running.')

        except:
            self.signals.message.emit('WARNING: Could not get APS running!')

        
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
        self.aps = APS.APS()

        #Enumerate the number of connected APS devices and fill out the combo box
        (numAPS, deviceSerials) = self.aps.enumerate()
        self.printMessage('Found {0} APS units'.format(numAPS))
        
        #Fill out the device ID combo box
        self.ui.deviceIDComboBox.clear()
        if numAPS > 0:
            self.ui.deviceIDComboBox.insertItems(0,['{0} ({1})'.format(num, deviceSerials[num]) for num in range(numAPS)])
            self._bitfilename = self.aps.getDefaultBitFileName()

        #Create a reference to the global thread pool
        self.threadPool = QtCore.QThreadPool.globalInstance()

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
        #Have to keep a reference around otherwise it gets deleted too early        
        bitFileLoader = LoadBitFileRunner(self._bitFileName, self.aps, self.ui.deviceIDComboBox.currentIndex())
        bitFileLoader.signals.message.connect(self.printFromThread)
        #Disable the run button while we are programming        
        self.ui.runButton.setEnabled(False)
        bitFileLoader.signals.finished.connect(lambda : self.ui.runButton.setEnabled(True))
        self.threadPool.start(bitFileLoader)
        
    def test_PLL_sync(self):
        #Start a background thread for testing the PLL sync
        PLLTester = PLLSyncTestRunner(self.aps, self.ui.deviceIDComboBox.currentIndex())
        PLLTester.signals.message.connect(self.printFromThread)
        #Disable the run button while we are programming        
        self.ui.runButton.setEnabled(False)
        PLLTester.signals.finished.connect(lambda : self.ui.runButton.setEnabled(True))
        self.threadPool.start(PLLTester)
                
    def waveformDialog(self, textBox):
        fileName, fileFilter = QtGui.QFileDialog.getOpenFileName(self.ui, 'Open File', '', 'HDF5 Files (*.h5);;Matlab Files (*.mat)')
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
        #Pull the settings from the gui
        settings = {}
        
        #Sampling frequency frequencies
        settings['frequency'] = self.aps.VALID_FREQUENCIES[self.ui.sampleRate.currentIndex()];
        self.printMessage('Set frequency to {0}'.format(settings['frequency']))

        #Get the run mode
        if self.ui.sequencerMode.currentIndex() == 0:
            self.printMessage('Waveform Mode')
            settings['runMode'] = self.aps.RUN_WAVEFORM
        else:
            self.printMessage('Sequence Mode')
            settings['runMode'] = self.aps.RUN_SEQUENCE

        #Check to see how to trigger
        if self.ui.triggerType.currentIndex() == 0:  # Internal 
            settings['triggerSource'] = 'internal'
            self.printMessage('Internal trigger.')
        else: # External:
            self.printMessage('External trigger.')
            settings['triggerSource'] = 'external'

        # get trigger interval (only if internally triggered)
        settings['triggerInterval'] = float(self.ui.triggerInterval.text())
        if settings['triggerSource'] == 'internal':
            self.printMessage('Setting trigger interval to {0}'.format(settings['triggerInterval']))
        
        #Get the four channel mode stuff
        settings['fourChannelMode'] = bool(self.ui.chAllOnOff.isChecked())
        if settings['fourChannelMode']:
            settings['chAll'] = {}
            settings['chAll']['seqfile'] = self.ui.chAllfile.text()

        #Pull out specific channel properties
        CHANNELNAMES = ('chan_1','chan_2','chan_3','chan_4')
        for ct,channelName in enumerate(CHANNELNAMES):
            settings[channelName] = {}
            settings[channelName]['amplitude'] = float(getattr(self.ui,'ch{0}scale'.format(ct+1)).text())
            settings[channelName]['offset'] = float(getattr(self.ui,'ch{0}offset'.format(ct+1)).text())
            settings[channelName]['enabled'] = bool(getattr(self.ui,'ch{0}enable'.format(ct+1)).isChecked())
            if not settings['fourChannelMode']:
                settings[channelName]['seqfile'] = getattr(self.ui,'ch{0}file'.format(ct+1)).text()
            #Do a check whether the file exists
            if (not settings['fourChannelMode']) and settings[channelName]['enabled'] and (not os.path.isfile(settings[channelName]['seqfile'])):
                QtGui.QMessageBox.warning(self.ui, 'Oops!', 'Channel {0} is enabled with a non-existent file.'.format(ct+1))
                self.stop()
                raise

        #Disable buttons we don't want while running
        self.ui.runButton.setEnabled(False)
        self.ui.stopButton.setEnabled(True)
        self.ui.actionLoad_Bit_File.setEnabled(False)
        self.ui.actionTest_PLL_Sync.setEnabled(False)        

        #Do the slow work (loading large sequences) lifting in another thread
        tmpAPSRunner = APSRunner(self.aps, self.ui.deviceIDComboBox.currentIndex(), settings )        
        tmpAPSRunner.signals.message.connect(self.printFromThread)        
        self.threadPool.start(tmpAPSRunner)        
        
    def stop(self):
        self.ui.stopButton.setEnabled(False)
        self.ui.runButton.setEnabled(True)
        self.ui.actionLoad_Bit_File.setEnabled(True)
        self.ui.actionTest_PLL_Sync.setEnabled(True)        
        self.aps.stop()
        self.aps.disconnect()
        self.printMessage('Stopped')
    
        
if __name__ == '__main__':
    # create the Qt application
    app = QtGui.QApplication(sys.argv)
    frame = APScontrol()
    sys.exit(app.exec_())
