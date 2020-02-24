import argparse
import sys, os
parser = argparse.ArgumentParser()
parser.add_argument('pyqlabpath', help='path to PyQLab directory')
parser.add_argument('qubit', help='qubit name')
parser.add_argument('stop', help='longest delay in ns', type = int)
parser.add_argument('step', help='delay step in ns', type = int)

args = parser.parse_args()

from QGL import *

q = QubitFactory(args.qubit)
RamseyStop = args.stop
RamseyStep = args.step
Ramsey(q, np.arange(0,RamseyStop/1e9,RamseyStep/1e9), suffix=True) 


