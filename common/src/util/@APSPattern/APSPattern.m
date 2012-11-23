classdef APSPattern < handle
    
    properties (Constant=true)
        %APS contraints and constants
        ADDRESS_UNIT = 4;
        MIN_PAD_SIZE = 4;
        MIN_LL_ENTRY_COUNT = 2;
        MAX_WAVEFORM_VALUE = 8191;
        MAX_WAVEFORM_POINTS = 2^14;
        MAX_REPEAT_COUNT = 2^10-1;
        MAX_LL_ENTRIES = 4096;
        
        %APS bit masks
        START_MINILL_BIT = 16;
        END_MINILL_BIT = 15;
        WAIT_TRIG_BIT = 14;
        TA_PAIR_BIT = 13;
    end
    
    methods (Static)
        % forward references
        exportAPSConfig(path, basename, varargin)
        
        
        % Build the waveform library
        %   - absorb paddings into waveform varients
        %   - create the waveform vector
        %   - associate offsets into the vector with each waveform
        
        function library = build_WFLib(pattern, useVarients)
            
            %Default to use variants
            if ~exist('useVarients','var')
                useVarients = 1;
            end
            
            %Load a reference to the class
            %TODO: why is this static then?
            self = APSPattern();
            
            %Pull out the waveforms and link lists
            waveforms = pattern.waveforms;
            linkLists = pattern.linkLists;
            wfKeys = waveforms.keys();
            
            %Sort out whether we are using IQ mode from the size of the
            %waveforms
            if size(waveforms(wfKeys{1}),2) == 2
                IQmode = true;
            else
                IQmode = false;
            end
            
            % populate paddingLib with empty arrays for every hash
            paddingLib = struct();
            for ct = 1:length(wfKeys)
                paddingLib.(wfKeys{ct}) = [];
            end
            if useVarients
                % preprocess waveforms
                for miniLLct = 1:length(linkLists)
                    for entryct = 1:length(linkLists{miniLLct})
                        %Reset the paddings counts at the start of every
                        %miniLL
                        paddingLib = self.preprocessEntry(linkLists{miniLLct}{entryct}, paddingLib, entryct == 1);
                    end
                end
            end
            
            %Allocate space and structues
            offsets = struct();
            lengths = struct();
            varients = struct();
            
            % allocate space for data;
            wfVec_I = zeros([1, self.MAX_WAVEFORM_POINTS],'int16');
            if IQmode
                wfVec_Q = zeros([1, self.MAX_WAVEFORM_POINTS], 'int16');
            end
            
            %Now loop through waveform library
            idx = 1;
            for tmp = wfKeys
                curKey = tmp{1};
                origWF = waveforms(curKey);
                
                %The maximum padding we'll need before we can just create
                %a new zero entry
                maxPadding = self.ADDRESS_UNIT*(self.MIN_LL_ENTRY_COUNT+1)-1;
                %Allocate a cell array for the original and the varients
                varientWFs = cell(maxPadding+1,1);
                
                %See what varients are needed for this waveform
                curPaddings = sort(paddingLib.(curKey));
                if isempty(curPaddings)
                    curPaddings = 0;
                end
                
                %Then add a waveform for each padding
                for curPad = curPaddings
                    assert(curPad <= maxPadding, 'WF padding is too large')
                    
                    %Add the padding to the waveform
                    tmpWF_I = [zeros([1,curPad]) origWF(:,1)'];
                    if IQmode
                        tmpWF_Q = [zeros([1,curPad]), origWF(:,2)'];
                    end
                    
                    %Handle TA pairs by padding out to 4 samples
                    if length(tmpWF_I) == 1
                        % time amplitude pair
                        % pad out to 4 samples
                        tmpWF_I = repmat(tmpWF_I, 1, 4);
                        if IQmode
                            tmpWF_Q = repmat(tmpWF_Q, 1, 4);
                        end
                    end
                    
                    %Pad total length to a multiple of 4
                    residual = mod(-length(tmpWF_I), self.ADDRESS_UNIT);
                    if residual ~= 0 && residual < self.MIN_PAD_SIZE
                        tmpWF_I(end+1:end+residual) = 0;
                        if IQmode
                            tmpWF_Q(end+1:end+residual) = 0;
                        end
                    end
                    
                    assert(mod(length(tmpWF_I), self.ADDRESS_UNIT) == 0, 'WF Padding Failed')
                    
                    %insert into global waveform array
                    wfVec_I(idx:idx+length(tmpWF_I)-1) = tmpWF_I;
                    if IQmode
                        wfVec_Q(idx:idx+length(tmpWF_Q)-1) = tmpWF_Q;
                    end
                    
                    % insert the first instance of the waveform into the
                    % offset, length, and varient maps
                    if ~isfield(offsets, curKey)
                        offsets.(curKey) = idx;
                        lengths.(curKey) = length(tmpWF_I);
                        varients.(curKey) = {};
                    end
                    if useVarients
                        varient.offset = idx;
                        % set length of wf remove extra 8 points that
                        % are used to handle 0 and 1 count TA
                        varient.length = length(tmpWF_I);
                        varient.pad = curPad;
                        varientWFs{curPad+1} = varient; % store the varient at position varientWFs{leadPad+1}
                    end
                    idx = idx + length(tmpWF_I);
                end
                if useVarients && length(origWF) > 1
                    varients.(curKey) = varientWFs;
                end
            end
            
            if idx > self.MAX_WAVEFORM_POINTS
                throw(MException('APS:OutOfMemory',sprintf('Waveform memory %i exceeds APS maximum of %i', idx, aps.max_waveform_points)));
            end
            
            % trim data to only points used
            wfVec_I = wfVec_I(1:idx-1);  % subtract one point as idx is the next insertion point
            if IQmode
                wfVec_Q = wfVec_Q(1:idx-1);
            end
            
            % double check mod ADDRESS_UNIT
            assert(mod(length(wfVec_I), self.ADDRESS_UNIT) == 0,...
                'Global Link List Waveform memory should be mod 4');
            
            %Update the library to return
            library.offsets = offsets;
            library.lengths = lengths;
            library.varients = varients;
            library.wfVec_I = wfVec_I;
            if IQmode
                library.wfVec_Q = wfVec_Q;
            end
        end
        
        %Helper function to find necessary paddings
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
            
            expectedLength = expectedLength + entry.length;
            
            % if we have a zero that is less than count 3, we skip it and
            % pad the following entry
            if entry.isZero && (pendingLength + entry.length < (MIN_LL_ENTRY_COUNT+1) * ADDRESS_UNIT)
                pendingLength = expectedLength - currentLength;
                return;
            end
            
            % pad non-TAZ waveforms if the pendingLength is positive
            paddings = paddingLib.(entry.key);
            updateKeyFlag = 0;
            if pendingLength > 0 && ~entry.isZero && ~entry.isTimeAmplitude
                % add the padding length to the library
                if ~any(paddings == pendingLength) % same as ~ismember(pendingLength, paddings), but faster
                    paddings(end+1) = pendingLength;
                    updateKeyFlag = 1;
                end
                % the entry itself can potentially have additional padding to
                % make the length an integer multiple of the ADDRESS_UNIT
                residual = mod(-(entry.length + pendingLength), ADDRESS_UNIT);
                entry.length = entry.length + pendingLength + residual;
                % pad TAZ regardless of the sign of pendingLength
            elseif entry.isZero
                entry.length = entry.length + pendingLength;
            elseif ~entry.isZero && ~entry.isTimeAmplitude
                % mark this entry with padding = 0
                if ~any(paddings == 0) % same as ~ismember(0, paddings)
                    paddings(end+1) = 0;
                    updateKeyFlag = 1;
                end
            end
            
            % count val is (length in 4 sample units) - 1
            countVal = fix(entry.length / ADDRESS_UNIT) - 1;
            
            currentLength = currentLength + (countVal+1) * ADDRESS_UNIT;
            
            % if the pattern is running long, trim pendingLength
            pendingLength = expectedLength - currentLength;
            
            % update library entry
            if updateKeyFlag
                paddingLib.(entry.key) = paddings;
            end
        end
        
        %Main function to parse a set of patterns into link lists
        function [bankData, wfVec_I, wfVec_Q] = convertLinkListFormat(pattern, useVarients, waveformLibrary)
            self = APSPattern;
            if ~exist('useVarients','var') || isempty(useVarients)
                useVarients = 1;
            end
            
            if ~exist('waveformLibrary','var') || isempty(waveformLibrary)
                waveformLibrary = self.buildWaveformLibrary(pattern, useVarients);
            end
            
            wfVec_I = waveformLibrary.wfVec_I;
            if isfield(waveformLibrary, 'wfVec_Q')
                IQmode = true;
                wfVec_Q = waveformLibrary.wfVec_Q;
            else
                IQmode = false;
                wfVec_Q = [];
            end
            
            bankData = struct();
            numLLEntries = sum(cellfun(@length, pattern.linkLists));
            bankData.addr = zeros([1, numLLEntries], 'uint16');
            bankData.count = zeros([1, numLLEntries], 'uint16');
            bankData.repeat = zeros([1, numLLEntries], 'uint16');
            bankData.trigger1 = zeros([1, numLLEntries], 'uint16');
            bankData.trigger2 = zeros([1, numLLEntries], 'uint16');
            
            dropct = 0;
            idx = 1;
            for miniLLct = 1:length(pattern.linkLists)
                %TODO: process LL entry to split multi-trigger entries
                %                 linkList = self.preprocessLL(pattern.linkLists{miniLLct});
                linkList = pattern.linkLists{miniLLct};
                
                lenLL = length(linkList);
                assert(lenLL < self.MAX_LL_ENTRIES, 'Individual Link List %i exceeds APS maximum link list length', miniLLct)
                
                for entryct = 1:lenLL
                    entry = linkList{entryct};
                    
                    [addr, count] = self.entryToOffsetCount(entry, waveformLibrary, entryct==1);
                    
                    if isempty(addr) % TAZ of count < 3, skip it
                        dropct = dropct+1;
                        continue
                    end
                    
                    assert(count > self.MIN_LL_ENTRY_COUNT, 'Warning entry count < 3. This causes problems with APS\n')
                    
                    [triggerVal1, triggerVal2] = self.entryToTrigger(entry);
                    
                    bankData.addr(idx) = uint16(addr);
                    bankData.count(idx) = uint16(count);
                    bankData.trigger1(idx) = uint16(triggerVal1);
                    bankData.trigger2(idx) = uint16(triggerVal2);
                    
                    %                     set repeat at end of LL list, unless this is the
                    %                     first mini-LL, in which case we also set the repeat
                    
                    bankData.repeat(idx) = entry.repeat - 1; % make zero indexed
                    %Check for beginning/end miniLL
                    if entryct == 1
                        bankData.repeat(idx) = bitset(bankData.repeat(idx), self.START_MINILL_BIT, 1);
                        bankData.repeat(idx) = bitset(bankData.repeat(idx), self.WAIT_TRIG_BIT, 1);
                    elseif entryct == lenLL
                        bankData.repeat(idx) = bitset(bankData.repeat(idx), self.END_MINILL_BIT, 1);
                    end
                    
                    if entry.isTimeAmplitude
                        bankData.repeat(idx) = bitset(bankData.repeat(idx), self.TA_PAIR_BIT, 1);
                    end
                    
                    idx = idx + 1;
                end
            end
            
            %Trim the banks if necessary
            if dropct > 0
                bankData.addr = bankData.addr(1:end-dropct);
                bankData.count = bankData.count(1:end-dropct);
                bankData.trigger1 = bankData.trigger1(1:end-dropct);
                bankData.trigger2 = bankData.trigger2(1:end-dropct);
                bankData.repeat = bankData.repeat(1:end-dropct);
            end
            bankData.length = length(bankData.addr);
        end
        
        %Helper function to calculate address and counts for an entry
        function [addr, count] = entryToOffsetCount(entry, library, resetCounts)
            
            % state variables
            persistent expectedLength pendingLength currentLength
            if resetCounts
                expectedLength = 0;
                pendingLength = 0;
                currentLength = 0;
            end
            
            % lookup of class properites is expensive, create locals
            ADDRESS_UNIT = 4;
            MIN_LL_ENTRY_COUNT = 2;
            MAX_TA_COUNT = 2^16;
            
            expectedLength = expectedLength + entry.length;
            
            % if we have a zero that is less than count 3, we skip it and
            % pad the following entry
            if entry.isZero && (pendingLength + entry.length < (MIN_LL_ENTRY_COUNT+1) * ADDRESS_UNIT)
                pendingLength = expectedLength - currentLength;
                count = [];
                addr = [];
                return;
            end
            
            entryData.addr = library.offsets.(entry.key);
            if entry.isTimeAmplitude
                % TA pairs are always 4 points long in the library, so pull
                % the length from the input entry
                entryData.length = entry.length;
            else
                entryData.length = library.lengths.(entry.key);
            end
            entryData.varientWFs = library.varients.(entry.key);
            % pad non-TAZ waveforms if the pendingLength is positive, provided we have an appropriate varient
            if pendingLength > 0 && ~entry.isZero && ~entry.isTimeAmplitude && ~isempty(entryData.varientWFs)
                % attempt to use a varient
                padIdx = pendingLength + 1;
                assert(padIdx > 0 && padIdx <= (MIN_LL_ENTRY_COUNT+1) * ADDRESS_UNIT,sprintf('Padding Index %i Out of Range', padIdx));
                if length(entryData.varientWFs) >= padIdx   % matlab index offset
                    varient = entryData.varientWFs(padIdx);
                    if iscell(varient), varient = varient{1}; end; % remove cell wrapper
                    entryData.addr = varient.offset;
                    entryData.length = varient.length;
                    assert(varient.pad == pendingLength,'Pending length pad does not match');
                end
            elseif entry.isZero
                % pad TAZ regardless of the sign of pendingLength
                entryData.length = entry.length + pendingLength;
            end
            
            % convert from 1 based count to 0 based count
            % div by 4 required for APS addresses
            addr = fix((entryData.addr - 1) / ADDRESS_UNIT);
            
            % use entryData to get length as it includes the padded
            % length
            % count val is (length in 4 sample units) - 1
            count = fix(entryData.length / ADDRESS_UNIT) - 1;
            
            if entry.isTimeAmplitude && (count > MAX_TA_COUNT)
                %TODO: figure-out new repeat such that repeat*length =
                %count
                error('Link List countVal %i is too large', count);
            end
            
            currentLength = currentLength + (count+1) * ADDRESS_UNIT;
            
            % test to see if the pattern is running long and we need to trim
            % pendingLength
            pendingLength = expectedLength - currentLength;
            
        end
        
        function [triggerVal1, triggerVal2] = entryToTrigger(entry)
            % handle trigger values
            % APS only supports marker pulses, so convert high/low commands
            % into pulses
            % Delay = time in 4 sample increments
            
            TRIGGER_INCREMENT = 4;
            
            if entry.hasMarkerData
                %We use 0 as no trigger data so put in an extra delay for
                %short trigger delays
                if entry.markerDelay1 > 0 && entry.markerDelay1 < 4
                    entry.markerDelay1 = 4;
                end
                if entry.markerDelay2 > 0 && entry.markerDelay2 < 4
                    entry.markerDelay2 = 4;
                end
                triggerVal1 = fix(entry.markerDelay1 / TRIGGER_INCREMENT);
                triggerVal2 = fix(entry.markerDelay2 / TRIGGER_INCREMENT);
            else
                triggerVal1 = 0;
                triggerVal2 = 0;
            end
        end
        
        function maxRepInterval = estimateRepInterval(linkLists)
            %estimateRepInterval - estimates the max rep rate to support streaming of link list data
            %  maxRepInterval = estimateRepInterval(linkLists)
            %    linkLists - a cell array of link lists from PatternGen.build
            
            % Our strategy is just to look at the two longest miniLLs and
            % return the time it takes to write the second largest LL.
            timePerEntry = .050/4096; % measured 46ms average for 4096 entries, use 50 ms as a conservative estimate
            
            sortedLengths = sort(cellfun(@length, linkLists), 'descend');
            if (sum(sortedLengths(1:2)) > APSPattern.MAX_LL_ENTRIES)
                fprinf('WARNING: cannot fit two of the largest LinkLists in memory simultaneously. Impossible to stream without clever ordering.\n');
            end
            maxRepInterval = timePerEntry*sortedLengths(2);
        end
        
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
                end
            end
        end
        
        
    end
    
end

%         function splitList = preprocessLL(linkList)
%             % Perform any tasks necessary to processing a link list before
%             % the main loop. At present, this only requires breaking 'zero'
%             % entries with multiple triggers into separate entries
%             MIN_LL_ENTRY_LENGTH = 16;
%             splitList = linkList;
%
%             kk = 1; % index into splitList
%             for ii = 1:length(linkList)
%                 entry = linkList{ii};
%                 % split an entry only if the entry is at least twice the
%                 % minimum width + 4
%                 if entry.hasMarkerData && entry.isZero && length(entry.markerDelay) > 1
%                     % if the entry is too short to split, clear the marker
%                     % data
%                     if entry.repeat < 2*MIN_LL_ENTRY_LENGTH + 4
%                         entry.hasMarkerData = 0;
%                         splitList{ii} = entry;
%                         kk = kk + 1;
%                     else
%                         origLength = entry.repeat;
%                         delays = entry.markerDelay;
%                         newEntriesLength = 0;
%                         newEntries = cell(length(delays),1);
%
%                         for jj = 1:length(delays)-1
%                             newEntries{jj} = entry;
%                             % make sure the entry is at least the minimum
%                             % length (plus a little extra to avoid putting
%                             % the trigger right on the boundary)
%                             newEntries{jj}.repeat = max(delays(jj)+4, MIN_LL_ENTRY_LENGTH);
%                             % subtract the consumed length from the remaining
%                             % delay
%                             newEntries{jj}.markerDelay = delays(jj) - newEntriesLength;
%                             newEntriesLength = newEntriesLength + newEntries{jj}.repeat;
%                         end
%
%                         % the final entry has the balance of the original
%                         % length
%                         newEntries{end} = entry;
%                         newEntries{end}.repeat = origLength - newEntriesLength;
%                         newEntries{end}.markerDelay = delays(end) - newEntriesLength;
%
%                         % insert the new entries
%                         splitList = [splitList(1:kk-1); newEntries; linkList(ii+1:end)];
%                         kk = kk + length(delays);
%                     end
%                 else
%                     kk = kk + 1;
%                 end
%             end
%         end
%
