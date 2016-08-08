import argparse
import sys, os
parser = argparse.ArgumentParser()
parser.add_argument('qubit', help='qubit name')
args = parser.parse_args()

from QGL import *

q = QubitFactory(args.qubit)

numsteps = 40; #should be even

#Don't use zero because if there is a mixer offset it will be completely
#different because the source is never pulsed
amps = np.hstack((np.arange(-1, 0, 2./numsteps), np.arange(2./numsteps, 1+2./numsteps, 2./numsteps)))

seqs = [[Xtheta(q, amp=a), MEAS(q)] for a in amps] + [[Ytheta(q, amp=a), MEAS(q)] for a in amps]
fileNames = compile_to_hardware(seqs, fileName='Rabi/Rabi')
# plot_pulse_files(fileNames)
