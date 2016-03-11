import argparse
import sys, os
from copy import copy
import numpy as np
from QGL.Tomography import create_tomo_blocks
from itertools import product

parser = argparse.ArgumentParser()
parser.add_argument('pyqlabpath', help='path to PyQLab directory')
parser.add_argument('ancilla', help='ancilla qubit')
parser.add_argument('data', help='data qubit')
parser.add_argument('delay', type=float, help='delay after measurement')
parser.add_argument('shift', type=float, help='shift of echo pulse relative to the measurement center') 
parser.add_argument('phc', type=float, help='phase correction on data qubit')
parser.add_argument('ngates', type=int, help='number of RUS gates')
parser.add_argument('Fb', type=int, help='feedback on or off')

phv3 = np.arctan(4/3.)-np.pi

args = parser.parse_args()

from QGL import *

a = QubitFactory(args.ancilla)
q = QubitFactory(args.data)
measDelay = args.delay 
shift = args.shift
phc = args.phc
ngates = args.ngates
Fb = args.Fb

#dummy version 
if Fb: 
    seq1 = [[prepblock] + [Y90(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
    X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
    X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'),X(q)] + qwhile(0,
    [Y90m(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
    X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
    X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'),X(q)]) + \
    [Id(q,20e-9), Ztheta(q,angle = ngates*(phc-phv3)),tomoblock, MEAS(q)] \
    for prepblock, tomoblock in product(create_tomo_blocks((q,), 6), repeat=2)]

    seq2 = [[prepblock] + [Y90(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
    X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
    X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'),X(q)] + qwhile(0,
    [Y90m(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
    X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
    X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'),X(q)]) + \
    [Y90(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
    X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
    X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'),X(q)] + qwhile(0,
    [Y90m(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
    X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
    X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'),X(q)]) +\
    [Id(q,20e-9), Ztheta(q,angle = ngates*(phc-phv3)),tomoblock, MEAS(q)] \
    for prepblock, tomoblock in product(create_tomo_blocks((q,), 6), repeat=2)]

    seq3 = [[prepblock] + [Y90(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
    X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
    X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'),X(q)] + qwhile(0,
    [Y90m(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
    X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
    X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'),X(q)]) + \
    [Y90(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
    X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
    X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'),X(q)] + qwhile(0,
    [Y90m(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
    X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
    X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'),X(q)]) +\
    [Y90(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
    X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
    X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'),X(q)] + qwhile(0,
    [Y90m(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
    X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
    X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'),X(q)]) +\
    [Id(q,20e-9), Ztheta(q,angle = ngates*(phc-phv3)),tomoblock, MEAS(q)] \
    for prepblock, tomoblock in product(create_tomo_blocks((q,), 6), repeat=2)]

    seq4 = [[prepblock] + [Y90(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
    X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
    X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'),X(q)] + qwhile(0,
    [Y90m(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
    X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
    X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'),X(q)]) + \
    [Y90(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
    X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
    X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'),X(q)] + qwhile(0,
    [Y90m(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
    X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
    X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'),X(q)]) +\
    [Y90(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
    X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
    X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'),X(q)] + qwhile(0,
    [Y90m(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
    X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
    X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'),X(q)]) +\
    [Y90(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
    X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
    X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'),X(q)] + qwhile(0,
    [Y90m(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
    X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
    X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'),X(q)]) +\
    [Id(q,20e-9), Ztheta(q,angle = ngates*(phc-phv3)),tomoblock, MEAS(q)] \
    for prepblock, tomoblock in product(create_tomo_blocks((q,), 6), repeat=2)]
else:
    seq1 = [[prepblock] + [Y90(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
    X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
    X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'), X(q)] \
    + qif(0,[X(a)]) + [Id(a), Ztheta(q,angle = ngates*(phc-phv3)), tomoblock]\
    + [MEAS(q)] for prepblock, tomoblock in product(create_tomo_blocks((q,), 6), repeat=2)]

    seq2 = [[prepblock] + [Y90(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
    X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
    X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'), X(q)] +\
    [Y90(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
    X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
    X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'), X(q)]\
    + qif(0,[X(a)]) + [Id(a), Ztheta(q,angle = ngates*(phc-phv3)), tomoblock]\
    + [MEAS(q)] for prepblock, tomoblock in product(create_tomo_blocks((q,), 6), repeat=2)]

    seq3 = [[prepblock] + [Y90(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
    X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
    X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'), X(q)] +\
    [Y90(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
    X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
    X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'), X(q)] +\
    [Y90(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
    X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
    X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'), X(q)]\
    + qif(0,[X(a)]) + [Id(a), Ztheta(q,angle = ngates*(phc-phv3)), tomoblock]\
    + [MEAS(q)] for prepblock, tomoblock in product(create_tomo_blocks((q,), 6), repeat=2)]

    seq4 = [[prepblock] + [Y90(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
    X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
    X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'), X(q)] +\
    [Y90(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
    X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
    X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'), X(q)] +\
    [Y90(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
    X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
    X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'), X(q)] +\
    [Y90(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
    X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
    X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'), X(q)] \
    + qif(0,[X(a)]) + [Id(a), Ztheta(q,angle = ngates*(phc-phv3)), tomoblock]\
    + [MEAS(q)] for prepblock, tomoblock in product(create_tomo_blocks((q,), 6), repeat=2)]

if ngates==1:
    seq = seq1
elif ngates==2:
    seq = seq2
elif ngates==3:
    seq = seq3
elif ngates==4:
    seq = seq4
else:
    seq = seq1 + seq2 + seq3 + seq4 #not working
seqs = seq + create_cal_seqs((q,), numRepeats=2) #+ create_cal_seqs((a,), numRepeats=2,waitcmp=True)

fileNames = compile_to_hardware(seqs, 'ProcessTomo/ProcessTomo')