import argparse
import pickle, h5py
import numpy as np
import csv, tarfile
from QGL.drivers import APS2Pattern
parser = argparse.ArgumentParser()
parser.add_argument('seq_file', help='path to APS sequence')
parser.add_argument('instrs_file', help='path to instructions and Z indeces')
parser.add_argument('pauli_file', help='path to random GST file')
parser.add_argument('seq_ind', type=int, help='seq. number')

args = parser.parse_args()
seq = args.seq_file
instrs_file = args.instrs_file
pauli_file = args.pauli_file
seq_ind = args.seq_ind

def get_DiAC_table():
    return [
    [0, 1, 1],
    [0.5, -0.5, 0.5],
    [0, 0, 0],
    [0.5, 0.5, 0.5],
    [0, -0.5, 1],
    [0, 0, 1],
    [0, 0.5, 1],
    [0, 1, -0.5],
    [0, 1, 0],
    [0, 1, 0.5],
    [0, 0, 0.5],
    [0, 0, -0.5],
    [1, -0.5, 1],
    [1, 0.5, 1],
    [0.5, -0.5, -0.5],
    [0.5, 0.5, -0.5],
    [0.5, -0.5, 1],
    [1, -0.5, -0.5],
    [0, 0.5, -0.5],
    [-0.5, -0.5, 1],
    [1, 0.5, -0.5],
    [0.5, 0.5, 1],
    [0, -0.5, -0.5],
    [-0.5, 0.5, 1]]

def pauli_rand_DiAC(DiAC_seq, seq_ind):
    DiAC_table = get_DiAC_table()
    Zmat=[]
    print(seq_ind)
    t = tarfile.open(DiAC_seq, mode='r', fileobj=None, bufsize=10240)
    filename = "tmp-gst-1q-1024-r{num:03}.csv".format(num=seq_ind)
    info = t.getmember(filename)
    f = t.extractfile(filename).read().decode('ascii')
    gatemat = str.split(f,'\n')
    for ind,row in enumerate(gatemat[0:-1]):
        Zvec = [0]
        for pulse in str.split(row, ','):
            pulse = int(pulse)
            if pulse!=0:
                Zvec[-1] += DiAC_table[pulse-1][0]
                Zvec[-1] = np.mod(Zvec[-1]+1, 2)-1
                Zvec += [DiAC_table[pulse-1][1], DiAC_table[pulse-1][2]]
        Zmat+=[Zvec]
    return Zmat

def toggle_random_Z(filename, instrs, Z_indeces, pauli_file, seq_ind, nco_select = 1):
    MODULATOR_OP_OFFSET = 44
    NCO_SELECT_OP_OFFSET = 40
    MODULATION_CLOCK = 300e6
    FID = h5py.File(filename)
    payload_base = (0xe << MODULATOR_OP_OFFSET) | (nco_select << NCO_SELECT_OP_OFFSET)
    payload_0 = payload_base | np.uint32(np.mod(0 / (2 * np.pi), 1) * 2**28)
    payload_05 = payload_base | np.uint32(np.mod(-np.pi/2 / (2 * np.pi), 1) * 2**28)
    payload_m05 = payload_base | np.uint32(np.mod(np.pi/2 / (2 * np.pi), 1) * 2**28)
    payload_1 = payload_base | np.uint32(np.mod(np.pi / (2 * np.pi), 1) * 2**28)
    Z_mat = pauli_rand_DiAC(pauli_file, seq_ind)
    for m in range(len(Z_indeces)):
        for n in range(len(Z_indeces[m])):
            if Z_mat[m][n] == 0:
                instrs[Z_indeces[m][n]] = APS2Pattern.Instruction(0xA << 4, payload_0)
            elif Z_mat[m][n] == 0.5:
                instrs[Z_indeces[m][n]] = APS2Pattern.Instruction(0xA << 4, payload_05)
            elif Z_mat[m][n] == -0.5:
                instrs[Z_indeces[m][n]] = APS2Pattern.Instruction(0xA << 4, payload_m05)
            elif abs(Z_mat[m][n]) == 1:
                instrs[Z_indeces[m][n]] = APS2Pattern.Instruction(0xA << 4, payload_1)
            instrs[Z_indeces[m][n]].header |= 1&0x1 #set write flag to 1
    newinstrs = np.fromiter((instr.flatten() for instr in instrs), np.uint64, len(instrs))
    data = FID["chan_1/instructions/"]
    data[...] = newinstrs
    FID.close()
    return newinstrs


#read instructions and Z_indeces_file
with open(instrs_file, 'rb') as f:
    instrs, Z_indeces = pickle.load(f)

#replace random Zs
toggle_random_Z(seq, instrs, Z_indeces, pauli_file, seq_ind)

#save new Zs to file
#with open(Z_file, 'a') as f:
#    f.write(str(Z_indeces) + '\n')
