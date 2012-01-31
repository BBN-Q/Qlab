#!/usr/bin/python

from __future__ import division

import sys
import json
import os
import math
from copy import deepcopy

from optparse import OptionParser

from PySide import QtGui, QtUiTools, QtCore


class AddChannelDialog(QtGui.QDialog):
    def __init__(self, parent=None):
        super(AddChannelDialog, self).__init__(parent=parent)
        self.setWindowTitle('Add Channel')
        formLayout = QtGui.QFormLayout()
        self.nameLineEdit = QtGui.QLineEdit()
        self.typeComboBox = QtGui.QComboBox()
        self.typeComboBox.addItems(['qubit','physical'])
        formLayout.addRow('Channel Name:', self.nameLineEdit)
        formLayout.addRow('Channel Type:', self.typeComboBox)

        self.buttonBox = QtGui.QDialogButtonBox(QtGui.QDialogButtonBox.Ok  | QtGui.QDialogButtonBox.Cancel)
        self.buttonBox.accepted.connect(self.accept)
        self.buttonBox.rejected.connect(self.reject) 

        vbox = QtGui.QVBoxLayout()
        vbox.addLayout(formLayout)
        vbox.addWidget(self.buttonBox)
        
        self.setLayout(vbox)
        self.show()
        
class DeleteChannelDialog(QtGui.QDialog):
     def __init__(self, parent=None, channelNames=None):
        super(DeleteChannelDialog, self).__init__(parent=parent)
        self.setWindowTitle('Delete Channel')
        
        self.channelComboBox = QtGui.QComboBox()
        self.channelComboBox.addItems(channelNames)
        
        vbox = QtGui.QVBoxLayout()
        vbox.addWidget(self.channelComboBox)
        
        self.buttonBox = QtGui.QDialogButtonBox(QtGui.QDialogButtonBox.Ok  | QtGui.QDialogButtonBox.Cancel)
        self.buttonBox.accepted.connect(self.accept)
        self.buttonBox.rejected.connect(self.reject) 
        
        vbox.addWidget(self.buttonBox)
        
        self.setLayout(vbox)
        self.show()
   
    
