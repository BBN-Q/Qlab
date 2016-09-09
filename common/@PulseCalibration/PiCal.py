import argparse
import sys, os
parser = argparse.ArgumentParser()
parser.add_argument('qubit', help='qubit name')
parser.add_argument('direction', help='direction (X or Y)')
parser.add_argument('numPulses', type=int, help='maximum number of 180s')
parser.add_argument('piAmp', type=float, help='piAmp')
args = parser.parse_args()

from QGL import *

q = QubitFactory(args.qubit)
q.pulseParams['piAmp'] = args.piAmp

if args.direction == 'X':
    seqs = [[Id(q), MEAS(q)] for _ in range(2)] + [[X90(q)] + [X(q)]*n + [MEAS(q)] for n in range(args.numPulses) for _ in range(2)] + \
           [[X90m(q)] + [Xm(q)]*n + [MEAS(q)] for n in range(args.numPulses) for _ in range(2)]
else:
    seqs = [[Id(q), MEAS(q)] for _ in range(2)] + [[Y90(q)] + [Y(q)]*n + [MEAS(q)] for n in range(args.numPulses) for _ in range(2)] + \
           [[Y90m(q)] + [Ym(q)]*n + [MEAS(q)] for n in range(args.numPulses) for _ in range(2)]

fileNames = compile_to_hardware(seqs, fileName='PiCal/PiCal')
# plot_pulse_files(fileNames)
