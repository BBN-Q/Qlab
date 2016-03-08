import argparse
import sys, os
parser = argparse.ArgumentParser()
parser.add_argument('pyqlabpath', help='path to PyQLab directory')
parser.add_argument('control', help='control qubit name')
parser.add_argument('target', help='target qubit name')
parser.add_argument('caltype', type=float, help='1 for length, 2 for phase')
parser.add_argument('length', type=float, help='step for length calibration or fixed length in phase calibration (ns)')
args = parser.parse_args()

from QGL import *

q2 = QubitFactory(args.control)
q1 = QubitFactory(args.target)

if args.caltype==1:
	EchoCRLen(q2,q1,args.length*1e-9*np.arange(2,21),riseFall=20e-9,showPlot=False)
else:
	EchoCRPhase(q2,q1,np.linspace(0,2*np.pi,19),length=args.length*1e-9, riseFall=20e-9, showPlot=False)