module APSInstructions

export APSInstr, instruction, wf_entry, flow_entry
# , LLcall, LLreturn, LLgoto, LLrepeat, LLload, waitTrig!, write_file, testSeq, testSeq2, simpleSeq

import Base.show

type APSInstr
	data::Vector{Uint16}
	name::Symbol
	target::Symbol
end

const emptySymbol = symbol("")

APSInstr(data::Vector{Uint16}) = APSInstr(data, emptySymbol, emptySymbol)
APSInstr(data::Vector{Uint16}, name::Symbol) = APSInstr(data, name, emptySymbol)

function show(io::IO, e::APSInstr)
	for b in e.data
		@printf(io, "%04x", b)
	end
end

function write_file(filename, seq)
	open(filename, "w") do f
		for s = seq
			println(f, s)
		end
	end
end

# instruction encodings
WFM = 0x0000
TRIG = 0x0001
WAIT_TRIG = 0x0002
LOAD_REPEAT = 0x0003
DEC_REPEAT = 0x0004
GOTO = 0x0005
CALL = 0x0006
RET = 0x0007
SYNC = 0x0008

#The top bits of the 48 bit instruction payload set the sync or wait for trigger in the playback engines
WAIT_TRIG_INSTR_WORD = 1 << 14;
SYNC_INSTR_WORD = 1 << 15;

# CMP op encodings
EQUAL = 0x0004 | 0x0000
NOTEQUAL = 0x0004 | 0x0001
GREATERTHAN = 0x0004 | 0x0002
LESSTHAN = 0x0004 | 0x0003

function wf_entry(addr, count; TAPair=false, writeData=true, label=emptySymbol)
	instr = APSInstr(Uint16[WFM << 12 | (writeData ? 1 : 0) << 8, (TAPair ? 1 : 0) << 13  | count >> 8 , (count & 0xff) << 8 | addr >> 16, addr & 0xff], label)
	instr
end

function trig_entry(target, state, count, transitionWord; writeData=true, label=emptySymbol)
	instr = APSInstr(Uint16[TRIG << 12 | (writeData ? 1 : 0) << 8 | (target & 0x3), 0, (transitionWord & 0xf) << 1 | (state & 0x1), count & 0xff], label)
	instr
end

function flow_entry(cmd, cmp=0, mask=0, addr=0; label=emptySymbol)
	instr = APSInstr(Uint16[(cmd << 12) | (cmp << 8) | (mask & 0xff), 0, addr >> 16, addr & 0xff], label)

	if (cmd == WAIT_TRIG)
		instr.data[1] |= 1 << 8;
		instr.data[2] = WAIT_TRIG_INSTR_WORD;
	end
	if (cmd == SYNC)
		instr.data[1] |= 1 << 8;
		instr.data[2] = SYNC_INSTR_WORD;
	end
	instr
end



# # function LLdata(addr, count, repeat, trigA=0, TAPair=0; label=emptySymbol)
# # 	entry = LLentry(Uint16[TAPair << 14 | addr >> 16, addr & 0xff, count, trigA, 0x0000, repeat])
# # 	entry.name = label
# # 	entry
# # end

# # function LLcommand(cmd, mask=0x0000, addr::Integer=0x000000, count=0x0000; label=emptySymbol)
# # 	entry = LLentry(Uint16[cmd << 8 | mask, addr >> 16, addr & 0xff, count, 0x0000, 0x0000])
# # 	entry.name = label
# # 	entry
# # end

# # function LLcommand(cmd, mask, addr::Symbol, count=0; label=emptySymbol)
# # 	entry = LLentry(Uint16[cmd << 8 | mask, 0, 0, count, 0x0000, 0x0000])
# # 	entry.name = label
# # 	entry.target = addr
# # 	entry
# # end

