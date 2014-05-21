
% Class PATTERNGEN is a utility class for defining time-domain experiments.
%
% Example usage (spin echo experiment):
% delay = 0;
% fixedPt = 1200;
% cycleLen = 1500;
% pg = PatternGen;
% echotimes = 0:1000:10;
% patseq = {pg.pulse('X90p'),...
%			pg.pulse('QId', 'width', echotimes),...
%			pg.pulse('Yp'), ...
%			pg.pulse('QId', 'width', echotimes),...
%			pg.pulse('X90p')};
% [patx paty] = PatternGen.getPatternSeq(patseq, 1, delay, fixedPt, cycleLen);

% Copyright 2010 Raytheon BBN Technologies
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%     http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.

classdef PatternGen < handle
    properties
        pulseLength = 24;
        sigma = 6;
        piAmp = 4000;
        pi2Amp = 2000;
        pi4Amp = 1000;
        delta = -0.5;
        details = struct(); % Detailed pulse specific params.  This probably should replace all of above.
        params = struct(); % Per-pulse parameters.
        pulseType = 'gaussian';
        buffer = 4;
        SSBFreq = 0; % SSB modulation frequency (sign matters!!)
        % gating pulse parameters
        bufferDelay = 0;
        bufferReset = 12;
        bufferPadding = 12;
        
        cycleLength = 10000;
        samplingRate = 1.2e9; % in samples per second
        T = eye(2,2); % matrix correction matrix
        arbPulses;
        arbfname = '';
        linkListMode = false; % enable to construct link lists
        pulseCollection;
    end
    
    methods
        % constructor
        function obj = PatternGen(varargin)
            %PatternGen(varargin) - Creates a pulse generation object
            %  The first parameter can be a qubit label (e.g. 'q1'), in
            %  which case paramters will be pulled from file. Following
            %  that you can specify parameter name/value pairs (e.g.
            %  PatternGen('q1', 'cycleLength', 10000)).
            
            % intialize map containters
            obj.pulseCollection = containers.Map();
            obj.arbPulses = containers.Map();
            
            if nargin > 0 && mod(nargin, 2) == 1 && ischar(varargin{1})
                % called with a qubit name, load parameters from file
                pulseParams = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
                qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
                
                % pull out only relevant parameters
                qubitParams = pulseParams.(varargin{1});
                chParams = pulseParams.(qubitMap.(varargin{1}).IQkey);
                % combine the two structs
                M = [fieldnames(qubitParams)' fieldnames(chParams)'; struct2cell(qubitParams)' struct2cell(chParams)'];
                % remove duplicate fields
                [~, rows] = unique(M(1,:), 'first');
                M = M(:, rows);
                params = struct(M{:});
                
                % now initialize any property with that name 
                fnames = fieldnames(params);
                for ii = 1:length(fnames)
                    paramName = fnames{ii};
                    if ismember(paramName, properties('PatternGen'))
                        obj.(paramName) = params.(paramName);  
                        params=rmfield(params,paramName);
                    end
                end                
                if ~isempty(params)
                    obj.params = params;
                end
                % if there are remaining parameters, assign them
                if nargin > 1
                    obj.assignFromParamPairs(varargin{2:end});
                end
            elseif nargin > 0 && mod(nargin, 2) == 0
                % called with a parameter pair list
                obj.assignFromParamPairs(varargin{:});
            end
        end
        
        function assignFromParamPairs(obj, varargin)
            for i=1:2:nargin-1
                paramName = varargin{i};
                paramValue = varargin{i+1};
                
                if ismember(paramName, properties('PatternGen'))
                    obj.(paramName) = paramValue;
                else
                    warning('%s Ignored not a parameter of PatternGen', paramName);
                end
            end
        end
        
        % pattern generator
        function [xpat ypat] = getPatternSeq(obj, patList, n, delay, fixedPoint)
            numPatterns = size(patList,2);
            xpat = zeros(fixedPoint,1);
            ypat = zeros(fixedPoint,1);
            accumulatedPhase = 0;
            timeStep = 1/obj.samplingRate;
            
            len = 0;

            for i = 1:numPatterns
                [xpulse, ypulse, frameChange] = patList{i}.getPulse(n, accumulatedPhase); % get the pulse in the appropriate frame;
                
                increment = length(xpulse);
                xpat(len+1:len+increment) = xpulse;
                ypat(len+1:len+increment) = ypulse;
                len = len + increment;
                accumulatedPhase = accumulatedPhase - 2*pi*obj.SSBFreq*timeStep*increment + frameChange;
            end
            
            xpat = xpat(1:len);
            ypat = ypat(1:len);
            
            xpat = int16(obj.makePattern(xpat, fixedPoint + delay, [], obj.cycleLength));
            ypat = int16(obj.makePattern(ypat, fixedPoint + delay, [], obj.cycleLength));
        end
        
        function retVal = pulse(obj, p, varargin)                        
            identityPulses = {'QId' 'MId' 'ZId'};
            qubitPulses = {'Xp' 'Xm' 'X90p' 'X90m' 'X45p' 'X45m' 'Xtheta' 'Yp' 'Ym' 'Y90p' 'Y90m' 'Y45p' 'Y45m' 'Ytheta' 'Up' 'Um' 'U90p' 'U90m' 'Utheta'};
            measurementPulses = {'M'};
            fluxPulses = {'Zf' 'Zp' 'Z90p' 'Zm' 'Z90m'};
            
            % Handle pulse aliases and merge in per-pulse parameters
            if isfield(obj.params,p)
                pp=obj.params.(p);
                if isfield(pp,'mapto')
                    p=pp.mapto;
                    pp=rmfield(pp,'mapto');
                end
                varargin=[([fieldnames(pp),struct2cell(pp)]'),varargin'];
                varargin=varargin(:)';
            end
            % set default pulse parameters
            params.amp = 0;
            params.pulse = p;
            params.width = obj.pulseLength;
            params.sigma = obj.sigma;
            params.details = obj.details;
            params.delta = obj.delta;
            params.angle = 0; % in radians
            params.rotAngle = 0;
            params.modFrequency = obj.SSBFreq;
            params.duration = params.width + obj.buffer;
            if ismember(p, qubitPulses) || ismember(p, measurementPulses)
                params.pType = obj.pulseType;
            elseif ismember(p, fluxPulses) || ismember(p, identityPulses)
                params.pType = 'square';
            end
            params.arbfname = obj.arbfname; % for arbitrary pulse shapes
            params = parseargs(params, varargin{:});
                        
            % if only a width was specified (not a duration), need to update the duration
            % parameter
            if ismember('width', varargin(1:2:end)) && ~ismember('duration', varargin(1:2:end))
                params.duration = params.width + obj.buffer;
            end
            
            % extract additional parameters from pulse name
            
            % single qubit pulses
            xPulses = {'Xp' 'Xm' 'X90p' 'X90m' 'X45p' 'X45m' 'Xtheta'};
            yPulses = {'Yp' 'Ym' 'Y90p' 'Y90m' 'Y45p' 'Y45m' 'Ytheta'};
            if ismember(p, xPulses)
                params.angle = 0;
            elseif ismember(p, yPulses)
                params.angle = pi/2;
            end
            
            % set amplitude/rotation angle defaults
            switch p
                case {'Xp','Yp','Up','Zp'}
                    params.amp = obj.piAmp;
                    params.rotAngle = pi;
                case {'Xm','Ym','Um','Zm'}
                    params.amp = -obj.piAmp;
                    params.rotAngle = pi;
                case {'X90p','Y90p','U90p','Z90p'}
                    params.amp = obj.pi2Amp;
                    params.rotAngle = pi/2;
                case {'X90m','Y90m','U90m','Z90m'}
                    params.amp = -obj.pi2Amp;
                    params.rotAngle = pi/2;
                case {'X45p','Y45p','U45p','Z45p'}
                    params.amp = obj.pi4Amp;
                    params.rotAngle = pi/4;
                case {'X45m','Y45m','U45m','Z45m'}
                    params.amp = -obj.pi4Amp;
                    params.rotAngle = pi/4;
            end
            
            % measurement pulses
            if ismember(p, measurementPulses)
                params.amp = obj.piAmp;
                params.buffer = 0;
            end
            
            % these parameters are always determined by the class properties
            params.samplingRate = obj.samplingRate;
            params.T = obj.T;
            
            % create the Pulse object
            retVal = Pulse(p, params);
        end
        
        function LinkLists = build(obj, pulseList, numsteps, delay, fixedPoint, gated)
            % function pg.build(pulseList, numsteps, delay, fixedPoint)
            % inputs:
            % pulseList - cell array of Pulse objects (generated by PatternGen.pulse())
            % numsteps - number of parameters to iterate over in pulseList
            % delay - offset from fixedPoint in # of samples
            % fixedPoint - the delay at which to right align the pulse
            %     sequence, in # of samples
            % gated - boolean that determines if gating pulses should be
            %     calculated for the sequence marker channel
            % returns:
            % LinkLists - nested cell array of miniLL sequences

            if ~exist('gated', 'var')
                gated = 1;
            end
            
            %For now assume we gate with marker1 of the IQ pair
            if gated
                ch = 1;
            end

            numPatterns = length(pulseList);
            
            padWaveform = [0,0];
            padWaveformKey = Pulse.hash(padWaveform);
            padPulse = struct();
            padPulse.isTimeAmplitude = 1;
            padPulse.isZero = 1;
            obj.pulseCollection(padWaveformKey) = padWaveform;
            
            function [entry, frameChange] = buildEntry(pulse, n, accumulatedPhase)
                if isequal(pulse, padPulse)
                    xypulse = padWaveform;
                    frameChange = 0;
                else
                    [xpulse, ypulse, frameChange] = pulse.getPulse(n, accumulatedPhase);
                    xypulse = [xpulse, ypulse];
                end
                entry.length = size(xypulse,1);

                if pulse.isTimeAmplitude && entry.length > 1
                    %Shorten up square waveforms to a single point
                    xypulse = xypulse(fix(end/2),:);
                end
                
                entry.key = Pulse.hash(xypulse);
                entry.repeat = 1;
                entry.isTimeAmplitude = pulse.isTimeAmplitude;
                entry.isZero = pulse.isZero || strcmp(entry.key,padWaveformKey);
                if entry.isZero
                    entry.key = padWaveformKey;
                end
                entry.hasMarkerData = 0;
                entry.markerDelay1 = 0;
                entry.markerDelay2 = 0;
                entry.markerMode = 3; % 0 - pulse, 1 - rising, 2 - falling, 3 - none
                entry.linkListRepeat = 0;
                
                % add to pulse collection
                if ~obj.pulseCollection.isKey(entry.key)
                    obj.pulseCollection(entry.key) = xypulse;
                end
            end
            
            LinkLists = cell(1, numsteps);
            
            for n = 1:numsteps
                % start with a padding pulse which we later expand to the
                % correct length
                LinkList = cell(numPatterns+2,1);
                LinkList{1} = buildEntry(padPulse, 1, 0);
                
                accumulatedPhase = 0;
                timeStep = 1/obj.samplingRate;
                for ii = 1:numPatterns
                    [LinkList{1+ii}, frameChange] = buildEntry(pulseList{ii}, n, accumulatedPhase);
                    dt = LinkList{1+ii}.length * LinkList{1+ii}.repeat;
                    accumulatedPhase = accumulatedPhase - 2*pi*obj.SSBFreq*timeStep*dt + frameChange;
                end

                % sum lengths
                xsum = 0;
                for ii = 1:numPatterns
                    xsum = xsum + LinkList{1+ii}.repeat * LinkList{1+ii}.length;
                end
                
                % pad left
                LinkList{1}.length = fixedPoint + delay - xsum;
                %Catch a pulse sequence is too long when the initial padding is less than zero
                if(LinkList{1}.length < 0)
                    error('Pulse sequence step %i is too long.  Try increasing the fixedpoint.',n);
                end

                xsum = xsum + LinkList{1}.length;
                
                % pad right by adding pad waveform with appropriate repeat
                LinkList{end} = buildEntry(padPulse, 1, 0);
                
                LinkList{end}.length = obj.cycleLength - xsum;
                
                % add gating markers
                if gated
                    LinkList = obj.addGatePulses(LinkList, ch);
                end
                
                LinkLists{n} = LinkList;
            end
        end
        
        function linkList = addGatePulses(obj, linkList, ch)
            % uses the following class buffer parameters to add gating
            % pulses:
            %     bufferReset
            %     bufferPadding
            %     bufferDelay
            
            % The strategy is the following: we add triggers to zero
            % entries and to pulses followed by zero entries. Zero entries
            % followed by pulses get a trigger high. Pulses followed by
            % zeros get a trigger low.
            
            if (ch == 1)
                markerStr = 'markerDelay1';
            elseif (ch == 2)
                markerStr = 'markerDelay2';
            else
                error('Can only handle ch = 1 or 2');
            end

            state = 0; % 0 = low, 1 = high
            %Time from end of previous LL entry that trigger needs to go
            %high to gate pulse
            startDelay = fix(obj.bufferPadding - obj.bufferDelay);

            LLlength = length(linkList);
            for ii = 1:LLlength-1
                entryWidth = linkList{ii}.length;
                %If current state is low and next linkList is pulse, then
                %we go high in this entry.
                %If current state is high and next entry is TAZ then go low
                %in this one (but check bufferReset)
                if state == 0 && ~linkList{ii+1}.isZero
                    linkList{ii}.hasMarkerData = 1;
                    markerDelay = entryWidth - startDelay;
                    if markerDelay < 1
                        markerDelay = 1;
                        fprintf('addGatePulses warning: fixed buffer high pulse to start of pulse\n');
                    end
                    linkList{ii}.(markerStr) = markerDelay;
                    linkList{ii}.markerMode = 0;
                    state = 1;
                elseif state == 1 && ((linkList{ii+1}.isZero && linkList{ii+1}.length - 2*obj.bufferPadding > obj.bufferReset) || ii+1 == LLlength)
                    %Time from beginning of pulse LL entry that trigger needs to go
                    %low to end gate pulse
                    endDelay = fix(entryWidth + obj.bufferDelay + obj.bufferPadding);
                    if endDelay < 1
                        endDelay = 1;
                        fprintf('addGatePulses warning: fixed buffer low pulse to start of pulse\n');
                    end
                    linkList{ii}.hasMarkerData = 1;
                    linkList{ii}.(markerStr) = endDelay;
                    linkList{ii}.markerMode = 0; % 0 = pulse mode
                    state = 0;
                end
            end % end for
        end
            
        function [xpattern, ypattern] = linkListToPattern(obj, linkList)
            xpattern = zeros(1,obj.cycleLength);
            ypattern = xpattern;
            idx = 1;
            for ct = 1:length(linkList)
                if linkList{ct}.isTimeAmplitude
                    amplitude = obj.pulseCollection(linkList{ct}.key);
                    xamp = amplitude(1,1);
                    yamp = amplitude(1,2);
                    xpattern(idx:idx+linkList{ct}.length-1) = xamp * ones(1,linkList{ct}.length);
                    ypattern(idx:idx+linkList{ct}.length-1) = yamp * ones(1,linkList{ct}.length);
                    idx = idx + linkList{ct}.length;
                else
                    currWf = obj.pulseCollection(linkList{ct}.key);
                    xpattern(idx:idx+linkList{ct}.repeat*length(currWf)-1) = repmat(currWf(:,1)', 1, linkList{ct}.repeat);
                    ypattern(idx:idx+linkList{ct}.repeat*length(currWf)-1) = repmat(currWf(:,2)', 1, linkList{ct}.repeat);
                    idx = idx + linkList{ct}.repeat*size(currWf,1);
                end
            end
        end
    end
    methods (Static)
        function out = print(seq)
            if iscell(seq)
                out = cellfun(@PatternGen.print, seq, 'UniformOutput', false);
            else
                out = seq.print();
            end
        end
        function out = padLeft(m, len)
            if length(m) < len
                out = [zeros(len - length(m), 1); m];
            else
                out = m;
            end
        end
        
        function out = padRight(m, len)
            if length(m) < len
                out = [m; zeros(len-length(m), 1)];
            else
                out = m;
            end
        end
        
        function out = makePattern(leftPat, fixedPt, rightPat, totalLength)
            self = PatternGen;
            if(length(leftPat) > fixedPt)
                error('Your sequence is %d too long.  Try moving the fixedPt out.', (length(leftPat)-fixedPt))
            end
            out = self.padRight([self.padLeft(leftPat, fixedPt); rightPat], totalLength);
        end

        % buffer pulse generator
		function out = bufferPulse(patx, paty, zeroLevel, padding, reset, delay)
            % min reset = 1
            if reset < 1
				reset = 1;
			end

            % subtract offsets
			patx = patx(:) - zeroLevel;
            paty = paty(:) - zeroLevel;
            
            % find when either channel is high
            pat = double(patx | paty);
			
			% buffer to the left
			pat = flipud(conv( flipud(pat), ones(1+padding, 1), 'same' ));
			
			% buffer to the right
			pat = conv( pat, ones(1+padding, 1), 'same');
			
			% convert to on/off
			pat = uint8(logical(pat));
			
			% keep the pulse high if the delay is less than the reset time
            onOffPts = find(diff(int8(pat)));
            bufferSpacings = diff(onOffPts);
            if length(onOffPts) > 2
                for ii = 1:floor(length(bufferSpacings)/2)
                    if bufferSpacings(2*ii) < reset
                        pat(onOffPts(2*ii):onOffPts(2*ii+1)+1) = 1;
                    end
                end
            end
			
			% shift by delay # of points
            out = circshift(pat, delay);
        end
        
        function seqs = addTrigger(seqs, delay, width, ch)
            % adds a trigger pulse to each sequence
            % delay - delay (in samples) from the beginning of the link list to the
            %   trigger rising edge
            % width - width (in samples) of the trigger pulse
            % ch - which marker to channel to use
            
            if (ch == 1)
                markerStr = 'markerDelay1';
            elseif (ch == 2)
                markerStr = 'markerDelay2';
            else
                error('Can only handle ch = 1 or 2');
            end
            
            %We can't implement triggers at delay 0
            assert(delay>0, 'Sorry! Triggers at delay=0 cannot be implemented yet.');
            
            for miniLLct = 1:length(seqs)
                %Find the cummulative length of each entry
                timePts = [0; cumsum(cellfun(@(tmpEntry) tmpEntry.length*tmpEntry.repeat, seqs{miniLLct}))];
                
                %Make sure the trigger falls in the sequence
                assert(delay+width<timePts(end), 'Oops! You have asked for a trigger outside of the pulse sequence');

                %Find where to put the go high blip
                goHighEntry = find(delay<=timePts, 1)-1;
                
                seqs{miniLLct}{goHighEntry}.hasMarkerData = 1;
                markerDelay = delay-timePts(goHighEntry);
                %The firmware can't handle 0 delays
                if markerDelay == 0
                    markerDelay = markerDelay+1;
                end
                seqs{miniLLct}{goHighEntry}.(markerStr) = markerDelay;
                
                %Now if the length of the pulse is greater than one we need
                %to put the go low blip
                if (width > 1)
                    goLowEntry = find((delay+width)<timePts, 1)-1;
                    
                    %If it is the same entry we should be doing something
                    %fancy like splitting or pushing the goHighBack one
                    %entry but for now just go low as soon as possible
                    if (goLowEntry == goHighEntry)
                        seqs{miniLLct}{goLowEntry+1}.hasMarkerData = 1;
                        seqs{miniLLct}{goLowEntry+1}.(markerStr) = 1;
                    else
                        seqs{miniLLct}{goLowEntry}.hasMarkerData = 1;
                        markerDelay = delay+width-timePts(goLowEntry);
                        %The firmware can't handle 0 delays
                        if markerDelay == 0
                            markerDelay = markerDelay+1;
                        end
                        seqs{miniLLct}{goLowEntry}.(markerStr) = markerDelay;
                    end
                end
            end
            
        end
        
    end
end
