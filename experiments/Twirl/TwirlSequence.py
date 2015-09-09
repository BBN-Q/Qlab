import argparse
import sys, os
parser = argparse.ArgumentParser()
parser.add_argument('pyqlabpath', help='path to PyQLab directory')
parser.add_argument('juliapath', help='path to Julia directory')
parser.add_argument('seq', type=int, help='sequence file identifier')


args = parser.parse_args()

sys.path.append(args.pyqlabpath)
execfile(os.path.join(args.pyqlabpath, 'startup.py'))
execfile(os.path.join(args.juliapath, 'twirl_seq.py'))


q1 = QubitFactory('q1')
q2 = QubitFactory('q2')
q3 = QubitFactory('q3')
q5 = QubitFactory('q5')
CR = QubitFactory('CR')
CR2 = QubitFactory('CR2')
CR5 = QubitFactory('CR5')

#seq = twirl_seq_4q(q1, q2, q3, q5, [Id(q1)*Id(q2)*Id(q3)*Y90(q5)*Id(CR5)*Id(CR2)*Id(CR)], "C:/Users/qlab/Documents/Julia/Twirl/twirl_IIIY90s%d.csv" %args.seq) + create_cal_seqs((q1,q2,q3,q5), 1)
seqCRd1 = ZX90_CR(q3,q1,CR)
seqCRd2 = ZX90_CR(q3,q2,CR2)
seqCRd3 = ZX90_CR(q3,q5,CR5)

seqLPN = [Y90(q3)] + seqCRd2 + [Z90m(q3)]+ seqCRd3 + [Z90m(q3)] + seqCRd1 + [Z90m(q3), Y90(q3)*X90(q1)*X90(q2)*X90(q5),X(q3)*Y90m(q1)*Y90m(q2)*Y90m(q5)] + [Y90(q3)*Y90(q1)*Y90(q2)*Y90(q5), X(q3)*X(q1)*X(q2)*X(q5)] 
seq = twirl_seq_4q(q1, q2, q3, q5, seqLPN, "C:/Users/qlab/Documents/Julia/Twirl/twirl_LPN%d.csv" %args.seq) + create_cal_seqs((q1,q2,q3,q5), 1)

fileNames = compile_to_hardware(seq, "Twirl/Twirl")