# # LLcall(addr; label=emptySymbol) = LLcommand(CALL, 0, addr; label=label)
# # LLcall(mask, addr; label=emptySymbol) = LLcommand(CALL | EQUAL << 3, mask, addr; label=label)
# # LLreturn(; label=emptySymbol) = LLcommand(RET; label=label)
# # LLreturn(mask; label=emptySymbol) = LLcommand(RET | EQUAL << 3, mask; label=label)
# # LLgoto(addr; label=emptySymbol) = LLcommand(GOTO, 0, addr; label=label)
# # LLrepeat(addr; label=emptySymbol) = LLcommand(REPEAT, 0, addr; label=label)
# # LLload(count; label=emptySymbol) = LLcommand(LOAD, 0, 0, count; label=label)

# # function waitTrig!(entry)
# # 	entry.data[1] |= 1 << 15
# # 	entry
# # end

# # updates the address in a command instruction
# function updateAddr!(entry, addr)
# 	entry.data[3] = addr >> 16
# 	entry.data[4] = addr & 0xff
# 	entry
# end

function resolve_symbols!(seq)
	labeledEntries = filter((x) -> x[2].name != emptySymbol, collect(enumerate(seq)))
	symbolDict = {entry.name => idx-1 for (idx, entry) in labeledEntries}
	println(symbolDict)
	for entry in seq
		if entry.target != emptySymbol && haskey(symbolDict, entry.target)
			#println("Updating target of $(entry.target) to $(symbolDict[entry.target]). Before:")
			#println(entry)
			updateAddr!(entry, symbolDict[entry.target])
			#println("After:")
			#println(entry)
		end
	end
	seq
end

# # test sequences

function simpleSeq()
	seq = APSInstr[]
	push!(seq, wf_entry(0, 63; label=:A))
	push!(seq, wf_entry(0, 7; label=:B))
	push!(seq, wf_entry(8, 7; label=:C))
	push!(seq, wf_entry(16, 7))
	push!(seq, wf_entry(24, 7))
	push!(seq, wf_entry(32, 7))
	push!(seq, flow_entry(GOTO, 0, 0, 0))
	resolve_symbols!(seq)
end

function ramsey()
	seq = APSInstr[]
	for delay in 10:10:100
		push!(seq, flow_entry(SYNC))
		push!(seq, flow_entry(WAIT_TRIG))
		push!(seq, wf_entry(0, 9, TAPair=true, writeData=false))
		push!(seq, trig_entry(0, 0, 8, 0x3))
		push!(seq, wf_entry(8, 7))
		push!(seq, trig_entry(0, 1, 7, 0xC))
		push!(seq, wf_entry(0, delay, TAPair=true))
		push!(seq, trig_entry(0, 0, delay, 0x3))
		push!(seq, wf_entry(16, 7))
		push!(seq, trig_entry(0, 1, 7, 0xC))
	end
	push!(seq, flow_entry(GOTO))
	resolve_symbols!(seq)
end

# function testSeqA()
# 	seq = LLentry[]
# 	push!(seq, LLdata(0, 7, 0, 0))		# addr, cout, repeat, trigA                         # 0
# 	push!(seq, LLdata(8, 7, 1, 0))                                                          # 1
# 	push!(seq, LLdata(0, 7, 0, 2))                                                          # 2
# 	seq
# end

# function testSeqB()
# 	seq = testSeq()
# 	push!(seq, LLload(1))				          # load global repeat count = 1             # 3
# 	push!(seq, LLdata(0, 7, 0, 0; label=:A))	  # wf - addr, cout, repeat, trigA           # 4 - A
# 	push!(seq, LLcall(0x01, :C))                  # mask, addr                               # 5 
# 	push!(seq, LLdata(8, 7, 0, 0))                # wf - addr, cout, repeat, trigA           # 6
# 	push!(seq, LLrepeat(:A))			          # repeat - ll - addr                       # 7
# 	push!(seq, LLload(2))				          # load global repeat 2                     # 8
# 	push!(seq, LLdata(0, 7, 0, 4; label=:B))      # wf - addr, cout, repeat, trigA              # 9  - B
# 	push!(seq, LLdata(8, 7, 0, 2; label=:C))      # wf - addr, cout, repeat, trigA              # 10 - C
# 	push!(seq, LLdata(0, 7, 0, 0))                # wf - addr, cout, repeat, trigA              # 11
# 	push!(seq, LLdata(8, 7, 0, 0))                # wf - addr, cout, repeat, trigA              # 12
# 	push!(seq, LLrepeat(:B))                      # repeat - ll - addr                       # 13
# 	push!(seq, LLdata(0x00, 7, 0, 0; label=:D))   # wf - addr, cout, repeat, trigA           # 14 - D
# 	push!(seq, LLreturn(0x02))                    # return - mask                            # 15
# 	push!(seq, LLgoto(:D))                        # jump to addr  (should be the repeat 9)   # 16
# 	resolve_symbols!(seq)
# end

