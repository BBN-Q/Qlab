import argparse
import sys, os
import numpy as np
from copy import copy
parser = argparse.ArgumentParser()
parser.add_argument('pyqlabpath', help='path to PyQLab directory')
parser.add_argument('qubit', help='qubit name')
parser.add_argument('ramseystop', type=float, help='max pulse spacing (in s)')
parser.add_argument('npoints', type=int, help='number of segments')
args = parser.parse_args()

from QGL import *
q = QubitFactory(args.qubit)

Ramsey(q,np.linspace(0,args.ramseystop,args.npoints), showPlot = False, calRepeats=0) 
