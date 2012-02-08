"""
#Create set of pulses for single qubit randomized benchmarking sequence. 

Created on Tue Feb 07 15:01:37 2012

@author: Colm Ryan and Marcus Silva
"""
import numpy as np
from scipy.linalg import expm
from scipy.constants import pi

from functools import reduce
from itertools import permutations


#Number of gates that we want
gateLengths = 2**np.arange(2,7)

#Number of randomizations
numRandomizations = 32

#Single qubit paulis
X = np.array([[0, 1],[1, 0]])
Y = np.array([[0, -1j],[1j, 0]])
Z = np.array([[1, 0],[0, -1]]);
I = np.eye(2)

#Basis Cliffords
Cliff = {}
Cliff[0] = I
Cliff[1] = expm(-1j*(pi/4)*X)
Cliff[2] = expm(-2j*(pi/4)*X)
Cliff[3] = expm(-3j*(pi/4)*X)
Cliff[4] = expm(-1j*(pi/4)*Y)
Cliff[5] = expm(-2j*(pi/4)*Y)
Cliff[6] = expm(-3j*(pi/4)*Y)
Cliff[7] = expm(-1j*(pi/4)*Z)
Cliff[8] = expm(-2j*(pi/4)*Z)
Cliff[9] = expm(-3j*(pi/4)*Z)
Cliff[10] = expm(-1j*(pi/2)*(1/np.sqrt(2))*(X+Y))
Cliff[11] = expm(-1j*(pi/2)*(1/np.sqrt(2))*(X-Y))
Cliff[12] = expm(-1j*(pi/2)*(1/np.sqrt(2))*(X+Z))
Cliff[13] = expm(-1j*(pi/2)*(1/np.sqrt(2))*(X-Z))
Cliff[14] = expm(-1j*(pi/2)*(1/np.sqrt(2))*(Y+Z))
Cliff[15] = expm(-1j*(pi/2)*(1/np.sqrt(2))*(Y-Z))
Cliff[16] = expm(-1j*(pi/3)*(1/np.sqrt(3))*(X+Y+Z))
Cliff[17] = expm(-2j*(pi/3)*(1/np.sqrt(3))*(X+Y+Z))
Cliff[18] = expm(-1j*(pi/3)*(1/np.sqrt(3))*(X-Y+Z))
Cliff[19] = expm(-2j*(pi/3)*(1/np.sqrt(3))*(X-Y+Z))
Cliff[20] = expm(-1j*(pi/3)*(1/np.sqrt(3))*(X+Y-Z))
Cliff[21] = expm(-2j*(pi/3)*(1/np.sqrt(3))*(X+Y-Z))
Cliff[22] = expm(-1j*(pi/3)*(1/np.sqrt(3))*(-X+Y+Z))
Cliff[23] = expm(-2j*(pi/3)*(1/np.sqrt(3))*(-X+Y+Z))

inverseMap = [0, 3, 2, 1, 6, 5, 4, 9, 8, 7, 10, 11, 12, 13, 14, 15, 17, 16, 19, 18, 21, 20, 23, 22]

#Pulses that we can apply
#[QId X90p, X90m, Y90p, Y90m, Xp, Xm, Yp, Ym]
generatorPulses = [0, 1, 3, 4, 6, 2, 2, 5, 5]

#Generate all sequences up to length three
generatorSeqs = [x for x in permutations(generatorPulses,1)] + [x for x in permutations(generatorPulses,2)] + [x for x in permutations(generatorPulses,3)]

def memoize(function):
	cache = {}
	def decorated(*args):
		if args not in cache:
			cache[args] = function(*args)
		return cache[args]
	return decorated

#@memoize
def clifford_multiply(C1, C2):
    '''
    Multiplication table for single qubit cliffords.  Note this assumes C1 is applied first. 
    '''
    tmpMult = np.dot(Cliff[C2],Cliff[C1])
    checkArray = np.array([np.abs(np.trace(np.dot(tmpMult.transpose().conj(),Cliff[x]))) for x in range(24)])
    return checkArray.argmax()
    

#Generate random sequences
randomSequences = [np.random.randint(0,24, (numRandomizations, gateLength)).tolist() for gateLength in gateLengths]

#For each sequence calculate inverse
randomISeqs = []
randomXSeqs = []
for tmpSeqs in randomSequences:
    tmpISeq = []    
    tmpXSeq = []    
    for tmpSeq in tmpSeqs:
        totalCliff = reduce(clifford_multiply, tmpSeq)
        inverseCliff = inverseMap[totalCliff]
        tmpISeq.append(tmpSeq + [inverseCliff])
        inverseCliffX = clifford_multiply(inverseCliff, 2)
        tmpXSeq.append(tmpSeq + [inverseCliffX])        
    randomISeqs.append(tmpISeq)
    randomXSeqs.append(tmpXSeq)
    
#Each Clifford corresponds to one or many sequences of pulses we can apply    


#Replace each Clifford in the sequences with a sequence of pulses we can apply





    

    
    
        
    