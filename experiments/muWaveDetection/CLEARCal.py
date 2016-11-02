import argparse
import sys, os
parser = argparse.ArgumentParser()
parser.add_argument('qubit', help='qubit name')
parser.add_argument('meas_qubit', help='name of auxiliary qubit for msm''t pulse')
parser.add_argument('ramsey_stop', type=float, help='max pulse spacing (in us)')
parser.add_argument('npoints', type=int, help='number of segments')
parser.add_argument('ramsey_freq', type=float, help='virtual Ramsey frequency (in MHz)')
parser.add_argument('delay', type=float, help='delay between end of Ramsey and final msm''t (in us)')
parser.add_argument('eps1', type=float, help='amplitude of first CLEAR step')
parser.add_argument('eps2', type=float, help='amplitude of second CLEAR step')
parser.add_argument('tau', type=float, help='length of each CLEAR step (us)')
parser.add_argument('state', type=int, help='initial qubit state (0/1)')


args = parser.parse_args()

from QGL import *

q = QubitFactory(args.qubit)
qM = QubitFactory(args.meas_qubit)

pulseSpacings = np.linspace(0, args.ramsey_stop*1e-6, args.npoints)

Prep = X(q) if args.state else Id(q)

#print MEAS(qM).amp
#amp_end = abs(MEAS(qM).shape[int(-2e9*args.tau)]) #pulse amplitude at the end of the pulse, before CLEAR steps. Used to normalize eps1, eps2
#print amp_end
#print args.eps1

seqs = [[Prep, MEAS(qM, amp1 = args.eps1, amp2 = args.eps2, step_length = args.tau*1e-6), X90(q), Id(q,d), U90(q,phase = args.ramsey_freq*1e6*d), Id(q, args.delay*1e-6), MEAS(q)] for d in pulseSpacings]
seqs += create_cal_seqs((q,), 2, delay = args.delay*1e-6)

fileNames = compile_to_hardware(seqs, fileName='CLEARCal/CLEARCal',axis_descriptor=[
            time_descriptor(pulseSpacings),
            cal_descriptor((q,), 2)])
