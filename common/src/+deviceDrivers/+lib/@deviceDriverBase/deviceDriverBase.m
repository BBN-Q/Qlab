 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Module Name :  deviceDriverBase.m
 %
 % Author/Date : C.B. Lirakis / 06-Jul-09
 %
 % Description : Base object that all others inherit from. 
 % All items that are common to all subclasses should reside here
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
 %                CBL
 %
 % $Revision$
 %
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %
 % Using a handle class does not create copies when passed 
 % between modules. 
 %
 classdef deviceDriverBase < handle
    properties (Constant = true)
         NoError  = {0, 'No Error'};
         NoFile   = {-1,'File error.'};
         OpenFail = {-2, 'File open failed.'};
         BadKey   = {-3, 'Poorly formed key.'};
         OutOfBounds = {-10, 'Value out of bounds.'};
         BadRead  = {-11, 'Bad read (Insufficent characters or prefix.'};
         LogError = {-12, 'Error logging data to file.'};
         Empty    = {-13, 'String empty.'};
         NoData   = {-14, 'No data available.'};
    end
    properties
        % These represent private variables that for the most part should
        % remain untouched. 
        Name;    % human readable name for object
        UniqueID;
        % To do put a static object counter here.
        % To do, access control on object, r,w, streamer etc.
        
        % Populate Last error with an error code based on the last 
        % operation done. 
        LastError;
        % To do: need enumeration of errors. 
        
        %
        % Use this to direct errors to the command line or screen 
        % These want to be the equivalent of static in a C++ class
        %
        UseErrorDialog;
        %
        % Debuging level
        %
        DebugLevel;
        %
        % Class of object, for devices.
        % Eg: Bias, AWG, Counter ...
        %
        DeviceClass;
        %
        % Number Channels on device
        %
        NumberChannels;
        %
        % Channel label, what is the channel connected to?
        % Includes number
        %
        ChannelLabel;
        %
        % Comments for this device.
        %
        Comment;
    end
    methods
        % Constructor
        function obj = deviceDriverBase(val)
            if nargin == 0
                obj.Name = '';
            else
                obj.Name = val;
            end
            % Placeholder use seconds since midnight as unique id
            obj.UniqueID          = now; 
            obj.LastError         = obj.NoError; % represents a no error condition. 
            obj.UseErrorDialog    = false;
            obj.DebugLevel        = 0; % No debugging output
            obj.DeviceClass       = 'none';
            obj.NumberChannels    = 0;
            obj.ChannelLabel{1}.Number = 1;
            obj.ChannelLabel{1}.Label  = 'none';
        end 
        %
        % No destructor is necessary here.
        %
        
        %
        % Function to access and set name. 
        % Note that this controls the accidental setting of varibles
        %
        function obj = set.Name(obj,name)
            obj.Name = name;
        end
        function name = get.Name(obj)
            name = obj.Name;
        end
        function error = get.LastError(obj)
            error = obj.LastError;
        end
        function set.UseErrorDialog(obj, value)
            obj.UseErrorDialog = value;
        end
        function set.DebugLevel(obj, level)
            if(level>-1)
                obj.DebugLevel = level;
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : Configure
        %
        % Description : Configure the base object parameters.
        %
        % Inputs : none
        %
        % Returns : none
        %
        % Error Conditions : 
        %      0 SUCCESS!
        %
        % Unit Tested on: 
        %
        % Unit Tested by: CBL
        %
        % $Revision$
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function Configure(obj)
            input = cellstr(datestr(now));
            obj.Comment = inputdlg('Enter a comment:', 'Comment',10, ...
                input);
        end
        %
        % All classes should have a dump associated with them
        % It will help during development and debug.
        % All variables should be output in a user readable fashion
        %
        function Dump(obj)
            fprintf('Name: %s -----\nID: %d LastError: %s, ', ...
                obj.Name, obj.UniqueID, obj.LastError{2});
            if obj.UseErrorDialog
                fprintf('Error Dialog: Yes');
            else
                fprintf('Error Dialog: No');
            end
            fprintf('\n');
            fprintf('Device Class: %s, Number Channels: %d\n', ...
                obj.DeviceClass, obj.NumberChannels);
            for i=1:length(obj.ChannelLabel)
                fprintf('Channel Assignment: %d %s \n', ...
                    obj.ChannelLabel{i}.Number, obj.ChannelLabel{i}.Label);
            end
            fprintf('Comment: %s\n', obj.Comment);
        end
        %
        % Need to make load and save objects. 

    end % methods
end % classdef
