"""
#Create set of pulses for single qubit randomized benchmarking sequence. 

Created on Tue Feb 07 15:01:37 2012

@authors: Colm Ryan and Marcus Silva
"""
import numpy as np
from scipy.linalg import expm
from scipy.constants import pi

from functools import reduce
from itertools import permutations

import csv

def memoize(function):
	cache = {}
	def decorated(*args):
		if args not in cache:
			cache[args] = function(*args)
		return cache[args]
	return decorated

@memoize
def clifford_multiply(C1, C2):
    '''
    Multiplication table for single qubit cliffords.  Note this assumes C1 is applied first. 
    '''
    tmpMult = np.dot(Cliffs[C2].matrix,Cliffs[C1].matrix)
    checkArray = np.array([np.abs(np.trace(np.dot(tmpMult.transpose().conj(),Cliffs[x].matrix))) for x in range(24)])
    return checkArray.argmax()


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
class Clifford(object):
    def __init__(self, matrix, inverse, shapeName, shapePhase):
        self.matrix = matrix
        self.inverse = inverse
        self.shapeName = shapeName
        self.shapePhase = shapePhase
    

#Basis Cliffords
Cliffs = {}
Cliffs[0] = Clifford(I, 0, 'QId', None)
Cliffs[1] = Clifford(expm(-1j*(pi/4)*X), 3, 'R90', 0)
Cliffs[2] = Clifford(expm(-2j*(pi/4)*X), 2, 'R180', 0)
Cliffs[3] = Clifford(expm(-3j*(pi/4)*X), 1, 'R90', 0.5)
Cliffs[4] = Clifford(expm(-1j*(pi/4)*Y), 6, 'R90', 0.25)
Cliffs[5] = Clifford(expm(-2j*(pi/4)*Y), 5, 'R180', 0.25)
Cliffs[6] = Clifford(expm(-3j*(pi/4)*Y), 4, 'R90', 0.75)
Cliffs[7] = Clifford(expm(-1j*(pi/4)*Z), 9, 'QId', None)
Cliffs[8] = Clifford(expm(-2j*(pi/4)*Z), 8, 'QId', None)
Cliffs[9] = Clifford(expm(-3j*(pi/4)*Z), 7, 'QId', None)
Cliffs[10] = Clifford(expm(-1j*(pi/2)*(1/np.sqrt(2))*(X+Y)), 10, 'R180', 0.125)
Cliffs[11] = Clifford(expm(-1j*(pi/2)*(1/np.sqrt(2))*(X-Y)), 11, 'R180', -0.125)
Cliffs[12] = Clifford(expm(-1j*(pi/2)*(1/np.sqrt(2))*(X+Z)), 12, 'RXpZ', 0)
Cliffs[13] = Clifford(expm(-1j*(pi/2)*(1/np.sqrt(2))*(X-Z)), 13, 'RXpZ', 0.5)
Cliffs[14] = Clifford(expm(-1j*(pi/2)*(1/np.sqrt(2))*(Y+Z)), 14, 'RXpZ', 0.25)
Cliffs[15] = Clifford(expm(-1j*(pi/2)*(1/np.sqrt(2))*(Y-Z)), 15, 'RXpZ', 0.75)
Cliffs[16] = Clifford(expm(-1j*(pi/3)*(1/np.sqrt(3))*(X+Y+Z)), 17, 'RXpYpZ', 0) 
Cliffs[17] = Clifford(expm(-2j*(pi/3)*(1/np.sqrt(3))*(X+Y+Z)), 16, 'RXpYmZ', 0.5)
Cliffs[18] = Clifford(expm(-1j*(pi/3)*(1/np.sqrt(3))*(X-Y+Z)), 19, 'RXpYpZ', -0.25)
Cliffs[19] = Clifford(expm(-2j*(pi/3)*(1/np.sqrt(3))*(X-Y+Z)), 18, 'RXpYmZ', 0.25)
Cliffs[20] = Clifford(expm(-1j*(pi/3)*(1/np.sqrt(3))*(X+Y-Z)), 21, 'RXpYmZ', 0)
Cliffs[21] = Clifford(expm(-2j*(pi/3)*(1/np.sqrt(3))*(X+Y-Z)), 20, 'RXpYpZ', 0.5)
Cliffs[22] = Clifford(expm(-1j*(pi/3)*(1/np.sqrt(3))*(-X+Y+Z)), 23, 'RXpYpZ', 0.25)
Cliffs[23] = Clifford(expm(-2j*(pi/3)*(1/np.sqrt(3))*(-X+Y+Z)), 22, 'RXpYmZ', -0.25) 


#Generate random sequences
randomSeqs = [np.random.randint(0,24, (gateLength-1)).tolist() for gateLength in gateLengths for ct in range(numRandomizations) ] 

#For each sequence calculate inverse and the X sequence and append the final Clifford
randomISeqs = []
randomXSeqs = []
for tmpSeq in randomSeqs:
    totalCliff = reduce(clifford_multiply, tmpSeq)
    inverseCliff = Cliffs[totalCliff].inverse
    inverseCliffX = clifford_multiply(inverseCliff, 2)
    randomISeqs.append(tmpSeq + [inverseCliff])
    randomXSeqs.append(tmpSeq + [inverseCliffX])    
    

#Write out the files now
with open('RB_ISeqs.txt','wt') as ISeqFID:
    writer = csv.writer(ISeqFID)
    writer.writerows(randomISeqs)

with open('RB_XSeqs.txt','wt') as XSeqFID:
    writer = csv.writer(XSeqFID)
    writer.writerows(randomXSeqs)





    

    
    
        
    
