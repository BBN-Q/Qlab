%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Module Name : dacii.m
%
% Author/Date : B.C. Donovan / 21-Oct-08
%
% Description : dacii object for QLab Experiment Framework
%               Based on original DacII object
%
%               Wraps libdacii for access to dacii box.
%
% Restrictions/Limitations :
%
%   Requires libdacii.dll and libdacii.h
%
% Change Descriptions :
%
% Classification : Unclassified
%
% References :
%
%
%    Modified    By    Reason
%    --------    --    ------
%                BCD
%
% $Author: bdonovan $
% $Date$
% $Locker:  $
% $Name:  $
% $Revision$
%
% $Log: dacii.m,v $
% Revision 1.5  2008/12/03 15:47:57  bdonovan
% Added support for multiple DAC boxes to libdacii. Updated dacii.m for new api.
%
% Revision 1.1  2008/10/23 20:41:35  bdonovan
% First version of CMD Builder GUI that uses C dll to communicate with DACII board.
%
% C library to communicate with board is in ./lib.
%
% Matlab code has been reorganized into classes. GUI is not edited with the guide command
% in matlab.
%
% Independent triggering of each of the 4 DACs has been confirmed for both software
%  and hardware triggering with cbl_dac2_r3beta.bit
%
%
% Copyright (C) BBN Technologies Corp. 2008
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef DacII < deviceDrivers.lib.deviceDriverBase
    %DACII Summary of this class goes here
    %   Detailed explanation goes here
    properties
        library_path = './lib/';
        device_id = 0;
        num_devices;
        message_manager =[];
        bit_file_path = '';
        bit_file = 'mqco_dac2_r10_p13.bit';
        expected_bit_file_ver = hex2dec('10');
        Address = 0;
        verbose = 0;
    end
    properties %(Access = 'private')
        is_open = 0;
        bit_file_programmed = 0;
        max_waveform_points = 4096;
        max_ll_length = 64;
        bit_file_version = 0;
        ELL_VERSION = hex2dec('10');
        
        % variables used to adjust link list padding
        pendingLength = 0;
        pendingValue = 0;
        expectedLength = 0;
        currentLength = 0;
        
    end
    
    properties (Constant)
        ADDRESS_UNIT = 4;
        
        ELL_MAX_WAVFORM = 8192;
        ELL_MAX_LL = 512;
        
        %% ELL Linklist Masks and Contants
        ELL_ADDRESS            = hex2dec('07FF');
        ELL_TIME_AMPLITUDE     = hex2dec('8000');
        ELL_ZERO               = hex2dec('4000');
        ELL_VALID_TRIGGER      = hex2dec('2000');
        ELL_FIRST_ENTRY        = hex2dec('1000');
        ELL_LAST_ENTRY         = hex2dec('800');
        ELL_TA_MAX             = hex2dec('FFFF');
        ELL_TRIGGER_DELAY      = hex2dec('3FFF');
        ELL_TRIGGER_MODE_SHIFT = 14;
        ELL_TRIGGER_DELAY_UNIT = 3.333e-9;
    end
    
    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function d = DacII()
            d = d@deviceDrivers.lib.deviceDriverBase('DacII');
            d.load_library();
            
            buffer = libpointer('stringPtr','                            ');
            calllib('libdacii','DACII_ReadLibraryVersion', buffer,length(buffer.Value));
            d.log(sprintf('Loaded %s', buffer.Value));
            
            % build path for bitfiles
            script_path = mfilename('fullpath');
            extended_path = '\DacII';
            baseIdx = strfind(script_path,extended_path);
            
            d.bit_file_path = script_path(1:baseIdx);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function connect(obj,address)
            
            % Experiment Framework function for connecting to
            % A DacII, allow numeric or serial number based
            % addressing
            
            if isnumeric(address)
                val = obj.open(address);
            else
                val = obj.openBySerialNum(address);
            end
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function disconnect(obj)
            obj.close()
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function log(dac,line)
            if ~isempty(dac.message_manager)
                dac.message_manager.disp(line)
            else
                disp(line)
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function load_library(d)
            if (ispc())
                libfname = 'libdacii.dll';
            elseif (ismac())
                libfname = 'libdacii.dylib';
            else
                libfname = 'libdacii.so';
            end
            
            % build library path
            script_path = mfilename('fullpath');
            schString = [filesep 'DacII'];
            idx = strfind(script_path,schString);
            d.library_path = [script_path(1:idx) filesep 'lib' filesep];
            if ~libisloaded('libdacii')
                [notfound warnings] = loadlibrary([d.library_path libfname], ...
                    [d.library_path 'libdacii.h']);
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function num_devices = enumerate(dac)
            % Library may not be opened if a stale object is left in
            % memory by matlab. So we reopen on if need be.
            dac.load_library()
            dac.num_devices = calllib('libdacii','DACII_NumDevices');
            num_devices = dac.num_devices;
        end
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % setAll is called as part of the Experiment initialize instruments
        function setAll(obj,init_params)
            fs = fields(init_params);
            for i = 1:length(fs)
                initStr = sprintf('obj.%s = init_params.%s;',fs{i},fs{i});
                eval(initStr);
            end
            
            % Determine if it needs to be programmed
            bitFileVer = obj.readBitFileVersion();
            if ~isnumeric(bitFileVer) || bitFileVer ~= obj.expected_bit_file_ver
                obj.loadBitFile();
            end
            
            obj.bit_file_programmed = 1;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function val = open(dac,id)
            if (dac.is_open)
                dac.close()
            end
            
            if exist('id','var')
                dac.device_id = id;
            end
            
            val = calllib('libdacii','DACII_Open' ,dac.device_id);
            if (val == 0)
                dac.log(sprintf('DACII USB Connection Opened'));
                dac.is_open = 1;
            elseif (val == 1)
                dac.log(sprintf('Could not open device %i.', dac.device_id))
                dac.log(sprintf('Device may be open by a different process'));
            elseif (val == 2)
                dac.log(sprintf('DACII Device Not Found'));
            else
                dac.log(sprintf('Unknown return from LIBDACII: %i', val));
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function val = openBySerialNum(dac,serialNum)
            if (dac.is_open)
                dac.close()
            end
            
            val = calllib('libdacii','DACII_OpenBySerialNum' ,serialNum);
            if (val >= 0)
                dac.log(sprintf('DACII USB Connection Opened'));
                dac.is_open = 1;
                dac.device_id = val;
            elseif (val == -1)
                dac.log(sprintf('Could not open device %i.', dac.device_id))
                dac.log(sprintf('Device may be open by a different process'));
            elseif (val == -2)
                dac.log(sprintf('DACII Device Not Found'));
            else
                dac.log(sprintf('Unknown return from LIBDACII: %i', val));
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function close(dac)
            val = calllib('libdacii','DACII_Close',dac.device_id);
            if (val == 0)
                dac.log(sprintf('DACII USB Connection Closed\n'));
            else
                dac.log(sprintf('Error closing DACII USB Connection: %i\n', val));
            end
            dac.is_open = 0;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function val = readBitFileVersion(dac)
            val = calllib('libdacii','DACII_ReadBitFileVersion', dac.device_id);
            dac.bit_file_version = val;
            if val >= dac.ELL_VERSION
                dac.max_waveform_points = dac.ELL_MAX_WAVFORM;
                dac.max_ll_length = dac.ELL_MAX_LL;
            end
        end
        
        function dbgForceELLMode(dac)
            %% Force constants to ELL mode for debug testing
            dac.max_waveform_points = dac.ELL_MAX_WAVFORM;
            dac.max_ll_length = dac.ELL_MAX_LL;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function programFPGA(dac, data, bytecount,sel)
            if ~(dac.is_open)
                warning('DACII:ProgramFPGA','DACII is not open');
                return
            end
            dac.log('Programming FPGA ');
            val = calllib('libdacii','DACII_ProgramFpga',dac.device_id,data, bytecount,sel);
            if (val < 0)
                errordlg(sprintf('DACII_ProgramFPGA returned an error code of: %i\n', val), ...
                    'Programming Error');
            end
            dac.log('Done');
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function loadBitFile(dac,filename)
            
            if ~exist('filename','var')
                filename = [dac.bit_file_path dac.bit_file];
            end
            
            if ~(dac.is_open)
                warning('DACII:loadBitFile','DACII is not open');
                return
            end
            dac.setupVCX0();
            dac.setupPLL();
            
            % assume we are programming both FPGA with the same bit file
            Sel = 3;
            
            dac.log(sprintf('Loading bit file: %s', filename));
            eval(['[DataFileID, FOpenMessage] = fopen(''', filename, ''', ''r'');']);
            if ~isempty(FOpenMessage)
                error('DACII:loadBitFile', 'Input DataFile Not Found');
            end
            
            [filename, permission, machineformat, encoding] = fopen(DataFileID);
            %eval(['disp(''Machine Format = ', machineformat, ''');']);
            
            [DataVec, DataCount] = fread(DataFileID, inf, 'uint8=>uint8');
            dac.log(sprintf('Read %i bytes.', DataCount));
            
            dac.programFPGA(DataVec, DataCount,Sel);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Waveform / Link List Load Functions
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function loadWaveform(dac,id,waveform,offset)
            if ~(dac.is_open)
                warning('DACII:loadWaveForm','DACII is not open');
                return
            end
            if isempty(waveform)
                return
            end
            dac.log(sprintf('Loading Waveform length: %i into DAC%i ', length(waveform),id));
            val = calllib('libdacii','DACII_LoadWaveform', dac.device_id,waveform,length(waveform),offset,id);
            if (val < 0)
                errordlg(sprintf('DACII_LoadWaveform returned an error code of: %i\n', val), ...
                    'Programming Error');
            end
            dac.log('Done');
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function loadLinkList(dac,id,offsets,counts, ll_len)
            trigger = [];
            repeat = [];
            bank = 0;
            dac.loadLinkListELL(dac,id,offsets,counts, trigger, repeat, ll_len, bank)
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function loadLinkListELL(dac,id,offsets,counts, trigger, repeat, ll_len, bank)
            if ~(dac.is_open)
                warning('DACII:loadLinkListELL','DACII is not open');
                return
            end
            dac.log(sprintf('Loading Link List length: %i into DAC%i ', ll_len,id));
            val = calllib('libdacii','DACII_LoadLinkList',dac.device_id, offsets,counts,trigger,repeat,ll_len,id,bank);
            if (val < 0)
                errordlg(sprintf('DACII_LoadLinkList returned an error code of: %i\n', val), ...
                    'Programming Error');
            end
            dac.log('Done');
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Trigger / Pause / Disable Waveform or FPGA
        %% setLinkListMode
        %% setFrequency
        %%
        %% These function share a common base function to wrap libdacii
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function val = librarycall(dac,mesg,func,varargin)
            % common base call for a number of functions
            if ~(dac.is_open)
                warning('DACII:librarycall','DACII is not open');
                return
            end
            dac.log(mesg)
            
            switch size(varargin,2)
                case 0
                    val = calllib('libdacii',func,dac.device_id);
                case 1
                    val = calllib('libdacii',func,dac.device_id, varargin{1});
                case 2
                    val = calllib('libdacii',func,dac.device_id, varargin{1}, varargin{2});
                case 3
                    val = calllib('libdacii',func,dac.device_id, varargin{1}, varargin{2}, varargin{3});
                otherwise
                    error('More than 3 varargin arguments to librarycall are not supported\n');
            end
            dac.log('Done');
        end
        
        function triggerWaveform(dac,id,trigger_type)
            val = dac.librarycall(sprintf('Trigger Waveform %i Type: %i', id, trigger_type), ...
                'DACII_TriggerDac',id,trigger_type);
        end
        
        function pauseWaveform(dac,id)
            val = dac.librarycall(sprintf('Pause Waveform %i', id), 'DACII_PauseDac',id);
        end
        
        function disableWaveform(dac,id)
            val = dac.librarycall(sprintf('Disable Waveform %i', id), 'DACII_DisableDac',id);
        end
        
        function triggerFpga(dac,id,trigger_type)
            val = dac.librarycall(sprintf('Trigger Waveform %i Type: %i', id, trigger_type), ...
                'DACII_TriggerFpga',id,trigger_type);
        end
        
        function pauseFpga(dac,id)
            val = dac.librarycall(sprintf('Pause Waveform %i', id), 'DACII_PauseFpga',id);
        end
        
        function disableFpga(dac,id)
            val = dac.librarycall(sprintf('Disable Waveform %i', id), 'DACII_DisableFpga',id);
        end
        
        function setLinkListMode(dac,id, enable,dc)
            val = dac.librarycall(sprintf('Dac: %i Link List Enable: %i Mode: %i', id, enable,dc), ...
                'DACII_SetLinkListMode',enable,dc,id);
        end
        
        function setFrequency(dac,id, freq)
            val = dac.librarycall(sprintf('Dac: %i Freq : %i', id, freq), ...
                'DACII_SetPllFreq',id,freq);
        end
        
        function setupPLL(dac)
            val = dac.librarycall('Setup PLL', 'DACII_SetupPLL');
        end
        
        function setupVCX0(dac)
            val = dac.librarycall('Setup VCX0', 'DACII_SetupVCXO');
        end
        
         function readAllRegisters(dac)
            val = dac.librarycall(sprintf('Read Registers'), ...
                'DACII_ReadAllRegisters');
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Link List Format Conversion
        %%
        %% Converts link lists produced by PaternGen to a format suitable for use with the
        %% DacII. Enforces length of waveform mod 4 = 0. Attempts to addjust padding to
        %% compenstate.
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %% TODO: Clean up verbose messages
        
        function library = buildWaveformLibrary(dac, waveforms, useVarients)
            % convert baseWaveforms to waveform array suitable for the DacII
            
            offsets = containers.Map('KeyType','double','ValueType','any');
            lengths = containers.Map('KeyType','double','ValueType','any');
            varients = containers.Map('KeyType','double','ValueType','any');
            
            % allocate space for data;
            data = zeros([1, dac.max_waveform_points],'uint16');
            
            idx = 1;
            
            % loop through waveform library
            keys = waveforms.keys();
            while keys.hasMoreElements()
                key = keys.nextElement();
                orgWF = waveforms.get(key);
                varientWFs = {};
                if useVarients
                    endPad = 3;
                else
                    endPad = 0;
                end
                if length(orgWF) == 1
                    endPad = 0;
                end
                
                for leadPad = 0:endPad
                    wf = [];  % clear waveform
                    for i = 1:leadPad
                        wf(end+1) = 0;
                    end
                    wf(end+1:end+length(orgWF)) = orgWF;
                    % test for padding to mod 4
                    if length(wf) == 1
                        % time amplitude pair
                        % example to save value repeated four times
                        wf = ones([1,dac.ADDRESS_UNIT]) * wf;
                    end
                    pad = dac.ADDRESS_UNIT - mod(length(wf),dac.ADDRESS_UNIT);
                    if pad ~= 0 && pad < dac.ADDRESS_UNIT
                        % pad to length 4
                        wf(end+1:end+pad) = zeros([1,pad],'uint16');
                    end
                    
                    assert(mod(length(wf),dac.ADDRESS_UNIT) == 0, 'WF Padding Failed')
                    
                    %insert into global waveform array
                    data(idx:idx+length(wf)-1) = uint16(wf);
                    
                    if leadPad == 0
                        offsets(key) = idx;
                        lengths(key) = length(wf);
                    end
                    if useVarients
                        varient.offset = idx;
                        varient.length = length(wf);
                        varient.pad = leadPad;
                        varientWFs{end+1} = varient;
                    end
                    idx = idx + length(wf);
                end
                if useVarients && length(orgWF) > 1
                    varients(key) = varientWFs;
                end
            end
            
            if idx > dac.max_waveform_points
                throw(MException('DacII:OutOfMemory','Waveform memory exceeds DacII maximum'));
            end
            
            % trim data to only points used
            data = data(1:idx-1);  % one extra point as it is the next insertion point
            
            % double check mod ADDRESS_UNIT
            assert(mod(length(data),dac.ADDRESS_UNIT) == 0,...
                'Global Link List Waveform memory should be mod 4');
            
            library.offsets = offsets;
            library.lengths = lengths;
            library.varients = varients;
            library.waveforms = data;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [offsetVal countVal] = entryToOffsetCount(dac,entry,library, firstEntry, lastEntry)
            
            entryData.offset = library.offsets(entry.key);
            entryData.length = library.lengths(entry.key);
            
            if library.varients.isKey(entry.key)
                entryData.varientWFs = library.varients(entry.key);
            else
                entryData.varientWFs = [];
            end
            
            dac.expectedLength = dac.expectedLength + entry.length * entry.repeat;
            
            % correct for changing in padding
            
            adjustNegative = 0;
            
            if dac.pendingLength > 0 && ~isempty(entryData.varientWFs)
                % attempt to us a varient
                padIdx = dac.pendingLength + 1;
                assert(padIdx > 0 && padIdx <= 4,sprintf('Padding Index %i Out of Range', padIdx));
                if length(entryData.varientWFs) >= padIdx   % matlab index offset
                    varient = entryData.varientWFs(padIdx);
                    if iscell(varient), varient = varient{1}; end; % remove cell wrapper
                    entryData.offset = varient.offset;
                    entryData.length = varient.length;
                    assert(varient.pad == dac.pendingLength,'Pending length pad does not match');
                    if dac.verbose
                        fprintf('\tUsing WF varient with pad: %i\n', padIdx - 1);
                    end
                end
            elseif dac.pendingLength < 0
                % if pattern is running long and output is zero trim the length
                % may get bumped back up
                if entry.isZero
                    entry.repeat = entry.repeat + dac.pendingLength;
                    adjustNegative = 1;
                    if dac.verbose
                        fprintf('\tTrimming zero pad by: %i from %i\n', dac.pendingLength);
                    end
                end
            end
            
            %% convert from 1 based count to 0 based count
            %% div by 4 required for dacII addresses
            address = (entryData.offset - 1) / dac.ADDRESS_UNIT;
            
            % offset register format
            %  15  14  13   12   11  10 9 8 7 6 5 4 3 2 1 0
            % | A | Z | T | LS | LE |      Offset / 4      |
            %
            %  Address - Address of start of waveform / 4
            %  A       - Time Amplitude Pair
            %  Z       - Output is Zero
            %  T       - Entry has valid output trigger delay
            %  LS      - Start of Mini Link List
            %  LE      - End of Mini Link List
            
            offsetVal = bitand(address, dac.ELL_ADDRESS);  % address
            if entry.isTimeAmplitude
                offsetVal = bitor(offsetVal, dac.ELL_TIME_AMPLITUDE);
            end
            
            if entry.isZero
                offsetVal = bitor(offsetVal, dac.ELL_ZERO);
            end
            
            if entry.hasTrigger
                offsetVal = bitor(offsetVal, dac.ELL_VALID_TRIGGER);
            end
            
            if firstEntry  % start of link list
                offsetVal = bitor(offsetVal, dac.ELL_FIRST_ENTRY);
            end
            
            if lastEntry % end of link list
                offsetVal = bitor(offsetVal, dac.ELL_LAST_ENTRY);
            end
            
            % use entryData to get length as it includes the padded
            % length
            if ~entry.isTimeAmplitude
                countVal = fix(entryData.length/dac.ADDRESS_UNIT);
            else
                countVal = fix(floor(entry.repeat / entryData.length));
                diff = entry.repeat - countVal * dac.ADDRESS_UNIT;
                dac.pendingValue = library.waveforms(entryData.offset);
            end
            if (~entry.isTimeAmplitude && countVal > dac.ELL_ADDRESS) || ...
                    (entry.isTimeAmplitude && countVal > dac.ELL_TA_MAX)
                error('Link List countVal %i is too large', countVal);
            end
            
            dac.currentLength = dac.currentLength + countVal * dac.ADDRESS_UNIT;
            
            % test to see if the pattern is running long and we need to trim
            % pendingLength
            
            dac.pendingLength = dac.expectedLength - dac.currentLength;
            
            if dac.verbose
                fprintf('\tExpected Length: %i Actual Length: %i Pending: %i \n',  ...
                    dac.expectedLength, dac.currentLength, dac.pendingLength);
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function triggerVal = entryToTrigger(dac,entry)
            % handle trigger values
            %% Trigger Delay
            %  15  14  13   12   11  10 9 8 7 6 5 4 3 2 1 0
            % | Mode |                Delay                |
            % Delay = time in 3.333 ns increments ( 0 - 54.5 usec )
            
            % TODO:  hard code trigger for now, need to think about how to
            % describe
            triggerMode = 3; % do nothing
            triggerDelay = 0;
            
            triggerMode = bitshift(triggerMode,dac.ELL_TRIGGER_MODE_SHIFT);
            triggerDelay = fix(round(triggerDelay / dac.ELL_TRIGGER_DELAY_UNIT));
            
            triggerVal = bitand(triggerDelay, dac.ELL_TRIGGER_DELAY);
            triggerVal = bitor(triggerVal, triggerMode);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [wf, banks] = convertLinkListFormat(dac, pattern, useVarients)
            if ~exist('useVarients','var') || isempty(useVarients)
                useVarients = 0;
            end
            
            library = dac.buildWaveformLibrary(pattern.waveforms, useVarients);
            
            wf = dacIIWaveform();
            wf.data = library.waveforms;
            
            function bank = allocateBank()
                bank.offset = zeros([1,dac.max_ll_length],'uint16');
                bank.count = zeros([1,dac.max_ll_length],'uint16');
                bank.trigger = zeros([1,dac.max_ll_length],'uint16');
                bank.repeat = zeros([1,dac.max_ll_length],'uint16');
                bank.length = dac.max_ll_length;
            end
            
            function bank = trimBank(bank,len)
                bank.offset = bank.offset(1:len);
                bank.count = bank.count(1:len);
                bank.trigger = bank.trigger(1:len);
                bank.repeat = bank.repeat(1:len);
                bank.length = len;
            end
            
            curBank = 1;
            banks{curBank} = allocateBank();
            
            % loop through link lists
            idx = 1;
            
            % clear padding adjust variables
            dac.pendingLength = 0;
            dac.pendingValue = 0;
            dac.expectedLength = 0;
            dac.currentLength = 0;
            
            for i = 1:length(pattern.linkLists)
                linkList = pattern.linkLists{i};
                
                lenLL = length(linkList);
                
                if  lenLL > dac.max_ll_length
                    error('Individual Link List %i exceeds DacII maximum link list length', i)
                end
                
                if (idx + lenLL) > dac.max_ll_length
                    banks{curBank} = trimBank(banks{curBank},idx-1);
                    curBank = curBank + 1;
                    banks{curBank} = allocateBank();
                    idx = 1;
                end
                
                for j = 1:lenLL
                    entry = linkList{j};
                    
                    if dac.verbose
                        fprintf('Entry %i: key: %10i length: %2i repeat: %4i \n', j, entry.key, entry.length, ...
                            entry.repeat);
                    end
                    
                    [offsetVal countVal] = entryToOffsetCount(dac,entry,library, i == 1, i == lenLL);
                    
                    if dac.verbose
                        fprintf('\tLink List Offset: %4i Length: %4i Expanded Length: %4i TA: %i Zero:%i\n', ...
                            bitand(offsetVal,dac.ELL_ADDRESS) * dac.ADDRESS_UNIT, ...
                            countVal, countVal * dac.ADDRESS_UNIT, ...
                            entry.isTimeAmplitude, entry.isZero);
                    end
                    
                    triggerVal = dac.entryToTrigger(entry);
                    
                    banks{curBank}.offset(idx) = uint16(offsetVal);
                    banks{curBank}.count(idx) = uint16(countVal);
                    banks{curBank}.trigger(idx) = uint16(triggerVal);
                    
                    % TODO: hard coded repeat count of 0
                    banks{curBank}.repeat(idx) = uint16(0);
                    
                    idx = idx + 1;
                end
            end
            
            % trim last bank
            banks{curBank} = trimBank(banks{curBank},idx-1);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [pattern] = linkListToPattern(dac,wf, banks)
            pattern = [];
            if iscell(banks)
                nBanks = length(banks);
            else
                nBanks = 1;
            end
            for i = 1:nBanks
                if dac.verbose
                    fprintf('Processing Bank: %i\n', i);
                end
                if iscell(banks)
                    bank = banks{i};
                else
                    bank = banks;
                end
                
                for j = 1:bank.length
                    
                    offset = bank.offset(j);
                    count = bank.count(j);
                    TA = bitand(offset, dac.ELL_TIME_AMPLITUDE) == dac.ELL_TIME_AMPLITUDE;
                    zero = bitand(offset, dac.ELL_ZERO) == dac.ELL_ZERO;
                    
                    idx = dac.ADDRESS_UNIT*bitand(offset, dac.ELL_ADDRESS) + 1;
                    
                    expandedCount = dac.ADDRESS_UNIT * count;
                    
                    if ~TA && ~zero
                        endIdx = dac.ADDRESS_UNIT*count + idx - 1;
                        if dac.verbose
                            fprintf('Using wf.data(%i:%i) length: %i TA:%i zero:%i\n', idx, endIdx,...
                                length(idx:endIdx), TA , zero);
                        end;
                        newPat = wf.data(idx:endIdx);
                        assert(mod(length(newPat),dac.ADDRESS_UNIT) == 0, ...
                            'Expected len(wf) % 4 == 0');
                    elseif zero
                        if dac.verbose
                            fprintf('Using zeros: %i\n', expandedCount);
                        end
                        newPat = zeros([1, expandedCount],'uint16');
                    elseif TA
                        if dac.verbose
                            fprintf('Using TA: %i@%i\n', expandedCount, wf.data(idx));
                        end
                        newPat = wf.data(idx)*ones([1, expandedCount],'uint16');
                    end
                    
                    pattern = [pattern newPat];
                end
            end
        end
        
        function setModeR5(dac)
            dac.bit_file = 'cbl_dac2_r5_d6ma_fx.bit';
            dac.expected_bit_file_ver = 5;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end
    methods(Static)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function unload_library()
            if libisloaded('libdacii')
                unloadlibrary libdacii
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function wf = getNewWaveform()
            % Utility function to get a DacII wavform object from DacII Driver
            try
                wf = dacIIWaveform();
            catch
                % if dacIIWaveform is not on the path
                % attempt to add the util directory to the path
                % and reload the waveform
                path = mfilename('fullpath');
                % search path
                spath = ['common' filesep 'src'];
                idx = strfind(path,spath);
                path = [path(1:idx+length(spath)) 'util'];
                addpath(path);
                wf = dacIIWaveform();
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% External Functions (See external files)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %% UnitTest of Link List Format Conversion
        %% See: LinkListFormatUnitTest.m
        LinkListFormatUnitTest(sequence)
        
        function dac = UnitTest(skipLoad)
            %
            
            % work around for not knowing full name
            % of class - can not use simply DacII when in 
            % experiment framework
            classname = mfilename('class');
            
            % tests channel 0 & 1 output for basic bit file testing
            dac = eval(sprintf('%s();', classname));
            
            % waveform parameters
            wfScaleFactor = 1;
            wfOffset = 0;
            wfSampleRate = 1200;
            
            dacId = 0;
            
            %dac.setModeR5();
            dac.open(dacId);
            
            if (~dac.is_open)
                dac.close();
                dac.open(dacId);
                if (~dac.is_open)
                    error('Could not open dac')
                end
            end
            

            dac.loadBitFile();

            ver = dac.readBitFileVersion();
            fprintf('Found Bit File Version: %i\n', ver);
            dac.readAllRegisters();
            pause(1);
            keyboard
            for cnt = 1:5
                
                wf = dac.getNewWaveform();
                ln = cnt * 400;
                
                wf.data = [zeros([1,2000 - ln]) ones([1,ln])];
                wf.set_scale_factor(cnt/10+.5);
                
                dac.loadWaveform(0, wf.get_vector(), wf.offset);
                
                ln = (5-cnt) * 400;
                
                wf.data = [zeros([1,2000 - ln]) ones([1,ln]) zeros([1,1000])];
                wf.set_scale_factor((20-cnt)/10+.5);
                
                dac.loadWaveform(1, wf.get_vector(), wf.offset);
                
                dac.setFrequency(0, wf.sample_rate);
                dac.triggerFpga(0, 1); % 0 -  dac number 1 - software trigger
                
                pause(10);
                
                dac.pauseFpga(0);
                dac.pauseFpga(2);
                
            end
            
            dac.close();
        end
    end
end
