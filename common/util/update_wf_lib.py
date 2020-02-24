#update waveforms in target sequence from current ChanParams settings.
#Warning: this updates all channels, beware of possible conflicts
import argparse
import sys, os
parser = argparse.ArgumentParser()
parser.add_argument('pyqlabpath', help='path to PyQLab directory')
parser.add_argument('seqPath', help='path of sequence to be updated')
parser.add_argument('seqName', help='name of sequence to be updated')
args = parser.parse_args()

from QGL import *
from QGL.drivers import APS2Pattern
from QGL import config

qubits = ChannelLibrary.channelLib.connectivityG.nodes()
edges = ChannelLibrary.channelLib.connectivityG.edges()

pulseList = []
for q in qubits:
	if config.pulse_primitives_lib == 'standard':
		pulseList.append([AC(q, ct) for ct in range(24)])
	else:
		pulseList.append([X90(q), Y90(q), X90m(q), Y90m(q)])
for edge in edges:
	pulseList.append(ZX90_CR(edge[0],edge[1]))
#update waveforms in the desired sequence (generated with APS2Pattern.SAVE_WF_OFFSETS = True)
PatternUtils.update_wf_library(pulseList, os.path.normpath(os.path.join(args.seqPath, args.seqName)))