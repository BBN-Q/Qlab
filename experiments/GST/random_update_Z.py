import argparse
import pickle, h5py
import numpy as np
from QGL.drivers import APS2Pattern
parser = argparse.ArgumentParser()
parser.add_argument('seq_file', help='path to APS sequence')
parser.add_argument('instrs_file', help='path to instructions and Z indeces')
parser.add_argument('Z_file', help='path to register of applied Z rotations')

args = parser.parse_args()
seq = args.seq_file
instrs_file = args.instrs_file
Z_file = args.Z_file

def toggle_random_Z(filename, instrs, Z_indeces, nco_select = 1):
    MODULATOR_OP_OFFSET = 44
    NCO_SELECT_OP_OFFSET = 40
    MODULATION_CLOCK = 300e6
    FID = h5py.File(filename)
    payload_base = (0xe << MODULATOR_OP_OFFSET) | (nco_select << NCO_SELECT_OP_OFFSET)
    payload_0 = payload_base | np.uint32(np.mod(0 / (2 * np.pi), 1) * 2**28)
    payload_1 = payload_base | np.uint32(np.mod(np.pi / (2 * np.pi), 1) * 2**28)
    random_Z = []
    seq_num = -1
    for m in range(len(Z_indeces)):
        random_Z.append([])
        for n in range(len(Z_indeces[m])):
            Z_k = np.random.randint(2) #add random phase (0 or pi)
            random_Z[m].append(Z_k)
            if Z_k == 0:
                instrs[Z_indeces[m][n]] = APS2Pattern.Instruction(0xA << 4, payload_0)
            else:
                instrs[Z_indeces[m][n]] = APS2Pattern.Instruction(0xA << 4, payload_1)

            #TODO: determine whether a final X per sequence is played or not ??
    newinstrs = np.fromiter((instr.flatten() for instr in instrs), np.uint64, len(instrs))
    data = FID["chan_1/instructions/"]
    data[...] = newinstrs
    FID.close()
    return random_Z

#read instructions and Z_indeces_file
with open(instrs_file, 'rb') as f:
    instrs, Z_indeces = pickle.load(f)

#replace random Zs
Z_indeces = toggle_random_Z(seq, instrs, Z_indeces)

#save new Zs to file
with open(Z_file, 'a') as f:
    f.write(str(Z_indeces) + '\n')
