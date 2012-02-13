'''
Package for Quantum Tomography Code.

Written by Colm Ryan 22 Sept 2010
'''
     

import numpy as np

import copy

from itertools import product
from functools import reduce
from collections import OrderedDict

from scipy.linalg import sqrtm

def qst_iter(measurements, expresults, n, maxiter = 1000):
    '''
    Function to perform QST based on iterative maximum likelihood.  From Jezek
    et al. Quantum inference of states and processes. Physical Review A (2003) vol. 68 (1) pp. 1-7
    
     bestrho = findrho_iter(measurements,expresults,n,maxiter)
    
     measurements - list of matrix of POVM's 
     expresults - vector of experimental probabilities
     n - number of qubits
     maxiter - maximum number of iterations (optional, default 1000)
    
    '''
    
    #Start with the identity state
    bestrho = np.eye(2**n, dtype=np.complex)/2**n
    
    #Iteration counter
    iterct = 0
    
    #Change in bestrho
    diffrho = 1
    
    #Start looping
    while ((diffrho > 1e-8) & (iterct < maxiter)):
        
        #Calculate R matrix
        R = np.zeros((2**n,2**n), dtype=np.complex)
        measct = 0
        for tmpPOVM in measurements:
            R += (expresults[measct]/np.trace(np.dot(tmpPOVM,bestrho)))*tmpPOVM
            measct += 1

        #Update the density matrix
        oldrho = bestrho.copy()
        
        bestrho = np.dot(R,np.dot(oldrho,R))
        bestrho = bestrho/np.trace(bestrho)
        
        #Calculate change to see if we have stopped moving
        diffrho = 1 - np.abs(np.trace(np.dot(bestrho.conj().transpose(),oldrho))/np.sqrt(np.real(np.trace(np.dot(bestrho,bestrho))*np.trace(np.dot(oldrho,oldrho)))))
        iterct += 1
        
    return bestrho

def qst_maxlik(observables, expResults, n, guessRho = None):
    '''
    Function to perform quantum state tomography based on constrained least square maximization.
    '''
    
    from scipy.optimize import leastsq
    dim = 2**n
    
    #Define a helper function to convert between a density matrix and Tvector
    def rho2Tvec(rho):
        #Take the Cholesky decomposition (rho better be positive definite)
        Tmat = np.linalg.cholesky(rho)
        Tvec = []
        #First do the real part
        for rowct in range(dim):
            for colct in range(rowct+1):
                Tvec.append(np.real(Tmat[rowct,colct]))
        
        #Now the imaginary
        for rowct in range(dim):
            for colct in range(rowct):
                Tvec.append(np.imag(Tmat[rowct,colct]))
                
        return np.array(Tvec)
    
    #Define a helper function to convert between a T vector and a density matrix
    def Tvec2rho(Tvec):
        indexct = 0
        
        Tmat = np.zeros((dim,dim), dtype=np.complex)
        #First do the real part
        for rowct in range(dim):
            for colct in range(rowct+1):
                Tmat[rowct,colct] += Tvec[indexct]
                indexct += 1
        
        #Now the imaginary
        for rowct in range(dim):
            for colct in range(rowct):
                Tmat[rowct,colct] += 1j*Tvec[indexct]
                indexct += 1
                
        return np.dot(Tmat,Tmat.transpose().conj())
    
    #Define the error function
    def errorT(Tvec):

        #Calculate the rho associated with the current Tvec
        tmpRho = Tvec2rho(Tvec)
        
        simObs = np.zeros(len(observables))
        #Calculate the expected observables
        for ct,tmpObs in enumerate(observables):
            simObs[ct] = np.real(np.trace(np.dot(tmpObs,tmpRho)))
            
#        return np.sum(np.append((simObs - expResults),4*(np.real(np.trace(tmpRho)) - 1))**2)  #fmin version with sum squared
        return np.append((simObs - expResults),4*(np.real(np.trace(tmpRho)) - 1))   #leastsq version with raw residuals
        
    #Setup a guess rho of the identity state
    guessVec = rho2Tvec((1.0/dim)*np.eye(dim)) if guessRho is None else rho2Tvec(guessRho)

    #Call the optimizer
    bestVec = leastsq(errorT, guessVec, epsfcn = 1e-6, maxfev = int(1e3))
    print('Final Error: {0}'.format(np.sum(errorT(bestVec[0])**2)))
