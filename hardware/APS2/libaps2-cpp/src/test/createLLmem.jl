module LinkListFormat

export LLdata, LLcall, LLreturn, LLgoto, LLrepeat, LLload, waitTrig!, write_file, testSeq, testSeq2, simpleSeq

import Base.show

type LLentry
	data::Vector{Uint16}
	name::Symbol
	target::Symbol
end

const emptySymbol = symbol("")

LLentry(data::Vector{Uint16}) = LLentry(data, emptySymbol, emptySymbol)

function show(io::IO, e::LLentry)
	out = ""
	for b in e.data
		out *= string(b)[3:end]
	end
	print(io, out)
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
LOAD = 0x0001
REPEAT = 0x0002
GOTO = 0x0003
CALL = 0x0004
RET = 0x0005

# CMP op encodings
EQUAL = 0x0004 | 0x0000
NOTEQUAL = 0x0004 | 0x0001
GREATERTHAN = 0x0004 | 0x0002
LESSTHAN = 0x0004 | 0x0003

function LLdata(addr, count, repeat, trigA=0, TAPair=0; label=emptySymbol)
	entry = LLentry(Uint16[TAPair << 14 | addr >> 16, addr & 0xff, count, trigA, 0x0000, repeat])
	entry.name = label
	entry
end

function LLcommand(cmd, mask=0x0000, addr::Integer=0x000000, count=0x0000; label=emptySymbol)
	entry = LLentry(Uint16[cmd << 8 | mask, addr >> 16, addr & 0xff, count, 0x0000, 0x0000])
	entry.name = label
	entry
end

function LLcommand(cmd, mask, addr::Symbol, count=0; label=emptySymbol)
	entry = LLentry(Uint16[cmd << 8 | mask, 0, 0, count, 0x0000, 0x0000])
	entry.name = label
	entry.target = addr
	entry
end

LLcall(addr; label=emptySymbol) = LLcommand(CALL, 0, addr; label=label)
LLcall(mask, addr; label=emptySymbol) = LLcommand(CALL | EQUAL << 3, mask, addr; label=label)
LLreturn(; label=emptySymbol) = LLcommand(RET; label=label)
LLreturn(mask; label=emptySymbol) = LLcommand(RET | EQUAL << 3, mask; label=label)
LLgoto(addr; label=emptySymbol) = LLcommand(GOTO, 0, addr; label=label)
LLrepeat(addr; label=emptySymbol) = LLcommand(REPEAT, 0, addr; label=label)
LLload(count; label=emptySymbol) = LLcommand(LOAD, 0, 0, count; label=label)

function waitTrig!(entry)
	entry.data[1] |= 1 << 15
	entry
end

# updates the address in a command instruction
function updateAddr!(entry, addr)
	entry.data[2] = addr >> 16
	entry.data[3] = addr & 0xff
	entry
end

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

# test sequences

function simpleSeq()
	seq = LLentry[]
	push!(seq, waitTrig!(LLdata(0, 255, 0; label=:A)))
	push!(seq, LLdata(0, 7, 0, 1; label=:B))
	push!(seq, LLdata(8, 7, 0; label=:C))
	push!(seq, LLdata(16, 7, 0; label=:D))
	push!(seq, LLdata(24, 7, 0; label=:E))
	push!(seq, LLdata(16, 7, 0))
	push!(seq, LLdata(8, 7, 0))
	push!(seq, LLdata(0, 7, 0, 1))
	push!(seq, LLgoto(:A))
	resolve_symbols!(seq)
end

function testSeqA()
	seq = LLentry[]
	push!(seq, LLdata(0, 7, 0, 0))		# addr, cout, repeat, trigA                         # 0
	push!(seq, LLdata(8, 7, 1, 0))                                                          # 1
	push!(seq, LLdata(0, 7, 0, 2))                                                          # 2
	seq
end

