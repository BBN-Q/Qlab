%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Module Name : waveform.
%
% Author/Date : B.C. Donovan / 21-Oct-08
%
% Description : waveform object for
%               APS Command GUI
%             
%
% Restrictions/Limitations :
%
%
% Change Descriptions :
%
% Classification : Unclassified
%
% References :
%
%    CMD Builder GUI v130 by J. Galliger
%
%
%    Modified    By    Reason
%    --------    --    ------
%                BCD
%
% $Author: bdonovan $
% $Date: 2008/12/03 15:47:57 $
% $Locker:  $
% $Name:  $
% $Revision: 103 $
%
% Copyright (C) BBN Technologies Corp. 2008 - 2011
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef APSWaveform < handle
%WAVEFORM Summary of this class goes here
%   Detailed explanation goes here

   properties
       file_name;
       path_name;
       scale_factor = 1.0;
       offset = 0;
       trigger_type = 1;      % 1 -- Software 2 -- Hardware
       sample_rate = 1200;

       data = [];
       dataMode = 1;        % 1 -- int16 (-8192, 8191), 2 -- floats (-1.0, 1.0)
       
       link_list_enable = 0;  % 1 -- Enable 2 -- Disable
       link_list_mode = 0;    % 1 -- DC 2 -- waveform
       
       have_link_list = false;
       link_list_offset = [];
       link_list_counts = [];
       
       % MQCO APS 0x10 additions
       link_list_trigger = [];
       link_list_repeat = [];
       ell = false;
       ellData = [];
       link_list_repeatCount = 0;
       
       have_time_amplitude = false;
       time_pairs = [];
       amplitude_pairs = [];
       
       message_manager = [];
       
       num_bits = 12;
   end
   
   properties %(Access = 'private')
       max_wf_len_samples = 8192; %4096
       max_wf_amp_samples = 8192;
       max_wf_amp_value = 8191; % max positive value for 13 bits
       
       valid_sample_rates = [1200,600,300,100,40];
       
       wf_modulus = 4;
       
       max_ll_length = 64;
       INT_DATA = 1;
       REAL_DATA = 2;
   end

   methods
   
   	   function set_8k_mode(wf)
   	      wf.max_wf_len_samples = 8192;
   	   end
   
       function set_file(wf,file_name,path_name)
           wf.data = [];
           wf.file_name = file_name;
           wf.path_name = path_name;
       end
       
       function log(wf,line)
            if ~isempty(wf.message_manager)
                wf.message_manager.disp(line)
            else
                disp(line)
            end
       end
       
       function set_scale_factor(wf,sf)
           if (sf < -1)
               sf = -1;
               fprintf('Warning: Scale factor out of range. Setting to -1\n')
           elseif(sf > 1.0)
               sf = 1;
               fprintf('Warning: Scale factor out of range. Setting to 1\n')
           end
           
           wf.scale_factor = sf;
               
       end
       
       function set_sample_rate(wf,sr)
           if (isempty(find(wf.valid_sample_rates == sr)))
               disp('Invalid Sample Rate');
           else
               wf.sample_rate = sr;
           end
       end
       
       function set_link_list_enable(wf,enable)
           if (en ~= 0 && en ~=1)
               en = 0;
           end
           
           wf.link_list_enable = enable;      
       end
       
       function set_link_list_mode(wf,mode)
           if (mode ~= 0 && mode ~=1)
               mode = 0;
           end
           
           wf.link_list_mode = mode;      
       end
       
       function set_vector(wf, data)
           wf.data = data;
       end
       
       
       function set_offset(wf,offset)
           
           if offset > 1
               offset = 1;
               fprintf('Warning Waveform DC Offset Out of Range. Clipping to 1\n');
           elseif offset < -1
               offset = -1;
               fprintf('Warning Waveform DC Offset Out of Range. Clipping to -1\n');
           end
           
           wf.offset = offset;
       end
       
       function data = prep_vector(wf)
           
            %wf.log(sprintf('Preparing waveform scale_factor = %.3f\n', wf.scale_factor));
           
            %  If the Waveform Length is Greater Than MaxWFLenSamps,
            %  We Would Like to Downsample to fit into the DAC Memory,
            %  But for Now, We'll Just Truncate the Waveform
                      
            data = wf.data;
            
            if (length(data) < 1)
                return;
            end
           
            if (length(data) > wf.max_wf_len_samples)
                wf.log(sprintf('Vector Len = %i Max = %i. Truncating WF...', length(data), wf.max_wf_len_samples));
                data = data(1:wf.max_wf_len_samples);
            end
           
            % If the Waveform Length is NOT Evenly Divisible by the transfer size (WFMod),
            % then we have to zero pad to a modulo WFMod length
            
            DSLength = length(data);
            DSLengthMod4 = mod(DSLength, wf.wf_modulus);
            if (DSLengthMod4 ~= 0)
                wf.log('Padding WF...');
                NSampsToCreate =  wf.wf_modulus - DSLengthMod4;
                data(DSLength+1:DSLength+NSampsToCreate) = 0;
            end;
            
            % if waveform data is reals, scale and convert to int16s
            if wf.dataMode == wf.REAL_DATA
                scale = wf.scale_factor * wf.max_wf_amp_value;
            else
                scale = wf.scale_factor;
            end

            % convert offset to ADC counts
            offset = wf.offset * wf.max_wf_amp_value;
            
            % convert data to ADC counts and add offset;
            data = data*scale + offset;

            data = fix(data);
            
            % clip data
            data(find(data > wf.max_wf_amp_value)) = wf.max_wf_amp_value;
            data(find(data < -wf.max_wf_amp_value)) = -wf.max_wf_amp_value;
            
            % ensure int16 data storage
            data = int16(data);
       end
       
       function vec = get_vector(wf)
           if isempty(wf.data)
               wf.read_file();
           end
           vec = wf.prep_vector();
       end
       
       function plot(wf)
           data = wf.get_vector();
           if (~isempty(data))
               figure;
               
               l = length(data);
               AX = plotyy(1:l,double(data)./wf.max_wf_amp_value,1:l,data);
               
               ylim(AX(1),[-1 1]);
               ylim(AX(2),[-wf.max_wf_amp_value wf.max_wf_amp_value]);
               set(get(AX(1),'Ylabel'),'String','Output Voltage') 
               set(get(AX(2),'Ylabel'),'String','Output ADC Counts') 
               yticks1 = [-1  -.75  -.5    -.25 0 .25 .5 .75 1];
               yticks2 = int16(fix(yticks1 * wf.max_wf_amp_value));
               set(AX(1), 'ytick', yticks1)
               set(AX(2), 'ytick', yticks2)
               xlabel('Sample')
           end
       end
       
       function read_file(wf)
           UImatFile = [wf.path_name wf.file_name];
           
           if (~exist(UImatFile, 'file'))
                wf.log(sprintf('[Error] File not found: %s\n', UImatFile));
                errordlg(sprintf('Waveform file: %s not found', UImatFile), 'File not found', 'modal');
                return;
           end;
           
           UImatVar = 'WFVec';
           
           % clear stale variables to make sure that they are loaded
           % from the file correctly
           if (exist('WFVec','var'))
               clear WFVec;
           end
          
           % Read in the waveform file
         
           load(UImatFile)
           
           %% Check for standard waveform vec
           
           if (exist('WFVec', 'var'))
               wf.data = WFVec;
           elseif ~(exist('linkList16','var'))
               wf.log('Waveform file does not have WFVec variable');
               wf.data = [];
           end;
           
           %% Test for MQCO APS Version 0x10 file format
           
           wf.have_link_list = 0;
           wf.ell = false;
           if exist('linkList16','var')
               wf.data = linkList16.waveformLibrary;
               wf.ellData = linkList16;
               wf.ell = true;
                if ~wf.check_ell_format()
                  wf.log('Warning APS 0x10 Link List is not in the correct format');
               else
                   wf.have_link_list = 1;
                   wf.log('Found APS 0x10 Link List');
               end
           end
           
       end
       
        function valid = check_ell_format(wf)
            valid = 0;
            
            requiredFields = {'offset', 'count', 'trigger', 'repeat', 'length'};
            
            matchingLengthIdx = [1 2 3 4];
            
            if isempty(wf.ellData)
                wf.log('ELL link list is empty');
                return
            end
            
            if ~isfield(wf.ellData,'bankA')
                wf.log('ELL link list is required to have a bank A')
                return
            end
            
            if ~isfield(wf.ellData,'repeatCount')
                wf.log('ELL link list is required to have a repeat count');
                return
            end
            
            for i = 1:length(requiredFields)
                if ~isfield(wf.ellData.bankA,requiredFields{i})
                    wf.log(sprintf('ELL Bank is required to have field %s', requiredFields{i}))
                end
                if isfield(wf.ellData,'bankB')
                    if ~isfield(wf.ellData.bankB,requiredFields{i})
                        wf.log(sprintf('ELL Bank is required to have field %s', requiredFields{i}))
                    end
                end
            end
            
            for i = matchingLengthIdx
                if length(wf.ellData.bankA.(requiredFields{1})) ~= length(wf.ellData.bankA.(requiredFields{i}))
                    wf.log(sprintf('ELL Bank Fields must match length'))
                end
                if isfield(wf.ellData,'bankB')
                    if length(wf.ellData.bankB.(requiredFields{1})) ~= length(wf.ellData.bankB.(requiredFields{i}))
                        wf.log(sprintf('ELL Bank Fields must match length'))
                    end
                end
            end
            
            % counts must be at least 3
            if (wf.ellData.bankA.count(wf.ellData.bankA.count < 3))
                wf.log(sprintf('ELL minimum count field value is 3'));
                return
            end
            if isfield(wf.ellData,'bankB')
                if (wf.ellData.bankB.count(wf.ellData.bankB.count < 3))
                    wf.log(sprintf('ELL minimum count field value is 3'));
                    return
                end
            end
            
            valid = 1;
        end
        
        
       
       function prep_time_amplitude_pairs(wf)
            amps = [];
            offsets = [];
            counts = [];
            
            for i = 1:length(wf.amplitude_pairs)
                offset = min(find(amps == wf.amplitude_pairs(i)));
                if isempty(offset)
                    new_amp = ones([1,4]) * wf.amplitude_pairs(i);
                    amps = [amps new_amp];
                    offset = min(find(amps == wf.amplitude_pairs(i)));
                end
                
                offsets(i) = (offset - 1) / 4; % shift from 1 based addressing to 0
                
