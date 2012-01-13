#!/usr/bin/python

import sys
import os.path
import pdb

from PySide.QtCore import *
from PySide.QtGui import *

from APS_ui import Ui_Dialog

from APSMatlabFile import APSMatlabFile

import aps

libPath = '../../../common/src/+deviceDrivers/@APS/lib/'

class APScontrol(QDialog, Ui_Dialog):
    def __init__(self, parent=None):
        super(APScontrol, self).__init__(parent)
        self.setupUi(self)

        # connect UI element to signals
        self.bitFileOpen.clicked.connect(self.bitFileDialog)
        self.programButton.clicked.connect(self.programFPGA)
        self.runButton.clicked.connect(self.run)
        self.stopButton.clicked.connect(self.stop)

        self.ch1fileOpen.clicked.connect(self.waveformDialog1)
        self.ch2fileOpen.clicked.connect(self.waveformDialog2)
        self.ch3fileOpen.clicked.connect(self.waveformDialog3)
        self.ch4fileOpen.clicked.connect(self.waveformDialog4)

        # set default scale factor / offset values
        for i in range(1,5):
            self.setScaleFactor(i,1.0)
            self.setOffset(i,0)

        self.aps = aps.APS(libPath)

        self.bitFileName.setText(self.aps.getDefaultBitFileName())
        self.connect()
        
    def connect(self):
        # connect to APS
        numAPS = self.aps.enumerate()
        self.printMessage('Found %i APS units' % numAPS)
        
        # todo edit drop unit drop down to increase number of available units
        
        self.printMessage('Opening connection to APS 0')
        self.aps.connect(0)
        self.updateFirmwareVersion(self.aps.readBitFileVersion())
        

    def printMessage(self, message):
        self.messageLog.append(message)

    def bitFileDialog(self):
        fileName, fileFilter = QFileDialog.getOpenFileName(self, 'Open File', '', 'Bit files (*.bit)')
        self.bitFileName.setText(fileName)

    def waveformDialog1(self):
        self.waveformDialog(1)
        
    def waveformDialog2(self):
        self.waveformDialog(2)
        
    def waveformDialog3(self):
        self.waveformDialog(3)
        
    def waveformDialog4(self):
        self.waveformDialog(4)

    def waveformDialog(self,channel):
        # todo: error file channel number
        if (channel < 1) or (channel > 4):
            print "Error ==> unknown channel", channel
            return

        fileName, fileFilter = QFileDialog.getOpenFileName(self, 'Open File', '', 'Matlab Files (*.mat);;Waveform files (*.m);;Sequence files (*.seq)')
        cmd = 'self.ch%ifile.setText(fileName)' % channel
        exec(cmd)
        
    def programFPGA(self):
        # check that file exists
        if not os.path.isfile(self.bitFileName.text()):
            self.printMessage("Error file not found: %s" % self.bitFileName.text() )
            return
        
        # load the file
        self.printMessage('Programming FPGA bitfile.')
        self.aps.loadBitFile(self.bitFileName.text())
        self.printMessage("Loaded firmware version %i" % self.aps.readBitFileVersion())
        self.updateFirmwareVersion(self.aps.readBitFileVersion())

    def updateFirmwareVersion(self, version):
        self.bitFileVersion.setText("Firmware version: %i" % version)

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
            cmd = 'trigger[chan-1] = self.ch%ienable.isChecked()' % chan
            exec(cmd)
            if trigger[chan - 1]:
                        
                # load file
                fileData = APSMatlabFile()
                
                # prefer to use following two lines but this is not
                # working in python 3
                #cmd = 'filename = self.ch%ifile.text()' % chan
                #exec(cmd)
                
                if chan == 1:
                    filename = self.ch1file.text()
                elif chan == 2:
                    filename = self.ch2file.text()
                elif chan == 3:
                    filename = self.ch3file.text()
                elif chan == 4:
                    filename = self.ch4file.text()
                
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
            cmd = 'self.ch%iscale.setText(value)' % channel
            exec(cmd)
        else:
            print 'Unknown channel', channel
            
    def setOffset(self,channel,value):
        value = '%.2f' % value
        if channel in range(1,5):
            cmd = 'self.ch%ioffset.setText(value)'% channel
            exec(cmd)
        else:
            print 'Unknown channel', channel
        
if __name__ == '__main__':
    # create the Qt application
    app = QApplication(sys.argv)
    frame = APScontrol()
    frame.show()
    sys.exit(app.exec_())
