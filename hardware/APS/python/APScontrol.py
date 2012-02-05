#!/usr/bin/python

import sys
import os.path

from PySide import QtGui, QtCore, QtUiTools

from APSMatlabFile import APSMatlabFile

import aps

libPath = '../../../common/src/+deviceDrivers/@APS/lib/'

class APScontrol(object):
    _bitFileName = ''
    def __init__(self, parent=None):

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
        
        self.ui.actionLoad_Bit_File.triggered.connect(self.bitFileDialog)

        #Set some validators for the scale factor / offset values so we don't have to error check later
        for channelct in range(1,5):
            #First the scale to anything
            tmpLineEdit = getattr(self.ui, 'ch{0}scale'.format(channelct))
            tmpLineEdit.setValidator(QtGui.QDoubleValidator())
            
            #Then the offset to +/-1 because it is of the full scale
            tmpLineEdit = getattr(self.ui, 'ch{0}offset'.format(channelct))
            tmpLineEdit.setValidator(QtGui.QDoubleValidator())
            tmpLineEdit.validator().setRange(-1,1)
            
        #Create an APS class instance for interacting with the instrument
        self.aps = aps.APS(libPath)
        
        #Enumerate the number of connected APS devices and fill out the combo box
        (numAPS, deviceSerials) = self.aps.enumerate()
        self.printMessage('Found {0} APS units'.format(numAPS))
        
        #Fill out the device ID combo box
        self.ui.deviceIDComboBox.clear()
        self.ui.deviceIDComboBox.insertItems(0,['{0} ({1})'.format(num, deviceSerials[num]) for num in range(numAPS)])
        
        #Try to connect to the device
        self.connect()
        
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

    def bitFileDialog(self):
        self._bitFileName = QtGui.QFileDialog.getOpenFileName(self.ui, 'Open File', '', 'Bit files (*.bit)')[0]
        self.programFPGA()
        
    def waveformDialog(self, textBox):
        fileName, fileFilter = QtGui.QFileDialog.getOpenFileName(self.ui, 'Open File', '', 'Matlab Files (*.mat);;Waveform files (*.m);;Sequence files (*.seq)')
        textBox.setText(fileName)
        
    def programFPGA(self):
        #Check that file exists
        if not os.path.isfile(self._bitFileName):
            self.printMessage("Error bitfile not found: %s" % self.bitFileName.text() )
            return
        
        #Load the file
        self.printMessage('Programming FPGA bitfile.')
        self.aps.loadBitFile(self._bitFileName)
        self.printMessage("Loaded firmware version %i" % self.aps.readBitFileVersion())

    def run(self):
        self.runButton.setEnabled(0)
        self.stopButton.setEnabled(1)

        # check frequencies
        validFreqs = self.aps.VALID_FREQUENCIES;
        frequency = validFreqs[self.sampleRate.currentIndex()];
        
        # set frequency
        self.aps.setFrequency(self.aps.FPGA0, frequency)
        self.aps.setFrequency(self.aps.FPGA1, frequency)
        self.printMessage('Set frequency to %i' % frequency)
        
        # get mode
        if self.sequencerMode.currentIndex() == 0:
            self.printMessage('Continous Mode')
            mode = self.aps.LL_CONTINUOUS
        else:
            self.printMessage('One Shot Mode')
            mode = self.aps.LL_ONESHOT
        
        # check to see how to trigger
        
        trigger_type = self.triggerType.currentIndex();
        if trigger_type == 0:  # Internal (aka Software Trigger)
            trigger_type = self.aps.TRIGGER_SOFTWARE
        else: # External (aka Software Trigger)
            trigger_type = self.aps.TRIGGER_HARDWARE
        
        trigger = [0,0,0,0];
        allTrigger = True
        triggeredFPGA = [False,False]
                
        for chan in range(1,5):
            checkBox = getattr(self, 'ch%ienable' % chan)
            trigger[chan-1] = checkBox.isChecked()
            if trigger[chan - 1]:
                        
                # load file
                fileData = APSMatlabFile()
                
                fileTextBox = getattr(self, 'ch%ifile' % chan)
                filename = fileTextBox.text()
                
                self.printMessage('Loading file %s' % filename)
                fileData.readFile(filename)
                data = fileData.get_vector()
                
                # clear existing APS LL data
                self.aps.clearLinkListELL(chan - 1)
                
                self.printMessage('Sending waveform to APS')
                self.aps.loadWaveform(chan - 1, data)
                
                if fileData.isLinkList:
                    # need to load link list data
                    if fileData.bankA:
                        bA = fileData.bankA
                        self.printMessage('Loading Bank A')
                        self.aps.loadLinkListELL(chan - 1, bA['offset'], bA['count'],
                                                 bA['trigger'], bA['repeat'], bA['length'],
                                                 self.aps.BANKA)
                    
                    if fileData.bankB:
                        bB = fileData.bankB
                        self.printMessage('Loading Bank B')
                        self.aps.loadLinkListELL(chan - 1, bA['offset'], bA['count'],
                                                 bA['trigger'], bA['repeat'], bA['length'],
                                                 self.aps.BANKB)
                        
                    self.printMessage('Set link list repeat and mode')
                    self.aps.setLinkListRepeat(chan - 1, fileData.repeatCount)
                    self.aps.setLinkListMode(chan - 1, self.aps.LL_ENABLE,mode)
                    
                
            allTrigger = allTrigger and trigger[chan - 1]

        if allTrigger:
            self.printMessage('Trigger All FPGAs')
            triggeredFPGA[0] = True
            triggeredFPGA[1] = True
            #self.aps.triggerFpga(self.aps.BOTH_FPGAS,trigger_type)
            self.aps.triggerFpga(self.aps.FPGA0,trigger_type)
            self.aps.triggerFpga(self.aps.FPGA1,trigger_type)
        elif trigger[0] and trigger[1]:
            triggeredFPGA[0] = True
            self.printMessage('Trigger FPGA 0')
            self.aps.triggerFpga(self.aps.FPGA0,trigger_type)
        elif trigger[2] and trigger[3]:
            triggeredFPGA[1] = True
            self.printMessage('Trigger FPGA 1')
            self.aps.triggerFpga(self.aps.FPGA1,trigger_type)
    
        for chan in range(0,4):
            if not triggeredFPGA[chan // 2] and trigger[chan]:
                self.printMessage('Trigger Channel %i' % (chan + 1))
                self.aps.triggerWaveform(chan,trigger_type)
                    
        self.printMessage('Running')

    def stop(self):
        self.stopButton.setEnabled(0)
        self.runButton.setEnabled(1)
        
        self.aps.disableFpga(0)
        self.aps.disableFpga(2)
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
        
if __name__ == '__main__':
    # create the Qt application
    app =QtGui.QApplication(sys.argv)
    frame = APScontrol()
    sys.exit(app.exec_())