function testSeqB()
	seq = testSeq()
	push!(seq, LLload(1))				          # load global repeat count = 1             # 3
	push!(seq, LLdata(0, 7, 0, 0; label=:A))	  # wf - addr, cout, repeat, trigA           # 4 - A
	push!(seq, LLcall(0x01, :C))                  # mask, addr                               # 5 
	push!(seq, LLdata(8, 7, 0, 0))                # wf - addr, cout, repeat, trigA           # 6
	push!(seq, LLrepeat(:A))			          # repeat - ll - addr                       # 7
	push!(seq, LLload(2))				          # load global repeat 2                     # 8
	push!(seq, LLdata(0, 7, 0, 4; label=:B))      # wf - addr, cout, repeat, trigA              # 9  - B
	push!(seq, LLdata(8, 7, 0, 2; label=:C))      # wf - addr, cout, repeat, trigA              # 10 - C
	push!(seq, LLdata(0, 7, 0, 0))                # wf - addr, cout, repeat, trigA              # 11
	push!(seq, LLdata(8, 7, 0, 0))                # wf - addr, cout, repeat, trigA              # 12
	push!(seq, LLrepeat(:B))                      # repeat - ll - addr                       # 13
	push!(seq, LLdata(0x00, 7, 0, 0; label=:D))   # wf - addr, cout, repeat, trigA           # 14 - D
	push!(seq, LLreturn(0x02))                    # return - mask                            # 15
	push!(seq, LLgoto(:D))                        # jump to addr  (should be the repeat 9)   # 16
	resolve_symbols!(seq)
end

function testCacheJump()
	seq = LLentry[]
	push!(seq, LLdata(1, 7, 0; label=:A))	# 0
	push!(seq, LLdata(2, 7, 0 ))
	push!(seq, LLdata(3, 7, 0 ))	
	push!(seq, LLdata(4, 7, 0 ))
	push!(seq, LLdata(5, 7, 0 ))	
	push!(seq, LLgoto(:C))      			# 5 - jump C                 
	push!(seq, LLdata(6, 7, 0; label=:B))	# 6
	push!(seq, LLdata(7, 7, 0))
	push!(seq, LLdata(8, 7, 0))	
	push!(seq, LLdata(9, 7, 0))
	push!(seq, LLdata(10, 7, 0))
	push!(seq, LLgoto(:A))                  # 11 - jump A   
	push!(seq, LLdata(11, 7, 0; label=:C))	# 12
	push!(seq, LLdata(12, 7, 0))
	push!(seq, LLdata(13, 7, 0;))	
	push!(seq, LLdata(14, 7, 0;))
	push!(seq, LLdata(16, 7, 0;))	
	push!(seq, LLgoto(:B))   				# 17
	resolve_symbols!(seq)
end

function testCacheJump2()
        seq = LLentry[]
        push!(seq, LLdata(1, 7, 0; label=:A))	# 0
        push!(seq, LLgoto(:C))      			# 1 - jump C
        push!(seq, LLdata(3, 7, 0; label=:B))   # 2
        push!(seq, LLgoto(:D))      			# 3 - jump D
        push!(seq, LLdata(5, 7, 0; label=:C))	# 4
        push!(seq, LLgoto(:B))      			# 5 - jump B
        push!(seq, LLdata(7, 7, 0; label=:D))   # 6
        push!(seq, LLgoto(:A))      			# 7 - jump C
        resolve_symbols!(seq)
end

function testCacheJump3()
        seq = LLentry[]
        push!(seq, LLdata(1, 7, 0))	# 0
        push!(seq, LLgoto(:A))      	# 1 - jump A
        push!(seq, LLdata(3, 7, 0))	# 2
        push!(seq, LLdata(4, 7, 0))	# 3
        push!(seq, LLdata(5, 7, 0))	# 4
        push!(seq, LLdata(6, 7, 0))	# 5
        push!(seq, LLdata(7, 7, 0))	# 6
        push!(seq, LLdata(8, 7, 0))	# 7
        push!(seq, LLdata(9, 7, 0))	# 8
        push!(seq, LLdata(10, 7,0; label=:A))	# 9
        push!(seq, LLgoto(:C))      	# 10 - jump C
        push!(seq, LLdata(12, 7, 0; label=:B))   # 11
        push!(seq, LLgoto(:D))      	# 12 - jump D
        push!(seq, LLdata(14, 7, 0; label=:C))	# 13
        push!(seq, LLgoto(:B))      	# 14
        push!(seq, LLdata(16, 7, 0; label=:D))   # 15
        push!(seq, LLgoto(:A))  	# 16
        resolve_symbols!(seq)
end

function writeTestFiles()
        seq = simpleSeq();
        write_file("simpleSeq.dat", seq)
end

end
