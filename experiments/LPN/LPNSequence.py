import argparse
import sys, os
from copy import copy

parser = argparse.ArgumentParser()
parser.add_argument('pyqlabpath', help='path to PyQLab directory')
parser.add_argument('seqtype', help='c/q for classical/quantum')
parser.add_argument('seqkey', help='implemented oracle')
parser.add_argument('ancilla', help='ancilla qubit name')
parser.add_argument('data1', help='data qubit 1 name')
parser.add_argument('data2', help='data qubit 2 name')
parser.add_argument('data3', help='data qubit 3 name')
parser.add_argument('CR1', help='CR gate 1 name')
parser.add_argument('CR2', help='CR gate 2 name')
parser.add_argument('CR3', help='CR gate 3 name')


args = parser.parse_args()

sys.path.append(args.pyqlabpath)
execfile(os.path.join(args.pyqlabpath, 'startup.py'))
a = QubitFactory(args.ancilla)
d1 = QubitFactory(args.data1)
d2 = QubitFactory(args.data2)
d3 = QubitFactory(args.data3)
CRd1 = QubitFactory(args.CR1)
CRd2 = QubitFactory(args.CR2)
CRd3 = QubitFactory(args.CR3)

seqkey = args.seqkey
seqtype = args.seqtype

seqCRd1 = ZX90_CR(a,d1,CRd1)
seqCRd2 = ZX90_CR(a,d2,CRd2)
seqCRd3 = ZX90_CR(a,d3,CRd3)

if seqtype == 'q':
	Hadgates = [Y90(a)*Y90(d1)*Y90(d2)*Y90(d3), X(a)*X(d1)*X(d2)*X(d3)]
else:
	Hadgates = []

if seqkey == '111':
	seq = [Y90(a)] + seqCRd2 + [Z90m(a)]+ seqCRd3 + [Z90m(a)] + seqCRd1 + [Z90m(a), Y90(a)*X90(d1)*X90(d2)*X90(d3),X(a)*Y90m(d1)*Y90m(d2)*Y90m(d3)] + Hadgates + [MEAS(a)*MEAS(d1)*MEAS(d2)*MEAS(d3)] 
elif seqkey == '110':
    seq = [Y90(a)*Y90(d3)] + seqCRd2 + [Z90m(a)]+ seqCRd1 + [Z90m(a), Y90(a)*X90(d1)*X90(d2),X(a)*Y90m(d1)*Y90m(d2)] + Hadgates + [MEAS(a)*MEAS(d1)*MEAS(d2)*MEAS(d3)] 
elif seqkey == '101':
	seq = [Y90(a)*Y90(d2)] + seqCRd3 + [Z90m(a)]+ seqCRd1 + [Z90m(a), Y90(a)*X90(d1)*X90(d3),X(a)*Y90m(d1)*Y90m(d3)] + Hadgates + [MEAS(a)*MEAS(d1)*MEAS(d2)*MEAS(d3)] 
elif seqkey == '100':
	seq = [Y90(a)*Y90(d2)*Y90(d3)] + seqCRd1 + [Z90m(a), Y90(a)*X90(d1),X(a)*Y90m(d1)] + Hadgates + [MEAS(a)*MEAS(d1)*MEAS(d2)*MEAS(d3)] 
elif seqkey == '011':
	seq = [Y90(a)*Y90(d1)] + seqCRd2 + [Z90m(a)]+ seqCRd3 + [Z90m(a)] + [Y90(a)*X90(d2)*X90(d3),X(a)*Y90m(d2)*Y90m(d3)] + Hadgates + [MEAS(a)*MEAS(d1)*MEAS(d2)*MEAS(d3)] 
elif seqkey == '010':
	seq = [Id(CRd1), Y90(a)*Y90(d1)*Y90(d3)] + seqCRd2 + [Z90m(a)] + [Y90(a)*X90(d2),X(a)*Y90m(d2)] + Hadgates + [MEAS(a)*MEAS(d1)*MEAS(d2)*MEAS(d3)] #the Id on CRd1 is necessary to overwrite the seq. in the APS, with the current config. 
elif seqkey == '001':
	seq = [Y90(a)*Y90(d1)*Y90(d2)] + seqCRd3 + [Z90m(a)]+  [Y90(a)*X90(d3),X(a)*Y90m(d3)] + Hadgates + [MEAS(a)*MEAS(d1)*MEAS(d2)*MEAS(d3)] 
elif seqkey == '000':
	seq = [Id(CRd1), Id(a)*Y90(d1)*Y90(d2)*Y90(d3)] + Hadgates + [MEAS(a)*MEAS(d1)*MEAS(d2)*MEAS(d3)]

seqs = []
for _ in range(10):
	seqs+=[copy(seq)]

#add calibration points
seqs+=[[MEAS(a)*MEAS(d1)*MEAS(d2)*MEAS(d3)]]
seqs+=[[X(d3), MEAS(a)*MEAS(d1)*MEAS(d2)*MEAS(d3)]]
seqs+=[[X(a), MEAS(a)*MEAS(d1)*MEAS(d2)*MEAS(d3)]]
seqs+=[[X(d2), MEAS(a)*MEAS(d1)*MEAS(d2)*MEAS(d3)]]
seqs+=[[X(d1), MEAS(a)*MEAS(d1)*MEAS(d2)*MEAS(d3)]]

fileNames = compile_to_hardware(seqs, 'LPN/LPN')