import argparse
import sys, os
parser = argparse.ArgumentParser()
parser.add_argument('pyqlabpath', help='path to PyQLab directory')
parser.add_argument('physChan', help='physChan')
parser.add_argument('ampFactor', type=float, help='ampFactor')
parser.add_argument('phaseSkew', type=float, help='phaseSkew')
args = parser.parse_args()

sys.path.append(args.pyqlabpath)
from Libraries import channelLib

if args.physChan not in channelLib.channelDict:
	sys.exit(1)

channelLib[args.physChan].ampFactor = args.ampFactor
channelLib[args.physChan].phaseSkew = args.phaseSkew