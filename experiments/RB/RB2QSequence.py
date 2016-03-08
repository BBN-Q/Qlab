import argparse
import sys, os
parser = argparse.ArgumentParser()
parser.add_argument('pyqlabpath', help='path to PyQLab directory')
parser.add_argument('target', help='target qubit name')
parser.add_argument('control', help='control qubit name')
parser.add_argument('CR', help='CR pulse name')

args = parser.parse_args()

from QGL import *

qt = QubitFactory(args.target)
qc = QubitFactory(args.control)
CR = QubitFactory(args.CR)

seqs= create_RB_seqs(2,[2,4,6,8,10,12],repeats=5,interleaveGate=None)
TwoQubitRB(qt,qc,CR,seqs,showPlot=False)
