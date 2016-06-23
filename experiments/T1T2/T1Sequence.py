import argparse
import sys, os
parser = argparse.ArgumentParser()
parser.add_argument('pyqlabpath', help='path to PyQLab directory')
parser.add_argument('qubit', help='qubit name')
parser.add_argument('stop', help='longest delay in ns', type = float)
parser.add_argument('step', help='delay step in ns', type = float)

args = parser.parse_args()

from QGL import *

q = QubitFactory(args.qubit)
T1Stop = args.stop
T1Step = args.step
InversionRecovery(q, np.arange(0,T1Stop/1e9,T1Step/1e9), suffix=True) 


