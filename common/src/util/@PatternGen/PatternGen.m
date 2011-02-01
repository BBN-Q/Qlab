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
%
% File: PatternGen.m
%
% Description: class for defining time-domain experiments
% example usage (spin echo experiment):
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

classdef PatternGen < handle
    properties
        dPulseLength = 24;
        dSigma = 6;
        dPiAmp = 4000;
        dPiOn2Amp = 2000;
        dPiOn4Amp = 1000;
        cycleLength = 10000;
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
        function [outx, outy] = squarePulse(amp, n, varargin)
            outx = amp * ones(n, 1);
            outy = zeros(n, 1);
        end
        
        function [outx, outy] = gaussianPulse(amp, n, sigma)
            midpoint = (n+1)/2;
            t = 1:n;
            outx = round(amp * exp(-(t - midpoint).^2./(2 * sigma^2))).';
            outy = zeros(n, 1);
        end
        
        function [outx, outy] = gaussOn(amp, n, sigma)
            t = 1:n;
            outx = round(amp * exp(-(t - n).^2./(2 * sigma^2))).';
            outy = zeros(n, 1);
        end
        
        function [outx, outy] = gaussOff(amp, n, sigma)
            t = 1:n;
            outx = round(amp * exp(-(t-1).^2./(2 * sigma^2))).';
            outy = zeros(n, 1);
        end
        
        function [outx, outy] = tanhPulse(amp, n, sigma)
            if (n < 6*sigma)
                warning('tanhPulse:params', 'Tanh pulse length is shorter than rise+fall time');
            end
            t0 = 3*sigma + 1;
            t1 = n - 3*sigma;
            t = 1:n;
            outx = round(0.5*amp * (tanh((t-t0)./sigma) + tanh(-(t-t1)./sigma))).';
            outy = zeros(n, 1);
        end
        
        % buffer pulse generator
		function out = bufferPulse(pat, zeroLevel, padding, reset, delay)
			self = PatternGen;
			% subtract offset
			pat = pat - zeroLevel;
			
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
                        warning(sprintf('%s Ignored not a parameter of PatternGen', paramName));
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
                [xpulse ypulse] = patList{i}(n);
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
            fluxPulses = {'Zf' 'ZId'};
            
            % set default pulse parameters
            params.amp = 0;
            params.width = self.dPulseLength;
            params.duration = params.width + 5;
            params.sigma = self.dSigma;
            params.angle = 0; % in radians
            if ismember(p, qubitPulses)
                params.pType = 'gaussian';
            elseif ismember(p, measurementPulses)
                params.pType = 'square';
            elseif ismember(p, fluxPulses)
                params.pType = 'square';
            end
            params = parseargs(params, varargin{:});
            
            
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
            if (strcmp(p, 'Xp') || strcmp(p, 'Yp') || strcmp(p, 'Up')), params.amp = self.dPiAmp; end
            if (strcmp(p, 'Xm') || strcmp(p, 'Ym') || strcmp(p, 'Um')), params.amp = -self.dPiAmp; end
            
            % pi/2 pulses
            if (strcmp(p, 'X90p') || strcmp(p, 'Y90p') || strcmp(p, 'U90p')), params.amp = self.dPiOn2Amp; end
            if (strcmp(p, 'X90m') || strcmp(p, 'Y90m') || strcmp(p, 'U90m')), params.amp = -self.dPiOn2Amp; end
            
            % pi/4 pulses
            if (strcmp(p, 'X45p') || strcmp(p, 'Y45p') || strcmp(p, 'U45p')), params.amp = self.dPiOn4Amp; end
            if (strcmp(p, 'X45m') || strcmp(p, 'Y45m') || strcmp(p, 'U45m')), params.amp = -self.dPiOn4Amp; end
            
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
                    if isscalar(x)
                        out = x;
                    else
                        out = x(n);
                    end
                end
                
                amp = getelement(params.amp);
                width = getelement(params.width);
                sigma = getelement(params.sigma);
                angle = getelement(params.angle);
                duration = getelement(params.duration);
                
                [xpulse, ypulse] = pf(amp, width, sigma);
                
                xypairs = [xpulse ypulse].';
                R = [cos(angle) -sin(angle); sin(angle) cos(angle)];
                xypairs = R * xypairs;
                xpulse = xypairs(1,:).';
                ypulse = xypairs(2,:).';
                
                if (duration > width)
                    padleft = floor((params.duration - width)/2);
                    padright = ceil((params.duration - width)/2);
                    xpulse = [zeros(padleft,1); xpulse; zeros(padright,1)];
                    ypulse = [zeros(padleft,1); ypulse; zeros(padright,1)];
                end
            end
        end
        
        function [xpat, ypat] = build(obj,patListParams,numsteps, delay, fixedPoint)
            
            duration = obj.dPulseLength + 5;
            
            % build pulse function list
            for i = 1:length(patListParams)
                name = patListParams{i}{1};
                if strcmp(name,'QId')
                    continue
                end
                if length(patListParams{i}) > 1
                    patList{i} = obj.pulse(name, patListParams{i}{2:end});
                else
                    patList{i} = obj.pulse(name);
                end
            end

            numPatterns = size(patList,2);
            len = 0;
            
            xLinkLists = {};
            yLinkLists = {};
            
            xWaveformTable = java.util.Hashtable;
            yWaveformTable = java.util.Hashtable;
            
            padWaveform = [0];
            padWaveformKey = java.util.Arrays.deepHashCode(padWaveform);
            
            function [entry, table] = buildEntry(table, pulse)
                key = java.util.Arrays.deepHashCode(pulse);
                if ~table.containsKey(key)
                    table.put(key, pulse);
                end;
                entry.key = key;
                entry.length = length(pulse);
                entry.repeat = 1;
                entry.isTimeAmplitude = 0;
            end
            
            for n = 1:numsteps
                xLinkList = {};
                yLinkList = {};
                [xLinkList{1} xWaveformTable] = buildEntry(xWaveformTable, padWaveform);
                [yLinkList{1} yWaveformTable] = buildEntry(yWaveformTable, padWaveform);
                
                for i = 1:numPatterns
                    name = patListParams{i}{1};
                    % Hash Waveform unless it is an Identity pulse which
                    % is treated as a speacial case of time amplitude pair
                    
                    if ~strcmp(name,'QId')
                        [xpulse ypulse] = patList{i}(n);
                        [xLinkList{i+1} xWaveformTable] = buildEntry(xWaveformTable, xpulse);
                        [yLinkList{i+1} yWaveformTable] = buildEntry(yWaveformTable, ypulse);
                    else
                        % treak QId as a seperate case
                        % use a time amplitude pair with the padWaveform
                        % delay must be a minimum of the duration amount set
                        % above
                        [xLinkList{i+1} xWaveformTable] = buildEntry(xWaveformTable, padWaveform);
                        [yLinkList{i+1} yWaveformTable] = buildEntry(yWaveformTable, padWaveform);
                        
                        % find width
                        for j = 2:2:length(patListParams)
                            if strcmp(patListParams{i}{j},'width')
                                r = patListParams{i}{j+1}(n);
                                if r < duration
                                    r = duration;
                                end
                                
                                xLinkList{i+1}.repeat = r;
                                yLinkList{i+1}.repeat = r;
                                break;
                            end
                        end
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
                [xLinkList{end+1} xWaveformTable] = buildEntry(xWaveformTable, padWaveform);
                [yLinkList{end+1} yWaveformTable] = buildEntry(yWaveformTable, padWaveform);
                
                xLinkList{end}.repeat = obj.cycleLength - xsum;
                yLinkList{end}.repeat = obj.cycleLength - ysum;
                
                % set padding to time amplitude mode
                xLinkList{1}.isTimeAmplitude = 1;
                yLinkList{1}.isTimeAmplitude = 1;
                xLinkList{end}.isTimeAmplitude = 1;
                yLinkList{end}.isTimeAmplitude = 1;
                
                xLinkLists{n} = xLinkList;
                yLinkLists{n} = yLinkList;
            end
            
            xpat.waveforms = xWaveformTable;
            xpat.linkLists = xLinkLists;
            ypat.waveforms = yWaveformTable;
            ypat.linkLists = yLinkLists;
            
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
