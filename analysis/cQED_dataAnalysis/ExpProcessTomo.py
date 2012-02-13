# -*- coding: utf-8 -*-
"""
Created on Mon Feb 13 10:14:23 2012

Script for dealing with experimental process data

@author: cryan
"""

from scipy.io import loadmat
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cm

from itertools import product
from functools import reduce
from collections import OrderedDict

from scipy.linalg import expm
from scipy.constants import pi

from QTomo import qpt_iter, Liouville2Pauli, createCartPOVM

dataFile = '/home/cryan/Desktop/tomoData.mat'
numQubits = 1
nbrRepeats = 2

#Single qubit paulis
X = np.array([[0, 1],[1, 0]])
Y = np.array([[0, -1j],[1j, 0]])
Z = np.array([[1, 0],[0, -1]]);
I = np.eye(2)    

singleQubitPrepPulses = OrderedDict([('QId',I), ('Xp',expm(-2j*(pi/4)*X)), ('X90p',expm(-1j*(pi/4)*X)), ('X90m',expm(1j*(pi/4)*X)), ('Y90p',expm(-1j*(pi/4)*Y)), ('Y90m',expm(1j*(pi/4)*Y))])
singleQubitReadoutPulses = singleQubitPrepPulses    

#Create all possibilities of state prep and readout pulses
prepPulses = [reduce(np.kron, tmpPulseList) for tmpPulseList in [x for x in product(singleQubitPrepPulses.values(),repeat=numQubits)]]
measPulses = [reduce(np.kron, tmpPulseList) for tmpPulseList in [x for x in product(singleQubitReadoutPulses.values(),repeat=numQubits)]]

#Assume we measure the ground state probability
measOp = np.zeros((2**numQubits, 2**numQubits))
measOp.flat[0] = 1

#See how the preparation and measurment pulses transform the initial state and measurement operator
initState = np.zeros((2**numQubits,2**numQubits))
initState[0][0] = 1
inputStates = [np.dot(np.dot(prepPulse, initState), prepPulse.transpose().conj()) for prepPulse in prepPulses]
measOpTransformed = [np.dot(np.dot(tmpReadOut.transpose().conj(), measOp), tmpReadOut) for tmpReadOut in measPulses]    

#Load the data
allExpData = loadmat(dataFile)['tomoData'].flatten()
#Take the mean of the repeats
meanExpData = np.mean(np.reshape(allExpData, (nbrRepeats, allExpData.size/nbrRepeats), order='F'), axis=0)

#Scale the data
rawData = meanExpData[:(len(prepPulses)*len(measPulses))]

calData = meanExpData[-2**numQubits:]

calScale = calData[1] - calData[0]

scaledData = 1 - (rawData - calData[0])/calScale

#Reshape 
scaledData.resize((len(prepPulses), len(measPulses)))

#Convert the measurement results into cartesian POVMs
cartPOVMs = createCartPOVM(numQubits)

POVMexpResults = np.zeros((len(prepPulses), len(cartPOVMs)))

for prepct in range(len(prepPulses)):
    for POVMct, tmpPOVM in enumerate(cartPOVMs):
        #Find which transformed measurment operator this corresponds to 
        tmpIndex = np.array([np.trace(np.dot(tmpPOVM,tmpOp)).real for tmpOp in measOpTransformed]).argmax()
        POVMexpResults[prepct, POVMct] = scaledData[prepct, tmpIndex]*np.trace(np.dot(tmpPOVM, measOpTransformed[tmpIndex])).real           
    
#Call the optimization
fitMap = qpt_iter(inputStates, cartPOVMs, POVMexpResults, numQubits )    
    
#Convert to the Pauli map representation
pauliMap =  Liouville2Pauli(fitMap,numQubits)
plt.figure()
plt.imshow(pauliMap[0], cmap = cm.RdBu, interpolation='none', vmin=-1, vmax=1)
plt.xticks(np.arange(4**numQubits), pauliMap[1])
plt.yticks(np.arange(4**numQubits), pauliMap[1])
plt.ylabel('Input State')
plt.xlabel('Output State')
plt.colorbar()
plt.show()

