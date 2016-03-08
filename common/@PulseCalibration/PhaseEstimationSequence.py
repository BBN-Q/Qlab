import argparse
import sys, os
import numpy as np
from copy import copy
parser = argparse.ArgumentParser()
parser.add_argument('pyqlabpath', help='path to PyQLab directory')
parser.add_argument('qubit', help='qubit name')
parser.add_argument('direction', help='direction (X or Y)')
parser.add_argument('numPulses', type=int, help='log2(n) of the longest sequence n')
parser.add_argument('amplitude', type=float, help='pulse amplitude')
args = parser.parse_args()

from QGL import *

q = QubitFactory(args.qubit)

if args.direction == 'X':
    pPulse = Xtheta(q, amp=args.amplitude)
    mPulse = X90m(q)
else:
    pPulse = Ytheta(q, amp=args.amplitude)
    mPulse = Y90m(q)

# Exponentially growing amplications of the target pulse
# (1, 2, 4, 8, 16, 32, 64, 128, ...) x X90
# first two sequence give measurement calibration
seqs = [[pPulse]*n for n in 2**np.arange(args.numPulses+1)]

# measure each along Z or X/Y
seqs = [s + m for s in seqs for m in [ [MEAS(q)], [mPulse, MEAS(q)] ]]

# tack on calibrations
seqs = [[Id(q), MEAS(q)], [X(q), MEAS(q)]] + seqs

# repeat each
repeated_seqs = [copy(s) for s in seqs for _ in range(2)]

fileNames = compile_to_hardware(repeated_seqs, fileName='RepeatCal/RepeatCal')
# plot_pulse_files(fileNames)
