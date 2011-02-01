%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Module Name :  calDacII.m
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

classdef calDacII < expManager.expBase
    properties %This is only for properties not defined in the 'experiment' superlcass
        
        baseFileName = '';
        
        dac0wf = '';
        dac1wf = '';
        dac2wf = '';
        dac3wf = '';
        
        wfScaleFactors = [1,1,1,1];
        wfOffsets = [0,0,0,0];
        wfSampleRates = [1200,1200,1200,1200];
        
        % simultaneous both DACs on the same FPGA
        simultaneous = true;
        
        mode = 'linkListTest'
    end
    methods (Static)
        %% Class constructor
        function obj = calDacII(base_path,cfgFileName)
            if ~exist('cfg_file_number','var')
                cfg_file_number = 1; % default value
            end
            
            if ~exist('base_path','var')
                [pathstr name ext] = fileparts(mfilename('fullpath'));
                extendedStr = '\common\src\+expManager\@calDacII';
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
            %Set initial Exp parameters
            errorMsg = obj.prepareForExperiment(errorMsg);
        end
        
        function errorMsg = Do(obj)
            fprintf(obj.DataFileHandle,'$$$ Beginning of Data\n');
            switch obj.mode
                case 'functionalTest'
                    obj.basicFunctionalTest()
                case 'linkListTest'
                    obj.linkListTest()
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
                eval(initStr);
            end
        end
        
        %% error checking method
        function errorMsg = errorCheckExpParams(obj,ExpParams,errorMsg)
            % Error checking goes here or in switchingCurve.init.
            %if obj.inputStructure.SoftwareDevelopmentMode
            %    obj.inputStructure.errorChecked = true;
            %end
        end
        
        function basicFunctionalTest(obj)
            dac = obj.Instr.dacii;
            
            % build waveform object array
            for i = 1:4
                waveforms(i) = dacIIWaveform();
            end
            
            % keep tracks of if we should trigger a given channel
            % if the file was empty above we won't trigger
            trigger = [1,1,0,0];
            
            for cnt = 1:5
                
                wf = dacIIWaveform();
                ln = cnt * 400;
                
                wf.data = [zeros([1,2000 - ln]) ones([1,ln])];
                wf.set_scale_factor(cnt/10+.5);
                
                dac.loadWaveform(0, wf.get_vector(), wf.offset);
                
                ln = (5-cnt) * 400;
                
                wf.data = [zeros([1,2000 - ln]) ones([1,ln]) zeros([1,1000])];
                wf.set_scale_factor((20-cnt)/10+.5);
                
                tic
                dac.loadWaveform(1, wf.get_vector(), wf.offset);
                toc
                
                if (obj.simultaneous)
                    if (trigger(1) && trigger(2))
                        dac.setFrequency(0,waveforms(1).sample_rate);
                        dac.triggerFpga(0, 1); % 0 -  dac number 1 - software trigger
                    end
                    if (trigger(3) && trigger(4))
                        dac.setFrequency(2,waveforms(1).sample_rate);
                        dac.triggerFpga(2, 1); % 2 -  dac number 1 - software trigger
                    end
                else
                    for i = 1:4
                        if (trigger(i))
                            dac.setFrequency(i-1,waveforms(i).sample_rate);
                            dac.triggerWaveform(i-1, waveforms(i).trigger_type);
                        end
                    end
                end
                
                
                keyboard;
                
                if (obj.simultaneous)
                    dac.pauseFpga(0);
                    dac.pauseFpga(2);
                else
                    for i = 1:4
                        dac.pauseWaveform(i-1);
                    end
                end
            end
        end
        
        function linkListTest(obj)
            dac = obj.Instr.dacii;

			linkListEnable = 1;
			dcMode = 0;
			dacID = 0;
			softwareTrigger = 1;
            
            ramp = 1;
			
            % build waveform object array
            for i = 1:4
                waveforms(i) = dacIIWaveform();
            end
            
            % keep tracks of if we should trigger a given channel
            % if the file was empty above we won't trigger
            trigger = [1,0,0,0];
            
            wf = dacIIWaveform();
            
            a = 100;
            b = 90;
            c = 80;
            d = 70;
            e = 60;
            f = 50;
            g = 40;
            h = 20;
            i = 10;
           
            bl = 200; % blockLength
            
            numWaveforms = 9;
            
            function v = pulse(len)
                v = ones([1,len]);
                if ramp
                    v = v .* [1:len] ./len;
                end
            end

            wf.data = [zeros([1,bl-a]) pulse(a) ...
                zeros([1,bl-b]) pulse(b) ...
                zeros([1,bl-c]) pulse(c) ...
                zeros([1,bl-d]) pulse(d) ...
                zeros([1,bl-e]) pulse(e) ...
                zeros([1,bl-f]) pulse(f) ...
                zeros([1,bl-g]) pulse(g) ...
                zeros([1,bl-h]) pulse(h) ...
                zeros([1,bl-i]) pulse(i) ...
                ];

            wf.set_scale_factor(1);
            
            wfLen = length(wf.data);
            
            dac.disableFpga(0);
            dac.disableFpga(2);
            keyboard
            tic
            dac.loadWaveform(dacID, wf.get_vector(), wf.offset);
            ta = toc;
            
            fprintf('Waveform load time: %.2f\n', ta);
            keyboard
            dac.setFrequency(dacID,800);
            
            loadTimes = [];
            
            counts = floor(wfLen/numWaveforms/4);
            offset = wfLen;
            
            for cnt = 1:100
               
                offset = offset + wfLen/numWaveforms/4;
                if offset >= wfLen/4
                    offset = 0;
                end
                offset = floor(offset);
                fprintf('Loading link list offset = %i counts = %i\n', offset, counts);
				
				llLen = 1;
				counts = bl/4;  % block length in 4 sample groups
				
				tic
				if 1
					dac.loadLinkList(dacID,[offset],[counts], llLen)
					dac.setLinkListMode(dacID, linkListEnable,dcMode)
				else
					dac.loadLinkListWithMode(dacID,[offset],[counts], llLen, linkListEnable,dcMode);
				end
                tb = toc;
                loadTimes = [loadTimes tb];
                fprintf('Link List Load Time: %.2f\n', tb);
                
                dac.triggerWaveform(dacID, softwareTrigger); 
                
                pause(1);
                dac.pauseWaveform(dacID);
               
            end
            fprintf('Mean Link List Load Time: %.4f\n', mean(loadTimes));
        end
        
    end
end


