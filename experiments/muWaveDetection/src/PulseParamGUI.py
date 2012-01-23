#!/usr/bin/python

import sys
import os.path
import json

from PySide.QtCore import *
from PySide.QtGui import *

from PulseParam_ui import Ui_Dialog

class PulseParamGUI(QDialog, Ui_Dialog):
    _paramPath = '../cfg/example-json.txt'
    _params = {}
    _emptyQubitParams = {'piAmp': 0, 'pi2Amp': 0, 'sigma': 0, 'delta': 0, 'pulseLength': 0, 'pulseType': 'drag'}
    _emptyChannelParams = {'bufferPadding': 0, 'bufferReset': 0, 'bufferDelay': 0, 'offset': 0, 'delay': 0, 'T': [[1,0],[0,1]]}
    _currentQubit = ''
    _currentChannel = ''
    
    def __init__(self, parent=None):
        super(PulseParamGUI, self).__init__(parent)
        self.setupUi(self)

        # connect UI element to signals
        self.updateButton.clicked.connect(self.writeParameters)
        self.refreshButton.clicked.connect(self.refreshParameters)
        self.qubitComboBox.activated.connect(self.updateQubitParameters)
        self.channelComboBox.activated.connect(self.updateChannelParameters)
        
        self.loadParameters()
        self.updateQubitParameters(0, False)
        self.updateChannelParameters(0, False)
    
    def loadParameters(self):
        f = open(self._paramPath, 'r')
        self._params = json.loads(f.read())
        f.close()
    
    def refreshParameters(self):
        self.loadParameters()
        self.updateQubitParameters(saveBeforeSwitch=False)
        self.updateChannelParameters(saveBeforeSwitch=False)
    
    def updateQubitParameters(self, index=0, saveBeforeSwitch=True):
        # save parameters
        if saveBeforeSwitch:
            self.saveQubitParameters()
        
        # update GUI with parameters for newly selected channel
        qubit = self.qubitComboBox.currentText()
        if qubit not in self._params.keys():
            self._params[qubit] = self._emptyQubitParams
        self.piAmp.setText(str(self._params[qubit]['piAmp']))
        self.pi2Amp.setText(str(self._params[qubit]['pi2Amp']))
        self.sigma.setText(str(self._params[qubit]['sigma']))
        self.delta.setText(str(self._params[qubit]['delta']))
        self.pulseLength.setText(str(self._params[qubit]['pulseLength']))
        self.pulseType.setText(self._params[qubit]['pulseType'])
        self._currentQubit = qubit
    
    def updateChannelParameters(self, index=0, saveBeforeSwitch=True):
        # save parameters
        if saveBeforeSwitch:
            self.saveChannelParameters()
        
        # update GUI with parameters for newly selected channel
        channel = self.channelComboBox.currentText()
        if channel not in self._params.keys():
            self._params[channel] = self._emptyChannelParams
        self.bufferPadding.setText(str(self._params[channel]['bufferPadding']))
        self.bufferReset.setText(str(self._params[channel]['bufferReset']))
        self.bufferDelay.setText(str(self._params[channel]['bufferDelay']))
        self.offset.setText(str(self._params[channel]['offset']))
        self.delay.setText(str(self._params[channel]['delay']))
        self.T.setText(str(self._params[channel]['T']))
        self._currentChannel = channel

    def saveQubitParameters(self):
        qubit  = self._currentQubit
        self._params[qubit]['piAmp'] = int(self.piAmp.text())
        self._params[qubit]['pi2Amp'] = int(self.pi2Amp.text())
        self._params[qubit]['delta'] = float(self.delta.text())
        self._params[qubit]['sigma'] = int(self.sigma.text())
        self._params[qubit]['pulseLength'] = int(self.pulseLength.text())
        self._params[qubit]['pulseType'] = self.pulseType.text()
        
    def saveChannelParameters(self):
        channel = self._currentChannel
        self._params[channel]['bufferPadding'] = int(self.bufferPadding.text())
        self._params[channel]['bufferReset'] = int(self.bufferReset.text())
        self._params[channel]['bufferDelay'] = int(self.bufferDelay.text())
        self._params[channel]['offset'] = int(self.offset.text())
        self._params[channel]['delay'] = int(self.delay.text())
        self._params[channel]['T'] = eval(self.T.text())
        
    def writeParameters(self):
        self.saveQubitParameters()
        self.saveChannelParameters()
        f = open(self._paramPath, 'w')
        f.write(json.dumps(self._params, indent=1))
        f.close()

if __name__ == '__main__':
    # create the Qt application
    app = QApplication(sys.argv)
    frame = PulseParamGUI()
    frame.show()
    sys.exit(app.exec_())