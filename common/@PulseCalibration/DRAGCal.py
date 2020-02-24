import argparse
import sys, os
parser = argparse.ArgumentParser()
parser.add_argument('qubit', help='qubit name')
parser.add_argument('--deltas', type=float, required=True, nargs='+', help='list of drag scaling values')
parser.add_argument('--nums_pulses', type=int, required=True, nargs='+', help='list of number of pulses')
args = parser.parse_args()

from QGL import *

q = QubitFactory(args.qubit)

# N applications of pseudoidentity [X90(q), X90m(q)] followed by final [X90(q)] 

seqs = []
for n in args.nums_pulses:
	seqs += [[X90(q, dragScaling = d), X90m(q, dragScaling = d)]*n + [X90(q, dragScaling = d), MEAS(q)] for d in args.deltas]

seqs += create_cal_seqs((q,),2)

fileNames = compile_to_hardware(seqs, fileName='DRAGCal/DRAGCal')
