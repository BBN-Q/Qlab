"""
#Create set of pulses for single qubit randomized benchmarking sequence. 

Created on Tue Feb 07 15:01:37 2012

@authors: Colm Ryan and Marcus Silva
"""
import numpy as np
from functools import reduce

import csv

def memoize(function):
	cache = {}
	def decorated(*args):
		if args not in cache:
			cache[args] = function(*args)
		return cache[args]
	return decorated

@memoize
def pauli_multiply(P1, P2):
    '''
    Multiplication table for single qubit cliffords.  Note this assumes C1 is applied first. 
    '''
    tmpMult = np.dot(Paulis[P2].matrix,Paulis[P1].matrix)
    checkArray = np.array([np.abs(np.trace(np.dot(tmpMult.transpose().conj(),Paulis[x].matrix))) for x in range(1,5)])
    return checkArray.argmax()+1


#Number of gates that we want
gateLengths = np.array([2, 4, 8, 16, 32, 64, 96, 128, 192, 256, 320])

#Number of randomizations
numRandomizations = 32

#Single qubit paulis
X = np.array([[0, 1],[1, 0]])
Y = np.array([[0, -1j],[1j, 0]])
Z = np.array([[1, 0],[0, -1]]);
I = np.eye(2)

#Basically a structure to contain some infor about the Cliffords
class Pauli(object):
    def __init__(self, matrix, inverse):
        self.matrix = matrix
        self.inverse = inverse
    
#Basis Cliffords
Paulis = {}
Paulis[1] = Pauli(I, 1)
Paulis[2] = Pauli(X, 2)
Paulis[3] =  Pauli(Y, 3)
Paulis[4] = Pauli(Z, 4)

targetGate = 1

#Generate random sequence of Paulis for each number of gates we want to look at and repeat numRandomization times
randPauliLists = [np.random.randint(1,5, gatect-1).tolist() for gatect in gateLengths for randct in range(numRandomizations) ] 

#Interleave gate of interest
#interLeavedGateLists = [np.vstack((tmpGateList, targetGate*np.ones_like(tmpGateList))).flatten(order='F').tolist() for tmpGateList in randPauliLists]
    
#For each sequence calculate inverse and the X sequence and append the final Clifford
randomISeqs = []
#randomXSeqs = []
for tmpPauliSeq in randPauliLists:
    totalPauli = reduce(pauli_multiply, tmpPauliSeq)
    inversePauli = Paulis[totalPauli].inverse
#    inverseCliffX = clifford_multiply(inverseCliff, 2)
    randomISeqs.append(tmpPauliSeq + [inversePauli])
#    randomXSeqs.append(tmpSeq + [inverseCliffX])    
    

#Write out the files now
with open('PauliTwirl_ISeqs.txt','wt') as ISeqFID:
    writer = csv.writer(ISeqFID)
    writer.writerows(randomISeqs)

#with open('PauliTwirl_XSeqs.txt','wt') as XSeqFID:
#    writer = csv.writer(XSeqFID)
#    writer.writerows(randomXSeqs)





    

    
    
        
    