# function testCacheJump()
# 	seq = LLentry[]
# 	push!(seq, LLdata(1, 7, 0; label=:A))	# 0
# 	push!(seq, LLdata(2, 7, 0 ))
# 	push!(seq, LLdata(3, 7, 0 ))	
# 	push!(seq, LLdata(4, 7, 0 ))
# 	push!(seq, LLdata(5, 7, 0 ))	
# 	push!(seq, LLgoto(:C))      			# 5 - jump C                 
# 	push!(seq, LLdata(6, 7, 0; label=:B))	# 6
# 	push!(seq, LLdata(7, 7, 0))
# 	push!(seq, LLdata(8, 7, 0))	
# 	push!(seq, LLdata(9, 7, 0))
# 	push!(seq, LLdata(10, 7, 0))
# 	push!(seq, LLgoto(:A))                  # 11 - jump A   
# 	push!(seq, LLdata(11, 7, 0; label=:C))	# 12
# 	push!(seq, LLdata(12, 7, 0))
# 	push!(seq, LLdata(13, 7, 0;))	
# 	push!(seq, LLdata(14, 7, 0;))
# 	push!(seq, LLdata(16, 7, 0;))	
# 	push!(seq, LLgoto(:B))   				# 17
# 	resolve_symbols!(seq)
# end

# function testCacheJump2()
#         seq = LLentry[]
#         push!(seq, LLdata(1, 7, 0; label=:A))	# 0
#         push!(seq, LLgoto(:C))      			# 1 - jump C
#         push!(seq, LLdata(3, 7, 0; label=:B))   # 2
#         push!(seq, LLgoto(:D))      			# 3 - jump D
#         push!(seq, LLdata(5, 7, 0; label=:C))	# 4
#         push!(seq, LLgoto(:B))      			# 5 - jump B
#         push!(seq, LLdata(7, 7, 0; label=:D))   # 6
#         push!(seq, LLgoto(:A))      			# 7 - jump C
#         resolve_symbols!(seq)
# end

# function testCacheJump3()
#         seq = LLentry[]
#         push!(seq, LLdata(1, 7, 0))	# 0
#         push!(seq, LLgoto(:A))      	# 1 - jump A
#         push!(seq, LLdata(3, 7, 0))	# 2
#         push!(seq, LLdata(4, 7, 0))	# 3
#         push!(seq, LLdata(5, 7, 0))	# 4
#         push!(seq, LLdata(6, 7, 0))	# 5
#         push!(seq, LLdata(7, 7, 0))	# 6
#         push!(seq, LLdata(8, 7, 0))	# 7
#         push!(seq, LLdata(9, 7, 0))	# 8
#         push!(seq, LLdata(10, 7,0; label=:A))	# 9
#         push!(seq, LLgoto(:C))      	# 10 - jump C
#         push!(seq, LLdata(12, 7, 0; label=:B))   # 11
#         push!(seq, LLgoto(:D))      	# 12 - jump D
#         push!(seq, LLdata(14, 7, 0; label=:C))	# 13
#         push!(seq, LLgoto(:B))      	# 14
#         push!(seq, LLdata(16, 7, 0; label=:D))   # 15
#         push!(seq, LLgoto(:A))  	# 16
#         resolve_symbols!(seq)
# end

function writeTestFiles()
        seq = simpleSeq();
        write_file("simpleSeq.dat", seq)
end

end
