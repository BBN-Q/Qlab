import argparse
import sys, os
parser = argparse.ArgumentParser()
parser.add_argument('pyqlabpath', help='path to PyQLab directory')
parser.add_argument('nbrSegments', type=int, help='nbrSegments')
args = parser.parse_args()

sys.path.append(args.pyqlabpath)
from Libraries import instrumentLib

if 'X6' not in instrumentLib.instrDict.keys():
	sys.exit(1)

X6=instrumentLib['X6']
X6.nbrSegments = int(args.nbrSegments)

instrumentLib.write_to_file()