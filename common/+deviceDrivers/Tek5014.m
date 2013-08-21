% AWG5014 is an instrument wrapper class for the Tektronix Arbitrary Waveform Generator 5014.
% Like the other instrument classes, it provides an interface for interacting with device
% while abstracting away the GPIB instruction set.

%   Original author: Bhaskar Mookerji
%   Date: July 2009
%   Revised by Blake Johnson, 3/29/2011

% Copyright 2010-13 Raytheon BBN Technologies
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

classdef Tek5014 < deviceDrivers.lib.GPIBorEthernet
    
    properties (Access = public)
        samplingRate = 1e9
        triggerSource % 'internal' or 'external'
        triggerInterval % trigger rate for internal trigger
        runMode
        running
    end
    
    methods
        function obj = Tek5014()
            obj.DEFAULT_PORT = 4000;
        end
        
        % instrument meta-setter
        function setAll(obj, settings)
            % load AWG file before doing anything else
            if isfield(settings, 'seqFile')
                if ~isfield(settings, 'seqForce')
                    settings.seqForce = false;
                end
                
                % load an AWG file if the settings file is changed or if force == true
                if (~strcmp(obj.getSetupFileName(), settings.seqFile) || settings.seqForce)
                    obj.openConfig(settings.seqFile);
                    obj.operationComplete(); % wait until we're done with the load to continue
                end
            end
            settings = rmfield(settings, 'seqFile');
            settings = rmfield(settings, 'seqForce');
            
            % set channel settings
            channelStrs = {'chan_1','chan_2','chan_3','chan_4'};
            for ct = 1:4
                ch = channelStrs{ct};
                obj.setAmplitude(ct, settings.(ch).amplitude);
                obj.setOffset(ct, settings.(ch).offset);
                obj.setEnabled(ct, settings.(ch).enabled);
            end
            settings = rmfield(settings, channelStrs);
            
            % parse remaining settings
            fields = fieldnames(settings);
            for j = 1:length(fields);
                name = fields{j};
                if ismember(name, methods(obj))
                    feval(['obj.' name], settings.(name));
                elseif ismember(name, properties(obj))
                    if ~isempty(settings.(name))
                        obj.(name) = settings.(name);
                    end
                end
            end
        end
        
        %% Memory and directory structure methods
        function val = getSetupFileName(obj)
            %GETSETUPFILENAME returns the current setup file for the AWG.
            
            gpib_string = 'AWGControl:SNAMe?';
            val = obj.query(gpib_string);
            
            % output is of the form: "name","basepath"
            expr = '"(.*)","(.*)"';
            matches = regexp(val, expr, 'tokens');
            if ~isempty(matches)
                matches = fliplr(matches{1}); %put the path in front
                val = [matches{:}]; %then concatenate
            end
        end
        
        function loadConfig(obj, name)
            %loadConfig(NAME) opens an AWG configuration from a specified
            % settings file on the AWG's main hard drive (usually 'C:\'). If a
            % path is not specified, the local (or default) path is assumed.
            %
            %	Argument(s):
            %		name	A MATLAB string specifying the path to a file.
            %
            %	Example:
            %		% myAWG is a pre-existing AWG object connected to the instrument
            %		myAWG.openConfig('\my\project\awg\foo.awg');
            %
            %		myAWG.openConfig('foo.awg');
            %
            if ~isa(name, 'char')
                error('Invalid file name');
            end
            if ~exist(name, 'file')
                error('Could not find %s', name);
            end
            name = ['"' name '"'];
            gpib_string = ['AWGControl:SREStore ' name];
            obj.write(gpib_string);
        end
        
        function run(obj)
            %RUN enables active output from the AWG.
            obj.write('AWGControl:RUN');
            obj.running = 1;
            %Wait for it to actually start
            obj.operationComplete()
        end
        
        function stop(obj)
            %STOP ends the output of a waveform or sequence
            obj.write('AWGControl:STOP');
            %Wait for it to actually stop.
            obj.operationComplete();
        end
        
        function operationComplete(obj)
            val = 0;
            max_count = 3;
            count = 1;
            while ~(val == 1 || count > max_count)
                val = str2double(obj.query('*OPC?'));
                count = count + 1;
            end
        end
        
        % Waveform methods
        function loadWaveform(obj, ch, waveform, marker1, marker2)
            % loadWaveform(ch, waveform, marker1, marker2)
            %   ch = channel (1-4)
            %   waveform = vector of int16s or doubles
            %   marker1 = vector of 0's and 1's
            %   marker2 = vector of 0's and 1's
            
            if nargin < 5 % markers not provided, zero them
                marker1 = zeros(length(waveform), 1, 'uint8');
                marker2 = marker1;
            end
            
            wfName = ['ch' num2str(ch)];
            switch (class(waveform))
                case 'int16'
                    obj.sendWaveformInt(wfName, waveform, marker1, marker2)
                case 'double'
                    obj.sendWaveformReal(wfName, waveform, marker1, marker2)
                otherwise
                    error('waveform data must be int16 or double')
            end
            obj.write(['SOURce' num2str(ch) ':WAVeform "' wfName '"']);
        end
        
        function sendWaveformInt(obj, name, waveform, marker1, marker2)
            if nargin < 5 % markers not provided, zero them
                marker1 = zeros(length(waveform), 1, 'uint8');
                marker2 = marker1;
            end
            
            data = TekPattern.packPattern(waveform, marker1, marker2);
            
            % pack waveform by separating waveform values into (low-8, high-8)
            % sequential values, aka LSB format
            bindata = zeros(2*length(data),1);
            bindata(1:2:end) = bitand(data,255);
            bindata(2:2:end) = bitshift(data,-8);
            bindata = bindata';
            
            % write
            obj.deleteWaveform(name);
            obj.createWaveform(name, length(waveform), 'integer');
            obj.binblockwrite(bindata, [':wlist:waveform:data "' name '",']);
        end
        
        function sendWaveformReal(obj, name, waveform, marker1, marker2)
            % SENDWAVEFORMREAL sends a floating point (i.e., real) waveform buffer to the AWG.
            % It currently sends a row buffer but should work with column buffers.
            %
            %   Arguments:
            %       name        A name string
            %       waveform      Row vector floats
            %
            %   Example:
            %       myAWG.sendWaveformReal('test_wfm', sin([0:pi/100:2*pi]));
            waveform = single(waveform); % need sinle-precision (32-bit) data
            
            if nargin < 5 % markers not provided, zero them
                marker1 = zeros(length(waveform), 1, 'uint8');
                marker2 = marker1;
            end
            
            % encode marker 1 bits to bit 6
            marker1 = bitshift(uint8(logical(marker1)),6);
            
            % encode marker 2 bits to bit 7
            marker2 = bitshift(uint8(logical(marker2)),7);
            
            % merge markers
            m = marker1 + marker2;
            
            % stitch waveform data with marker data as per progammer manual
            binblock = zeros(1,length(waveform)*5,'uint8'); % real uses 5 bytes per sample
            for k=1:length(waveform)
                binblock((k-1)*5+1:(k-1)*5+5) = [uint8(waveform(k)) m(k)];
            end
            
            obj.deleteWaveform(name);
            obj.createWaveform(name, 'real', length(waveform));
            obj.binblockwrite(binblock, [':wlist:waveform:data "' name '",']);
        end
        
        function createWaveform(obj, name, size, type)
            gpib_string = [':WLISt:WAVeform:NEW "', name , '",', num2str(size), ', ',type];
            obj.write(gpib_string);
        end
        
        function deleteWaveform(obj, name)
            obj.write([':wlist:waveform:del "' name '";']);
        end
        
        function val = getWaveform(obj, name)
            gpib_string = ['WLIST:WAVeform:DATA? "', name, '"'];
            obj.write(gpib_string);
            val = obj.binblockread('uint16');
        end
        
        function val = getWaveformReal(obj, name, startIndex, blockSize)
            gpib_string = ['WLIST:WAVeform:DATA? ', name, ',', ...
                num2str(startIndex),',', num2str(blockSize)];
            obj.write(gpib_string);
            val = obj.binblockread('single');
        end
        
        function sendMarkerData(obj, name, marker1, marker2)
            if not(isa(name, 'char')) || ...
                    (length(marker1) ~= length(marker2))
                error('');
            end
            
            % encode marker 1 bits to bit 6
            marker1 = bitshift(uint8(logical(marker1)),6); %check dec2bin(marker1(2),8)
            
            % encode marker 2 bits to bit 7
            marker2 = bitshift(uint8(logical(marker2)),7); %check dec2bin(marker2(2),8)
            
            % merge markers
            m = marker1 + marker2; %check dec2bin(m(2),8)
            
            obj.binblockwrite(m, [':wlist:waveform:marker:data "' name '",']);
        end
        
        function [success] = waitForAWGtoStartRunning(obj,maxTime,maxTrys)
            if ~exist('maxTime','var')
                maxTime = 15; %seconds
            end
            
            if ~exist('maxTrys','var')
                maxTrys = 3; %seconds
            end
            
            numTrys = 0;
            while 1
                numTrys = numTrys+1;
                t_start = clock;
                while 1
                    fprintf('waiting for AWG\n')
                    OperationState = obj.running;
                    if  OperationState > 0
                        success = 1;
                        break
                    elseif etime(clock,t_start) > maxTime
                        success = 0;
                        break
                    end
                    pause(0.1)
                end
                if success == 1
                    break
                elseif numTrys > maxTrys
                    success = 0;
                    break
                end
            end
        end
        
        % channel methods
        function setAmplitude(obj, ch, amp)
            obj.write(['SOURce' num2str(ch) ':VOLTage:AMPLitude ' num2str(amp)]);
        end
        
        function out = getAmplitude(obj, ch)
            out = str2double(obj.query(['SOURce' num2str(ch) ':VOLTage:AMPLitude?']));
        end
        
        function setOffset(obj, ch, offset)
            obj.write(['SOURce' num2str(ch) ':VOLTage:OFFSet ' num2str(offset)]);
        end
        
        function out = getOffset(obj, ch)
            out = str2double(obj.query(['SOURce' num2str(ch) ':VOLTage:OFFSet?']));
        end
        
        function setEnabled(obj, ch, enabled)
            if isnumeric(enabled)
                enabled = num2str(enabled);
            end
            propMap = containers.Map({'on', '1', 'off', '0'},{'ON','ON','OFF','OFF'});
            obj.write(['OUTPut' num2str(ch) ':STATe ' propMap(lower(enabled))]);
        end
        
        function out = getEnabled(obj, ch)
            out = str2double(obj.query(['OUTPut' num2str(ch) ':STATe?']));
        end
        
        function setSkew(obj, ch, skew)
            obj.write(['SOURce' num2str(ch) ':SKEW ' num2str(skew)]);
        end
        
        function out = getSkew(obj, ch)
            out = str2double(obj.query(['SOURce' num2str(ch) ':SKEW?']));
        end
        
        function setMarkerHigh(obj, ch, marker, high)
            obj.write(['SOURce' num2str(ch) ':MARKer' num2str(marker) ':VOLTage:HIGH ', num2str(high)]);
        end
        
        function out = getMarkerHigh(obj, ch, marker)
            out = str2double(obj.query(['SOURce' num2str(ch) ':MARKer' num2str(marker) ':VOLTage:HIGH?']));
        end
        
        function setMarkerLow(obj, ch, marker, low)
            obj.write(['SOURce' num2str(ch) ':MARKer' num2str(marker) ':VOLTage:LOW ', num2str(low)]);
        end
        
        function out = getMarkerLow(obj, ch, marker)
            out = str2double(obj.query(['SOURce' num2str(ch) ':MARKer' num2str(marker) ':VOLTage:LOW?']));
        end
        
        % property get accessors
        
        function val = get.triggerInterval(obj)
            val = 1./str2double(obj.query('TRIGger:TIMer?'));
        end
        
        function val = get.triggerSource(obj)
            val = obj.query('TRIGger:SOURce?');
        end
        
        function val = get.runMode(obj)
            val = obj.query('AWGControl:RMODe?');
        end
        
        function val = get.running(obj)
            val = obj.query('AWGControl:RSTate?');
        end
        
        function val = get.samplingRate(obj)
            temp = obj.query('SOURce1:FREQuency?');
            val = str2double(temp);
        end
        
        % property set accessors
        
        function obj = set.triggerInterval(obj, interval)
            if ~isnumeric(interval)
                error('Invalid trigger interval %f', interval);
            end
            obj.write(['TRIGger:TIMer ' num2str(1./interval)]);
            obj.triggerInterval = interval;
        end
        
        function obj = set.triggerSource(obj, source)
            checkMap = containers.Map({...
                'internal','external',...
                'int', 'ext'
                },{'INTernal','EXTernal','INTernal','EXTernal'});
            
            obj.write(['TRIGger:SOURce ' checkMap(lower(source))]);
            obj.triggerSource = source;
        end
        
        function obj = set.runMode(obj, mode)
            checkMap = containers.Map({...
                'TRIG','TRIGGERED',...
                'SEQ','SEQUENCE',...
                'GAT','GATED',...
                'CONT','CONTINUOUS'},...
                {'TRIG','TRIG',...
                'SEQ','SEQ',...
                'GAT','GAT',...
                'CONT','CONT'});
            
            obj.write(['AWGControl:RMODe ' checkMap(upper(mode))]);
            obj.runMode = mode;
        end
        
        function obj = set.samplingRate(obj, value)
            optionString = 'SamplingRate';
            
            if (~isnumeric(value) || value < 10^7 || value > 10^10)
                error(['AWG Property: ', 'Invalid ', optionString, ' value: ', num2str(value)]);
            else
                gpib_string = ['SOURce1:FREQuency ', num2str(value)];
                obj.write(gpib_string);
                obj.samplingRate = value;
            end
        end
        
        % sequence methods
        function setSeqLength(obj, value)
            optionString = 'Length';
            if (~isnumeric(value) || value < 0 || value > 16000)
                error(['AWG Property: ', 'Invalid ', optionString, ' value: ', num2str(value)]);
            end
            obj.write(['SEQuence:LENGth ', num2str(value)]);
        end
        
        function setSeqloopCount(obj, value)
            optionString = 'LoopCount';
            
            if (~isnumeric(value) || value > 65536 || value < 1)
                error(['AWG Property: ', 'Invalid ', optionString, ' value: ', num2str(value)]);
            end
            gpib_string = ['SEQuence:ELEMent:LOOP:COUNt ', num2str(value)];
            obj.write(gpib_string);
        end
        
        function setSeqWaveformName(obj, n, name)
            gpib_string = ['SEQuence:ELEMent1:WAVeform', ...
                num2str(n),' "', name, '"'];
            obj.write(gpib_string);
        end
    end
end

