%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Agilent N9020A Spectrum Analyzer
%Created in July 2015 by Theodor Lundberg, Kim lab, Harvard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef AgilentN9020A < deviceDrivers.lib.GPIBorEthernet


    % Device properties correspond to instrument parameters
    properties (Access = public)
        ByteOrder  %Selects the binary data byte order for numeric data transfer.
        Identify %Returns an instruments identification information.
        Mode %Select the measurement mode by its mode number. 
        ModeOpts %Queries the instrument mode options.
        OperationComplete %Sets or queries completion status of an operation.
        SAAtten %Attenuation setting.
        SAAttnAuto %Sets or queries the attenuation auto mode.
        SAAve %Sets or queries the trace averaging mode.
        SAAveCoun %Sets or queries the average count value.
        SABlank %Turns the display on/off.
        SADate %Sets or queries the instruments date.
        SADet %Sets or queries detector type.
        SADetAuto %Sets or queries the detector type auto mode.
        SAFreqCenter %Sets the center of the displayed frequency range.
        SAFreqStart %Sets the start of the displayed frequency range.
        SAFreqStop %Sets the ending of the displayed frequency range.
        SAMarker %Sets or queries the state of a marker.
        SAMarkerMode %Sets or queries the mode of a marker.
        SAMarkerXAxis %Queries the marker X position in the current x-axis units.
        SAMarkerYAxis %Queries the marker Y position in the current y-axis units.
        SAPeakExc %Sets the minimum amplitude variation of signals the marker indenfies.
        SAPeakTresh %Sets or queries the peak threshold value.
        SAPreamp %Sets or queries the status of the internal pre-amp.
        SAPresetType %Sets or queries the instrument preset mode.
        SARBW %Sets or queries the resolution bandwidth.
        SARBWAuto %Sets or queries the resolution bandwidth auto mode.
        SARefLevel %Sets or queries the absolute y-max amplitude displayed.
        SARFCoup %Sets or gets the RF input coupling.
        SAScaleDiv %Sets or queries the logarithmic units per vertical graticule division on the display.
        SAScaleType %Sets or queries the vertical scale type for the display.
        SASpan %Sets or queries the frequency span.
        SASweepPoints %(Sets? and)Queries the number of trace points.
        SASweepSingle %ON: Sweep cycles run continously. OFF: Sweeps only one.
        SASweepTime %Queries the trace sweep time. Sweep Time can be influenced by RBW and VBW.
        SASweepTimeAuto %Can only be used when FFT is OFF.
        SATime %Queries the time.
        SATitle %Sets or Queries the display title.
        SATrigger %Sets or queries the trigger source.
        SAVBW %Sets or queries the video bandwidth
        SAVBWAuto %Sets or queries the resolution bandwidth auto mode
        SAYunits %Sets or queries the y axis units
        WavAcquisitionTime %Set the measurement acquisition time.
        WavAver %Waveform—Averaging State. Preset is ON.
        WavCurrentCapture %Returns the current record that being read from the data capture buffer.
        WavFirstCapture %Specifies the first data record that will be routed to the input to be played back. 
        WavHardAvg %Sets the number of time averages to be made
        WavIFWidth %Selects either the wideband input hardware or the standard “narrowband” path.
        WavLastCapture %Specifies the last data record that will be routed to the input to be played back.
        WavNextCapture %Specfies the next record that will be read from the data capture buffer.
        WavRBW %Set the resolution bandwidth.
        WavSampleRate %Sets the sample rate
        WavTimeCapture %Specfies the length of time that data will be captured.  Preset: 102.500 ms
        WavTraceDisplay %
    end % end device properties


    methods (Access = public)
        function InitCaptureData(obj)
            % For group functions, OBJ is the group object. For
            % base device functions, OBJ is the device object.

            % Get the interface object
            interface=get(obj,'interface');

            % Tell it the precision
            fprintf(interface,':FORM:DATA REAL,32');

            % Set 
            fprintf(interface,':INIT:TCAP');
        end
        
        
        function res=QuerySCPI(obj,cmd)
            interface=get(obj,'interface');

            res=query(interface,cmd);
        end
        
        
        function SAInitiate(obj)
            interface=get(obj,'interface');

            % Set 
            fprintf(interface,':INIT:IMM');
        end
        
        
        function SAMarkerCentFreq(obj)
            % Get the interface object
            interface=get(obj,'interface');

            fprintf(interface, 'CALC:MARK:CENT');
        end
        
        
        function SAMarkerPeak(obj)
            % Get the interface object
            interface=get(obj,'interface');

            fprintf(interface, 'CALC:MARK:MAX');
        end
        
        
        function SAMarkerPeakLeft(obj)
            % Get the interface object
            interface=get(obj,'interface');

            fprintf(interface, 'CALC:MARK:MAX:LEFT');
        end
        
        
        function SAMarkerPeakNext(obj)
        % Get the interface object
            interface=get(obj,'interface');

            fprintf(interface, 'CALC:MARK:MAX:NEXT');   
        end
        
        
        function SAMarkerPeakRight(obj)
            % Get the interface object
            interface=get(obj,'interface');

            fprintf(interface, 'CALC:MARK:MAX:RIGHT');
        end
        
        
        function CHP = SAMeasCHP(obj)
            % Get the interface object
            interface=get(obj,'interface');

            CHP = query(interface, 'READ:CHP?');
        end
        
        
        function OBW = SAMeasOBW(obj)
            % Get the interface object
            interface=get(obj,'interface');

            OBW = query(interface, 'READ:OBW?');
        end 
        
        function [freq,amp] = SAPeakAcq(obj)
            % Get the interface object
            interface=get(obj,'interface');

            % Set the analyzer into single sweep mode
            fprintf(interface,':INIT:CONT OFF');

            % Trigger the sweep and wait for it to complete
            fprintf(interface,':INIT:IMM;*WAI');

            % Get the data back
            peaks = str2num(query(interface,':TRAC:MATH:PEAK?'));

            freq = peaks(1:2:end-1)';
            amp = peaks(2:2:end)';

            %Sweep continously agian
            fprintf(interface,':INIT:CONT ON');
        end
        
        function [freq, amp] = SAPeakAcqMax(obj)
            % Get the interface object
            interface=get(obj,'interface');

            % Change instrument mode to spectrum analyzer
            fprintf(interface,':INST:NSEL 1');

            % Set the analyzer into single sweep mode
            fprintf(interface,':INIT:CONT OFF');

            % Trigger the sweep and wait for it to complete
            fprintf(interface,':INIT:IMM;*WAI');

            % Get the peak data back
            fprintf(interface,':CALC:MARK:MAX');
            freq = str2double(query(interface,':CALC:MARK:X?'));
            amp = str2double(query(interface,':CALC:MARK:Y?'));

            fprintf(interface,':INIT:CONT ON');
        end
        
        function [freq,amp]=SAGetTrace(obj) %x axis is given in freq
            % Get the interface object
            interface=get(obj,'interface');
    
            % Tell it the precision
            fprintf(interface,':FORM:DATA REAL,32');

            % Set the analyzer into single sweep mode
            %fprintf(interface,':INIT:CONT OFF');

            % Trigger the sweep and wait for it to complete
            fprintf(interface,':INIT:IMM');
            opc=query(interface,'*OPC?');

            % Get the data back
            fprintf(interface,':TRACE:DATA? TRACE1');
            amp=binblockread(interface,'float');
            fread(interface,1);
            
            %Get the frequency
            interface=get(obj,'interface');
            SPAN = str2double(query(interface,':FREQ:SPAN?'));
            SP = str2double(query(interface,'OBW:SWE:POIN?'));
            CF = str2double(query(interface,':FREQ:CENT?'));
            StartF = CF-SPAN/2;
            dF=SPAN./1000;
            freq=zeros(SP+1,1);
            for n=1:SP+1
                freq(n)=StartF+(n-1)*dF;
            end
            
            %fprintf(interface,':INIT:CONT ON');
        end
        
        
        function data=SATraceAcq(obj) %x axis is No of points
            % For group functions, OBJ is the group object. For
            % base device functions, OBJ is the device object.


            % Get the interface object
            interface=get(obj,'interface');
    
            % Tell it the precision
            fprintf(interface,':FORM:DATA REAL,32');

            % Set the analyzer into single sweep mode
            %fprintf(interface,':INIT:CONT OFF');

            % Trigger the sweep and wait for it to complete
            fprintf(interface,':INIT:IMM');
            opc=query(interface,'*OPC?');

            % Get the data back
            fprintf(interface,':TRACE:DATA? TRACE1');
            data=binblockread(interface,'float');
            fread(interface,1);
            
            %fprintf(interface,':INIT:CONT ON');
        end
        
        
        function SYSPreset(obj)
            % Get the interface object
            interface=get(obj,'interface');

            fprintf(interface, ':SYST:PRES');
        end
            
        
        function SASetSpan(obj,val)
            interface=get(obj,'interface');
            temp={':FREQ:SPAN',val,'Hz'};
            sp=sprintf('%s %d %s',temp{:});
            fprintf(interface,sp);
        end
        
        function SPAN = SAGetSpan(obj)
            interface=get(obj,'interface');

            SPAN = query(interface,':FREQ:SPAN?');
        end
        
        function SASetCenterFreq(obj,val)
            interface=get(obj,'interface');
            temp={':FREQ:CENT',val,'Hz'};
            cf=sprintf('%s %d %s',temp{:});
            fprintf(interface,cf);
        end
        
        function CF = SAGetCenterFreq(obj)
            interface=get(obj,'interface');

            CF = query(interface,':FREQ:CENT?');
        end
        
        
        function SASetRBW(obj,val)
            interface=get(obj,'interface');
            temp={'BAND',val,'Hz'};
            rbw=sprintf('%s %d %s',temp{:});
            fprintf(interface,rbw);
        end
        
        function RBW = SAGetRBW(obj)
            interface=get(obj,'interface');
    
            RBW = query(interface,'BAND?');
        end
                
        function SASetVBW(obj,val)
            interface=get(obj,'interface');
            temp={'BAND.VID',val,'Hz'};
            rbw=sprintf('%s %d %s',temp{:});
            fprintf(interface,rbw);
        end
        
        function VBW = SAGetVBW(obj)
            interface=get(obj,'interface');
    
            VBW = query(interface,'BAND:VID?');
        end
        
        function SASetNoSweepPoints(obj,val)
            interface=get(obj,'interface');
            temp={'OBW:SWE:POIN',val,' '};
            sp=sprintf('%s %d %s',temp{:});
            fprintf(interface,sp);
        end
        
        function SP = SAGetNoSweepPoints(obj)
            interface=get(obj,'interface');
    
            SP = query(interface,'OBW:SWE:POIN?');
        end
        
        function iqdp=WavDeepCapture(obj)
            interface=get(obj,'interface');
            N=query(interface,'TCAP:LREC?');
            N=str2num(N);


            fprintf(interface,':FORM:DATA REAL,32');

            IQData=[];

            for x = 1:N
                fprintf(interface,':READ:WAV0?');
                Record=binblockread(interface,'float');
                fread(interface,1);
                IQData=[IQData;Record];
            end

            % data is interleaved inphase, quad

            inphase=IQData(1:2:end);
            quad=IQData(2:2:end);

            % final complex vector
            iqdp=inphase+i*quad;
        end
        
        
        function WavFetchDCapDData(obj)
            % Get the interface object
            interface=get(obj,'interface');

            % Tell it the precision
            fprintf(interface,':FORM:DATA REAL,32');

            fprintf(interface, ':WAV:IFP WIDE');
            fprintf(interface, ':INIT:TCAP');
            fprintf(interface,':FETC:TCAP?');

            % Get the data back
            data=binblockread(interface,'float');
            fread(interface,1);
        end
        
        
        function iqf=WavFetchIQData(obj)
            % Get the interface object
            interface=get(obj,'interface');

            % Tell it the precision
            fprintf(interface,':FORM:DATA REAL,32');

            fprintf(interface,':FETCH:WAV0?');

            % Get the data back
            data=binblockread(interface,'float');
            fread(interface,1);

            % data is interleaved inphase, quad
            inphase=data(1:2:end);
            quad=data(2:2:end);

            % final complex vector
            iqf=inphase+i*quad;
        end
        
        
        function WavInitIQData(obj)
            % Get the interface object
            interface=get(obj,'interface');

            % Tell it the precision
            fprintf(interface,':FORM:DATA REAL,32');

            % Set 
            fprintf(interface,':INIT:WAV');
        end
        
        
        function data=WavMeasIQData(obj)
            % Get the interface object
            interface=get(obj,'interface');

            % Change instrument mode to spectrum analyzer
            fprintf(interface,':INST:NSEL 8');

            % Tell it the precision
            fprintf(interface,':FORM:DATA REAL,32');

            % Set the Occupied Bandwidth Meas Mode
            fprintf(interface,':MEAS:WAV?');

            % Get the data back
            data=binblockread(interface,'float');
            fread(interface,1);
        end
        
        
        function iqr=WavReadIQData(obj)
            %function [inphase,quad,iqr]=WavReadIQData(obj)

            % Get the interface object
            interface=get(obj,'interface');

            % Tell it the precision
            fprintf(interface,':FORM:DATA REAL,32');

            fprintf(interface,':READ:WAV0?');

            % Get the data back
            data=binblockread(interface,'float');
            fread(interface,1);

            % data is interleaved inphase, quad
            inphase=data(1:2:end);
            quad=data(2:2:end);

            % final complex vector
            iqr=inphase+i*quad;
        end
        
        
        function WriteSCPI(obj,cmd)
            interface=get(obj,'interface');

            fprintf(interface,cmd);
        end
        
        
    end % end instrument parameter accessors

end % end classdef

