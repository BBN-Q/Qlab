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
        dDelta = 0.4;
        dPulseType = 'gaussian';
        dBuffer = 5;
        dmodFrequency = 0; % SSB modulation frequency (sign matters!!)
        cycleLength = 10000;
        samplingRate = 1e9; % in samples per second
        correctionT = eye(2,2);
        arbPulses = containers.Map();
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
            outx = round(amp * exp(-(t - midpoint).^2./(2 * sigma^2))).';
            outy = zeros(n, 1);
        end
        
        function [outx, outy] = gaussOnPulse(params)
            amp = params.amp;
            n = params.width;
            sigma = params.sigma;
            
            t = 1:n;
            outx = round(amp * exp(-(t - n).^2./(2 * sigma^2))).';
            outy = zeros(n, 1);
        end
        
        function [outx, outy] = gaussOffPulse(params)
            amp = params.amp;
            n = params.width;
            sigma = params.sigma;
            
            t = 1:n;
            outx = round(amp * exp(-(t-1).^2./(2 * sigma^2))).';
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
        
        function [outx, outy] = dragPulse(params)
            self = PatternGen;
            yparams = params;
            yparams.amp = params.amp * params.delta;
            
            [outx, tmp] = self.gaussianPulse(params);
            [outy, tmp] = self.derivGaussianPulse(yparams);
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
            
            if ~ismember(fname, keys(arbPulses))
                % need to load the pulse from file
                % TODO check for existence of file before loading it
                arbPulses(fname) = load(fname);
            end
            pulseData = arbPulses(fname);
            outx = round(amp*pulseData(:,1));
            outy = round(amp*pulseData(:,2));
        end
        
        % buffer pulse generator
		function out = bufferPulse(patx, paty, zeroLevel, padding, reset, delay)
			self = PatternGen;
			% subtract offsets
			patx = patx - zeroLevel;
            paty = paty - zeroLevel;
            
            % find when either channel is high
            pat = double(patx | paty);
			
			% buffer to the left
			pat = flipud(conv( flipud(pat), ones(1+padding, 1), 'same' ));
			
			% buffer to the right
			pat = conv( pat, ones(1+padding, 1), 'same');
			
			% convert to on/off
			pat = uint8(logical(pat));
			
			% keep the pulse high if the delay is less than the reset time
			% min reset = 1
			if reset < 1
				reset = 1;
			end
			i = 1;
			while i < (length(pat)-reset-1)
				if (pat(i) && pat(i+reset+1))
					pat = [pat(1:i); ones(reset,1); pat(i+reset+1:end)];
					i = i + reset + 1;
				else
					i = i + 1;
				end
			end
			
			% shift to the left by the delay amount
			out = [pat(delay+1:end); zeros(delay,1)];
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
            self = PatternGen;
            numPatterns = size(patList,2);
            xpat = zeros(fixedPoint,1);
            ypat = zeros(fixedPoint,1);
            len = 0;
            
            for i = 1:numPatterns
                [xpulse ypulse] = patList{i}(n); % call the current pulse function
                increment = length(xpulse);
                xpat(len+1:len+increment) = xpulse;
                ypat(len+1:len+increment) = ypulse;
                len = len + increment;
            end
            
            xpat = xpat(1:len);
            ypat = ypat(1:len);
            
            xpat = self.makePattern(xpat, fixedPoint + delay, [], obj.cycleLength);
            ypat = self.makePattern(ypat, fixedPoint + delay, [], obj.cycleLength);
        end
        
        function pHandle = pulse(obj, p, varargin)
            self = obj;
            pHandle = @pulseFunction;
            
            qubitPulses = {'QId' 'Xp' 'Xm' 'X90p' 'X90m' 'X45p' 'X45m' 'Xtheta' 'Yp' 'Ym' 'Y90p' 'Y90m' 'Y45p' 'Y45m' 'Ytheta' 'Up' 'Um' 'U90p' 'U90m' 'Utheta'};
            measurementPulses = {'M' 'MId'};
            fluxPulses = {'Zf' 'ZId' 'Zp' 'Z90p', 'Zm', 'Z90m'};
            
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
            elseif ismember(p, measurementPulses)
                params.pType = 'square';
            elseif ismember(p, fluxPulses)
                params.pType = 'square';
            end
            params.arbfname = ''; % for arbitrary pulse shapes
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
            
            % pi pulses
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
            end
            
            % create closure with the parameters defined above
            function [xpulse, ypulse] = pulseFunction(n)
                % if amp, width, sigma, or angle is a vector, get the nth entry
                function out = getelement(x)
                    if isscalar(x) || ischar(x)
                        out = x;
                    else
                        out = x(n);
                    end
                end
                
                % pick out the nth element of parameters provided as
                % vectors
                elementParams = params;
                fields = fieldnames(params);
                for ii = 1:length(fields)
                    field = fields{ii};
                    elementParams.(field) = getelement(params.(field));
                end
                angle = elementParams.angle;
                duration = elementParams.duration;
                width = elementParams.width;
                
                [xpulse, ypulse] = pf(elementParams);
                
                % rotate and correct the pulse
                complexPulse = xpulse +1j*ypulse;
                timeStep = 1/self.samplingRate;
                tmpAngles = angle + 2*pi*params.modFrequency*timeStep*(0:(width-1))';
                complexPulse = complexPulse.*exp(1j*tmpAngles);
                xypairs = self.correctionT*[real(complexPulse) imag(complexPulse)].';
                xpulse = xypairs(1,:).';
                ypulse = xypairs(2,:).';
                
                if (duration > width)
                    padleft = floor((duration - width)/2);
                    padright = ceil((duration - width)/2);
                    xpulse = [zeros(padleft,1); xpulse; zeros(padright,1)];
                    ypulse = [zeros(padleft,1); ypulse; zeros(padright,1)];
                end
            end
        end
        
        function [xpat, ypat, patList, pulseCollection] = build(obj,patListParams,numsteps, delay, fixedPoint, pulseCollection)
            % xpat - struct(waveforms, linkLists) with hashtable of
            %   x waveforms and the link list that references the hashtable
            % ypat - same for y waveforms
            % patList - sequential references to pulseCollection entries
            % pulseCollection - hashtable of pulse() closures
            
            if ~exist('pulseCollection', 'var') || isempty(pulseCollection)
                pulseCollection = containers.Map();
            end
            
            if ~libisloaded('libaps')
                md5 = java.security.MessageDigest.getInstance('MD5');
            else
                sha1key = libpointer('stringPtr','                                        ');
            end
            
            % build pulse function list
            for i = 1:length(patListParams)
                name = patListParams{i}{1};
                if length(patListParams{i}) > 1
                    patList{i} = obj.pulse(name, patListParams{i}{2:end});
                else
                    if ~isKey(pulseCollection,name)
                        pulseCollection(name) = obj.pulse(name);
                    end
                    patList{i} = pulseCollection(name);
                end
            end

            numPatterns = size(patList,2);
            len = 0;
            
            xLinkLists = {};
            yLinkLists = {};
            
            xWaveformTable = java.util.Hashtable;
            yWaveformTable = java.util.Hashtable;
            
            padWaveform = [0];
            padWaveformKey = hashArray(padWaveform);
                        
            function h = hashArray(array)
                % this hash array function was causing performance problems
                % original version created digest every call to hashArray
                % and used dec2hex to convert to a hex string as a hash
                %
                % new version keeps one message digest per call to build
                % and uses java to build hash string. Still need to check
                % performance
                if ~libisloaded('libaps')
                    md5.reset();
                    md5.update(array);
                    h=typecast(md5.digest,'uint8');
                    h = mat2str(h);
                else
                    sha1key.Value = '                                        ';
                    calllib('libaps','APS_HashPulse', array,length(array),sha1key,length(sha1key.Value));
                    h = sha1key.Value;
                end
            end
            
            
            function [entry, table] = buildEntry(table, pulse, pulseType)
                
                if ~exist('pulseType', 'var')
                    pulseType = '';
                end
                
                key = hashArray(pulse);
                
                entry.key = key;
                % mark square pulses as time/amplitude
                if strcmp(pulseType, 'square')
                    % repeat = width for time/amplitude pulses
                    entry.length = 1;
                    entry.repeat = length(pulse);
                    entry.isTimeAmplitude = 1;
                    % convert pulse to a single point
                    % note, this introduces an error with buffered pulses
                    if length(pulse) > 1
                        pulse = pulse(fix(end/2));
                    end
                else
                    entry.length = length(pulse);
                    entry.repeat = 1;
                    entry.isTimeAmplitude = 0;
                end
                entry.isZero = strcmp(key,padWaveformKey);
                entry.hasTrigger = 0;
                entry.linkListRepeat = 0;
                
                if ~table.containsKey(key)
                    table.put(key, pulse);
                end;
            end
            
            for n = 1:numsteps
                
                xLinkList = {};
                yLinkList = {};
                [xLinkList{1} xWaveformTable] = buildEntry(xWaveformTable, padWaveform, 'square');
                [yLinkList{1} yWaveformTable] = buildEntry(yWaveformTable, padWaveform, 'square');
                
                for i = 1:numPatterns
                    
                    name = patListParams{i}{1};
                    % Hash Waveform unless it is an Identity pulse which
                    % is treated as a speacial case of time amplitude pair
                    
                    [xpulse ypulse] = patList{i}(n);
                    if (~xpulse & ~ypulse) % null pulses are effectively QId's
                        name = 'QId';
                    end
                    if ~strcmp(name,'QId')
                        
                        % grab pulse type
                        pulseType = '';
                        paramNames = {patListParams{i}{2:2:end}};
                        paramIdx = find(strcmp(paramNames, 'pType'));
                        if ~isempty(paramIdx)
                            pulseType = patListParams{i}{1+2*paramIdx};
                        end
                        
                        [xLinkList{i+1} xWaveformTable] = buildEntry(xWaveformTable, xpulse, pulseType);
                        [yLinkList{i+1} yWaveformTable] = buildEntry(yWaveformTable, ypulse, pulseType);
                    else
                        % treat QId as a special case
                        % use a time amplitude pair with the padWaveform
                        % delay must be a minimum of the duration amount set
                        % above
                        [xLinkList{i+1} xWaveformTable] = buildEntry(xWaveformTable, padWaveform, 'square');
                        [yLinkList{i+1} yWaveformTable] = buildEntry(yWaveformTable, padWaveform, 'square');
                        
                        % repeat = width
                        r = length(xpulse);
                        xLinkList{i+1}.repeat = r;
                        yLinkList{i+1}.repeat = r;
                    end
                end

                % sum lengths
                xsum = 0;
                ysum = 0;
                for i = 2:length(xLinkList)
                    xsum = xsum + xLinkList{i}.repeat * xLinkList{i}.length;
                    ysum = ysum + yLinkList{i}.repeat * yLinkList{i}.length;
                end
                
                % pad left but setting repeat count
                xLinkList{1}.repeat = fixedPoint + delay - xsum;
                yLinkList{1}.repeat = fixedPoint + delay - ysum;
                
                xsum = xsum + xLinkList{1}.repeat;
                ysum = ysum + yLinkList{1}.repeat;
                
                % pad right by adding pad waveform with appropriate repeat
                [xLinkList{end+1} xWaveformTable] = buildEntry(xWaveformTable, padWaveform, 'square');
                [yLinkList{end+1} yWaveformTable] = buildEntry(yWaveformTable, padWaveform, 'square');
                
                xLinkList{end}.repeat = obj.cycleLength - xsum;
                yLinkList{end}.repeat = obj.cycleLength - ysum;
                
                xLinkLists{n} = xLinkList;
                yLinkLists{n} = yLinkList;
            end
            
            xpat.waveforms = xWaveformTable;
            xpat.linkLists = xLinkLists;
            ypat.waveforms = yWaveformTable;
            ypat.linkLists = yLinkLists;
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
        
        function [pattern] = linkListToPattern(obj, linkListPattern, n)
            linkList = linkListPattern.linkLists{n};
            wf = linkListPattern.waveforms;
            
            nEntries = length(linkList);
            pattern = [];
            for i = 1:nEntries
                if linkList{i}.isTimeAmplitude
                    amplitude = wf.get(linkList{i}.key)';
                    amplitude = amplitude(1);
                    newPat = amplitude * ones(1,linkList{i}.repeat);
                    pattern = [pattern newPat];
                else
                    for r = 1:linkList{i}.repeat
                        pattern = [pattern wf.get(linkList{i}.key)'];
                    end
                end
            end
        end
    end
end