class PulseParamGUI(object):
    _paramPath = ''
    _params = {}
    _emptyQubitParams = {'channelType':'logical', 'piAmp': 0, 'pi2Amp': 0, 'sigma': 0, 'delta': 0, 'pulseLength': 0, 'pulseType': 'drag', 'buffer': 4}
    _emptyChannelParams = {'channelType':'physical', 'bufferPadding': 0, 'bufferReset': 0, 'bufferDelay': 0, 'offset': 0, 'delay': 0, 'T': [[1,0],[0,1]], 'passThru': 1}
    _currentQubit = None
    _currentChannel = None
    
    def __init__(self, fileName=None):

        #It seems there should be some nicer way to do this so that we could still subclass QMainWindow
        loader = QtUiTools.QUiLoader()
        file = QtCore.QFile('pulseParamGUI.ui')
        file.open(QtCore.QFile.ReadOnly)
        self.ui = loader.load(file)
        file.close()
        
        #Set some validators to help ensure we don't get bogus input
        self.ui.piAmp.setValidator(QtGui.QDoubleValidator())
        self.ui.pi2Amp.setValidator(QtGui.QDoubleValidator())
        self.ui.pulseLength.setValidator(QtGui.QIntValidator())
        self.ui.sigma.setValidator(QtGui.QIntValidator())
        self.ui.delta.setValidator(QtGui.QDoubleValidator())
        self.ui.buffer.setValidator(QtGui.QIntValidator())

        self.ui.bufferPadding.setValidator(QtGui.QIntValidator())
        self.ui.bufferReset.setValidator(QtGui.QIntValidator())
        self.ui.bufferDelay.setValidator(QtGui.QIntValidator())
        self.ui.offset.setValidator(QtGui.QIntValidator())
        self.ui.piAmp.setValidator(QtGui.QIntValidator())
        self.ui.ampFactor.setValidator(QtGui.QDoubleValidator())
        self.ui.phaseSkew.setValidator(QtGui.QDoubleValidator())
    

        # connect UI element to signals
        self.ui.updateButton.clicked.connect(self.writeParameters)
        self.ui.refreshButton.clicked.connect(self.refreshParameters)
        self.ui.qubitComboBox.activated.connect(self.updateQubitParameters)
        self.ui.channelComboBox.activated.connect(self.updateChannelParameters)
        
        #Connect menu actions
        self.ui.actionLoad_Cfg_File.triggered.connect(self.load_cfg_file)
        self.ui.actionSave_As.triggered.connect(self.save_as_cfg_file)
        self.ui.actionAdd_Channel.triggered.connect(self.add_channel)
        self.ui.actionDelete_Channel.triggered.connect(self.delete_channel)
        
        if fileName is not None:
            self._paramPath = fileName
            self.refreshParameters(fileName)
   
        self.ui.show()

    
    def save_as_cfg_file(self):
        '''
        Function to save to a new cfg file
        '''
        fileName = QtGui.QFileDialog.getSaveFileName(self.ui, 'Write Configuration File')[0]
        if fileName != '':
            self._paramPath = fileName
            self.writeParameters()
    
    def add_channel(self):
        '''
        Function to add a channel.
        '''
        #Create the dialog box
        dialogBox =  AddChannelDialog(self.ui)
        if dialogBox.exec_():
            newName = dialogBox.nameLineEdit.text()
            if newName != '':
                if dialogBox.typeComboBox.currentText() == 'qubit':
                    self._params[newName] = deepcopy(self._emptyQubitParams)
                else:
                    self._params[newName] = deepcopy(self._emptyChannelParams)
                self.ui.statusbar.showMessage('Added channel {0}'.format(newName),5000)
                self.saveQubitParameters()
                self.saveChannelParameters()
                self.update_combo_boxes()
                self.updateQubitParameters()
                self.updateChannelParameters()
                
    def delete_channel(self):
        '''
        Function to remove a channel.
        '''
        if not self._params:
            self.ui.statusbar.showMessage('Nothing to delete.',5000)
        else:
            dialogBox =  DeleteChannelDialog(self.ui, self._params.keys())
            if dialogBox.exec_():
                channeltoRemove = dialogBox.channelComboBox.currentText()
                del self._params[channeltoRemove]
                self.update_combo_boxes()
                self.updateQubitParameters()
                self.updateChannelParameters()
                self.ui.statusbar.showMessage('Deleted channel {0}'.format(channeltoRemove))
        
    def update_combo_boxes(self):
        '''
        Populate the combo boxes with the available channels
        '''
        self.ui.qubitComboBox.clear()
        self.ui.channelComboBox.clear()

        for tmpChanName, tmpChanDict in self._params.items():
           if tmpChanDict['channelType'] == 'logical':
               self.ui.qubitComboBox.addItem(tmpChanName)
           elif tmpChanDict['channelType'] == 'physical':
               self.ui.channelComboBox.addItem(tmpChanName)
           else:
               raise NameError('Unknown channel type.')
        
    
    def load_cfg_file(self):
        '''
        Function for menu item to load cfg. file.
        '''
        fileName = QtGui.QFileDialog.getOpenFileName(self.ui, 'Open Configuration File')[0]
        if fileName != '':
            self._paramPath = fileName
            self.refreshParameters(fileName)
    
    def loadParameters(self):
        with open(self._paramPath, 'r') as FID:
            self._params = json.load(FID)

    def refreshParameters(self, fileName=''):
        self.loadParameters()
        #Update the combo boxes from the file parameters
        self.update_combo_boxes()
        self.updateQubitParameters(saveBeforeSwitch=False)
        self.updateChannelParameters(saveBeforeSwitch=False)
        self.ui.statusbar.showMessage('Loaded Cfg. File {0}'.format(os.path.basename(fileName)), 5000 )        
    
    def updateQubitParameters(self, saveBeforeSwitch=True):
        # save parameters
        if saveBeforeSwitch:
            self.saveQubitParameters()
        
        # update GUI with parameters for newly selected channel
        qubit = self.ui.qubitComboBox.currentText()
        if qubit in self._params.keys():
            self.ui.piAmp.setText(str(self._params[qubit]['piAmp']))
            self.ui.pi2Amp.setText(str(self._params[qubit]['pi2Amp']))
            self.ui.sigma.setText(str(self._params[qubit]['sigma']))
            self.ui.delta.setText(str(self._params[qubit]['delta']))
            self.ui.pulseLength.setText(str(self._params[qubit]['pulseLength']))
            self.ui.pulseType.setText(self._params[qubit]['pulseType'])
            self.ui.buffer.setText(str(self._params[qubit]['buffer']))
            self._currentQubit = qubit
    
    def updateChannelParameters(self, saveBeforeSwitch=True):
        # save parameters
        if saveBeforeSwitch:
            self.saveChannelParameters()
        
        # update GUI with parameters for newly selected channel
        channel = self.ui.channelComboBox.currentText()
        if channel in self._params.keys():
            self.ui.bufferPadding.setText(str(self._params[channel]['bufferPadding']))
            self.ui.bufferReset.setText(str(self._params[channel]['bufferReset']))
            self.ui.bufferDelay.setText(str(self._params[channel]['bufferDelay']))
            self.ui.offset.setText(str(self._params[channel]['offset']))
            self.ui.delay.setText(str(self._params[channel]['delay']))
            #Covert the T into amp factor and phase info
            tmpT = self._params[channel]['T']
            self.ui.ampFactor.setText(str(tmpT[0][0]))
            self.ui.phaseSkew.setText(str((180/math.pi)*math.atan(tmpT[0][1]/tmpT[0][0])))
            if self._params[channel]['passThru']:
                self.ui.passThru.setChecked(QtCore.Qt.Checked)
            else:
                self.ui.passThru.setChecked(QtCore.Qt.Unchecked)
            self._currentChannel = channel

    def saveQubitParameters(self):
        if self._currentQubit is not None:
            self._params[self._currentQubit]['piAmp'] = float(self.ui.piAmp.text())
            self._params[self._currentQubit]['pi2Amp'] = float(self.ui.pi2Amp.text())
            self._params[self._currentQubit]['delta'] = float(self.ui.delta.text())
            self._params[self._currentQubit]['sigma'] = int(self.ui.sigma.text())
            self._params[self._currentQubit]['pulseLength'] = int(self.ui.pulseLength.text())
            self._params[self._currentQubit]['pulseType'] = self.ui.pulseType.text()
            self._params[self._currentQubit]['buffer'] = int(self.ui.buffer.text())
        
    def saveChannelParameters(self):
        if self._currentChannel is not None:
            self._params[self._currentChannel]['bufferPadding'] = int(self.ui.bufferPadding.text())
            self._params[self._currentChannel]['bufferReset'] = int(self.ui.bufferReset.text())
            self._params[self._currentChannel]['bufferDelay'] = int(self.ui.bufferDelay.text())
            self._params[self._currentChannel]['offset'] = int(self.ui.offset.text())
            self._params[self._currentChannel]['delay'] = int(self.ui.delay.text())
            #Recreate the T matrix
            ampFactor = float(self.ui.ampFactor.text())
            phaseSkew = (math.pi/180)*float(self.ui.phaseSkew.text())
            self._params[self._currentChannel]['T'] = [[ampFactor, ampFactor*math.tan(phaseSkew)], [0, 1/math.cos(phaseSkew)]]
            self._params[self._currentChannel]['passThru'] = int(self.ui.passThru.isChecked())
        
    def writeParameters(self):
        self.saveQubitParameters()
        self.saveChannelParameters()
        try:
            with open(self._paramPath, 'w') as FID:
                json.dump(self._params, FID, indent=1)
                self.ui.statusbar.showMessage('Wrote configuration to {0}'.format(os.path.basename(self._paramPath)),5000)
        except:
            self.ui.statusbar.showMessage('Unable to save file.',5000)

if __name__ == '__main__':
    #See if we have been passed a cfg file
    parser = OptionParser()
    parser.add_option('-f', action='store', type='string', dest='fileName', default=None)    
    (options, args) =  parser.parse_args(sys.argv[1:])

    # create the Qt application
    app = QtGui.QApplication(sys.argv)
    frame = PulseParamGUI(options.fileName)
    sys.exit(app.exec_())