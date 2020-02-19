classdef (Sealed) Keithley220 < deviceDrivers.lib.Keithley2x0
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Module Name : Keithley220
 %
 % Author/Date : C. B. Lirakis/ 24-Jul-09
 %
 % Description : Instrument wrapper class for Keithley 220 current source.
 % This inherits the properties from DAObject.
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
 % These are specific to the 220 unit
 properties (Constant = true)
     % Current Range
     Auto                  = {'R0', 7, 1.0e-4};
     One_nanoamp           = {'R1', 7, 1.0e-9};
     Ten_nanoamps          = {'R2', 7, 1.0e-8};
     Hundred_nanoamps      = {'R3', 7, 1.0e-7};
     One_microamps         = {'R4', 7, 1.0e-6};
     Ten_microamps         = {'R5', 7, 1.0e-5};
     Hundred_microamps     = {'R6', 7, 1.0e-4};
 end
 properties (Access = public)
     %inputs
     voltage_limit;
     Current;                % present value of current
 end % end properties
 
 methods (Access = public)
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     % Function Name : Keithley220 constructor
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
     function obj = Keithley220()
         obj = obj@deviceDrivers.lib.Keithley2x0();
         % Come back later and set this
         % up to instantiate as 230 or 220
         %
         obj.Name        = 'Keithley220';
         obj.DeviceClass = 'Bias';
         %
         % Default Parameters. 
         %
         obj.IsCurrentSource = true;
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
         obj.Configure@Keitley2x0;
         disp('No Keithley 220 configure.');
     end
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
      
 end % end public methods
 methods
     function val = get.voltage_limit(obj)
         gpib_string = strcat('V',obj.Execute);
         obj.Write(gpib_string);
         val = obj.ReadAndParseValue('Limit');
     end
     function obj = set.voltage_limit(obj, val)
         obj.LastError = obj.OutOfBounds;
     end
     
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     % Function Name : Current set method
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
     function obj = set.Current(obj, value)
         obj.LastError = obj.NoError;
         if obj.DebugLevel > 2
             fprintf('Value: Limit: %f\n', value, obj.Range{3});
         end
         % Perform check on ranges. 
         if value < obj.Range{3}
            obj.Current = value;
            gpib_string = sprintf('I%g%s', value, obj.Execute);
            obj.Write(gpib_string);
         else
             obj.LastError = obj.OutOfBounds;
         end
     end
     %%
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     % Function Name : Current get method
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
     function rc = get.Current(obj)
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
         if strcmp ( obj.Auto{1}, string)
             Range = obj.Auto;
         elseif strcmp ( obj.One_nanoamp{1}, string)
             Range = obj.One_nanoamp;
         elseif strcmp ( obj.Ten_nanoamps{1}, string)
             Range = obj.Ten_nanoamps;
         elseif strcmp ( obj.Hundred_nanoamps{1}, string)
             Range = obj.Hundred_nanoamps;
         elseif strcmp ( obj.One_microamps{1}, string)
             Range = obj.One_microamps;
         elseif strcmp ( obj.Ten_microamps{1}, string)
             Range = obj.Ten_microamps;
         elseif strcmp ( Hundred_microamps{1}, string)
             Range = Hundred_microamps;
         end
     end
 end % end private methods
end