%                 if (i == 1)
%                     duration = wf.time_pairs(i);
%                 else
%                     duration = wf.time_pairs(i) - wf.time_pairs(i - 1)
%                 end

                duration = wf.time_pairs(i);
                
                if (mod(duration,4) ~= 0)
                    wf.log(sprintf('[WARNING] Duration for TA pair %i not a multiple of 4. Truncating', i))
                    duration = duration - rem(duration,4);
                end
                    
                duration = duration / 4;
                counts(i) = duration;
            end
            wf.link_list_offset = offsets;
            wf.link_list_counts = counts;
            wf.data = amps;
            wf.have_link_list = 1;
       end
       	   
       function ell = get_ell_link_list(wf)
           if ~wf.ell
               ell = [];
               ell.len = 0;
               return
           end
           
           ell =  wf.ellData;
            ell.len = length(wf.ellData.bankA.offset);
       end
       
       function [offsets, counts, link_list_length] = get_link_list(wf)
            
            offsets = wf.link_list_offset;
            counts = wf.link_list_counts;
           
            link_list_length = length(offsets);
            
            if (length(offsets) ~= length(counts))
                wf.log('Link List: length(offsets) ~= length(counts');
                link_list_length = min(length(offsets),length(counts));
                wf.log(sprintf('Link List: setting length to %i', link_list_length));
            end
            
            if (link_list_length > wf.max_ll_length)
                wf.log('Warning: List List length too long. Truncating to %i', dac.max_ll_length)
                link_list_length =  wf.max_ll_length;
            end
            
            offsets = wf.link_list_offset(1:link_list_length);
            counts = wf.link_list_counts(1:link_list_length);
       end
     
   end
   
end 
