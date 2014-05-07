-- wireshark APS2 protocol dissectors
-- declare our protocol
aps_proto = Proto("aps2","APS2 Control Protocol")

local a = aps_proto.fields

local aps_commands = { [0] = "RESET",
					   [ 0x01] = "USER I/O ACK",
					   [ 0x09] = "USER I/O NACK",
					   [ 0x02] = "EPROM I/O",
					   [ 0x03] = "CHIP CONFIG I/O",
					   [ 0x04] = "RUN CHIP CONFIG",
					   [ 0x05] = "FPGA CONFIG ACK",
					   [ 0x0D] = "FPGA CONFIG NACK",
					   [ 0x06] = "FPGA CONFIG CONTROL",
					   [ 0x07 ] = "FGPA Status"
                      }

a.seqnum    = ProtoField.uint16("aps.seqnum", "SeqNum")
a.packedCmd = ProtoField.uint32("aps.cmd","Command"  , base.HEX)
a.ack       = ProtoField.uint8("aps.cmd", "Ack", base.DEC,  nil, 0x80)
a.seq       = ProtoField.uint8("aps.seq", "Seq", base.DEC,  nil, 0x40)
a.sel       = ProtoField.uint8("aps.sel", "Sel", base.DEC,  nil, 0x20)
a.rw        = ProtoField.uint8("aps.rw",  "R/W" , base.DEC, nil, 0x10)
a.cmd       = ProtoField.uint8("aps.cmd", "Cmd" , base.HEX, aps_commands, 0x0F)
a.mode_stat = ProtoField.uint8("aps.mode_state", "Mode/Stat" , base.HEX)
a.cnt       = ProtoField.uint16("aps.cnt", "Cnt" , base.DEC)
a.addr      = ProtoField.uint32("aps.address", "Address" , base.HEX)

a.chipcfgPacked = ProtoField.uint32("aps.chipcfgPacked", "Chip Config I/O Command" , base.HEX)
a.target = ProtoField.uint8("aps.target", "TARGET" , base.HEX)
a.spicnt = ProtoField.uint8("aps.spicnt", "SPICNT/DATA" , base.HEX)
a.instr = ProtoField.uint16("aps.instr", "INSTR" , base.HEX)
a.instrAddr = ProtoField.uint32("aps.instrAddr", "Addr" , base.HEX)
a.payload = ProtoField.bytes("aps.payload", "Data")

a.hostFirmwareVersion = ProtoField.uint32("aps.hostFirmwareVersion", "Host Firmware Version", base.HEX)
a.userFirmwareVersion = ProtoField.uint32("aps.userFirmwareVersion", "User Firmware Version", base.HEX)
a.configSource = ProtoField.uint32("aps.configSource", "Configuration Source", base.HEX)
a.userStatus = ProtoField.uint32("aps.userStatus", "User Status", base.HEX)
a.dac0Status = ProtoField.uint32("aps.dac0Status", "DAC 0 Status", base.HEX)
a.dac1Status = ProtoField.uint32("aps.dac1Status", "DAC 1 Status", base.HEX)
a.pllStatus = ProtoField.uint32("aps.pllStatus", "PLL Status", base.HEX)
a.vxcoStatus = ProtoField.uint32("aps.vxcoStatus", "VXCO Status", base.HEX)
a.sendPacketCount = ProtoField.uint32("aps.sendPacketCount", "Send Packet Count", base.DEC)
a.recPacketCount = ProtoField.uint32("aps.recPacketCount", "Receive Packet Count", base.DEC)
a.seqSkipCount = ProtoField.uint32("aps.seqSkipCount", "Sequence Skip Count", base.DEC)
a.seqDupCount = ProtoField.uint32("aps.seqDupCount", "Sequence Dup. Count", base.DEC)
a.fcsErrorCount = ProtoField.uint32("aps.fcsErrorCount", "FCS Error Count", base.DEC)
a.overrunCount = ProtoField.uint32("aps.overrunCount", "Packet Overrun Count", base.DEC)
a.uptimeSeconds = ProtoField.uint32("aps.uptimeSeconds", "Uptime Seconds", base.DEC)
a.uptimeNanoSeconds = ProtoField.uint32("aps.uptimeNanoSeconds", "Uptime Nanoseconds", base.DEC)

