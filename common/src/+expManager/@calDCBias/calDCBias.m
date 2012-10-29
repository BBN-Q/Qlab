%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Module Name :  calDCBias.m
%
% Author/Date : Brian Donovan / 06-Oct-10
%
% Description : This is the class used for testing DCBias Box
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

classdef calDCBias < expManager.expBase
    properties %This is only for properties not defined in the 'experiment' superlcass
        mode = 'sweepChannels';
        
        %% Parameters for sweepChannels Test
        currentAmpSensitivities = [200e-6 10e-6 500e-9];
        potValueStep  = 4;
        minimumCourse = 218;
        channel = 0;
        expData;
        useCurrentAmp = 1;
        setCalibration = 0;
       
        
        
        %% Parameters for stability test
        stabilityChannel = 0;
        stabilityValue = 0;
        stabilityHours = 1;
        stabilityFigIntervalMin = 10;
        stabilityCourse = 0;
        stabilityMedium = 0;
        stabilityFine = 0;
        
        %% Parameter for loading calibration from file
        calibrationFile = '';
        
        %% Parameter for testConfiguration
        nPoints = 1000;
        
        stabilitySensitivity = 500e-9; % current Amp Sensivity
        
        baseFileName = '';
    end
    methods (Static)
        %% Class constructor
        function obj = calDCBias(base_path,cfgFileName)
            if ~exist('cfg_file_number','var')
                cfg_file_number = 1; % default value
            end
            
            if ~exist('base_path','var')
                [pathstr name ext] = fileparts(mfilename('fullpath'));
                extendedStr = '\common\src\+expManager\@calDCBias';
                extendedIdx = strfind(pathstr,extendedStr);
                base_path = pathstr(1:extendedIdx - 1);
            end
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % A little more thought needs to go into the handling of these
            % variables.  Should the be hardcoded?  Should they be inputs?
            % Should they be stored in a cfg file?
            [t1, r1] = strtok(cfgFileName, '.'); %strip period
            
            if(size(strfind(t1, '_'), 2) ~= 2)
                error('config file name does not conform, expName_v1_number.cfg');
            end
            
            [ScriptName, r1] = strtok(t1, '_');
            [VersionName, r1] = strtok(r1, '_');
            [cfg_file_number, r1] = strtok(r1, '_');
            HomeDirectory = ScriptName; %In general SriptName should match HomeDirectory
            Name = [ScriptName '_' VersionName];
            
            data_path = [base_path 'experiments\' HomeDirectory '\data\'];
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % finally we inheret methods and properties from the experiment class
            obj = obj@expManager.expBase(Name,data_path,cfgFileName);
            
            obj.baseFileName = obj.DataFileName(1:end-3);
            obj.baseFileName = [data_path obj.baseFileName];
            
            mode = 'sweepChannels';
        end
    end
    methods
        %% Base functions
        function errorMsg = Init(obj)
            errorMsg = '';
            InstrParams = obj.inputStructure.InstrParams;
            ExpParams   = obj.inputStructure.ExpParams;
            
            %Open all instruments, this routine only uses InstrParams
            errorMsg = obj.openInstruments(errorMsg);
            %%% The next two functions are experiment specific %%%
            %Check ExpParams for errors
            errorMsg = obj.errorCheckExpParams(ExpParams,errorMsg);
            
            errorMsg = obj.initExpParams(ExpParams);
            
            %Prepare all instruments for measurement, this routine uses only ExpParams
            errorMsg = obj.initializeInstruments(errorMsg);
        end
        
        function errorMsg = Do(obj)
            fprintf(obj.DataFileHandle,'$$$ Beginning of Data\n');
            switch obj.mode
                case 'sweepChannels'
                    errorMsg = obj.sweepChannels();
                case 'stability'
                    errorMesg = obj.stability();
                case 'loadCalibration'
                    errorMesg = obj.setCalibrationFromFile();
                case 'testCalibration'
                    errorMesg = obj.testCalibration();
                otherwise
                    error(sprintf('unknown expType: %s', obj.mode))
                    
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
        
        function errorMsg = initExpParams(obj,Params)
            errorMsg = '';
            fs = fields(Params);
            for i = 1:length(fs)
                initStr = sprintf('obj.%s = Params.%s;',fs{i},fs{i});
                try
                    eval(initStr);
                catch
                    fprintf('Failed to set: %s\n', initStr);
                end
            end
        end
        
        %% error checking method
        function errorMsg = errorCheckExpParams(obj,ExpParams,errorMsg)
            % Error checking goes here or in switchingCurve.init.
            %if obj.inputStructure.SoftwareDevelopmentmode
            %    obj.inputStructure.errorChecked = true;
            %end
        end
        
        function errorMsg = sweepChannels(obj)
            errorMsg = '';
            
            dc = obj.Instr.dc;
            
            % Course
            dc.ZeroAll();
            [potDataC dmmDataC adcDataC dcDataC] = obj.executeSingle(obj.channel,0);
            
            % remove first point due to large step down
            obj.expData.potDataC = potDataC;
            obj.expData.dmmDataC = dmmDataC;
            obj.expData.adcDataC = adcDataC;
            obj.expData.dcDataC = dcDataC;
            
            % fit course function
            
            fitC = polyfit(potDataC,dmmDataC,1);
            obj.expData.potFitC = fitC;
            
            % restrict ADC to postivie current
            idx = find(dmmDataC > 0);
            
            fitADC = polyfit(adcDataC(idx),dmmDataC(idx),1);
            obj.expData.adcFit = fitADC;
            
            %Medium
            dc.ZeroAll();
            rc = dc.SetSinglePot( obj.channel, 0, obj.minimumCourse);
            [potDataM dmmDataM adcDataM dcDataM] = obj.executeSingle(obj.channel,1);
            
            obj.expData.potDataM = potDataM;
            obj.expData.dmmDataM = dmmDataM;
            obj.expData.adcDataM = adcDataM;
            obj.expData.dcDataM = dcDataM;
            
            fitM = polyfit(potDataM,dmmDataM,1);
            obj.expData.potFitM = fitM;
            
            %% Fine
            dc.ZeroAll();
            rc = dc.SetSinglePot( obj.channel, 0, obj.minimumCourse);
            [potDataF dmmDataF adcDataF dcDataF] = obj.executeSingle(obj.channel,2);
            
            obj.expData.potDataF = potDataF;
            obj.expData.dmmDataF = dmmDataF;
            obj.expData.adcDataF = adcDataF;
            obj.expData.dcDataF = dcDataF;
            
            fitF = polyfit(potDataF,dmmDataF,1);
            obj.expData.potFitF = fitF;
            
            if obj.setCalibration
                
                fprintf('Setting Calibration Data for DCBias\n')
                dc.SetCalibrationData('ADC', obj.channel,fitADC);
                [p] = dc.GetCalibrationData('ADC', obj.channel);
                fprintf('Set Cal ADC %f %f Ret Val %f %f\n', fitADC(1),fitADC(2), p.slope,p.intercept);
                
                dc.SetCalibrationData('C',obj.channel,fitC,max(dmmDataC), min(dmmDataC));
                snapnow;
                [p] = dc.GetCalibrationData('C', obj.channel);
                fprintf('Set Cal C %g %g Ret Val %g %g\n', fitC(1),fitC(2),p.slope,p.intercept);
                
                dc.SetCalibrationData('M',obj.channel,fitM, max(dmmDataM), min(dmmDataM));
                [p] = dc.GetCalibrationData('M', obj.channel);
                fprintf('Set Cal M %g Ret Val %g\n', fitM(1), p.slope);
                
                dc.SetCalibrationData('F',obj.channel,fitF, max(dmmDataF), min(dmmDataF));
                [p] = dc.GetCalibrationData('F', obj.channel);
                fprintf('Set Cal F %g Ret Val %g\n', fitF(1), p.slope);
            end
            
            expData = obj.expData;
            expData.minimumCourse = obj.minimumCourse;
            expData.potValueStep = obj.potValueStep;
            
            matFileName = [obj.baseFileName 'mat'];
            save(matFileName,'expData');
            fprintf(obj.DataFileHandle,'Binary data written to: %s\n',matFileName);
            
            figure(1)
            clf
            subplot(211)
            plot(dmmDataC,'r','LineWidth',2)
            hold on
            plot(dmmDataM,'g','LineWidth',2)
            plot(dmmDataF,'b','LineWidth',2)
            ylabel('Current [A]')
            legend('C','M','F')
            
            subplot(212)
            plot(adcDataC,'r','LineWidth',2)
            hold on
            plot(adcDataM,'g','LineWidth',2)
            plot(adcDataF,'b','LineWidth',2)
            ylabel('ADC Counts')
            xlabel('POT Value')
            
            figFileName = [obj.baseFileName(1:end-1) '_current.fig'];
            saveas(gcf,figFileName);
            %close(1);
            fprintf(obj.DataFileHandle,'Figure data written to: %s\n',figFileName);
            
            % do not plot ardunio reported current as this is currently
            % broken
            if 0
                figure(2);
                clf;
                plot(dcDataC,'r','LineWidth',2)
                hold on
                plot(dcDataM,'r','LineWidth',2)
                plot(dcDataF,'r','LineWidth',2)
                xlabel('POT Value')
                ylabel('Current [A]')
                title('Ardunio Reported Current')
                figFileName = [obj.baseFileName(1:end-1) '2.fig'];
                saveas(gcf,figFileName);
                fprintf(obj.DataFileHandle,'Figure data written to: %s\n',figFileName);
                %close(2);
            end
        end
        
        function [potData dmmData adcData dcData] = executeSingle(obj,channel,pot)
            values.dmm = [];
            values.adc = [];
            values.channel = channel;
            values.pot = pot;
            values.value = [];
            
            dc = obj.Instr.dc;
            dmm = obj.Instr.dmm;
            
            sensitivity = obj.currentAmpSensitivities(pot+1);
            
            if obj.useCurrentAmp
                fprintf('Set Current Amp Sensitivity To: %i nA/V\n',sensitivity*1e9);
                keyboard
            end
            
            dmmData = [];  % current read with DMM
            adcData = [];  % raw ADC value
            dcData = [];   % converted current value
            
            pauseTime = 0.01;
            
            fid = obj.DataFileHandle;
            
            potData = 0:obj.potValueStep:1023;
            
            for PotValue= potData
                rc = dc.SetSinglePot( channel, pot, PotValue);
                pause(pauseTime);
                DMM_Value = dmm.value;
                
                % read a second time as there can be a delay in reading
                % the correct value from the DMM
                
                pause(pauseTime);
                DMM_Value = dmm.value;
                
                if obj.useCurrentAmp
                    DMM_Value = DMM_Value*sensitivity;
                end
                
                ADC_Value = dc.ReadADC(channel);
                
                C_Value = dc.GetCurrent(channel);
                
                dmmData(end+1) = DMM_Value;
                adcData(end+1) = ADC_Value;
                dcData(end+1) = C_Value;
                dataStr = sprintf('Pot: %i PotValue: %i DMM_Value: %.3e ADC_Value: %i\n', pot,PotValue,DMM_Value,ADC_Value);
                fprintf(fid,dataStr);
                fprintf(dataStr);
                pause(pauseTime);
            end
        end
        
        function errorMesg = stability(obj)
            errorMesg = '';
            fprintf('Starting stability test\n')
            channel = obj.stabilityChannel;
            value   = obj.stabilityValue;
            hours   = obj.stabilityHours;
            
            course = obj.stabilityCourse;
            medium = obj.stabilityMedium;
            fine = obj.stabilityFine;
            
            sensitivity = obj.stabilitySensitivity;
            stabilityFigIntervalMin = obj.stabilityFigIntervalMin;
            numMeasure = 60*60*hours;
            timePause  = 3;
            
            dc = obj.Instr.dc;
            dmm = obj.Instr.dmm;
            
            if isfield(obj.Instr,'temp')
                tempDMM = obj.Instr.temp;
            else
                tempDMM = [];
            end
            
            dc.ZeroAll();
            
            %dc.SetCurrent(channel,value);
            
            rc = dc.SetSinglePot( channel, 0, course);
            rc = dc.SetSinglePot( channel, 1, medium);
            rc = dc.SetSinglePot( channel, 2, fine);
            
            startTime = clock;
            
            keyboard
            
            % Use the etime (elapsed time) function to end the DA
            
            data.numMeasure = numMeasure;
            data.channel = channel;
            data.value = value;
            data.hours = hours;
            
            
            data.clock = [];
            data.dmm = [];
            data.adc = [];
            data.temp = [];
            
            figure(1)
            clf
            
            fid = obj.DataFileHandle;
            
            labelsSet = 0;

            lastFigTime = clock;
            
            while (etime(clock, startTime) < numMeasure)
                DMM_Value = [];
                DMM_Value = dmm.value; %% Read back the current
                
                if obj.useCurrentAmp
                    DMM_Value = DMM_Value * sensitivity;
                end
                pause(2);
                TEMP_Value = [];
                if ~isempty(tempDMM)
                    TEMP_Value = tempDMM.value;
                end
                
                if isempty(TEMP_Value)
                    TEMP_Value = NaN;
                end
                
                if isempty(DMM_Value)
                    DMM_Value = NaN;
                end
                
                ADC_Value = dc.ReadADC(channel);% Get the ADC Data
                curClock = now;
                data.clock(end+1) = curClock;
                
                data.dmm(end+1) = DMM_Value;
                data.adc(end+1) = ADC_Value;
                data.temp(end+1) = TEMP_Value;
                
                if ~isempty(tempDMM)
                    subplot(211)
                end
                
                plot(curClock,DMM_Value,'.')
                ylabel('Current [A]')
                title('Stability Test')
                datetick('x',13)
                hold on
                
                if ~isempty(tempDMM)
                    subplot(212)

                    plot(curClock,TEMP_Value/1000,'.')
                    ylabel('Resistance [k\Omega]')
                    hold on
                    datetick('x',13)
                end
                
		    if etime(clock,lastFigTime) > 60*stabilityFigIntervalMin 
                figFileName = [obj.baseFileName 'fig'];
            	saveas(gcf,figFileName);
                matFileName = [obj.baseFileName 'mat'];
                save(matFileName,'data');
                lastFigTime = clock;
		    end

                dataStr = sprintf('Clock: %s DMM_Value: %.3e ADC_Value: %i TEMP_Value: %i\n', datestr(curClock),DMM_Value,ADC_Value,TEMP_Value);
                fprintf(fid,dataStr);
                fprintf(dataStr);
                pause( timePause);
            end
            
            matFileName = [obj.baseFileName 'mat'];
            save(matFileName,'data');
            fprintf(obj.DataFileHandle,'Binary data written to: %s\n',matFileName);
            
            figure(1);
            clf;
            subplot(211)
            plot(data.clock,data.dmm,'.')
            ylabel('Current [A]')
            title('Stability Test')
            datetick('x')
            
            if ~isempty(tempDMM)
                subplot(212)
                plot(curClock,TEMP_Value/1000,'.')
                ylabel('Resistance [k\Omega]')
                hold on
                datetick('x',13)
            else
                subplot(212)
                plot(data.clock,data.adc,'.')
                ylabel('ADC Counts')
                xlabel('Time')
                datetick('x')
            end
            
            figFileName = [obj.baseFileName 'fig'];
            saveas(gcf,figFileName);
            close(1);
            
        end
        
        function errorMesg = setCalibrationFromFile(obj)
            errorMesg = '';
            load(obj.calibrationFile);
            
            fid = obj.DataFileHandle;
            channel = obj.channel;
            dc = obj.Instr.dc;
            
            s = sprintf('Setting Calibration for channel %i from %s\n', channel, obj.calibrationFile);
            fprintf('%s',s);
            fprintf(fid,'%s',s);
            
            %% Course
            pot = expData.potDataC;
            dmm = expData.dmmDataC;
            p = polyfit(pot,dmm,1);
            dc.SetCalibrationData('C',channel,p,max(dmm),min(dmm));
            dc.GetCalibrationData('C',channel);
            
            %% ADC
            pot = expData.potDataC;
            dmm = expData.dmmDataC;
            adc = expData.adcDataC;
            
            % restrict ADC to positive current
            idx = find(dmm > 0);
            pot = pot(idx);
            adc = adc(idx);
            p = polyfit(adc,dmm(idx),1);
            dc.SetCalibrationData('ADC',channel,p);
            dc.GetCalibrationData('ADC',channel);
            
            
            %% Medium
            pot = expData.potDataC;
            dmm = expData.dmmDataM;
            p = polyfit(pot,dmm,1);
            dc.SetCalibrationData('M',channel,p,max(dmm),min(dmm));
            dc.GetCalibrationData('M',channel);
            
            %% Fine
            pot = expData.potDataF;
            dmm = expData.dmmDataF;
            p = polyfit(pot,dmm,1);
            dc.SetCalibrationData('F',channel,p,max(dmm),min(dmm));
            dc.GetCalibrationData('F',channel);
        end
        
        function errorMesg = testCalibration(obj)
            errorMesg = '';
            fprintf('Testing Calibration\n');
            channel = obj.channel;
            
            dc = obj.Instr.dc;
            dmm = obj.Instr.dmm;
            fid = obj.DataFileHandle;
            
            cal = dc.GetCalibrationData('C',channel);
            
            minVal = cal.min;
            maxVal = cal.max;
            delta = maxVal - minVal;
            nPoints = obj.nPoints;
            step = delta / nPoints;
            
            current = minVal:step:maxVal;
            
            setValues = [];
            
            for c = current
                dc.SetCurrent(0,c);
                % read twice
                v = dmm.value;
                v = dmm.value;
                setValues = [setValues v];
                fprintf('Set: %g Read: %g\n', c,v);
                fprintf(fid,'Set: %g Read: %g\n', c,v);
            end
            %%
            figure(1);
            clf;
            subplot(121)
            plot(current*1e3,setValues*1e3);
            hold on
            plot(current*1e3,current*1e3,'k')
            title('SetCurrent Response')
            xlabel('Requested Current [mA]');
            ylabel('Measured Current [mA]');
            subplot(122);
            plot(current*1e3,(setValues-current)*1e3);
            title('Absolute Error')
            xlabel('Requested Current [mA]');
            ylabel('Error [mA]');
            figFileName = [obj.baseFileName(1:end-1) '_calibration.fig'];
            saveas(gcf,figFileName);
            fprintf(obj.DataFileHandle,'Figure data written to: %s\n',figFileName);
            %close(1);
        end
        
    end
end

