import argparse
import sys, os
parser = argparse.ArgumentParser()
parser.add_argument('pyqlabpath', help='path to PyQLab directory')
parser.add_argument('qubit', help='qubit name')
parser.add_argument('direction', help='direction (X or Y)')
parser.add_argument('numPulses', type=int, help='maximum number of 90s')
parser.add_argument('pi2Amp', type=float, help='pi2Amp')
args = parser.parse_args()

sys.path.append(args.pyqlabpath)
execfile(os.path.join(args.pyqlabpath, 'startup.py'))

q = QubitFactory(args.qubit)
q.pulseParams['pi2Amp'] = args.pi2Amp

if args.direction == 'X':
    pPulse = X90(q)
    mPulse = X90m(q)
else:
    pPulse = Y90(q)
    mPulse = Y90m(q)

# +X rotations and -X rotations
# (1, 3, 5, 7, 9, 11, 13, 15, 17) x X90
seqs = [[Id(q), MEAS(q)]] + [[pPulse]*n + [MEAS(q)] for n in range(1,2*args.numPulses,2)] + \
    [[mPulse]*n + [MEAS(q)] for n in range(1,2*args.numPulses,2)] 

fileNames = compile_to_hardware(seqs, fileName='Pi2Cal/Pi2Cal', nbrRepeats=2)
#plot_pulse_files(fileNames)
