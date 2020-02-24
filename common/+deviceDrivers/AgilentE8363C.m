classdef AgilentE8363C < deviceDrivers.lib.GPIBorEthernet
%AGILENTE8363C
%
%
% Author(s): rhiltner with generate_driver.py
% Generated on: Fri Oct 16 11:37:54 2009

    % Device properties correspond to instrument parameters
    properties (Access = public)
        sweep_data;
        marker1_state;		% Values: ['off', 'on']
        marker1_x;		% Values: (numeric)
        marker1_y;
        marker2_state;		% Values: ['off', 'on']
        marker2_x;		% Values: (numeric)
        marker2_y;
        measurements;
        select_measurement;		% Values: (string)
        trace_source;		% Values: (string)
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
        frequency;          % frequency, for use in CW mode
    end % end device properties


    methods (Access = public)
        function obj = AgilentE8363C()
            %AGILENTE8363C constructor
        end

        % Instrument-specific methods
        function clear(obj)
        %CLEAR
            gpib_string = '*CLS';
            obj.write(gpib_string);
        end

        function wait(obj)
        %WAIT
            gpib_string = '*WAI';
            obj.write(gpib_string);
        end
        function abort(obj)
        %ABORT
            gpib_string = ':ABORt';
            obj.write(gpib_string);
        end
        
        function [frequencies, s21] = getTrace(obj)
            % select measurement
            % get measurement name
            measurement = obj.measurements;
            % take the part before the comma
            commaPos = strfind(measurement, ',');
            obj.select_measurement = measurement(2:commaPos-1);
            s21 = obj.sweep_data;
            
            center_freq = obj.sweep_center;
            span = obj.sweep_span;
            frequencies = linspace(center_freq - span/2, center_freq + span/2, length(s21));
        end
        
        function reaverage(obj)
            % reaverage
            % Clears current data and waits until NA has a full set of
            % averages.
            obj.abort();
            obj.average_clear();
            
            obj.wait();
            obj.block_for_averaging();
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
            obj.write(gpib_string);
        end
        function markers_off(obj)
        %MARKERS_OFF
            gpib_string = ':CALCulate:MARKer:AOFF';
            obj.write(gpib_string);
        end
        function define_measurement(obj, valuea, valueb)
        %DEFINE_MEASUREMENT
            gpib_string = ':CALCulate:PARameter:DEFine:EXTended';
            % Validate input
            check_vala = class(valuea);
            checkMapObja = containers.Map({'char'},{1});
            if not (checkMapObja.isKey(check_vala))
                error('Invalid input');
            end

            check_valb = class(valueb);
            checkMapObjb = containers.Map({'char'},{1});
            if not (checkMapObjb.isKey(check_valb))
                error('Invalid input');
            end

            gpib_string = [gpib_string ' ' valuea ',' valueb];
            obj.write(gpib_string);
        end
        function delete_all_measurements(obj)
        %DELETE_ALL_MEASUREMENTS
            gpib_string = ':CALCulate:PARameter:DELete:ALL';
            obj.write(gpib_string);
        end
        function delete_measurement(obj, value)
        %DELETE_MEASUREMENT
            gpib_string = ':CALCulate:PARameter:DELete:NAME';
            % Validate input
            check_val = class(value);
            checkMapObj = containers.Map({'char'},{1});
            if not (checkMapObj.isKey(check_val))
                error('Invalid input');
            end

            gpib_string = [gpib_string ' ' value];
            obj.write(gpib_string);
        end
        function send_trigger(obj)
        %SEND_TRIGGER
            gpib_string = ':INITiate:IMMediate';
            obj.write(gpib_string);
        end
        function average_clear(obj)
        %AVERAGE_CLEAR
            gpib_string = ':SENSe1:AVERage:CLEar';
            obj.write(gpib_string);
        end
        
        function block_for_averaging(obj)
        %BLOCK_FOR_AVERAGING blocks until averaging is complete
            while 1
                status = str2double(obj.averaging_complete);
                if status ~= 0
                    break
                end
            end
        end
        
        function CWMode(obj)
            % reset the device
            obj.write('*RST');
            % put the analyzer in CW mode
            obj.write(':SENSE:SWEEP:TYPE CW');
        end
        
    end % end methods

    methods % Instrument parameter accessors
        function val = get.sweep_data(obj)
            gpib_string = ':CALCulate:DATA';
            textdata = obj.query([gpib_string '? SDATA;']);
            data = str2num(textdata);
            val = data(1:2:end) + 1i*data(2:2:end);
        end
        function val = get.marker1_state(obj)
            gpib_string = ':CALCulate:MARKer1:STATe';
            val = obj.query([gpib_string '?']);
        end
        function val = get.marker1_x(obj)
            gpib_string = ':CALCulate:MARKer1:X';
            val = obj.query([gpib_string '?']);
        end
        function val = get.marker1_y(obj)
            gpib_string = ':CALCulate:MARKer1:Y';
            val = obj.query([gpib_string '?']);
        end
        function val = get.marker2_state(obj)
            gpib_string = ':CALCulate:MARKer2:STATe';
            val = obj.query([gpib_string '?']);
        end
        function val = get.marker2_x(obj)
            gpib_string = ':CALCulate:MARKer2:X';
            val = obj.query([gpib_string '?']);
        end
        function val = get.marker2_y(obj)
            gpib_string = ':CALCulate:MARKer2:Y';
            val = obj.query([gpib_string '?']);
        end
        function val = get.measurements(obj)
            gpib_string = ':CALCulate:PARameter:CATalog';
            val = obj.query([gpib_string '?']);
        end
        function val = get.select_measurement(obj)
            gpib_string = ':CALCulate:PARameter:SELect';
            val = obj.query([gpib_string '?']);
        end
        function val = get.output(obj)
            gpib_string = ':OUTPut:STATe';
            val = obj.query([gpib_string '?']);
        end
        function val = get.average_counts(obj)
            gpib_string = ':SENSe1:AVERage:COUNt';
            val = str2double(obj.query([gpib_string '?']));
        end
        function val = get.averaging(obj)
            gpib_string = ':SENSe1:AVERage:STATe';
            val = obj.query([gpib_string '?']);
        end
        function val = get.sweep_center(obj)
            gpib_string = ':SENSe:FREQuency:CENTer';
            val = str2double(obj.query([gpib_string '?']));
        end
        function val = get.sweep_span(obj)
            gpib_string = ':SENSe:FREQuency:SPAN';
            val = str2double(obj.query([gpib_string '?']));
        end
        function val = get.sweep_mode(obj)
            gpib_string = ':SENSe:SWEep:MODE';
            val = obj.query([gpib_string '?']);
        end
        function val = get.sweep_points(obj)
            gpib_string = ':SENSe:SWEep:POINts';
            val = str2double(obj.query([gpib_string '?']));
        end
        function val = get.power(obj)
            gpib_string = ':SOURce:POWer:LEVel:IMMediate:AMPLitude';
            val = obj.query([gpib_string '?']);
        end
        function val = get.averaging_complete(obj)
            gpib_string = ':STATus:OPERation:AVERaging1:CONDition';
            val = obj.query([gpib_string '?']);
        end
        function val = get.averaging_completed(obj)
            gpib_string = ':STATus:OPERation:AVERaging1:EVENt';
            val = obj.query([gpib_string '?']);
        end
        function val = get.nerr(obj)
            gpib_string = ':SYSTem:ERRor:COUNt';
            val = obj.query([gpib_string '?']);
        end
        function val = get.err(obj)
            gpib_string = ':SYSTem:ERRor';
            val = obj.query([gpib_string '?']);
        end
        function val = get.trigger_source(obj)
            gpib_string = ':TRIGger:SEQuence:SOURce';
            val = obj.query([gpib_string '?']);
        end
        function val = get.frequency(obj)
            gpib_string = 'SENS:FREQ';
            val = obj.query([gpib_string '?']);
        end

        function obj = set.marker1_state(obj, value)
            gpib_string = ':CALCulate:MARKer1:STATe';
            
            % Validate input
            checkMapObj = containers.Map({'off','on'},{'OFF','ON'});
            if not (checkMapObj.isKey(value))
                error('Invalid input');
            end

            gpib_string = [gpib_string ' ' checkMapObj(value)];
            obj.write(gpib_string);
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
            obj.write(gpib_string);
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
            obj.write(gpib_string);
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
            obj.write(gpib_string);
            obj.marker2_x = value;
        end
        function obj = set.select_measurement(obj, value)
            gpib_string = ':CALCulate:PARameter:SELect';
            
            % Validate input
            check_val = class(value);
            checkMapObj = containers.Map({'char'},{1});
            if not (checkMapObj.isKey(check_val))
                error('Invalid input');
            end

            gpib_string = [gpib_string ' ' value];
            obj.write(gpib_string);