#    bestVec = fmin(errorT, guessVec, maxfun = int(1e6))
    return Tvec2rho(bestVec[0])
        
def qpt_iter(inputStates,measurements,expResults,n):
    '''
    Function to perform iterative maximum liklihood CP map estimation. From Jezek
    et al. Quantum inference of states and processes. Physical Review A (2003) vol. 68 (1) pp. 1-7
    
    qpt_iter(inputStates,measurements,expResults,numQubits):
        inputState - list or array of input density matrices
        measurements - list of array of POVM operators
        expResults - matrix (numinputs, nummeasurements) of experimental results
        n - numQubits
    '''
    
    #Precalculate the partial trace indices for speed
    indices = partrace_indices(n,np.arange(n+1,2*n+1))
    
    numinputs = len(inputStates)
    nummeas = len(measurements)
    
    #Precalculate some matrices (warning trading space for time)
    inputmeas = np.zeros((numinputs,nummeas, 4**n, 4**n), dtype=np.complex128)
    for ct1 in range(numinputs):
        for ct2 in range(nummeas):
            inputmeas[ct1,ct2] = np.kron(inputStates[ct1].transpose(),measurements[ct2])

    #Now loop through the iterative updates
    dim = 2**n
    dim2 = 4**n

    #Intitial guess at map is identity
    curS = np.eye(dim2)/dim
    
    #Initial difference in map and iteration count
    diffS = 1
    iterct = 0

    while (diffS > 1e-3) and (iterct < 1e3):
        #Calculate K
        K = np.zeros((dim2,dim2), dtype=np.complex128)
        for ct1 in range(numinputs):
            for ct2 in range(nummeas):
               K += (expResults[ct1,ct2]/(np.trace(np.dot(curS,inputmeas[ct1,ct2]))))*inputmeas[ct1,ct2]
 
        #Calculate lambda
        tmpmat = np.dot(K, np.dot(curS,K))
 
        #Now take the partial trace
#        tmpmatbis = np.zeros((dim,dim))
#        for ct1 in range(dim):
#            for ct2 in range(dim):
#                tmpmatbis[ct1,ct2] = np.sum(tmpmat[indices[ct1],indices[ct2]])
        
        tmpmatbis = np.array([[np.sum(tmpmat[indices[ct1],indices[ct2]]) for ct2 in range(dim)] for ct1 in range(dim)])
        tmplambda = sqrtm(tmpmatbis)
    
        #Now  calculate the new S
        oldS = np.copy(curS)            
        tmpLambdaInv = np.linalg.inv(np.kron(tmplambda, np.eye(dim)))
        
        curS = np.dot(np.dot(np.dot(np.dot(tmpLambdaInv,K), oldS), K), tmpLambdaInv)
        
        diffS = (dim2 - np.real(np.trace(np.dot(curS, oldS))))/dim2
        
        iterct += 1
        
    #Convert S back into Liouville (column stacked) representation
    bestMap = np.zeros((dim2,dim2), dtype=np.complex128)
    
    #See what happens to each basis element
    for ct in range(dim2):
        #Create the basis element
        rhoIn = np.zeros((dim,dim))
        rhoIn.flat[ct] = 1
        
        #See how it is transformed by S
        tmpOut = np.dot(curS, np.kron(rhoIn, np.eye(dim)))
        rhoOut = partialtrace(tmpOut, np.arange(1,n+1))
        
        bestMap[:,ct] = rhoOut.flatten(order='F')
        
    return bestMap
        

def partialtrace(matIn, tspins):
    '''
    Helper function to calculate the partial trace.
    '''
    #Assume qubits for now
    numQubits = int(np.log2(matIn.shape[0]))
    indices = partrace_indices(numQubits, tspins)
    
    dimOut = 2**(numQubits-len(tspins))
    return np.array([[np.sum(matIn[indices[ct1],indices[ct2]]) for ct2 in range(dimOut)] for ct1 in range(dimOut)])
 


