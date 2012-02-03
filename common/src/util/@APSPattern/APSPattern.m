classdef APSPattern < handle
    
    properties (Constant)
        ADDRESS_UNIT = 4;
        MIN_PAD_SIZE = 4;
        MIN_LL_ENTRY_COUNT = 3;
        MAX_WAVEFORM_VALUE = 8191;
        
        ELL_MAX_WAVFORM = 8192;
        max_waveform_points = 8192;
        ELL_MAX_LL = 512;
        max_ll_length = 512;
        ELL_MIN_COUNT = 3;
        
        %% ELL Linklist Masks and Contants
        ELL_ADDRESS            = hex2dec('07FF');
        %ELL_TIME_AMPLITUDE     = hex2dec('8000');
        ELL_TIME_AMPLITUDE_BIT = 16;
        %ELL_LL_TRIGGER         = hex2dec('8000');
        ELL_LL_TRIGGER_BIT     = 16;
        %ELL_ZERO               = hex2dec('4000');
        ELL_ZERO_BIT           = 15;
        %ELL_VALID_TRIGGER      = hex2dec('2000');
        ELL_VALID_TRIGGER_BIT  = 14;
        %ELL_FIRST_ENTRY        = hex2dec('1000');
        ELL_FIRST_ENTRY_BIT    = 13;
        %ELL_LAST_ENTRY         = hex2dec('800');
        ELL_LAST_ENTRY_BIT     = 12;
        ELL_TA_MAX             = hex2dec('FFFF');
        ELL_TRIGGER_DELAY      = hex2dec('3FFF');
        ELL_TRIGGER_MODE_SHIFT = 14;
        ELL_TRIGGER_DELAY_UNIT = 3.333e-9;
        
        verbose = false;
    end
    
    methods (Static)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Link List Format Conversion
        %%
        %% Converts link lists produced by PaternGen to a format suitable for use with the
        %% APS. Enforces length of waveform mod 4 = 0. Attempts to adjust padding to
        %% compenstate.
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function [xlib, ylib] = buildWaveformLibrary(pattern, useVarients)
            self = APSPattern;
            waveforms = pattern.waveforms;
            linkLists = pattern.linkLists;

            keys = waveforms.keys();
            xWFs = containers.Map();
            yWFs = containers.Map();
            for ii = 1:length(keys)
                tempWf = waveforms(keys{ii});
                xWFs(keys{ii}) = tempWf(:,1);
                yWFs(keys{ii}) = tempWf(:,2);
            end
            
            xlib = self.buildWaveformLibraryQuad(linkLists, xWFs, useVarients);
            ylib = self.buildWaveformLibraryQuad(linkLists, yWFs, useVarients);
        end
        
        function library = buildWaveformLibraryQuad(linkLists, waveforms, useVarients)
            % convert baseWaveforms to waveform array suitable for the APS
            aps = APSPattern;

            if ~exist('useVarients','var')
                useVarients = 1;
            end
            
            % populate paddingLib with empty arrays for every hash
            paddingLib = struct();
            keys = waveforms.keys();
            for ii = 1:length(keys)
                paddingLib.(keys{ii}) = [];
            end
            if useVarients
                % preprocess waveforms
                for ii = 1:length(linkLists)
                    for jj = 1:length(linkLists{ii})
                        paddingLib = aps.preprocessEntry(linkLists{ii}{jj}, paddingLib, jj == 1);
                    end
                end
            end
            
            offsets = struct();
            lengths = struct();
            varients = struct();

            % allocate space for data;
            data = zeros([1, aps.max_waveform_points],'int16');

            idx = 1;

            % loop through waveform library
            keys = waveforms.keys();
            for ii = 1:length(keys)
                key = keys{ii};
                orgWF = waveforms(key);

                maxPadding = aps.ADDRESS_UNIT*(aps.ELL_MIN_COUNT+1)-1;
                varientWFs = cell(maxPadding+1,1);

                paddings = sort(paddingLib.(key));
                if isempty(paddings)
                    paddings = 0;
                end

                for padIdx = 1:length(paddings)
                    leadPad = paddings(padIdx);
                    assert(leadPad <= maxPadding, 'WF padding is too large')
                    wf = [zeros([1,leadPad]) orgWF'];

                    % pad total length to a multiple of 4
                    if length(wf) == 1
                        % time amplitude pair
                        % pad out to 4 samples
                        wf = ones([1,aps.ADDRESS_UNIT]) * wf;
                    end
                    residual = mod(-length(wf),aps.ADDRESS_UNIT);
                    if residual ~= 0 && residual < aps.MIN_PAD_SIZE
                        wf(end+1:end+residual) = zeros([1,residual],'int16');
                    end

                    assert(mod(length(wf),aps.ADDRESS_UNIT) == 0, 'WF Padding Failed')

                    %insert into global waveform array
                    data(idx:idx+length(wf)-1) = wf;

                    % insert the first instance of the waveform into the
                    % offset, length, and varient maps
                    if ~isfield(offsets, key)
                        offsets.(key) = idx;
                        lengths.(key) = length(wf);
                        varients.(key) = {};
                    end
                    if useVarients
                        varient.offset = idx;
                        % set length of wf remove extra 8 points that
                        % are used to handle 0 and 1 count TA
                        varient.length = length(wf);
                        varient.pad = leadPad;
                        varientWFs{leadPad+1} = varient; % store the varient at position varientWFs{leadPad+1}
                    end
                    idx = idx + length(wf);
                end
                if useVarients && length(orgWF) > 1
                    varients.(key) = varientWFs;
                end
            end

            if idx > aps.max_waveform_points
                throw(MException('APS:OutOfMemory',sprintf('Waveform memory %i exceeds APS maximum of %i', idx, aps.max_waveform_points)));
            end

            % trim data to only points used
            data = data(1:idx-1);  % one extra point as it is the next insertion point

            % double check mod ADDRESS_UNIT
            assert(mod(length(data),aps.ADDRESS_UNIT) == 0,...
                'Global Link List Waveform memory should be mod 4');

            library.offsets = offsets;
            library.lengths = lengths;
            library.varients = varients;
            library.waveforms = data;
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function paddingLib = preprocessEntry(entry, paddingLib, resetCounts)
            % preprocessEntry marks used waveforms in the library and
            % indicates which padding varients need to be generated
            % borrows most of its code from entryToOffsetCount
            
            % state variables
            persistent expectedLength pendingLength currentLength
            if resetCounts
                expectedLength = 0;
                pendingLength = 0;
                currentLength = 0;
            end
            
            % lookup of class properites is expensive, create locals
            ADDRESS_UNIT = 4;
            MIN_LL_ENTRY_COUNT = 3;

            expectedLength = expectedLength + entry.length * entry.repeat;

            % if we have a zero that is less than count 3, we skip it and
            % pad the following entry
            if entry.isZero && (pendingLength + entry.repeat < (MIN_LL_ENTRY_COUNT+1) * ADDRESS_UNIT)
                pendingLength = expectedLength - currentLength;
                return;
            end

            % pad non-TAZ waveforms if the pendingLength is positive
            paddings = paddingLib.(entry.key);
            updateKey = 0;
            if pendingLength > 0 && ~entry.isZero && ~entry.isTimeAmplitude
                % add the padding length to the library
                if ~any(paddings == pendingLength) % same as ~ismember(pendingLength, paddings), but faster
                    paddings(end+1) = pendingLength;
                    updateKey = 1;
                end
                % the entry itself can potentially have additional padding to
                % make the length an integer multiple of the ADDRESS_UNIT
                residual = mod(-(entry.length + pendingLength), ADDRESS_UNIT);
                entry.length = entry.length + pendingLength + residual;
            % pad TAZ regardless of the sign of pendingLength
            elseif entry.isZero
                entry.repeat = entry.repeat + pendingLength;
            elseif ~entry.isZero && ~entry.isTimeAmplitude
                % mark this entry with padding = 0
                if ~any(paddings == 0) % same as ~ismember(0, paddings)
                    paddings(end+1) = 0;
                    updateKey = 1;
                end
            end

            if ~entry.isTimeAmplitude
                % count val is (length in 4 sample units) - 1
                countVal = fix(entry.length / ADDRESS_UNIT) - 1;
            else
                countVal = fix(entry.repeat / ADDRESS_UNIT) - 1;
            end

            currentLength = currentLength + (countVal+1) * ADDRESS_UNIT;

            % if the pattern is running long, trim pendingLength
            pendingLength = expectedLength - currentLength;

            % update library entry
            if updateKey
                paddingLib.(entry.key) = paddings;
            end
        end

        function [offsetVal countVal ] = entryToOffsetCount(entry, library, firstEntry, lastEntry)
            % state variables
            persistent expectedLength pendingLength currentLength
            if firstEntry
                expectedLength = 0;
                pendingLength = 0;
                currentLength = 0;
            end
            
            % lookup of class properites is expensive, create locals
            ADDRESS_UNIT = 4;
            MIN_LL_ENTRY_COUNT = 3;
            ELL_ADDRESS            = 2047; % 0x07FF
            ELL_TIME_AMPLITUDE_BIT = 16;
            ELL_LL_TRIGGER_BIT     = 16;
            ELL_ZERO_BIT           = 15;
            ELL_VALID_TRIGGER_BIT  = 14;
            ELL_FIRST_ENTRY_BIT    = 13;
            ELL_LAST_ENTRY_BIT     = 12;
            ELL_TA_MAX             = 65535; % 0xFFFF

            expectedLength = expectedLength + entry.length * entry.repeat;

            % if we have a zero that is less than count 3, we skip it and
            % pad the following entry
            if entry.isZero && (pendingLength + entry.repeat < (MIN_LL_ENTRY_COUNT+1) * ADDRESS_UNIT)
                pendingLength = expectedLength - currentLength;
                countVal = [];
                offsetVal = [];
                return;
            end

            entryData.offset = library.offsets.(entry.key);
            entryData.length = library.lengths.(entry.key);
            entryData.varientWFs = library.varients.(entry.key);
            % pad non-TAZ waveforms if the pendingLength is positive, provided we have an appropriate varient
            if pendingLength > 0 && ~entry.isZero && ~entry.isTimeAmplitude && ~isempty(entryData.varientWFs)
                % attempt to use a varient
                padIdx = pendingLength + 1;
                assert(padIdx > 0 && padIdx <= (MIN_LL_ENTRY_COUNT+1) * ADDRESS_UNIT,sprintf('Padding Index %i Out of Range', padIdx));
                if length(entryData.varientWFs) >= padIdx   % matlab index offset
                    varient = entryData.varientWFs(padIdx);
                    if iscell(varient), varient = varient{1}; end; % remove cell wrapper
                    entryData.offset = varient.offset;
                    entryData.length = varient.length;
                    assert(varient.pad == pendingLength,'Pending length pad does not match');
                    if APSPattern.verbose
                        fprintf('\tUsing WF varient with pad: %i\n', padIdx - 1);
                    end
                end
            elseif entry.isZero
                % pad TAZ regardless of the sign of pendingLength
                entry.repeat = entry.repeat + pendingLength;
            end

            %% convert from 1 based count to 0 based count
            %% div by 4 required for APS addresses
            address = (entryData.offset - 1) / ADDRESS_UNIT;

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

            offsetVal = bitand(address, ELL_ADDRESS);  % trim address to 11-bits
            if entry.isTimeAmplitude
                offsetVal = bitset(offsetVal, ELL_TIME_AMPLITUDE_BIT);
            end

            if entry.isZero
                offsetVal = bitset(offsetVal, ELL_ZERO_BIT);
            end

            if entry.hasTrigger
                offsetVal = bitset(offsetVal, ELL_VALID_TRIGGER_BIT);
            end

            if firstEntry  % start of link list
                % handled outside of entryToOffsetCount
            end

            if lastEntry % mark end of link list
                offsetVal = bitset(offsetVal, ELL_LAST_ENTRY_BIT);
            end

            % use entryData to get length as it includes the padded
            % length
            if ~entry.isTimeAmplitude
                % count val is (length in 4 sample units) - 1
                countVal = fix(entryData.length / ADDRESS_UNIT) - 1;
            else
                countVal = fix(entry.repeat / ADDRESS_UNIT) - 1;
            end
            if (~entry.isTimeAmplitude && countVal > ELL_ADDRESS) || ...
                    (entry.isTimeAmplitude && countVal > ELL_TA_MAX)
                error('Link List countVal %i is too large', countVal);
            end

            currentLength = currentLength + (countVal+1) * ADDRESS_UNIT;

            % test to see if the pattern is running long and we need to trim
            % pendingLength

            pendingLength = expectedLength - currentLength;

        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function triggerVal = entryToTrigger(entry)
            % handle trigger values
            %% Trigger Delay
            %  15  14  13   12   11  10 9 8 7 6 5 4 3 2 1 0
            % | Mode |                Delay                |
            % Delay = time in 3.333 ns increments ( 0 - 54.5 usec )
            
            ELL_TRIGGER_DELAY      = 16383; %hex2dec('3FFF')
            ELL_TRIGGER_MODE_SHIFT = 14;

            % TODO:  hard code trigger for now, need to think about how to
            % describe
            triggerMode = 3; % do nothing
            triggerDelay = 0;

            triggerMode = bitshift(triggerMode, ELL_TRIGGER_MODE_SHIFT);
            triggerDelay = fix(triggerDelay);

            triggerVal = bitand(triggerDelay, ELL_TRIGGER_DELAY);
            triggerVal = bitor(triggerVal, triggerMode);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [wf, banks] = convertLinkListFormat(pattern, useVarients, waveformLibrary, miniLinkRepeat)
            aps = APSPattern;
            if aps.verbose
               fprintf('APS::convertLinkListFormat useVarients = %i\n', useVarients) 
            end

            if ~exist('useVarients','var') || isempty(useVarients)
                useVarients = 1;
            end

            if ~exist('waveformLibrary','var') || isempty(waveformLibrary)
                waveformLibrary = aps.buildWaveformLibrary(pattern, useVarients);
            end

            if ~exist('miniLinkRepeat', 'var') || isempty(miniLinkRepeat)
                miniLinkRepeat = 0;
            end


            wf = APSWaveform();
            wf.data = waveformLibrary.waveforms;

            curBank = 1;
            [banks{curBank} idx] = aps.allocateBank();

            for i = 1:length(pattern.linkLists)
                linkList = pattern.linkLists{i};

                lenLL = length(linkList);

                if  lenLL > aps.max_ll_length
                    error('Individual Link List %i exceeds APS maximum link list length', i)
                end

                % if we are going to fall off the end of the current LL
                % bank, allocate a new one
                if (idx + lenLL) > aps.max_ll_length
                    banks{curBank} = aps.trimBank(banks{curBank},idx-1);
                    curBank = curBank + 1;
                    [banks{curBank} idx] = aps.allocateBank();
                end

                for j = 1:lenLL
                    entry = linkList{j};

                    if aps.verbose
                        fprintf('Entry %i: key: %s length: %2i repeat: %4i \n', j, entry.key, entry.length, ...
                            entry.repeat);
                    end

                    % for test, put trigger on first entry of every mini-LL
                    if j == 1
                        entry.hasTrigger = 1;
                    end

                    [offsetVal countVal] = aps.entryToOffsetCount(entry, waveformLibrary, j == 1, j == lenLL - 1);

                    if isempty(offsetVal) % TAZ of count < 3, skip it
                        continue
                    end

                    if countVal < 3
                        fprintf('Warning entry count < 3. This causes problems with APS\n')
                    end

                    % if we are at end end of the link list entry but this is
                    % not the last of the link list entries set the mini link
                    % list start flag
                    if (i < length(pattern.linkLists)) && (j == lenLL)
                        offsetVal = bitset(offsetVal, aps.ELL_FIRST_ENTRY_BIT);   
                    end

                    if aps.verbose
                        fprintf('\tLink List Offset: %4i Length: %4i Expanded Length: %4i TA: %i Zero:%i\n', ...
                            bitand(offsetVal,aps.ELL_ADDRESS) * aps.ADDRESS_UNIT, ...
                            countVal, countVal * aps.ADDRESS_UNIT, ...
                            entry.isTimeAmplitude, entry.isZero);
                    end

                    % also need to set the LS bit on the first mini-LL
                    % entry
                    if idx == 1
                        offsetVal = bitset(offsetVal, aps.ELL_FIRST_ENTRY_BIT); 
                    end

                    triggerVal = aps.entryToTrigger(j == lenLL);

                    banks{curBank}.offset(idx) = uint16(offsetVal);
                    banks{curBank}.count(idx) = uint16(countVal);
                    banks{curBank}.trigger(idx) = uint16(triggerVal);

                    % set repeat at end of LL list, unless this is the
                    % first mini-LL, in which case we also set the repeat
                    if j == lenLL || idx == 1
                        repeat = uint16(miniLinkRepeat);
                        banks{curBank}.repeat(idx) = repeat;
                    else
                        banks{curBank}.repeat(idx) = 0;
                    end

                    idx = idx + 1;
                end
            end

            % trim last bank
            banks{curBank} = aps.trimBank(banks{curBank},idx-1);
        end
        
        % helper methods used by convertLinkListFormat
        function [bank, idx] = allocateBank()
            self = APSPattern;
            bank.offset = zeros([1,self.max_ll_length],'uint16');
            bank.count = zeros([1,self.max_ll_length],'uint16');
            bank.trigger = zeros([1,self.max_ll_length],'uint16');
            bank.repeat = zeros([1,self.max_ll_length],'uint16');
            bank.length = self.max_ll_length;

            idx = 1;
        end

        function bank = trimBank(bank,len)
            self = APSPattern;
            bank.offset = bank.offset(1:len);
            bank.count = bank.count(1:len);
            bank.trigger = bank.trigger(1:len);
            bank.repeat = bank.repeat(1:len);
            bank.length = len;

            % fix the last mini-LL entry of the current bank by
            % clearing the LL_FIRST_ENTRY bit
            bank.offset(end) = bitset(bank.offset(end), self.ELL_FIRST_ENTRY_BIT, 0);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [pattern] = linkListToPattern(wf, banks)
            aps = APSPattern;
            if aps.verbose
               fprintf('APS::linkListToPattern\n') 
            end
            pattern = [];
            if iscell(banks)
                nBanks = length(banks);
            else
                nBanks = 1;
            end
            for i = 1:nBanks
                if aps.verbose
                    fprintf('Processing Bank: %i\n', i);
                end
                if iscell(banks)
                    bank = banks{i};
                else
                    bank = banks;
                end

                for j = 1:bank.length

                    offset = bank.offset(j);
                    count = bank.count(j) + 1; % length = (count+1)*ADDRESS_UNIT
                    TA = bitand(offset, aps.ELL_TIME_AMPLITUDE) == aps.ELL_TIME_AMPLITUDE;
                    zero = bitand(offset, aps.ELL_ZERO) == aps.ELL_ZERO;

                    idx = aps.ADDRESS_UNIT*bitand(offset, aps.ELL_ADDRESS) + 1;

                    expandedCount = aps.ADDRESS_UNIT * count;

                    if ~TA && ~zero
                        endIdx = aps.ADDRESS_UNIT*count + idx - 1;
                        if aps.verbose
                            fprintf('Using wf.data(%i:%i) length: %i TA:%i zero:%i\n', idx, endIdx,...
                                length(idx:endIdx), TA , zero);
                        end;
                        newPat = wf.data(idx:endIdx);
                        assert(mod(length(newPat),aps.ADDRESS_UNIT) == 0, ...
                            'Expected len(wf) % 4 == 0');
                    elseif zero
                        if aps.verbose
                            fprintf('Using zeros: %i\n', expandedCount);
                        end
                        newPat = zeros([1, expandedCount],'int16');
                    elseif TA
                        if aps.verbose
                            fprintf('Using TA: %i@%i\n', expandedCount, wf.data(idx));
                        end
                        newPat = wf.data(idx)*ones([1, expandedCount],'int16');
                    end
                    pattern = [pattern newPat];
                    %keyboard
                end
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function [unifiedX unifiedY] = unifySequenceLibraryWaveforms(sequences)
            unifiedX = java.util.Hashtable();
            unifiedY = java.util.Hashtable();
            h = waitbar(0,'Unifying Waveform Tables');
            n = length(sequences);
            for seq = 1:n
                waitbar(seq/n,h);
                sequence = sequences{seq};
                xwaveforms = sequence.llpatx.waveforms;
                ywaveforms = sequence.llpaty.waveforms;

                xkeys = xwaveforms.keys;
                ykeys = ywaveforms.keys;

                while xkeys.hasMoreElements()
                    key = xkeys.nextElement();
                    if ~unifiedX.containsKey(key)
                        unifiedX.put(key,xwaveforms.get(key));
                    end
                end

                while ykeys.hasMoreElements()
                    key = ykeys.nextElement();
                    if ~unifiedY.containsKey(key)
                        unifiedY.put(key,ywaveforms.get(key));
                    end
                end
            end

            close(h);
        end
        
        function unifiedX = unifySequenceLibraryWaveformsSingle(sequences)
            unifiedX = java.util.Hashtable();
            n = length(sequences);
            for seq = 1:n
                xwaveforms = sequences{seq}.waveforms;

                xkeys = xwaveforms.keys;

                while xkeys.hasMoreElements()
                    key = xkeys.nextElement();
                    if ~unifiedX.containsKey(key)
                        unifiedX.put(key,xwaveforms.get(key));
                    end
                end
            end
        end

    end
end