%             obj.select_measurement = value;
        end
        function obj = set.trace_source(obj, value)
            gpib_string = ':DISPlay:WINDow1:TRACe1:FEED';
            
            % Validate input
            check_val = class(value);
            checkMapObj = containers.Map({'char'},{1});
            if not (checkMapObj.isKey(check_val))
                error('Invalid input');
            end

            gpib_string = [gpib_string ' ' num2str(value)];
            obj.write(gpib_string);
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
            obj.write(gpib_string);
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
            obj.write(gpib_string);
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
            obj.write(gpib_string);
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
            obj.write(gpib_string);
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
            obj.write(gpib_string);
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
            obj.write(gpib_string);
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
            obj.write(gpib_string);
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
            obj.write(gpib_string);
        end
        function obj = set.trigger_source(obj, value)
            gpib_string = ':TRIGger:SEQuence:SOURce';
            
            % Validate input
            checkMapObj = containers.Map({'external','immediate','manual'},{'EXTernal','IMMediate','MANual'});
            if not (checkMapObj.isKey(value))
                error('Invalid input');
            end

            gpib_string = [gpib_string ' ' checkMapObj(value)];
            obj.write(gpib_string);
            obj.trigger_source = value;
        end
        function obj = set.frequency(obj, value)
            gpib_string = 'SENS:FREQ';
            
            % Validate input
            check_val = class(value);
            checkMapObj = containers.Map({'numeric','integer','float','single','double'},{1,1,1,1,1});
            if not (checkMapObj.isKey(check_val))
                error('Invalid input');
            end

            value = 1e9*value; %convert from GHz to Hz
            gpib_string = [gpib_string ' ' num2str(value)];
            obj.write(gpib_string);
        end
    end % end instrument parameter accessors

end % end classdef