def partrace_indices(nb_in, tspins):
    '''
    Helper function to calculate the indices summed over in a partial trace operation

    %The Partial trace is essentially picking out elements of the bigger
    %matrix to create a new submatrix and then taking the trace of that.  In
    %other words if a basis for the reduced space is |k> then  we factor the
    %matrix into a sum of |k><k| X \rho_k for each basis vector k where \rho_k
    %is the density matrix on the traced out space.  Then we just take the
    %trace of \rho_k.  The trick is for each |k><k| to pick the right elements
    %out to form \rho_k.
    
    %Find indices in larger space corresponding to each |k>.  This is not obvious but.....
    
    %inds is a 2D matrix where each row corresponds to a basis vector |k> and
    %says which indices correspond to |k>
    '''
    
    #Spins we are tracing out    
    tspins = np.sort(tspins);
    #Spins we are keeping
    kspins = np.setxor1d(tspins,np.arange(1,nb_in+1));
    
    nb_out = len(kspins);
    nb_tr = nb_in-nb_out;    
    
    #Create a logical array of binary numbers (one per row)
    # e.g. for n = 2 : [[0, 0], [0, 1], [1, 0], [1, 1]]
    maxnb = max(nb_out,nb_tr)
    binarynum = np.zeros((2**maxnb,maxnb), dtype=np.int8);
    for ct in range(maxnb):
        reps = 2**ct
        binarynum[:,-(ct+1)] = np.tile(np.hstack((np.zeros(reps), np.ones(reps))),(1, 2**maxnb/reps/2))


    '''    
    Now, the indices we are taking the sum of for each output element move as powers of two (or dimension) of the traced spins' indices in reverse order
    e.g. if we are tracing out the final spin then we take steps of 1, the second last spin we take steps of two. We always start at the origin [0,0] 
    For tracking out multiple spins we take all combinations.  E.g. if we have spins [1,2,3] and we are tracing spins [1,3]
    then we sum through indices [0, 1, 4, 5] from each starting point.
    '''
    
    #So calculate how the summed indices change
    steps = 2**(nb_in-np.array(tspins))
    summedSteps = np.sum(np.tile(steps,(2**nb_tr,1))*binarynum[:2**nb_tr,-nb_tr:],axis=1)
    summedSteps.shape

    '''
    The starting points move instead as powers of two (or dimension) of the remaining untraced spins in reverse order.
    '''
    startshift = 2**(nb_in-np.array(kspins))
    summedStartPts = np.sum(np.tile(startshift,(2**nb_out,1))*binarynum[:2**nb_out,-nb_out:],axis=1)

    #Now put it all together.  Each row is the set of indices which get summed over for an output matrix element
    #E.g. for matrix element rowct, colct we sum over inMat[indices[rowct], indices[colct]]
    indices = np.tile(summedStartPts, (2**nb_tr,1)).transpose() + np.tile(summedSteps, (2**nb_out,1))

    return indices


def createCartPOVM(n):
    '''
    Function to create the multiqubit POVM's which measure along the Cartesian axes for a given number of qubits
    '''
    #First create the single spin versions
    singlePOVM = [];
    singlePOVM.append((1.0/3)*np.array([[1,0],[0,0]]))
    singlePOVM.append((1.0/3)*np.array([[0,0],[0,1]]))
    singlePOVM.append((1.0/6)*np.array([[1,1],[1,1]]))
    singlePOVM.append((1.0/6)*np.array([[1,-1],[-1,1]]))
    singlePOVM.append((1.0/6)*np.array([[1,-1j],[1j,1]]))
    singlePOVM.append((1.0/6)*np.array([[1,1j],[-1j,1]]))
    
    #Create all n-tensor product version 
    return [reduce(np.kron, tmpPOVMList) for tmpPOVMList in [x for x in product(singlePOVM,repeat=n)]]



def Liouville2Pauli(map,n):
    '''
    Function to transform between column stacked Liouville representation a Pauli process map representation
    '''
    #First create the Pauli operators
    singlePaulis = [np.eye(2), np.array([[0, 1],[1, 0]]), np.array([[0, -1j],[1j, 0]]), np.array([[1, 0],[0, -1]]) ]
    multiPaulis = copy.deepcopy(singlePaulis)
    #Setup the strings for the Paulis
    singlePauliStr = ['I','X','Y','Z']
    multiPauliStr = copy.deepcopy(singlePauliStr)
    
    ct = 1
    while ct < n:
        ct += 1
        oldPaulis = copy.deepcopy(multiPaulis)
        oldPaulisStr = copy.deepcopy(multiPauliStr)
        multiPaulis = []
        multiPauliStr = []
        for tmpPauli, tmpPauliStr in zip(oldPaulis,oldPaulisStr):
            for tmpsinglePauli, tmpSinglePauliStr in zip(singlePaulis, singlePauliStr):
                multiPaulis.append(np.kron(tmpPauli,tmpsinglePauli))
                multiPauliStr.append(tmpPauliStr + tmpSinglePauliStr)
                
    
                
    pauliMap = np.zeros((4**n,4**n))            
    #Now evaluate the Pauli process map
    for ct1,pauliIn in enumerate(multiPaulis):
        for ct2,pauliOut in enumerate(multiPaulis):
            
            tmpOut = np.transpose(np.resize(np.dot(map,np.reshape(np.transpose(pauliIn),(4**n,1))),(2**n,2**n)))
            
            pauliMap[ct1,ct2] = np.trace(np.dot(tmpOut,pauliOut))/2**n
            
    return pauliMap, multiPauliStr
    
