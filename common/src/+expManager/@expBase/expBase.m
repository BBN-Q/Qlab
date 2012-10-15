% expBase
% This is the superclass that will be used for creating
% experiment objects.  This object is not meant to be instantiated
% directly.  This superclass will ensure that the experiment inputs and
% outputs are handeled uniformly.  Default parameters will be imported
% from a JSON cfg file, however these values may be changed.  For meta data
% will ultimately be stored in the output file header, not in the CFG
% files.

% Original author: William Kelly (July 2009)
%
% Copyright 2012 Raytheon BBN Technologies
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

classdef  expBase < handle
    properties
        Name
        filenumber
        cfgFileName
        DataFileName
        inputStructure
        DataFileHandler
        DataPath
        Instr = struct() %This field will hold the Instrument objects used in running the experiment
    end
    methods (Abstract)
        status = Init(obj)
        status = Do(obj)
        status = CleanUp(obj)
    end
    methods
		function  obj = expBase(Name, DataPath, cfgFileName, filenumber)
            if nargin < 3
                error('Must specify a Name, DataPath, and cfgFileName when running an experiment');
            end
            obj.Name = Name;
            obj.cfgFileName = cfgFileName;
            
            if ~exist('filenumber', 'var') || ~isnumeric(filenumber)
                obj.filenumber = 1;
            else
                obj.filenumber = filenumber;
            end
            
            obj.createDataFileName();
            obj.DataPath = DataPath;
        end

        function createDataFileName(obj)
			% createDataFileName
			% Constructs default file name for data storage
			% Name template: ddd_name.h5, where ddd = the file #
            obj.DataFileName = sprintf('%03d_%s.h5', obj.filenumber, obj.Name);
        end
        
        function [errorMsg] = openDataFile(obj, dimension, header, nbrDataSets)
			% This function opens an HDF5 data file handler
			% Parameters:
			% dimension (default 1) - dimension of the data set
			% header - structure of data to store in the file header
			% nbrDataSets (default 1) - number of independent data sets to store in the file
            
            errorMsg = '';
            if isempty(obj.DataFileName)
                errorMsg = 'No file name supplied';
                return
            end
            if ~exist('dimension', 'var')
                dimension = 1;
            end
            if ~exist('header', 'var')
                header = [];
            end
			if ~exist('nbrDataSets', 'var')
                nbrDataSets = 1;
            end
            % construct full path
			fullname = fullfile(obj.DataPath, obj.DataFileName);
            % open up the file with write/create permission
            obj.DataFileHandler = HDF5DataHandler(fullname, dimension, header, nbrDataSets);
        end

        function [errorMsg] = finalizeData(obj)
            obj.DataFileHandler.closeDataFile();
            errorMsg = '';
        end
        %% methods related to handling instruments
        function openInstruments(obj)
			% Creates intrument objects for all enabled instruments in InstrParams
			
            % clean up dangling instrument objects
            delete(instrfind);
            
            % remove instruments that have enable = false
			obj.removeDisabledInstr();
            InstrParams = obj.inputStructure.InstrParams;

			% loop through instruments
            InstrNames = fieldnames(InstrParams);
            for Instr_index = 1:numel(InstrNames)
                InstrName = InstrNames{Instr_index};

				disp(['Connecting to ' InstrParams.(InstrName).deviceName]);

				% create instrument object
				obj.Instr.(InstrName) = deviceDrivers.(InstrParams.(InstrName).deviceName);
				% connect
				obj.Instr.(InstrName).connect(InstrParams.(InstrName).Address);
            end
            disp('########### Done connecting to instruments ###########')
        end
        function initializeInstruments(obj)
            % for each device we call its setAll() method with the parameters in InitParams
            InitParams = obj.inputStructure.InstrParams;
            deviceTags = fieldnames(InitParams);
            for device_index = 1:numel(deviceTags) % for each device
                deviceTag = deviceTags{device_index};
                % find the associated parameters
                deviceParams = InitParams.(deviceTag);
                disp(['Initializing ' deviceTag]);
				% remove the deviceName and address fields from the list of
				% parameters since we have already used these in opening the
				% instrument object
                deviceParams = rmfield(deviceParams, {'deviceName' 'Address'});
				% call the instrument meta-setter with the given params
				if ~obj.inputStructure.SoftwareDevelopmentMode
					obj.Instr.(deviceTag).setAll(deviceParams);
				end
            end
            disp('############ Done initializing instruments ###########')
        end

        % Close Instruments
        function closeInstruments(obj)
            % it's assumed that each instrument has a method called
            % disconnect.
            InstrumentNames = fieldnames(obj.Instr);
            for Instr_index = 1:numel(InstrumentNames)
                if obj.inputStructure.SoftwareDevelopmentMode
                    fprintf('Closing %s',InstrumentNames{Instr_index});
                else
                    obj.Instr.(InstrumentNames{Instr_index}).disconnect()
                end
            end
		end
		% remove disabled instruments from inputStructure.InstrParams
		function removeDisabledInstr(obj)
			InstrParams = obj.inputStructure.InstrParams;
			InstrNames = fieldnames(InstrParams);
			for i = 1:length(InstrNames)
				name = InstrNames{i};
				% check for enable field
				if isfield(InstrParams.(name), 'enable') && ~InstrParams.(name).enable
					InstrParams = rmfield(InstrParams, name);
				end
			end
			obj.inputStructure.InstrParams = InstrParams;
		end
        % Class destructor
        function delete(obj)
            %Try to close any instruments left hanging open
            try
                obj.closeInstruments();
            catch %#ok<CTCH>
            end
            %Clean up the output file and rename if we didn't finish it
            %properly

            if isa(obj.DataFileHandler, 'HDF5DataHandler') && obj.DataFileHandler.fileOpen == 1
                obj.DataFileHandler.closeDataFile();
                fullname = fullfile(obj.DataPath, obj.DataFileName);
                [path, name, ~] = fileparts(fullname);
                movefile(fullname, fullfile(path, [name '.incomplete']));
            end
        end
    end
end

