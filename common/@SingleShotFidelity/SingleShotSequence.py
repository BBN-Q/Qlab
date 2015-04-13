import argparse
import sys, os
parser = argparse.ArgumentParser()
parser.add_argument('pyqlabpath', help='path to PyQLab directory')
parser.add_argument('qubit', help='target qubit name')
args = parser.parse_args()

sys.path.append(args.pyqlabpath)
execfile(os.path.join(args.pyqlabpath, 'startup.py'))

q = QubitFactory(args.qubit)

SingleShot(q, showPlot = False)
