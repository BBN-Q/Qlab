import argparse
import sys, os
parser = argparse.ArgumentParser()
parser.add_argument('pyqlabpath', help='path to PyQLab directory')
parser.add_argument('qubit', help='qubit')
parser.add_argument('length', type=float, help='length')
parser.add_argument('phase', type=float, help='phase')
args = parser.parse_args()

sys.path.append(args.pyqlabpath)
from Libraries import channelLib

if args.qubit not in channelLib.channelDict:
	sys.exit(1)

channelLib[args.qubit].pulseParams['length'] = args.length
channelLib[args.qubit].pulseParams['phase'] = args.phase

channelLib.write_to_file()