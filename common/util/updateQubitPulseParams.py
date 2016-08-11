import argparse
import sys, os
parser = argparse.ArgumentParser()
parser.add_argument('pyqlabpath', help='path to PyQLab directory')
parser.add_argument('qubit', help='qubit')
parser.add_argument('piAmp', type=float, help='piAmp')
parser.add_argument('pi2Amp', type=float, help='pi2Amp')
parser.add_argument('dragScaling', type=float, help='dragScaling')
args = parser.parse_args()

sys.path.append(args.pyqlabpath)
from QGL.ChannelLibrary import channelLib

if args.qubit not in channelLib.channelDict:
	sys.exit(1)

channelLib[args.qubit].pulseParams['piAmp'] = args.piAmp
channelLib[args.qubit].pulseParams['pi2Amp'] = args.pi2Amp
channelLib[args.qubit].pulseParams['dragScaling'] = args.dragScaling

channelLib.write_to_file()