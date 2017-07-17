'''
functions for GST experiments and seq. randomizations run from Matlab
'''

import os

'''
Return indeces of UPDATE_FRAME instructions
'''
def find_frame_instrs(filename):
    FID = h5py.File(filename)
    instrs = [APS2Pattern.Instruction.unflatten(instr) for instr in FID["chan_1"]["instructions"].value]
    Z_indeces = []
    seq_num = -1
    for k, instr in enumerate(instrs):
        if (instr.header >> 4 & 0xf == 10) and (instr.payload >> 45 & 0x7) == 7: #check if the instruction is an UPDATE_FRAME
            Z_indeces[seq_num].append(k)
        elif (instr.header >> 4 & 0xf == 2): #WAIT
            Z_indeces.append([])
            seq_num += 1
    FID.close()
    return instrs, Z_indeces

def save_frame_instrs(filename, filepath):
    instr_file = os.path.join(filepath, 'GST_1q_Z.pickle')
    instrs, Z_indeces = find_frame_instrs(filename)
    with open(instr_file, 'wb') as f:
        pickle.dump([instrs, Z_indeces], f) #python scripts can't output to matlab...
    return instrs, Z_indeces
'''
low-level function to enable/disable Z rotations
Return a list of 0/1 for off/on Z.

filename: full path and filename
instrs: full instruction set
Z_indeces: indeces of instructions = UPDATE_FRAME
nco_select: choose nco, if the physical channel is shared.
'''
def toggle_random_Z(filename, instrs, Z_indeces, nco_select = 1):
    MODULATOR_OP_OFFSET = 44
    NCO_SELECT_OP_OFFSET = 40
    MODULATION_CLOCK = 300e6
    FID = h5py.File(filename)
    payload_base = (0xe << MODULATOR_OP_OFFSET) | (nco_select << NCO_SELECT_OP_OFFSET)
    payload_0 = payload_base | np.uint32(np.mod(0 / (2 * np.pi), 1) * 2**28)
    payload_1 = payload_base | np.uint32(np.mod(pi / (2 * np.pi), 1) * 2**28)
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
            instrs[Z_indeces[m][n]].header |= 1&0x1 #set write flag to 1
            #TODO: determine whether a final X per sequence is played or not ??
    newinstrs = np.fromiter((instr.flatten() for instr in instrs), np.uint64, len(instrs))
    data = FID["chan_1/instructions/"]
    data[...] = newinstrs
    FID.close()
    return random_Z

#update Z gates in DiAC_seq reading Clifford numbers from pre-generated GST files
def pauli_rand_DiAC(DiAC_seq):
    DiAC_table = get_DiAC_table()
    Zmat=[]
    t = tarfile.open(DiAC_seq, mode='r', fileobj=None, bufsize=10240)
    for n in range(1,2):
        filename = 'tmp-gst-1q-1024-r%s.csv' %format(n,'03')
        info = t.getmember(filename)
        f = t.extractfile(filename).read().decode('ascii')
        gatemat = str.split(f,'\n')
        for ind,row in enumerate(gatemat[0:-1]):
            Zvec = [0]
            for pulse in str.split(row, ','):
                pulse = int(pulse)
                if pulse!=0:
                    Zvec[-1] += np.mod(Zvec[-1] + DiAC_table[pulse-1][0], 2)
                    Zvec += [DiAC_table[pulse-1][1], DiAC_table[pulse-1][2]]
            Zmat+=[Zvec]
    return Zmat

#1q gst with random interleaved Z
def GST_1q_Z(filename, qubit):
    import csv, tarfile
    seqs=[]
    with open('U:\data\RGST\gst-1q-1024.csv', 'rb') as fid:

        gatemat = csv.reader(fid, delimiter=',', quotechar='|')

        for ind,row in enumerate(gatemat):
            seq = []
            for key in row:
                if key=='1':
                    seq+=[Id(q), Z(q)] #AC(q,0) is a zero-length Id
                elif key!='0':
                    seq+=[AC(q,int(key)-1), Z(q)]
            seq+=[MEAS(q)]
            seqs+=[seq]
        seqs+=create_cal_seqs((q,),500)
    filenames = compile_to_hardware(seqs,'GST\GST')

#1q gst with DiAC pulses
def GST_1q_DiAC(filename, qubit):
    import csv, tarfile
    seqs=[]
    with open('U:\data\RGST\gst-1q-1024.csv', 'rb') as fid:

        gatemat = csv.reader(fid, delimiter=',', quotechar='|')

        for ind,row in enumerate(gatemat):
            seq = []
            for key in row:
                seq+=[DiAC(q,int(key)-1,compiled = False)]
            seq+=[MEAS(q)]
            seqs+=[seq]
        seqs+=create_cal_seqs((q,),500)
    filenames = compile_to_hardware(seqs,'GST\GST')
