import argparse
import sys, os
parser = argparse.ArgumentParser()
parser.add_argument('pyqlabpath', help='path to PyQLab directory')
parser.add_argument('qubit', help='qubit name')
parser.add_argument('direction', help='direction (X or Y)')
parser.add_argument('numPulses', type=int, help='maximum number of 180s')
parser.add_argument('piAmp', type=float, help='piAmp')
args = parser.parse_args()

sys.path.append(args.pyqlabpath)
execfile(os.path.join(args.pyqlabpath, 'startup.py'))

q = QubitFactory(args.qubit)
q.pulseParams['piAmp'] = args.piAmp

if args.direction == 'X':
    seqs = [[Id(q), MEAS(q)]] + [[X90(q)] + [X(q)]*n + [MEAS(q)] for n in range(args.numPulses)] + \
           [[X90m(q)] + [Xm(q)]*n + [MEAS(q)] for n in range(args.numPulses)]
else:
    seqs = [[Id(q), MEAS(q)]] + [[Y90(q)] + [Y(q)]*n + [MEAS(q)] for n in range(args.numPulses)] + \
           [[Y90m(q)] + [Ym(q)]*n + [MEAS(q)] for n in range(args.numPulses)]

fileNames = compile_to_hardware(seqs, fileName='PiCal/PiCal', nbrRepeats=2)
# plot_pulse_files(fileNames)
