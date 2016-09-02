import argparse
import sys, os
parser = argparse.ArgumentParser()
parser.add_argument('pyqlabpath', help='path to PyQLab directory')
parser.add_argument('qubit', help='qubit')
parser.add_argument('frequency', type=float, help='SSB frequency')
args = parser.parse_args()

sys.path.append(args.pyqlabpath)
from QGL.ChannelLibrary import channelLib
from QGL import *

if args.qubit not in channelLib.channelDict:
	sys.exit(1)

channelLib[args.qubit].frequency = args.frequency

#updates CR channels 
q = QubitFactory(args.qubit)

for predecessor in channelLib.connectivityG.predecessors(q):
	edge = ChannelLibrary.channelLib.connectivityG.edge[predecessor][q]['channel']
	edge.frequency = args.frequency

channelLib.write_to_file()