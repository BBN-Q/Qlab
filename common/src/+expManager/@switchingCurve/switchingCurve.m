%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Module Name :  switchingCurve.m
%
% Author/Date : William Kelly / 27-Jul-09
%
% Description : This is the class used for taking a switching curve or
% time of flight measurment on a single junction or SQUID
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
%
% RCS header info.
% ----------------
% $RCSfile$
% $Author$
% $Date$
% $Locker$
% $Name$
% $Revision$
%
% $Log: $
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef switchingCurve < expManager.expBase
    properties %This is only for properties not defined in the 'experiment' superlcass
    end
    methods (Static)
        %% Class constructor
        function obj = switchingCurve(data_path,cfgFileName)
            if ~exist('cfg_file_number','var')
                cfg_file_number = 2; % default value
            end
            if ~exist('base_path','var')
                base_path = 'C:\Documents and Settings\Administrator\My Documents\DR_Exp\SVN\qlab\'; % default value
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % A little more thought needs to go into the handling of these
            % variables.  Should the be hardcoded?  Should they be inputs?
            % Should they be stored in a cfg file?
%             [t1, r1] = strtok(cfgFileName, '.'); %strip period
%             
%             if(size(strfind(t1, '_'), 2) ~= 2)
%                 error('config file name does not conform, expName_v1_number.cfg');
%             end
%             
%             [ScriptName, r1] = strtok(t1, '_');
%             [VersionName, r1] = strtok(r1, '_');
%             [cfg_file_number, r1] = strtok(r1, '_');
%             HomeDirectory = ScriptName; %In general SriptName should match HomeDirectory
%             Name = [ScriptName '_' VersionName];
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % finally we inheret methods and properties from the experiment class
			obj = obj@expManager.expBase('switchingCurve',data_path,cfgFileName);
            % Add the appropriate directories to the path
            % for now this will be done manually
            %addpath([obj.BasePath,'ExpTree/switchingCurve/cfg'],'-END');
            %addpath([obj.BasePath,'ExpTree/switchingCurve/data'],'-END');
            %addpath([obj.BasePath,'ExpTree/switchingCurve/src/matlab'],'-END');
        end
    end
    methods
        %% Base functions
        function errorMsg = Init(obj)
            errorMsg = '';
            InstrParams = obj.inputStructure.InstrParams;
            TaskParams   = obj.inputStructure.TaskParams;
            InitParams  = obj.inputStructure.InitParams;
            %Open all instruments, this routine only uses InstrParams
            errorMsg = obj.openInstruments(errorMsg);
            %%% The next two functions are experiment specific %%%
            %Check ExpParams for errors
            errorMsg = obj.errorCheckExpParams(TaskParams,InitParams,errorMsg);
            %Prepare all instruments for measurement, this routine uses only ExpParams
            errorMsg = obj.initializeInstruments(errorMsg);
        end
        function errorMsg = Do(obj)
            fprintf(obj.DataFileHandle,'$$$ Beginning of Data\n');
            switch obj.Name
                case 'switchingCurve_v1'
                    errorMsg = obj.switchingCurveDo;
                otherwise
                    error('unknown expType')
            end
        end
        function errorMsg = CleanUp(obj)
            errorMsg = '';
            Instr = obj.Instr;
            
            %Close all instruments
            errorMsg = obj.closeInstruments;
        end
        %% Class destructor
        function delete(obj)
            % This function gets called whenever the object gets cleared
            % from the workspace
            try
                obj.closeInstruments
            catch
            end
        end
        %% error checking method
        function errorMsg = errorCheckExpParams(obj,ExpParams,InitParams,errorMsg)
            % Error checking goes here or in switchingCurve.init.
            %if obj.inputStructure.SoftwareDevelopmentMode
            %    obj.inputStructure.errorChecked = true;
            %end
        end
    end
end