-- create a function to dissect it
function aps_proto.dissector(buffer,pinfo,tree)

    pinfo.cols.protocol = "APS2"
    
    local subtree = tree:add(aps_proto,buffer())

    local offset = 0

 	subtree:add( a.seqnum , buffer(offset,2))
 	offset = offset + 2
    
 	local cmdTree = subtree:add( a.packedCmd, buffer(offset,4))

 	cmdTree:add( a.ack, buffer(offset,1))
 	cmdTree:add( a.seq, buffer(offset,1))
 	cmdTree:add( a.sel, buffer(offset,1))
 	cmdTree:add( a.rw,  buffer(offset,1))
 	cmdTree:add( a.cmd, buffer(offset,1))
 	cmdTree:add( a.mode_stat,  buffer(offset+1,1))
 	cmdTree:add( a.cnt,  buffer(offset+2,2))

 	local cmdVal = buffer(offset,1):bitfield(4,4)
 	pinfo.cols.info = ( aps_commands[cmdVal] or '?')

 	local ackVal = buffer(offset,1):bitfield(0,1)
 	if (ackVal == 1) then
 		pinfo.cols.info:append(" - ACK")
 	end

 	offset = offset + 4

 	if (cmdVal == 0x1 or cmdVal == 0x9) then
		subtree:add( a.addr, buffer(offset,4))
		offset = offset + 4
	end

	--If there is payload then show it
	if ((buffer:len() - offset) > 0) then 
		local dataTree = subtree:add(a.payload, buffer(offset))

		-- parse status words
		if (cmdVal == 0x07) then
			dataTree:add(a.hostFirmwareVersion, buffer(offset,4))
			offset = offset + 4
			dataTree:add(a.userFirmwareVersion, buffer(offset,4))
			offset = offset + 4
			dataTree:add(a.configSource, buffer(offset,4))
			offset = offset + 4
			dataTree:add(a.userStatus, buffer(offset,4))
			offset = offset + 4
			dataTree:add(a.dac0Status, buffer(offset,4))
			offset = offset + 4
			dataTree:add(a.dac1Status, buffer(offset,4))
			offset = offset + 4
			dataTree:add(a.pllStatus, buffer(offset,4))
			offset = offset + 4
			dataTree:add(a.vxcoStatus, buffer(offset,4))
			offset = offset + 4
			dataTree:add(a.sendPacketCount, buffer(offset,4))
			offset = offset + 4
			dataTree:add(a.recPacketCount, buffer(offset,4))
			offset = offset + 4
			dataTree:add(a.seqSkipCount, buffer(offset,4))
			offset = offset + 4
			dataTree:add(a.seqDupCount, buffer(offset,4))
			offset = offset + 4
			dataTree:add(a.fcsErrorCount, buffer(offset,4))
			offset = offset + 4
			dataTree:add(a.overrunCount, buffer(offset,4))
			offset = offset + 4
			dataTree:add(a.uptimeSeconds, buffer(offset,4))
			offset = offset + 4
			dataTree:add(a.uptimeNanoSeconds, buffer(offset,4))

		end 

	end

	-- parse chip config
	if (cmdVal == 0x03) then
		local chipcfg = subtree:add( a.chipcfgPacked, buffer(offset,4))		
		chipcfg:add( a.target, buffer(offset,1))
		chipcfg:add( a.spicnt, buffer(offset+1,1))
		local instr = chipcfg:add( a.instr, buffer(offset+2,2))

		local targetVal = buffer(offset,1):uint()

		if (targetVal == 0xd8 ) then
			instr:add( a.instrAddr, buffer(offset+2,1))
			instr:add( a.instrData, buffer(offset+3,1))

			pinfo.cols.info:append(" - PLL")
		end
	end



--    subtree = subtree:add(buffer(2,4),"Command")

    
    
    --local cmd = buffer(2,4):uint()

    --local ack = tostring(bit.tohex(bit.rshift(cmd, 31),1))
    --subtree:add(buffer(2,1),"ACK: " .. ack)

	--local seq = tostring(bit.tohex(bit.band(bit.rshift(cmd, 30),1), 0x1))
    --subtree:add(buffer(2,1),"SEQ: " .. seq)

   	--local sel = tostring(bit.tohex(bit.band(bit.rshift(cmd, 29),1), 0x1))
    --subtree:add(buffer(2,1),"SEL: " .. sel)

   	--local rw = tostring(bit.tohex(bit.band(bit.rshift(cmd, 28),1), 0x1))
    --subtree:add(buffer(2,1),"R/W: " .. rw)

    --local cmd2 = tostring(bit.tohex(bit.band(bit.rshift(cmd, 24), 0x7)))
    --subtree:add(buffer(2,1),"CMD: " .. cmd2)

    --local mode_stat = tostring(bit.tohex(bit.band(bit.rshift(cmd, 16), 0xFF)))
    --subtree:add(buffer(2,1),"MODE/STAT: " .. mode_stat)

    --local cnt = tostring(bit.tohex(bit.band(cmd, 0xFF)))
    --subtree:add(buffer(2,1),"CNT: " .. cnt)

    --subtree = subtree:add(buffer(6,4),"Addr:" .. buffer(6,4))
end
eth_table = DissectorTable.get("ethertype")
-- attach to ethernet type 0xBBAE
eth_table:add(47950,aps_proto)
