%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Module Name : waveform.
%
% Author/Date : B.C. Donovan / 21-Oct-08
%
% Description : waveform object for
%               CBL DAC II Ccommand GUI
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
% CVS header info.
% ----------------
% $CVSfile$
% $Author: bdonovan $
% $Date: 2008/12/03 15:47:57 $
% $Locker:  $
% $Name:  $
% $Revision: 103 $
%
% $Log: waveform.m,v $
% Revision 1.5  2008/12/03 15:47:57  bdonovan
% Added support for multiple DAC boxes to libdacii. Updated dacii.m for new api.
%
% Revision 1.1  2008/10/23 20:41:35  bdonovan
% First version of CMD Builder GUI that uses C dll to communicate with DACII board.
%
% C library to communicate with board is in ./lib.
%
% Matlab code has been reorganized into classes. GUI is not edited with the guide command
% in matlab.
%
% Independent triggering of each of the 4 DACs has been confirmed for both software
%  and hardware triggering with cbl_dac2_r3beta.bit
%
%
% Copyright (C) BBN Technologies Corp. 2008
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef dacIIWaveform < handle
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
       
       link_list_enable = 0;  % 1 -- Enable 2 -- Disable
       link_list_mode = 0;    % 1 -- DC 2 -- waveform
       
       have_link_list = 0;
       link_list_offset = [];
       link_list_counts = [];
       
       have_time_amplitude
       time_pairs = [];
       amplitude_pairs = [];
       
       message_manager = [];
       max_offset = 4095;
       
   end
   
   properties %(Access = 'private')
       max_wf_len_samples = 4096;
       max_wf_amp_samples = 8192;
       max_wf_amp_value = 8191; % max positive value for 13 bits
       
       valid_sample_rates = [1200,600,300,100,40];
       
       wf_modulus = 4;
       
       max_ll_length = 64;
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
           if (sf < 0)
               sf = 0;
           elseif(sf > 1.0)
               sf = 1;
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
           if (offset < 0)
               offset = 0;
           elseif(offset > wf.max_offset)
               offset = wf.max_offset;
           end
           wf.offset = offset;
       end
       
       function data = prep_vector(wf)
           
            wf.log(sprintf('Preparing waveform scale_factor = %.3f\n', wf.scale_factor));
           
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
           
            
            % The waveform amplitude could be anything,
            % so we need to scale it to full scale voltage (1 Volt),
            %  and apply the user input scale factor (0 to 1)
                       
            % The DAC Board will want the waveform voltage specified
            % as a Hex value from 0x0 to 0x1FFF (or MaxWFAmpSamps-1)
            % positive.
            
            scale = wf.scale_factor * 1/(max(abs(data)));
            scale = scale * wf.max_wf_amp_value;
            data = data* scale;
            
            data = fix(data);
            
            % ensure uint16 data storage 
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
               plot(data);
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
           
           if (exist('ll_offsets','var'))
               clear ll_offsets;
           end

           if (exist('ll_counts','var'))
               clear ll_counts;
           end
           
           if (exist('time_pairs','var'))
               clear time_pairs;
           end

           if (exist('amplitude_pairs','var'))
               clear amplitude_pairs;
           end
          
           % Read in the waveform file
         
           load(UImatFile)
           
           if (exist('WFVec', 'var'))
               wf.data = WFVec;
           else
               wf.log('Waveform file does not have WFVec variable');
               wf.data = [];
           end;

           if (exist('ll_offsets','var'))
               wf.log('Loaded Link List Offsets');
               wf.link_list_offset = ll_offsets;
           else
               wf.link_list_offset = [];
           end
           
           if (exist('ll_counts','var'))
               wf.log('Loaded Link List Counts');
               wf.link_list_counts = ll_counts;
           else
               wf.link_list_counts = [];
           end
           
           if (exist('time_pairs','var'))
               wf.log('Loaded Time Pairs');
               wf.time_pairs = time_pairs;
           else
               wf.time_pairs = [];
           end
           
           if (exist('amplitude_pairs','var'))
               wf.log('Loaded Amplitude Pairs');
               wf.amplitude_pairs = amplitude_pairs;
           else
               wf.amplitude_pairs = [];
           end
           
           wf.have_link_list = 0;
           if (length(wf.link_list_offset) ~= length(wf.link_list_counts)) 
               wf.log('Waveform Link List incorrectly formatted\n');
           else
               if ~isempty(wf.link_list_offset)
                   wf.have_link_list = 1;
               else
                   wf.log('Link list data not found');
               end
           end               
           
           wf.have_time_amplitude = 0;
           if (length(wf.time_pairs) ~= length(wf.amplitude_pairs)) 
               wf.log('Waveform Time Amplitude incorrectly formatted\n');
           else
               if ~isempty(wf.time_pairs)
                   wf.have_time_amplitude = 1;
                   wf.log('Converting time amplitude to wf offset count');
                   wf.prep_time_amplitude_pairs()
               else
                   wf.log('Time Amplitude data not found');
               end
           end  
           
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
