import argparse
import sys, os
parser = argparse.ArgumentParser()
parser.add_argument('pyqlabpath', help='path to PyQLab directory')
parser.add_argument('qubit', help='qubit name')
parser.add_argument('--deltas', type=float, required=True, nargs='+', help='list of drag scaling values')
args = parser.parse_args()

from QGL import *

q = QubitFactory(args.qubit)

numPsId = 8 # number pseudoidentities

# Id at the beginning
# N applications of pseudoidentity [X90(q), X90m(q)] inside a Ramsey sequence, i.e.
# X90, (sequence of +/-X90), Y90

seqs = []
for d in args.deltas:
    seqs += [[Id(q), MEAS(q)]] + [[X90(q)] + [X90(q, dragScaling=d), X90m(q, dragScaling=d)]*n + [Y90(q), MEAS(q)] for n in range(numPsId)]

# just a pi pulse for scaling
seqs += [[X(q), MEAS(q)]]

fileNames = compile_to_hardware(seqs, fileName='APE/APE')
# plot_pulse_files(fileNames)
