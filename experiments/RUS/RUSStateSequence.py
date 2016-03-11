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
parser.add_argument('psi0', help='initial state')
parser.add_argument('delay', type=float, help='delay after measurement')
parser.add_argument('shift', type=float, help='shift of echo pulse relative to the measurement center')	
parser.add_argument('phc', type=float, help='phase correction on data qubit')


phv3 = np.arctan(4/3.)-np.pi

args = parser.parse_args()

from QGL import *

PulseDic = {'x':Y90, 'y':X90m, '0':Id, '1':X}
prepPulse = PulseDic[args.psi0]
a = QubitFactory(args.ancilla)
q = QubitFactory(args.data)
measDelay = args.delay 
shift = args.shift
phc = args.phc


seq1 = [[prepPulse(q), Y90(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
            X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
            X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'), X(q)] + \
       [Id(a), Ztheta(q,angle = -0*phv3), Ztheta(q,angle = phc), tomoblock]\
            + [MEAS(q)] for tomoblock in create_tomo_blocks((q,),6)]


seq2 = [[prepPulse(q), Y90(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
            X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
            X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'),X(q)] + qif(0,
       [Y90m(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
            X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
            X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'),X(q), Ztheta(q,angle = phc), tomoblock],\
        [Id(a), Ztheta(q,angle = phc), tomoblock]) + [MEAS(q)] for tomoblock in create_tomo_blocks((q,),6)]


seq3 = [[prepPulse(q), Y90(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
            X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
            X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'),X(q)] + qif(0,
       [Y90m(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
            X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
            X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'),X(q)] + qif(0,
       [Y90m(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
            X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
            X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'),X(q),  Ztheta(q,angle = phc),tomoblock],\
        [Id(a),  Ztheta(q,angle = phc),tomoblock]),
        [Id(a),  Ztheta(q,angle = phc),tomoblock]) + [MEAS(q)] for tomoblock in create_tomo_blocks((q,),6)]

seqinf = [[prepPulse(q), Y90(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
            X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
            X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'),X(q)] + qwhile(0,
       [Y90m(a), Ztheta(a, angle=pi/4), Y90(a), X(a)*Y90(q)] + CNOT_CR(a,q) +[Ztheta(a, angle=-pi/4), Y90(a),\
            X(a), Ztheta(a, angle=pi/4)] + CNOT_CR(a,q) + [Y90(a)*Y90m(q), X(a), Ztheta(a, angle=pi/4), Y90(a), \
            X(a), MeasEcho(a,q,measDelay,shift,True),qwait('CMP'),X(q)]) + [Id(q,10e-9), Ztheta(q,angle = phc),tomoblock,\
        MEAS(q)] for tomoblock in create_tomo_blocks((q,),6)]


seqs = seq1 + seq2 + seq3 + seqinf + create_cal_seqs((q,), numRepeats=2) #+ create_cal_seqs((a,), numRepeats=2,waitcmp=True)



fileNames = compile_to_hardware(seqs, 'StateTomo/StateTomo')