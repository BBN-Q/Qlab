classdef (Sealed) Keithley230 < deviceDrivers.lib.Keithley2x0
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Module Name : Keithley230
    %
    % Author/Date : C. B. Lirakis/ 23-Jul-09
    %
    % Description : Instrument wrapper class for Keithley 230 programmable
    % voltage source. Inherits from Keithley2x0 class which carries most
    % of the functionality
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
    %                CBL
    %
    % $Revision$
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    % Define properties
    % These are specific to the 230 unit
    properties (Constant = true)
        % Voltage Range
        % parameters of structure:
        % v - string to use to set.
        % s - set or group that the values belong to
        % l - limit or range.
        Auto                  = {'R0', 7,  1.0e3 }; % Volts
        One_millivolt         = {'R1', 7, 1.0e-3 };
        One_Volt              = {'R2', 7,    1.0 };
        Ten_Volts             = {'R3', 7,   10.0 };
        OneHundredVolts       = {'R4', 7,  100.0 };
    end
    properties (Access = public)
        %inputs
        current_limit;	     %
        Voltage;                % present value
    end % end properties
    
    methods (Access = public)
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : Keithley230 constructor
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
        function obj = Keithley230()
            obj = obj@deviceDrivers.lib.Keithley2x0();
            % Come back later and set this
            % up to instantiate as 230 or 220
            %
            obj.Name =  'Keithley230';
            obj.DeviceClass = 'Voltage';
            %
            % Default Parameters.
            %
            obj.IsCurrentSource = false;
        end
        %%
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : SetDefaults
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
        function SetDefaults(obj)
            obj.SetDefaults@Keithley2x0;
            % Don't call this until after the card is opened.
            %
            % Default Parameters.
            %
            obj.Range        = obj.Auto;
        end
       
        %%
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
            obj.LoadParameters@GPIBClass(environment);
            Parameters = environment.GetValue(obj.Name);
            if environment.LastError{1} == 0
                if isfield(Parameters,'Range')
                    obj.Range = obj.SetParameter(Parameters.Range);
                    % Not sure what to do when this fails yet.
                end
            else
                obj.Configure();
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
            obj.Configure@Keithley2x0;
            disp('No Keithley 230 configure.');
        end
    end
    %%
    methods
        %%
        function val = get.current_limit(obj)
            gpib_string = strcat('I',obj.Execute);
            obj.Write(gpib_string);
            val = obj.ReadAndParseValue('Limit');
        end
        %%
        function obj = set.current_limit(obj, val)
            obj.LastError = obj.OutOfBounds;
            disp('Can not set current limit.');
        end
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : Voltage set method
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
        function obj = set.Voltage(obj, value)
            obj.LastError = obj.NoError;
            % Perform check on ranges.
            % bounds and input is in Volts
            if obj.DebugLevel > 2
                fprintf('Value: Limit: %f\n', value, obj.Range{3});
            end
               
            if value < obj.Range{3}
                obj.Voltage = value;
                gpib_string = sprintf('V%g%s', value, obj.Execute);
                obj.Write(gpib_string);
            else
                obj.LastError = obj.OutOfBounds;
            end
        end
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : Voltage get method
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
        function rc = get.Voltage(obj)
            obj.LastError = obj.NoError;
            rc = obj.ReadAndParse('Value');
        end
    end
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
        function Range = SetParameter(obj, string)
            obj.LastError = obj.NoError;
            
            if strcmp ( obj.Auto{1}, string)
                Range = obj.Auto;
            elseif strcmp ( obj.One_millivolt{1}, string)
                Range = obj.One_millivolt;
            elseif strcmp ( obj.One_Volt{1}, string)
                Range = obj.One_Volt;
            elseif strcmp ( obj.Ten_Volts{1}, string)
                Range = obj.Ten_Volts;
            elseif strcmp ( obj.OneHundredVolts{1}, string)
                Range = obj.OneHundredVolts;
            end
        end
    end % end private methods
end
