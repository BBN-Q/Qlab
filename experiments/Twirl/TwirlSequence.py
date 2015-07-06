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

seq = twirl_seq_4q(q1, q2, q3, q5, [Id(q1)*Id(q2)*Id(q3)*Id(q5)*Id(CR5)*Id(CR2)*Id(CR)], "C:/Users/qlab/Documents/Julia/Twirl/twirl_IIIs%d.csv" %args.seq) + create_cal_seqs((q1,q2,q3,q5), 1)
fileNames = compile_to_hardware(seq, "Twirl/Twirl")