%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Module Name :  expBase.m
 %
 % Author/Date : William Kelly / 09-Jul-09
 %
 % Description : This is the superclass that will be used for creating
 % experiment objects.  This object is not meant to be instantiated
 % directly.  This superclass will ensure that the experiment inputs and
 % outputs are handeled uniformly.  Default parameters will be imported
 % from a CFG file, however these values may be changed.  For meta data
 % will ultimately be stored in the output file header, not in the CFG
 % files.
 %
 % Restrictions/Limitations : UNRESTRICTED
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
 %    10/6/10     BRJ   Cleanup
 %
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
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef  expBase < handle
    properties
        Name
        filenumber
        cfgFileName
        DataFileName
        inputStructure
        DataFileHandler
        %HomeDirectory
        DataPath
        Instr = struct()%This field will hold the Instrument objects used in running the experiment
        DataStruct
    end
    methods (Abstract)
        status = Init(obj)
        status = Do(obj)
        status = CleanUp(obj)
    end
    methods
        %%
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
            
            createDataFileName(obj)
            obj.DataPath = DataPath;
        end
        %%
        function createDataFileName(obj)
            obj.DataFileName = sprintf('%03d_%s.h5', obj.filenumber, obj.Name);
        end
        
        %%
        function [errorMsg] = openDataFile(obj, dimension, header)
            % This function opens an HDF5 data file handler
            
            % First we make sure the filename exists
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
            % construct full path
			fullname = fullfile(obj.DataPath, obj.DataFileName);
            % open up the file with write/create permission
            obj.DataFileHandler = HDF5DataHandler(fullname, dimension, header);
        end
        %%
        function [errorMsg] = finalizeData(obj)
            obj.DataFileHandler.closeDataFile();
            errorMsg = '';
        end
        %% methods related to handling instruments
        function openInstruments(obj)
            % clean up all instrument objects
            openInstruments = instrfind;
            if ~isempty(openInstruments)
                fclose(openInstruments);
            end
            delete(openInstruments);
            
            % removed instruments that have enable = false
			obj.removeDisabledInstr();
            InstrParams = obj.inputStructure.InstrParams;
            
            % obtain a list of all the types of instruments we need to 
            % connect to.
            InstrNames = fieldnames(InstrParams);
            % the gpib substructure does not correspond to an actual instrument
            % as more insturment types are added it may become necessary to
            % add more of these lines, or to group all of the "helper"
            % parameters together.
            InstrNames = InstrNames(~strcmpi('gpib',fieldnames(InstrParams)));
            numInstr = numel(InstrNames);
            for Instr_index = 1:numInstr % for each instrument
                InstrName_i = InstrNames{Instr_index};%convert from cell to string
                % now we for each InstrName (e.g. "AWG") we connect to each
                % individual device
				disp(['Connecting to ' InstrParams.(InstrName_i).deviceName]);
				% this is the command to instantiate the object
				instantiateString = ['deviceDrivers.' InstrParams.(InstrName_i).deviceName];

				% address is a string or number that is taken as an
				% input by the method 'connect'
				address = InstrParams.(InstrName_i).Address;
				if isnumeric(address)
					addressString = num2str(address);
				else
					addressString = ['''' address ''''];
				end
				connectString = ['obj.Instr.' InstrName_i '.connect' '(' addressString ')' ';'];
				% if we are in SD mode we don't actually connect
				if obj.inputStructure.SoftwareDevelopmentMode
					disp(instantiateString);
					disp(connectString);
				else
					obj.Instr.(InstrName_i) = eval(instantiateString);
					eval(connectString);
				end
            end
            disp('########### Done connecting to instruments ###########')
        end
        function initializeInstruments(obj)
            % for each device we are going to call methods and set
            % properties using the values stored in InitParams
            InitParams = obj.inputStructure.InstrParams;
            deviceTags = fieldnames(InitParams);
            numDevices = numel(deviceTags);
            for device_index = 1:numDevices % for each device
                % find the device tag
                deviceTag_i = deviceTags{device_index};
                % find the associated parameters
                init_params_i = InitParams.(deviceTag_i);
                disp(['Initializing ' deviceTag_i]);
				% remove the deviceName and address fields from the list of
				% parameters since we have already used these in opening the
				% instrument object
                init_params_i = rmfield(init_params_i, {'deviceName' 'Address'});
				% call the instrument meta-setter with the given params
				if ~obj.inputStructure.SoftwareDevelopmentMode
					%feval(['obj.Instr.' deviceTag_i '.setAll'], init_params_i);
					init_str = ['obj.Instr.' deviceTag_i '.setAll(init_params_i)'];
					eval(init_str);
				end
            end
            disp('############ Done initializing instruments ###########')
        end

        %% Close Instruments
        function closeInstruments(obj)
            % it's assumed that each instrument has a method called
            % disconnect.
            SD_mode = obj.inputStructure.SoftwareDevelopmentMode;
            InstrumentNames = fieldnames(obj.Instr);
            for Instr_index = 1:numel(InstrumentNames)
                if SD_mode
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
        %Class destructor
        function delete(obj)
            %Try to close any instruments left hanging open
            try
                obj.closeInstruments();
            catch %#ok<CTCH>
            end
            %Clean up the output file and rename if we didn't finish it
            %properly
            if obj.DataFileHandler.fileOpen == 1
                obj.DataFileHandler.closeDataFile();
                fullname = fullfile(obj.DataPath, obj.DataFileName);
                [path, name, ~] = fileparts(fullname);
                movefile(fullname, fullfile(path, [name '.incomplete']));
            end
        end
    end
end

