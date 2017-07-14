import argparse
import sys, os
import numpy as np
from copy import copy
parser = argparse.ArgumentParser()
parser.add_argument('qc', help='control qubit')
parser.add_argument('qt', help='target qubit')
parser.add_argument('numPulses', type=int, help='log2(n) of the longest sequence n')
parser.add_argument('amplitude', type=float, help='pulse amplitude')
args = parser.parse_args()

from QGL import *

qc = QubitFactory(args.qc)
qt = QubitFactory(args.qt)
amp = args.amplitude

CRchan = ChannelLibrary.EdgeFactory(qc, qt)
CRchan.pulseParams['amp'] = amp

pPulse = ZX90_CR(qc,qt).seq
mPulse = X90m(qt)

# Exponentially growing amplications of the target pulse
# (1, 2, 4, 8, 16, 32, 64, 128, ...) x X90
# first two sequence give measurement calibration
seqs = [pPulse*n for n in 2**np.arange(args.numPulses+1)]

# measure each along Z or X/Y
seqs = [s + m for s in seqs for m in [ [MEAS(qt)], [mPulse, MEAS(qt)] ]]

# tack on calibrations
seqs = [[Id(qt), MEAS(qt)], [X(qt), MEAS(qt)]] + seqs

# repeat each
repeated_seqs = [copy(s) for s in seqs for _ in range(2)]

fileNames = compile_to_hardware(repeated_seqs, fileName='RepeatCal/RepeatCal')
