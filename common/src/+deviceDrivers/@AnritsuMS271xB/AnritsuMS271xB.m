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
% Author: Colm Ryan (cryan@bbn.com)
%
% Description: Instrument driver for the Antritsu spectrum analyzer (copy of HP71000).

classdef AnritsuMS271xB < handle
   properties
       center_frequency
       span
       resolution_bw
       video_bw
       sweep_mode
       video_averaging
       number_averages
       sweep_points
       socket
   end
   
   methods
       %Constructor
       function obj = AnritsuMS271xB()
       end
   
       function connect(obj, address)
           obj.socket = visa('ni', ['TCPIP::', address, '::INSTR']);
           fopen(obj.socket);
       end
       
       function disconnect(obj)
           fclose(obj.socket);
       end
       
       function delete(obj)
           delete(obj.socket)
       end
       
       function Write(obj, writeStr)
           fprintf(obj.socket, writeStr);
       end
       
       function val = Query(obj, queryStr)
           fprintf(obj.socket, queryStr);
           val = fscanf(obj.socket);
       end
       
       function sweep(obj)
           %Take a single sweep
           obj.Write(':INIT:CONT OFF');
           obj.Write(':INIT:IMM');
       end
       
       function reset(obj)
           %Reset instrument to default state
           obj.Write('*RST;');
       end
       
       function val = peakAmplitude(obj)
           %Return the peak amplitude (default to marker 1 for now)
           obj.Write(':CALC:MARK1:MAX'); % move marker to peak
           val = str2double(obj.Query(':CALC:MARK1:Y?')); % get marker amplitude
       end
       
       function val = peakFrequency(obj)
           %Return the peak frequency (default to marker 1 for now)
           obj.Write(':CALC:MARK1:MAX'); % move marker to peak
           val = str2double(obj.Query(':CALC:MARK1:X?')); % get marker amplitude
       end
       
       function [xdata, ydata] = downloadTrace(obj)
           %Download the full trace (default to trace 1 for now)
           obj.Write(':FORM:DATA REAL,32');
           ydata = binblockread(obj.Query('TRAC:DATA? 1'), 'float32');
		   
		   center_freq = obj.center_frequency;
		   curSpan = obj.span;
		   xdata = linspace(center_freq - curSpan/2, center_freq + curSpan/2, length(ydata));
       end
       
       % instrument meta-setter
		function setAll(obj, settings)
			fields = fieldnames(settings);
			for j = 1:length(fields);
				name = fields{j};
				if ismember(name, methods(obj))
					feval(['obj.' name], settings.(name));
				elseif ismember(name, properties(obj))
					obj.(name) = settings.(name);
				end
			end
        end
        
        % property accessors
        
        function val = get.center_frequency(obj)
            val = str2double(obj.Query(':FREQ:CENT?'));
        end
        
        function val = get.span(obj)
            val = str2double(obj.Query(':FREQ:SPAN?'));
        end
        
        function val = get.resolution_bw(obj)
            val = str2double(obj.Query(':BAND:BWID:RES?'));
        end
        
        function val = get.video_bw(obj)
            val = str2double(obj.Query(':BAND:BWID:VID?'));
        end
        
        function val = get.sweep_mode(obj)
            val = '';
        end
        
        function val = get.video_averaging(obj)
            val = obj.Query(':AVERAGE:TYPE?');
        end
        
        function val = get.number_averages(obj)
            val = str2double(obj.Query(':AVERAGE:COUNT?'));
        end
        
        function val = get.sweep_points(obj)
            error('Unimplemented')
        end
        
        % property settors
        
        function set.center_frequency(obj, value)
            % Validate input
            assert(isnumeric(value), 'Invalid input');
            obj.Write(sprintf(':FREQ:CENT %E',value));
        end
        
        function set.span(obj, value)
            % Validate input
            assert(isnumeric(value), 'Invalid input');
            obj.Write(sprintf(':FREQ:SPAN %E',value));
        end
        
        function set.resolution_bw(obj, value)
            if strcmp(value,'auto')
                obj.Write(':BAND:BWID:RES:AUTO ON');
            else
                assert(value > 10 && value < 3e6);
                obj.Write(sprintf(':BAND:BWID:RES %E',value));
            end
        end
        
        function set.video_bw(obj, value)
            if strcmp(value,'auto')
                obj.Write(':BAND:BWID:VID:AUTO ON');
            else
                assert(value > 1 && valu < 3e6);
                obj.Write(sprintf(':BAND:BWID:VID %E',value));
            end
        end
        
        function set.sweep_mode(obj, value)
            % Validate input
            checkMapObj = containers.Map({'single','continuous','cont'},...
                {'OFF','ON','ON'});
            if not (checkMapObj.isKey( lower(value) ))
                error('Invalid input');
            end
            
            obj.Write(sprintf(':INIT:CONT %s',checkMapObj(value)));
        end
        
        function set.video_averaging(obj, value)
            %Stub function for now
        end
        
        function set.number_averages(obj, value)
            % Validate input
            assert(value > 2 && value < 65535, 'Invalid input');
            obj.Write(sprintf(':AVERAGE:COUNT %E',int(value)));
        end
        
        function set.sweep_points(obj, value)
            %Stub function for now
        end
   end
end