import argparse
import sys, os
parser = argparse.ArgumentParser()
parser.add_argument('pyqlabpath', help='path to PyQLab directory')
parser.add_argument('qubit', help='qubit name')
args = parser.parse_args()

sys.path.append(args.pyqlabpath)
execfile(os.path.join(args.pyqlabpath, 'startup.py'))

q = QubitFactory(args.qubit)

numPsId = 10 # number pseudoidentities
angleShifts = (np.pi/180.)*np.linspace(-3.0, 3.0, 9)

seqs = []
for angle in angleShifts:
    SPAMBlock = [X(q), U(q, phase=np.pi/2+angle), X(q), U(q, phase=np.pi/2+angle)]
    seqs += [[Id(q), MEAS(q)]] + [[Y90(q)] + SPAMBlock*n + [X90m(q), MEAS(q)] for n in range(numPsId)]

# pi pulse for scaling
seqs += [[X(q), MEAS(q)]]

fileNames = compile_to_hardware(seqs, fileName='SPAM/SPAM', nbrRepeats=1)
# plot_pulse_files(fileNames)