if __name__ == "__main__":

    from scipy.linalg import expm
    from scipy.constants import pi
    #Test the quantum process tomography
    
    #Single qubit paulis
    X = np.array([[0, 1],[1, 0]])
    Y = np.array([[0, -1j],[1j, 0]])
    Z = np.array([[1, 0],[0, -1]]);
    I = np.eye(2)    
    
    singleQubitPrepPulses = OrderedDict([('QId',I), ('Xp',expm(-2j*(pi/4)*X)), ('X90p',expm(-1j*(pi/4)*X)), ('X90m',expm(1j*(pi/4)*X)), ('Y90p',expm(-1j*(pi/4)*Y)), ('Y90m',expm(1j*(pi/4)*Y))])
    singleQubitReadoutPulses = singleQubitPrepPulses    

    measOp = np.kron(Z,I) + np.kron(I,Z)
    measOp = np.array([[1,0],[0,0]])
    numQubits = 1

    CNOT = np.array([[1,0,0,0],[0,1,0,0],[0,0,0,1],[0,0,1,0]])    
    testMap = CNOT 
    testMap = I
    
    #Create all possibilities of state prep and readout pulses
    prepPulses = [reduce(np.kron, tmpPulseList) for tmpPulseList in [x for x in product(singleQubitPrepPulses.values(),repeat=numQubits)]]
    measPulses = [reduce(np.kron, tmpPulseList) for tmpPulseList in [x for x in product(singleQubitReadoutPulses.values(),repeat=numQubits)]]

    #Create some fake data
    #Assume we start in the 00 state. Then apply the preperation gate, the gate to be characterized and the readout pulse,then take the measurement operator.   
    rawExpResults = np.zeros((len(prepPulses), len(measPulses)))
    initState = np.zeros((2**numQubits,2**numQubits))
    initState[0][0] = 1
    inputStates = [np.dot(np.dot(prepPulse, initState), prepPulse.transpose().conj()) for prepPulse in prepPulses]
    measOpTransformed = [np.dot(np.dot(tmpReadOut.transpose().conj(), measOp), tmpReadOut) for tmpReadOut in measPulses]    
    for prepct, inputState in enumerate(inputStates):
        tmpState = np.dot(np.dot(testMap, inputState), testMap.transpose().conj())
        for measct, tmpMeas in enumerate(measOpTransformed):
            rawExpResults[prepct, measct] = np.trace(np.dot(tmpMeas,tmpState)).real
            
    
    #Convert the measurement results into cartesian POVMs
    cartPOVMs = createCartPOVM(numQubits)
    
    POVMexpResults = np.zeros((len(prepPulses), len(cartPOVMs)))
    
    for prepct in range(len(prepPulses)):
        for POVMct, tmpPOVM in enumerate(cartPOVMs):
            #Find which transformed measurment operator this corresponds to 
            tmpIndex = np.array([np.trace(np.dot(tmpPOVM,tmpOp)).real for tmpOp in measOpTransformed]).argmax()
            POVMexpResults[prepct, POVMct] = rawExpResults[prepct, tmpIndex]*np.trace(np.dot(tmpPOVM, measOpTransformed[tmpIndex])).real           
            
                    
    #Call the optimization
    fitMap = qpt_iter(inputStates, cartPOVMs, POVMexpResults, numQubits )    
#    
#    qpt_iter(inputStates,measurements,expResults,n):
    '''
    Function to perform iterative maximum liklihood CP map estimation. From Jezek
    et al. Quantum inference of states and processes. Physical Review A (2003) vol. 68 (1) pp. 1-7
    
    qpt_iter(inputStates,measurements,expResults,numQubits):
        inputState - list or array of input density matrices
        measurements - list of array of POVM operators
        expResults - matrix (numinputs, nummeasurements) of experimental results
        n - numQubits
    '''
    
