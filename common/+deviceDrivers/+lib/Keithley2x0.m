classdef Keithley2x0 < deviceDrivers.lib.GPIB
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Module Name : Keithley2x0
    %
    % Author/Date : Bhaskar Mookerji/ ?-Jul-09
    %
    % Description : Instrument wrapper class for Keithley 2x0 220 and 230
    %
    % Restrictions/Limitations :
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
    %    21-Jul-09   CBL   Modified  this basic structure is common to the
    %                      220 and 230 units. This represents the overlap.
    %
    % $Revision$
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    % Define properties common to 220 and 230 devices
    %%
    properties (Constant = true)
        REVISION_NUMBER = 0.01;
        %
        % To permit error checking I am going to add a second
        % field to each parameter. This will be the command set
        % it belongs to. So the field .v will be the value
        % and .s will the set number it belongs to.
        % the set will be checked in the 'set' method
        % to make sure that we are using an appropriate
        % Command with the parameter.
        %
        % Apparently, Matlab doesn't like using a structure
        % for initialization as a constant, therefore I'm using
        % cells. cell:
        %   1 - the string to send.
        %   2 - The group it belongs to
        %   3 - the limit associated with this parameter, -1 means no limit.
        %   4 - Help text with parameter
        %
        % Display configuration, set 1
        DisplaySource         = {'D0', 1, -1};
        DisplayLimit          = {'D1', 1, -1};
        DisplayDwellTime      = {'D2', 1, -1};
        DisplayMemoryLocation = {'D3', 1, -1};
        
        % Function
        Standby               = {'F0', 2, -1};
        Operate               = {'F1', 2, -1};
        
        % Program modes
        Single                = {'P0', 3, -1};
        Continuous            = {'P1', 3, -1};
        Step                  = {'P2', 3, -1};
        
        % Trigger options
        StartOn_TALK          = {'T0', 4, -1};
        StopOn_TALK           = {'T1', 4, -1};
        StartOn_GET           = {'T2', 4, -1};
        StopOn_GET            = {'T3', 4, -1};
        StartOn_X             = {'T4', 4, -1};
        StopOn_X              = {'T5', 4, -1};
        StartOn_EXT           = {'T6', 4, -1};
        StopOn_EXT            = {'T7', 4, -1};
        
        %Prefix - Group 5
        % for the moment I'm fixing this to G0
        LocationWithPrefix    = {'G0', 5, -1};
        
        % EOI - group 6
        EOI_ON                = {'K0', 6, -1};
        EOI_OFF               = {'K1', 6, -1};
        
        % TODO, implement SRQ and Status
        % TODO, put in error codes here and then filter them
        % down through the system appropriately.
        
    end
    %%
    properties (Access = protected)
        % Boolean variable to specify
        % current or voltage source, 220 or 230 unit.
        IsCurrentSource = false;
        OldOutputBits   = 0;
        %
        % For the set methods, indicate a read is in progress
        % so we don't issue multiples.
        ReadInProgress  = false;
        %
        % On parse save the limit and value
        %
        Limit;
        Value;
    end % private properties
    %%
    properties (Access = public)
        % These are all the last set values
        % They can be accessed in a straightforward way
        % using the class 'set' method.
        %
        % The  following variables represent control parameters
        % and should be saved on configuration.
        Range;
        Display;
        Function;
        Program;
        Trigger;
        EOI;
        
        % The next set are output control bits and are common across units.
        % These data are not saved in configuration.
        OutputBits;
        
        % The next set are input data and are NOT saved in
        % configuration.
        % These are the common paramters
        DwellTime;
        BufferAddress;
        MemoryLocation;
        
    end % end properties
    %%
    methods (Access = public)
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : Keithley2x0 constructor
        %
        % Description :
        %
        % Inputs :
        %
        % Returns :
        %
        % Error Conditions : NONE
        %
        % Unit Tested on:
        %
        % Unit Tested by: CBL
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = Keithley2x0()
            obj = obj@deviceDrivers.lib.GPIB();
            OldOutputBits      = 0;
            IsCurrentSource    = false;
            ReadInProgress     = false;
        end
        function SetDefaults(obj)
            % Don't call this until after the card is opened.
            %
            % Default Parameters.
            %
            obj.Display        = obj.DisplaySource;
            obj.Function       = obj.Operate;
            obj.Program        = obj.Single;
            obj.Trigger        = obj.StartOn_TALK;
        end
    end
    %%
    methods
        function obj = set.Range(obj, value)
            obj.LastError = obj.NoError;
            % does this value belong to the Current Range group?
            if value{2} == 7
                obj.Range = value;
                val = strcat(value{1}, obj.Execute);
                obj.Write( val);
            else
                obj.LastError = obj.NoFile;
            end
        end
        function obj = set.Function(obj, value)
            obj.LastError = obj.NoError;
            if value{2} == 2
                obj.Function = value;
                val = strcat(value{1}, obj.Execute);
                obj.Write( val);
            else
                obj.LastError = obj.BadParameter;
            end
        end
        function obj = set.Display(obj, value)
            obj.LastError = obj.NoError;
            if value{2} == 1
                obj.Display = value;
                val = strcat(value{1}, obj.Execute);
                obj.Write( val);
            else
                obj.LastError = obj.BadParameter;
            end
        end
        
        function obj = set.Program(obj, value)
            if value{2} == 3
                obj.Program = value;
                val = strcat( value{1}, obj.Execute);
                obj.Write( val);
            else
                obj.LastError = obj.BadParameter;
            end
        end
        function obj = set.Trigger(obj, value)
            obj.LastError = obj.NoError;
            % does this value belong to the trigger group?
            if value{2} == 4
                obj.Trigger = value;
                val = strcat( value{1}, obj.Execute);
                obj.Write( val);
            else
                obj.LastError = obj.BadParameter;
            end
        end
        function obj = set.EOI(obj, value)
            obj.LastError = obj.NoError;
            % does this value belong to the EOI group?
            if value{2} == 6
                obj.EOI = value;
                val = strcat( value{1}, obj.Execute);
                obj.Write( val);
            else
                obj.LastError = obj.BadParameter;
            end
        end
        function obj = set.OutputBits(obj, value)
            obj.LastError = obj.NoError;
            if (value ~= obj.OldOutputBits)
                % nothing to do unless the bit field has changed
                if (value < 15)
                    obj.OutputBits    = value;
                    obj.OldOutputBits = obj.OutputBits;
                    % INCOMPLETE
                    disp('Set output bits incomplete\n');
                    obj.LastError = obj.BadParameter;
                end
            end
        end
        
        function obj = set.DwellTime(obj,val)
            obj.LastError = obj.NoError;
            % Check bounds.
            if (val<3.0e-3) | (val>999.9)
                obj.LastError = obj.OutOfBounds;
            end
            obj.DwellTime = val;
            if ~obj.ReadInProgress
                % Send a command.
                gpib_string = sprintf('W%gX',val);
                obj.Write(gpib_string);
            end
        end
        
        function rc = get.DwellTime(obj)
            obj.LastError = obj.NoError;
            % Send a command.
            val = strcat('W', obj.Execute);
            obj.Write(val);
            % Read back the result
            rc = obj.ReadAndParse('Dwell');
        end
        
        function obj = set.BufferAddress(obj, val)
            obj.LastError = obj.NoError;
            % Check bounds.
            if (val<1) | (val>100)
                obj.LastError = obj.OutOfBounds;
            end
            obj.BufferAddress = val;
            % Send a command.
            gpib_string = sprintf('B%gX',val);
            obj.Write(gpib_string);
        end
        function rc = get.BufferAddress(obj)
            obj.LastError = obj.NoError;
            % Send a command.
            val = strcat('B', obj.Execute);
            obj.Write(val);
            % Read back the result
            rc = obj.Read();
            obj.BufferAddress = str2num(rc);
        end
        
        function obj = set.MemoryLocation(obj, val)
            obj.LastError = obj.NoError;
            % Check bounds.
            if (val<1) | (val>100)
                obj.LastError = obj.OutOfBounds;
            end
            obj.MemoryLocation = val;
            if ~obj.ReadInProgress
                % Send a command.
                gpib_string = sprintf('L%gX',val);
                obj.Write(gpib_string);
            end
        end
        
        function rc = get.MemoryLocation(obj)
            obj.LastError = obj.NoError;
            % Send a command.
            val = strcat('B', obj.Execute);
            obj.Write(val);
            % Read back the result
            rc = obj.ReadAndParse('Location');
        end
        function val = ReadAndParse(obj, ObjectToReturn)
            % read data from device then parse it.
            % note this is intimately dependent on the
            % prefix format, that is why I've elected
            % in the shortness of time to limit it to G0
            %
            gpib_string = obj.Read();
            % Parse this into fields.
            linedat = strread( gpib_string,'%s','delimiter',',');
            
            CurrentValue = 0;
            limit        = 0;
            dwell        = 0;
            loc          = 0;
            val          = 0;
            obj.ReadInProgress = true;
            if length(linedat)>0
                % The first one is the device setting
                prefix = linedat{1}(1:4); % gobble up the first 4 characters
                if obj.IsCurrentSource
                    if ~strcmp( prefix, 'ODCI')
                        obj.LastError = obj.BadRead;
                        return;
                    end
                else
                    if ~strcmp( prefix, 'NDCV')
                        obj.LastError = obj.BadRead;
                        return;
                    end
                end
                CurrentValue = str2double(linedat{1}(5:length(linedat{1})));
                obj.Value    = CurrentValue;
            else
                CurrentValue = 0;
            end
            %
            % TODO Error checking on read fields, EG look for NDCI
            % in the prefix and NDCV for Current and Voltage respectively.
            %
            
            % the second could be voltage or current limit
            if length(linedat)>1
                
                if obj.IsCurrentSource
                    if linedat{2}(1) == 'V'
                        limit     = str2double(linedat{2}(2:length(linedat{2})));
                    end
                else
                    if linedat{2}(1) == 'I'
                        limit     = str2double(linedat{2}(2:length(linedat{2})));
                    end
                end
                obj.Limit = limit;
            else
                limit = 0;
            end
            
            % the third is dwell time
            if length(linedat)>2
                if linedat{3} == 'W'
                    dwell         = str2double(linedat{3}(2:length(linedat{3})));
                end
                obj.DwellTime = dwell;
            else
                dwell = 0;
            end
            
            % the forth is the location
            if length(linedat)>3
                if linedat{3} == 'L'
                    loc = str2double(linedat{4}(2:length(linedat{4})));
                end
                obj.MemoryLocation = loc;
                obj.ReadInProgress = false;
            else
                loc = 0;
            end
            if strcmp(ObjectToReturn,'Value')
                val = CurrentValue;
            elseif strcmp(ObjectToReturn,'Limit')
                val = limit;
            elseif strcmp(ObjectToReturn,'Dwell')
                val = dwell;
            elseif strcmp(ObjectToReturn,'Location')
                val = loc;
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : LoadParameters
        %
        % Description :
        %
        % Inputs :
        %
        % Returns :
        %
        % Error Conditions :
        %      0 SUCCESS!
        %
        % Unit Tested on:
        %
        % Unit Tested by: CBL
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function LoadParameters(obj, environment)
            % First load the gpib parameters.
            % Since the class name is properly set
            % then it will find the correct address.
            % and open the card at the specified address.
            %
            obj.LoadParameters@GPIBClass(environment);
            
            % Now search for the parameters associated
            % with the parent name, eg:Keithley230
            %
            Parameters = environment.GetValue(obj.Name);
            if environment.LastError == obj.NoError;
                %
                % Now sort through the parameters we
                % are responsible for.
                %
                if exist(obj.Parameters.Range)
                    obj.SetParameter(obj.Parameters.Range);
                    % Not sure what to do when this fails yet.
                end
                if exist(Parameters.Display)
                    % Not sure what to do when this fails yet.
                    SetParameter(Parameters.Display);
                end
                if exist(Parameters.Function)
                    SetParameter(Parameters.Function);
                end
                if exist(Parameters.Program)
                    SetParameter(Parameters.Program);
                end
                if exist(Parameters.Trigger)
                    SetParameter(Parameters.Trigger);
                end
                if exist(Parameters.EOI)
                    SetParameter(Parameters.EOI);
                end
            else
                obj.Configure();
            end
        end
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : SaveParameters
        %
        % Description :
        %
        % Inputs : structure to populate with updated values.
        %
        % Returns : NONE
        %
        % Error Conditions : NONE
        %
        % Unit Tested on:
        %
        % Unit Tested by: CBL
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function SaveParameters(obj, environment)
            obj.SaveParameters@GPIBClass(environment);
            eval(['environent.',obj.class,'.',obj.Name, ...
                '.Display= obj.Display.v']);
            eval(['environent.',obj.class,'.',obj.Name, ...
                '.Function= obj.Function.v']);
            eval(['environent.',obj.class,'.',obj.Name, ...
                '.Program= obj.Program.v']);
            eval(['environent.',obj.class,'.',obj.Name, ...
                '.Trigger = obj.Trigger.v']);
            eval(['environent.',obj.class,'.',obj.Name, ...
                '.EOI = obj.EOI.v']);
            eval(['environent.',obj.class,'.',obj.Name, ...
                '.Range = obj.Range']);
        end
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : Dump
        %
        % Description : Just going up the class level to dump
        %               data about ourselves for debugging
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
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function none = Dump(obj)
            obj.Dump@GPIBClass;
            if obj.CardOpen
                if exists(obj.Display) & exists(obj.Function)
                    fprintf('Keithley Display: %s Function: %s \n', ...
                        obj.Display{1}, obj.Function{1});
                    
                    fprintf('Program: %s Trigger: %s EOI: %s\n', ...
                        obj.Program{1}, obj.Trigger{1}, obj.EOI{1});
                    fprintf ( 'Range %s\n', obj.Range{1});
                end
                fprintf('Dwell Time: %s Buffer Address %s Memory Location: %s\n', ...
                    obj.DwellTime, obj.BufferAddress, obj.MemoryLocation);
            end
        end
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : Configure
        %
        % Description : Bring up a gui to enter the parameters.
        %
        % Inputs : none
        %
        % Returns :
        %
        % Error Conditions :
        %      0 SUCCESS!
        %
        % Unit Tested on:
        %
        % Unit Tested by: CBL
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function Configure(obj)
            obj.Configure@GPIBClass;
        end
        
    end % end public methods
    methods (Access = private)
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : SetParameter
        %
        % Description : We only save the character values of the
        % parameters, use this to sort through the structure and
        % set the right values.
        %
        % Inputs : string value to match up with parameter
        %
        % Returns :
        %
        % Error Conditions :
        %      0 SUCCESS!
        %
        % Unit Tested on:
        %
        % Unit Tested by: CBL
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function SetParameter(string)
            if strcmp(DisplaySource{1},string)
                Display = DisplaySource;
            elseif strcmp(DisplayLimit{1}, string)
                Display = DisplayLimit;
            elseif strcmp( DisplayDwellTime{1}, string)
                Display = DisplayDwellTime;
            elseif strcmp( DisplayMemoryLocation{1}, string)
                Display = DisplayMemoryLocation;
            elseif strcmp( Standby{1}, string)
                Function = Standby;
            elseif strcmp( Operate{1}, string)
                Function = Operate;
            elseif strcmp( Single{1}, string)
                Program = Single;
            elseif strcmp( Continuous{1}, string)
                Program = Continuous;
            elseif strcmp( Step{1}, string)
                Program = Step;
            elseif strcmp( StartOn_TALK{1}, string)
                Trigger = StartOn_TALK;
            elseif strcmp( StopOn_TALK{1}, string)
                Trigger = StopOn_TALK;
            elseif strcmp( StartOn_GET{1}, string)
                Trigger = StartOn_GET;
            elseif strcmp( StopOn_GET{1}, string)
                Trigger = StopOn_GET;
            elseif strcmp( StartOn_X{1}, string)
                Trigger = StartOn_X;
            elseif strcmp( StopOn_X{1}, string)
                Trigger = StopOn_X;
            elseif strcmp( StartOn_EXT{1}, string)
                Trigger = StartOn_EXT;
            elseif strcmp( StopOn_EXT{1}, string)
                Trigger = StopOn_EXT;
            elseif strcmp( EOI_ON{1}, string)
                EOI = EOI_ON;
            elseif strcmp( EOI_OFF{1}, string)
                EOI = EOI_OFF;
            end
        end
    end % end private methods
end
