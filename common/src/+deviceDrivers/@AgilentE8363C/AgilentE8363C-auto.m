classdef AgilentE8363C < dev.DAObject.GPIB.GPIBWrapper
%AGILENTE8363C
%
%
% Author(s): rhiltner with generate_driver.py
% Generated on: Fri Oct 16 11:37:54 2009



    % Class-specific constant properties
    properties (Constant = true)

    end % end constant properties


    % Class-specific private properties
    properties (Access = private)

    end % end private properties


    % Class-specific public properties
    properties (Access = public)

    end % end public properties


    % Device properties correspond to instrument parameters
    properties (Access = public)
        identity;
        sweep_data;
        marker1_state;		% Values: ['off', 'on']
        marker1_x;		% Values: (numeric)
        marker1_y;
        marker2_state;		% Values: ['off', 'on']
        marker2_x;		% Values: (numeric)
        marker2_y;
        measurements;
        select_measurement;		% Values: (numeric)
        trace_source;		% Values: (numeric)
        output;		% Values: ['off', 'on']
        average_counts;		% Values: (numeric)
        averaging;		% Values: ['off', 'on']
        sweep_center;		% Values: (numeric)
        sweep_span;		% Values: (numeric)
        sweep_mode;		% Values: ['continuous', 'groups', 'hold', 'single']
        sweep_points;		% Values: (numeric)
        power;		% Values: (numeric)
        averaging_complete;
        averaging_completed;
        nerr;
        err;
        trigger_source;		% Values: ['external', 'immediate', 'manual']
    end % end device properties



    % Class-specific private methods
    methods (Access = private)

    end % end private methods


    methods (Access = public)
        function obj = AgilentE8363C()
        %AGILENTE8363C
            obj = obj@dev.DAObject.GPIB.GPIBWrapper();
        end % end constructor



        % Instrument-specific methods
        function clear(obj)
        %CLEAR
            gpib_string = '*CLS';
            obj.Write(gpib_string);
        end
        function reset(obj)
        %RESET
            gpib_string = '*RST';
            obj.Write(gpib_string);
        end
        function wait(obj)
        %WAIT
            gpib_string = '*WAI';
            obj.Write(gpib_string);
        end
        function abort(obj)
        %ABORT
            gpib_string = ':ABORt';
            obj.Write(gpib_string);
        end
        function marker1_search(obj, value)
        %MARKER1_SEARCH
            gpib_string = ':CALCulate:MARKer1:FUNCtion:EXECute';
            % Validate input
            checkMapObj = containers.Map({'compression','lpeak','ltarget','maximum','minimum','npeak','rpeak','rtarget','target'},{'COMPression','LPEak','LTARget','MAXimum','MINimum','NPEak','RPEak','RTARget','TARGet'});
            if not (checkMapObj.isKey(value))
                error('Invalid input');
            end

            gpib_string = [gpib_string ' ' checkMapObj(value)];
            obj.Write(gpib_string);
        end
        function markers_off(obj)
        %MARKERS_OFF
            gpib_string = ':CALCulate:MARKer:AOFF';
            obj.Write(gpib_string);
        end
        function define_measurement(obj, value)
        %DEFINE_MEASUREMENT
            gpib_string = ':CALCulate:PARameter:DEFine:EXTended';
            % Validate input
            check_val = class(value);
            checkMapObj = containers.Map({'numeric','integer','float','single','double'},{1,1,1,1,1});
            if not (checkMapObj.isKey(check_val))
                error('Invalid input');
            end

            gpib_string = [gpib_string ' ' num2str(value)];
            obj.Write(gpib_string);
        end
        function delete_all_measurements(obj)
        %DELETE_ALL_MEASUREMENTS
            gpib_string = ':CALCulate:PARameter:DELete:ALL';
            obj.Write(gpib_string);
        end
        function delete_measurement(obj, value)
        %DELETE_MEASUREMENT
            gpib_string = ':CALCulate:PARameter:DELete:NAME';
            % Validate input
            check_val = class(value);
            checkMapObj = containers.Map({'numeric','integer','float','single','double'},{1,1,1,1,1});
            if not (checkMapObj.isKey(check_val))
                error('Invalid input');
            end

            gpib_string = [gpib_string ' ' num2str(value)];
            obj.Write(gpib_string);
        end
        function send_trigger(obj)
        %SEND_TRIGGER
            gpib_string = ':INITiate:IMMediate';
            obj.Write(gpib_string);
        end
        function average_clear(obj)
        %AVERAGE_CLEAR
            gpib_string = ':SENSe1:AVERage:CLEar';
            obj.Write(gpib_string);
        end
    end % end methods

    methods % Class-specific private property accessors

    end % end private property accessors

    methods % Class-specific public property accessors

    end % end public property accessors

    methods % Instrument parameter accessors
        function val = get.identity(obj)
            gpib_string = '*IDN';
            val = obj.Query([gpib_string '?']);
        end
        function val = get.sweep_data(obj)
            gpib_string = ':CALCulate:DATA';
            val = obj.Query([gpib_string '?']);
        end
        function val = get.marker1_state(obj)
            gpib_string = ':CALCulate:MARKer1:STATe';
            val = obj.Query([gpib_string '?']);
        end
        function val = get.marker1_x(obj)
            gpib_string = ':CALCulate:MARKer1:X';
            val = obj.Query([gpib_string '?']);
        end
        function val = get.marker1_y(obj)
            gpib_string = ':CALCulate:MARKer1:Y';
            val = obj.Query([gpib_string '?']);
        end
        function val = get.marker2_state(obj)
            gpib_string = ':CALCulate:MARKer2:STATe';
            val = obj.Query([gpib_string '?']);
        end
        function val = get.marker2_x(obj)
            gpib_string = ':CALCulate:MARKer2:X';
            val = obj.Query([gpib_string '?']);
        end
        function val = get.marker2_y(obj)
            gpib_string = ':CALCulate:MARKer2:Y';
            val = obj.Query([gpib_string '?']);
        end
        function val = get.measurements(obj)
            gpib_string = ':CALCulate:PARameter:CATalog';
            val = obj.Query([gpib_string '?']);
        end
        function val = get.select_measurement(obj)
            gpib_string = ':CALCulate:PARameter:SELect';
            val = obj.Query([gpib_string '?']);
        end
        function val = get.output(obj)
            gpib_string = ':OUTPut:STATe';
            val = obj.Query([gpib_string '?']);
        end
        function val = get.average_counts(obj)
            gpib_string = ':SENSe1:AVERage:COUNt';
            val = obj.Query([gpib_string '?']);
        end
        function val = get.averaging(obj)
            gpib_string = ':SENSe1:AVERage:STATe';
            val = obj.Query([gpib_string '?']);
        end
        function val = get.sweep_center(obj)
            gpib_string = ':SENSe:FREQuency:CENTer';
            val = obj.Query([gpib_string '?']);
        end
        function val = get.sweep_span(obj)
            gpib_string = ':SENSe:FREQuency:SPAN';
            val = obj.Query([gpib_string '?']);
        end
        function val = get.sweep_mode(obj)
            gpib_string = ':SENSe:SWEep:MODE';
            val = obj.Query([gpib_string '?']);
        end
        function val = get.sweep_points(obj)
            gpib_string = ':SENSe:SWEep:POINts';
            val = obj.Query([gpib_string '?']);
        end
        function val = get.power(obj)
            gpib_string = ':SOURce:POWer:LEVel:IMMediate:AMPLitude';
            val = obj.Query([gpib_string '?']);
        end
        function val = get.averaging_complete(obj)
            gpib_string = ':STATus:OPERation:AVERaging1:CONDition';
            val = obj.Query([gpib_string '?']);
        end
        function val = get.averaging_completed(obj)
            gpib_string = ':STATus:OPERation:AVERaging1:EVENt';
            val = obj.Query([gpib_string '?']);
        end
        function val = get.nerr(obj)
            gpib_string = ':SYSTem:ERRor:COUNt';
            val = obj.Query([gpib_string '?']);
        end
        function val = get.err(obj)
            gpib_string = ':SYSTem:ERRor';
            val = obj.Query([gpib_string '?']);
        end
        function val = get.trigger_source(obj)
            gpib_string = ':TRIGger:SEQuence:SOURce';
            val = obj.Query([gpib_string '?']);
        end

        function obj = set.marker1_state(obj, value)
            gpib_string = ':CALCulate:MARKer1:STATe';
            
            % Validate input
            checkMapObj = containers.Map({'off','on'},{'OFF','ON'});
            if not (checkMapObj.isKey(value))
                error('Invalid input');
            end

            gpib_string = [gpib_string ' ' checkMapObj(value)];
            obj.Write(gpib_string);
            obj.marker1_state = value;
        end
        function obj = set.marker1_x(obj, value)
            gpib_string = ':CALCulate:MARKer1:X';
            
            % Validate input
            check_val = class(value);
            checkMapObj = containers.Map({'numeric','integer','float','single','double'},{1,1,1,1,1});
            if not (checkMapObj.isKey(check_val))
                error('Invalid input');
            end

            gpib_string = [gpib_string ' ' num2str(value)];
            obj.Write(gpib_string);
            obj.marker1_x = value;
        end
        function obj = set.marker2_state(obj, value)
            gpib_string = ':CALCulate:MARKer2:STATe';
            
            % Validate input
            checkMapObj = containers.Map({'off','on'},{'OFF','ON'});
            if not (checkMapObj.isKey(value))
                error('Invalid input');
            end

            gpib_string = [gpib_string ' ' checkMapObj(value)];
            obj.Write(gpib_string);
            obj.marker2_state = value;
        end
        function obj = set.marker2_x(obj, value)
            gpib_string = ':CALCulate:MARKer2:X';
            
            % Validate input
            check_val = class(value);
            checkMapObj = containers.Map({'numeric','integer','float','single','double'},{1,1,1,1,1});
            if not (checkMapObj.isKey(check_val))
                error('Invalid input');
            end

            gpib_string = [gpib_string ' ' num2str(value)];
            obj.Write(gpib_string);
            obj.marker2_x = value;
        end
        function obj = set.select_measurement(obj, value)
            gpib_string = ':CALCulate:PARameter:SELect';
            
            % Validate input
            check_val = class(value);
            checkMapObj = containers.Map({'numeric','integer','float','single','double'},{1,1,1,1,1});
            if not (checkMapObj.isKey(check_val))
                error('Invalid input');
            end

            gpib_string = [gpib_string ' ' num2str(value)];
            obj.Write(gpib_string);
            obj.select_measurement = value;
        end
        function obj = set.trace_source(obj, value)
            gpib_string = ':DISPlay:WINDow1:TRACe1:FEED';
            
            % Validate input
            check_val = class(value);
            checkMapObj = containers.Map({'numeric','integer','float','single','double'},{1,1,1,1,1});
            if not (checkMapObj.isKey(check_val))
                error('Invalid input');
            end

            gpib_string = [gpib_string ' ' num2str(value)];
            obj.Write(gpib_string);
            obj.trace_source = value;
        end
        function obj = set.output(obj, value)
            gpib_string = ':OUTPut:STATe';
            
            % Validate input
            checkMapObj = containers.Map({'off','on'},{'OFF','ON'});
            if not (checkMapObj.isKey(value))
                error('Invalid input');
            end

            gpib_string = [gpib_string ' ' checkMapObj(value)];
            obj.Write(gpib_string);
            obj.output = value;
        end
        function obj = set.average_counts(obj, value)
            gpib_string = ':SENSe1:AVERage:COUNt';
            
            % Validate input
            check_val = class(value);
            checkMapObj = containers.Map({'numeric','integer','float','single','double'},{1,1,1,1,1});
            if not (checkMapObj.isKey(check_val))
                error('Invalid input');
            end

            gpib_string = [gpib_string ' ' num2str(value)];
            obj.Write(gpib_string);
            obj.average_counts = value;
        end
        function obj = set.averaging(obj, value)
            gpib_string = ':SENSe1:AVERage:STATe';
            
            % Validate input
            checkMapObj = containers.Map({'off','on'},{'OFF','ON'});
            if not (checkMapObj.isKey(value))
                error('Invalid input');
            end

            gpib_string = [gpib_string ' ' checkMapObj(value)];
            obj.Write(gpib_string);
            obj.averaging = value;
        end
        function obj = set.sweep_center(obj, value)
            gpib_string = ':SENSe:FREQuency:CENTer';
            
            % Validate input
            check_val = class(value);
            checkMapObj = containers.Map({'numeric','integer','float','single','double'},{1,1,1,1,1});
            if not (checkMapObj.isKey(check_val))
                error('Invalid input');
            end

            gpib_string = [gpib_string ' ' num2str(value)];
            obj.Write(gpib_string);
            obj.sweep_center = value;
        end
        function obj = set.sweep_span(obj, value)
            gpib_string = ':SENSe:FREQuency:SPAN';
            
            % Validate input
            check_val = class(value);
            checkMapObj = containers.Map({'numeric','integer','float','single','double'},{1,1,1,1,1});
            if not (checkMapObj.isKey(check_val))
                error('Invalid input');
            end

            gpib_string = [gpib_string ' ' num2str(value)];
            obj.Write(gpib_string);
            obj.sweep_span = value;
        end
        function obj = set.sweep_mode(obj, value)
            gpib_string = ':SENSe:SWEep:MODE';
            
            % Validate input
            checkMapObj = containers.Map({'continuous','groups','hold','single'},{'CONTinuous','GROups','HOLD','SINGle'});
            if not (checkMapObj.isKey(value))
                error('Invalid input');
            end

            gpib_string = [gpib_string ' ' checkMapObj(value)];
            obj.Write(gpib_string);
            obj.sweep_mode = value;
        end
        function obj = set.sweep_points(obj, value)
            gpib_string = ':SENSe:SWEep:POINts';
            
            % Validate input
            check_val = class(value);
            checkMapObj = containers.Map({'numeric','integer','float','single','double'},{1,1,1,1,1});
            if not (checkMapObj.isKey(check_val))
                error('Invalid input');
            end

            gpib_string = [gpib_string ' ' num2str(value)];
            obj.Write(gpib_string);
            obj.sweep_points = value;
        end
        function obj = set.power(obj, value)
            gpib_string = ':SOURce:POWer:LEVel:IMMediate:AMPLitude';
            
            % Validate input
            check_val = class(value);
            checkMapObj = containers.Map({'numeric','integer','float','single','double'},{1,1,1,1,1});
            if not (checkMapObj.isKey(check_val))
                error('Invalid input');
            end

            gpib_string = [gpib_string ' ' num2str(value)];
            obj.Write(gpib_string);
            obj.power = value;
        end
        function obj = set.trigger_source(obj, value)
            gpib_string = ':TRIGger:SEQuence:SOURce';
            
            % Validate input
            checkMapObj = containers.Map({'external','immediate','manual'},{'EXTernal','IMMediate','MANual'});
            if not (checkMapObj.isKey(value))
                error('Invalid input');
            end

            gpib_string = [gpib_string ' ' checkMapObj(value)];
            obj.Write(gpib_string);
            obj.trigger_source = value;
        end
    end % end instrument parameter accessors

end % end classdef

%---END OF FILE---%

