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
        dPulseLength = 24;
        dSigma = 6;
        dPiAmp = 4000;
        dPiOn2Amp = 2000;
        dPiOn4Amp = 1000;
        dDelta = -0.5;
        dPulseType = 'gaussian';
        dBuffer = 5;
        dmodFrequency = 0; % SSB modulation frequency (sign matters!!)
        cycleLength = 10000;
        samplingRate = 1.2e9; % in samples per second
        correctionT = eye(2,2);
        arbPulses = containers.Map();
        dArbfname = '';
        linkList = false; % enable to construct link lists
        sha = java.security.MessageDigest.getInstance('SHA-1');
        pulseCollection = containers.Map();
    end
    
    methods (Static)
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
        
        %%%% pulse shapes %%%%%
        function [outx, outy] = squarePulse(params)
            amp = params.amp;
            n = params.width;
            
            outx = amp * ones(n, 1);
            outy = zeros(n, 1);
        end
        
        function [outx, outy] = gaussianPulse(params)
            amp = params.amp;
            n = params.width;
            sigma = params.sigma;
            
            midpoint = (n+1)/2;
            t = 1:n;
            baseLine = round(amp*exp(-midpoint^2/(2*sigma^2)));
            outx = round(amp * exp(-(t - midpoint).^2./(2 * sigma^2))).'- baseLine;
            outy = zeros(n, 1);
        end
        
        function [outx, outy] = gaussOnPulse(params)
            amp = params.amp;
            n = params.width;
            sigma = params.sigma;
            
            t = 1:n;
            baseLine = round(amp*exp(-n^2/(2*sigma^2)));
            outx = round(amp * exp(-(t - n).^2./(2 * sigma^2))).'- baseLine;
            outy = zeros(n, 1);
        end
        
        function [outx, outy] = gaussOffPulse(params)
            amp = params.amp;
            n = params.width;
            sigma = params.sigma;
            
            t = 1:n;
            baseLine = round(amp*exp(-n^2/(2*sigma^2)));
            outx = round(amp * exp(-(t-1).^2./(2 * sigma^2))).'- baseLine;
            outy = zeros(n, 1);
        end
        
        function [outx, outy] = tanhPulse(params)
            amp = params.amp;
            n = params.width;
            sigma = params.sigma;
            if (n < 6*sigma)
                warning('tanhPulse:params', 'Tanh pulse length is shorter than rise+fall time');
            end
            t0 = 3*sigma + 1;
            t1 = n - 3*sigma;
            t = 1:n;
            outx = round(0.5*amp * (tanh((t-t0)./sigma) + tanh(-(t-t1)./sigma))).';
            outy = zeros(n, 1);
        end
        
        function [outx, outy] = derivGaussianPulse(params)
            amp = params.amp;
            n = params.width;
            sigma = params.sigma;
            
            midpoint = (n+1)/2;
            t = 1:n;
            outx = round(amp .* (t - midpoint)./sigma^2 .* exp(-(t - midpoint).^2./(2 * sigma^2))).';
            outy = zeros(n, 1);
        end
        
        function [outx, outy] = derivGaussOnPulse(params)
           amp = params.amp;
           n = params.width;
           sigma = params.sigma;

           t = 1:n;
           outx = round(amp * (-(t-n)./sigma^2).*exp(-(t-n).^2./(2 * sigma^2))).';
           outy = zeros(n, 1);
        end

        function [outx, outy] = derivGaussOffPulse(params)
           amp = params.amp;
           n = params.width;
           sigma = params.sigma;

           t = 1:n;
           outx = round(amp * (-(t-1)./sigma^2).*exp(-(t-1).^2./(2 * sigma^2))).';
           outy = zeros(n, 1);
        end
        
        function [outx, outy] = dragPulse(params)
            self = PatternGen;
            yparams = params;
            yparams.amp = params.amp * params.delta;
            
            [outx, tmp] = self.gaussianPulse(params);
            [outy, tmp] = self.derivGaussianPulse(yparams);
        end
        
        function [outx, outy] = dragGaussOnPulse(params)
            self = PatternGen;
            derivParams = params;
            derivParams.amp = params.amp*params.delta;
            [outx, ~] = self.gaussOnPulse(params);
            [outy, ~] = self.derivGaussOnPulse(derivParams);
        end
        
        function [outx, outy] = dragGaussOffPulse(params)
            self = PatternGen;
            derivParams = params;
            derivParams.amp = params.amp*params.delta;
            [outx, ~] = self.gaussOffPulse(params);
            [outy, ~] = self.derivGaussOffPulse(derivParams);
        end
        
        function [outx, outy] = hermitePulse(params)
            %Broadband excitation pulse based on Hermite polynomials. 
            numPoints = params.width;
            timePts = linspace(-numPoints/2,numPoints/2,numPoints)';
            switch params.rotAngle
                case pi/2
                    A1 = -0.677;
                case pi
                    A1 = -0.956;
                otherwise
                    error('Unknown rotation angle for Hermite pulse.  Currently only handle pi/2 and pi.');
            end
            outx = params.amp*(1+A1*(timePts/params.sigma).^2).*exp(-((timePts/params.sigma).^2));
            outy = zeros(numPoints,1);
        end
        
        function [outx, outy] = arbitraryPulse(params)
            persistent arbPulses;
            if isempty(arbPulses)
                arbPulses = containers.Map();
            end
            amp = params.amp;
            fname = params.arbfname;
            delta = params.delta;
            
            if ~arbPulse.isKey(fname)
                % need to load the pulse from file
                % TODO check for existence of file before loading it
                arbPulses(fname) = load(fname);
            end
            pulseData = arbPulses(fname);
            outx = round(amp*pulseData(:,1));
            outy = round(delta*amp*pulseData(:,2));
        end
        
        % pulses defined in external files
        [outx, outy] = dragSqPulse(params);
        
        % buffer pulse generator
		function out = bufferPulse(patx, paty, zeroLevel, padding, reset, delay)
			self = PatternGen;
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
            onOffPts = find(diff(pat));
            bufferSpacings = diff(onOffPts);
            if length(onOffPts) > 2
                for ii = 1:(length(bufferSpacings)/2-1)
                    if bufferSpacings(2*ii) < reset
                        pat(onOffPts(2*ii):onOffPts(2*ii+1)+1) = 1;
                    end
                end
            end
			
			% shift by delay # of points
            out = circshift(pat, delay);
        end
    end
    
    methods
        % constructor
        function obj = PatternGen(varargin)
            % set any default parameters passed in
            if nargin > 0 && mod(nargin, 2) == 0
                for i=1:2:nargin
                    paramName = varargin{i};
                    paramValue = varargin{i+1};
                    
                    if ismember(paramName, properties('PatternGen'))
                        obj.(paramName) = paramValue;
                    else
                        warning('%s Ignored not a parameter of PatternGen', paramName);
                    end
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
                [xpulse ypulse] = patList{i}(n, accumulatedPhase); % call the current pulse function
                increment = length(xpulse);
                xpat(len+1:len+increment) = xpulse;
                ypat(len+1:len+increment) = ypulse;
                len = len + increment;
                accumulatedPhase = accumulatedPhase - 2*pi*obj.dmodFrequency*timeStep*increment;
            end
            
            xpat = xpat(1:len);
            ypat = ypat(1:len);
            
            xpat = obj.makePattern(xpat, fixedPoint + delay, [], obj.cycleLength);
            ypat = obj.makePattern(ypat, fixedPoint + delay, [], obj.cycleLength);
        end
        
        function retVal = pulse(obj, p, varargin)
            self = obj;
            if obj.linkList % if linkList mode is enabled, return a struct
                retVal = struct();
                retVal.pulseArray = {};
                retVal.hashKeys = [];
                retVal.isTimeAmplitude = 0;
                retVal.isZero = 0;
            else % otherwise return the pulseFunction closure
                retVal = @pulseFunction;
            end
            
            identityPulses = {'QId' 'MId' 'ZId'};
            qubitPulses = {'Xp' 'Xm' 'X90p' 'X90m' 'X45p' 'X45m' 'Xtheta' 'Yp' 'Ym' 'Y90p' 'Y90m' 'Y45p' 'Y45m' 'Ytheta' 'Up' 'Um' 'U90p' 'U90m' 'Utheta'};
            measurementPulses = {'M'};
            fluxPulses = {'Zf' 'Zp' 'Z90p' 'Zm' 'Z90m'};
            
            % set default pulse parameters
            params.amp = 0;
            params.width = self.dPulseLength;
            params.sigma = self.dSigma;
            params.delta = self.dDelta;
            params.angle = 0; % in radians
            params.rotAngle = 0;
            params.modFrequency = self.dmodFrequency;
            params.duration = params.width + self.dBuffer;
            if ismember(p, qubitPulses)
                params.pType = self.dPulseType;
            elseif ismember(p, measurementPulses) || ismember(p, fluxPulses) || ismember(p, identityPulses)
                params.pType = 'square';
            end
            params.arbfname = self.dArbfname; % for arbitrary pulse shapes
            params = parseargs(params, varargin{:});
            % if only a width was specified (not a duration), need to update the duration
            % parameter
            if ismember('width', varargin(1:2:end)) && ~ismember('duration', varargin(1:2:end))
                params.duration = params.width + self.dBuffer;
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
                    params.amp = self.dPiAmp;
                    params.rotAngle = pi;
                case {'Xm','Ym','Um','Zm'}
                    params.amp = -self.dPiAmp;
                    params.rotAngle = pi;
                case {'X90p','Y90p','U90p','Z90p'}
                    params.amp = self.dPiOn2Amp;
                    params.rotAngle = pi/2;
                case {'X90m','Y90m','U90m','Z90m'}
                    params.amp = -self.dPiOn2Amp;
                    params.rotAngle = pi/2;
                case {'X45p','Y45p','U45p','Z45p'}
                    params.amp = self.dPiOn4Amp;
                    params.rotAngle = pi/4;
                case {'X45m','Y45m','U45m','Z45m'}
                    params.amp = -self.dPiOn4Amp;
                    params.rotAngle = pi/4;
            end       
            
            if ismethod(self, [params.pType 'Pulse'])
                pf = eval(['@self.' params.pType 'Pulse']);
            else
                error('%s is not a valid method', [params.pType 'Pulse'] )
            end
            
            % measurement pulses
            if strcmp(p, 'M')
                params.amp = 1;
                params.modFrequency = 0;
            end
            
            % if amp, width, sigma, or angle is a vector, get the nth entry
            function out = getelement(x, n)
                if isscalar(x) || ischar(x)
                    out = x;
                else
                    out = x(n);
                end
            end
            
            function out = getlength(x)
                if isscalar(x) || ischar(x)
                    out = 1;
                else
                    out = length(x);
                end
            end
            
            % find longest parameter vector
            nbrPulses = max(structfun(@getlength, params));
            pulses = cell(nbrPulses,1);
            modAngles = cell(nbrPulses,1);
            % construct cell array of pulses for all parameter vectors
            for n = 1:nbrPulses
                % pick out the nth element of parameters provided as
                % vectors
                elementParams = structfun(@(x) getelement(x, n), params, 'UniformOutput', 0);
                duration = elementParams.duration;
                width = elementParams.width;
                
                [xpulse, ypulse] = pf(elementParams);
                
                % add buffer padding
                if (duration > width)
                    padleft = floor((duration - width)/2);
                    padright = ceil((duration - width)/2);
                    xpulse = [zeros(padleft,1); xpulse; zeros(padright,1)];
                    ypulse = [zeros(padleft,1); ypulse; zeros(padright,1)];
                end
                
                % store the pulse
                pulses{n} = xpulse +1j*ypulse;
                
                % precompute SSB modulation angles
                timeStep = 1/self.samplingRate;
                modAngles{n} = - 2*pi*params.modFrequency*timeStep*(0:(length(pulses{n})-1))';
            end
            
            % create closure with the parameters defined above
            function [xpulse, ypulse] = pulseFunction(n, accumulatedPhase)
                % n - index into parameter arrays
                % accumulatedPhase - allows dynamic updating of the basis
                %   based upon the position in time of the pulse
                angle = params.angle(1+mod(n-1, length(params.angle)));
                complexPulse = pulses{1+mod(n-1, length(pulses))};
                
                % rotate and correct the pulse
                tmpAngles = angle + accumulatedPhase + modAngles{1+mod(n-1, length(modAngles))};
                complexPulse = complexPulse.*exp(1j*tmpAngles);
                xypairs = self.correctionT*[real(complexPulse) imag(complexPulse)].';
                xpulse = xypairs(1,:).';
                ypulse = xypairs(2,:).';
            end
            
            if obj.linkList
                % how this should look
                %retVal.pulseArray = arrayfun(@pulseFunction, 1:nbrPulses, 'UniformOutput', 0);
                %retVal.hashKeys = cellfun(@obj.hashArray, retVal.pulseArray, 'UniformOutput', 0);
                % some weird MATLAB bug causes this not to work, hence the
                % following for loop
                retVal.pulseArray = cell(nbrPulses,1);
                retVal.hashKeys = cell(nbrPulses,1);
                for ii = 1:nbrPulses
                    [xpulse, ypulse] = pulseFunction(ii, 0);
                    retVal.pulseArray{ii} = [xpulse, ypulse];
                    retVal.hashKeys{ii} = obj.hashArray(retVal.pulseArray{ii});
                end
                if strcmp(params.pType, 'square')
                    retVal.isTimeAmplitude = 1;
                end
                if ismember(p, identityPulses)
                    retVal.isZero = 1;
                end
                for ii = 1:length(retVal.hashKeys)
                    self.pulseCollection(retVal.hashKeys{ii}) = retVal.pulseArray{ii};
                end
            end
            
        end
        
        function h = hashArray(obj, array)
            % uses java object to build hash string.
            if isempty(array)
                array = 0;
            end
            obj.sha.reset();
            obj.sha.update(array(:));
            h = obj.sha.digest();
            % concert to ASCII char array a-z
            h = char(97 + mod(h', 26));
        end
        
        function xpat = build(obj, patListParams, numsteps, delay, fixedPoint)
            % xpat - struct(waveforms, linkLists) with hashtable of
            %   x waveforms and the link list that references the hashtable
            % ypat - same for y waveforms
            % patList - sequential references to pulseCollection entries            

            numPatterns = length(patListParams); % check this
            
            padWaveform = [0,0];
            padWaveformKey = obj.hashArray(padWaveform);
            padPulse = struct();
            padPulse.pulseArray = {padWaveform};
            padPulse.hashKeys = {padWaveformKey};
            padPulse.isTimeAmplitude = 1;
            padPulse.isZero = 1;
            obj.pulseCollection(padWaveformKey) = padWaveform;
            
            function entry = buildEntry(pulse, n)
                
                reducedIndex = 1 + mod(n-1, length(pulse.hashKeys));
                entry.key = pulse.hashKeys{reducedIndex};
                if pulse.isTimeAmplitude
                    % repeat = width for time/amplitude pulses
                    entry.length = 1;
                    entry.repeat = length(pulse.pulseArray{reducedIndex});
                    entry.isTimeAmplitude = 1;
                else
                    entry.length = length(pulse.pulseArray{reducedIndex});
                    entry.repeat = 1;
                    entry.isTimeAmplitude = 0;
                end
                entry.isZero = pulse.isZero || strcmp(entry.key,padWaveformKey);
                if entry.isZero
                    % remove zero pulses from pulse collection
                    if ~all(entry.key == padWaveformKey) && obj.pulseCollection.isKey(entry.key)
                        obj.pulseCollection.remove(entry.key);
                    end
                    entry.key = padWaveformKey;
                end
                entry.hasTrigger = 0;
                entry.linkListRepeat = 0;
            end
            
            LinkLists = {};
            
            for n = 1:numsteps
                % start with a padding pulse which we later expand to the
                % correct length
                LinkList = cell(numPatterns+2,1);
                LinkList{1} = buildEntry(padPulse, 1);
                
                for ii = 1:numPatterns
                    LinkList{1+ii} = buildEntry(patListParams{ii}, n);
                end

                % sum lengths
                xsum = 0;
                for ii = 1:numPatterns
                    xsum = xsum + LinkList{1+ii}.repeat * LinkList{1+ii}.length;
                end
                
                % pad left but setting repeat count
                LinkList{1}.repeat = fixedPoint + delay - xsum;
                %Catch a pulse sequence is too long when the initial padding is less than zero
                if(LinkList{1}.repeat < 0)
                    error('Pulse sequence step %i is too long.  Try increasing the fixedpoint.',n);
                end

                xsum = xsum + LinkList{1}.repeat;
                
                % pad right by adding pad waveform with appropriate repeat
                LinkList{end} = buildEntry(padPulse, 1);
                
                LinkList{end}.repeat = obj.cycleLength - xsum;
                
                LinkLists{n} = LinkList;
            end
            
            xpat.waveforms = obj.pulseCollection;
            xpat.linkLists = LinkLists;
        end
            
        function plotWaveformTable(obj,table)
            wavefrms = [];
            keys = table.keys;
            while keys.hasMoreElements()
                key = keys.nextElement();
                wavefrms = [wavefrms table.get(key)'];
            end
            plot(wavefrms)
        end
        
        function [xpattern, ypattern] = linkListToPattern(obj, linkListPattern, n)
            linkList = linkListPattern.linkLists{n};
            wfLib = linkListPattern.waveforms;
            
            xpattern = zeros(1,obj.cycleLength);
            ypattern = xpattern;
            idx = 1;
            for ct = 1:length(linkList)
                if linkList{ct}.isTimeAmplitude
                    amplitude = wfLib(linkList{ct}.key);
                    xamp = amplitude(1,1);
                    yamp = amplitude(1,2);
                    xpattern(idx:idx+linkList{ct}.repeat-1) = xamp * ones(1,linkList{ct}.repeat);
                    ypattern(idx:idx+linkList{ct}.repeat-1) = yamp * ones(1,linkList{ct}.repeat);
                    idx = idx + linkList{ct}.repeat;
                else
                    currWf = wfLib(linkList{ct}.key);
                    xpattern(idx:idx+linkList{ct}.repeat*length(currWf)-1) = repmat(currWf(:,1)', 1, linkList{ct}.repeat);
                    ypattern(idx:idx+linkList{ct}.repeat*length(currWf)-1) = repmat(currWf(:,2)', 1, linkList{ct}.repeat);
                    idx = idx + linkList{ct}.repeat*size(currWf,1);
                end
            end
        end
    end
end
