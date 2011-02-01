%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Module Name : dacii.m
%
% Author/Date : B.C. Donovan / 21-Oct-08
%
% Description : dacii object for QLab Experiment Framework
%               Based on original DacII object
%             
%               Wraps libdacii for access to dacii box.
%
% Restrictions/Limitations :
%
%   Requires libdacii.dll and libdacii.h
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
%                BCD
%
% CVS header info.
% ----------------
% $CVSfile$
% $Author: bdonovan $
% $Date: 2008/12/03 15:47:57 $
% $Locker:  $
% $Name:  $
% $Revision: 160 $
%
% $Log: dacii.m,v $
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

classdef DacII < deviceDrivers.lib.deviceDriverBase 
%DACII Summary of this class goes here
%   Detailed explanation goes here
   properties
       library_path = './lib/';
       device_id = 0;
       num_devices;
       message_manager =[];
	   bit_file_path = '';
	   bit_file = 'cbl_dac2_r5_d6ma_fx.bit';
	   expected_bit_file_ver = 5;
       Address = 0;
   end
   properties %(Access = 'private')
       is_open = 0;
	   bit_file_programmed = 0;
   end

   methods
        function d = DacII()
            d = d@deviceDrivers.lib.deviceDriverBase('DacII');
		    d.load_library();
            
            buffer = libpointer('stringPtr','                            ');
            calllib('libdacii','DACII_ReadLibraryVersion', buffer,length(buffer.Value));
            d.log(sprintf('Loaded %s', buffer.Value));
            
			% build path for bitfiles
			script_path = mfilename('fullpath');
			extended_path = '\DacII';
			baseIdx = strfind(script_path,extended_path);
		
			d.bit_file_path = script_path(1:baseIdx);	
        end
        
        function connect(obj,address)
		
			% Experiment Framework function for connecting to 
			% A DacII, allow numeric or serial number based
			% addressing
			
			if isnumeric(address)
				val = obj.open(address);
			else
				val = obj.openBySerialNum(address);
			end

		end
		
		function disconnect(obj)
			obj.close()
        end	
        
        function log(dac,line)
            if ~isempty(dac.message_manager)
                dac.message_manager.disp(line)
            else
                disp(line)
            end
        end
          
        function load_library(d)
            if (ispc())
               libfname = 'libdacii.dll';
            elseif (ismac())
               libfname = 'libdacii.dylib';
            else
               libfname = 'libdacii.so';
            end

			% build library path
			script_path = mfilename('fullpath');
            schString = [filesep 'DacII'];
            idx = strfind(script_path,schString);
			d.library_path = [script_path(1:idx) filesep 'lib' filesep];
            if ~libisloaded('libdacii')
               [notfound warnings] = loadlibrary([d.library_path libfname], [d.library_path 'libdacii.h']);
            end  
        end
        
        function unload_library(dac)
            if libisloaded('libdacii')
                unloadlibrary libdacii
            end
        end

        function num_devices = enumerate(dac)
            % Library may not be opened if a stale object is left in
            % memory by matlab. So we reopen on if need be.
            dac.load_library()  
            dac.num_devices = calllib('libdacii','DACII_NumDevices');
        end
		
		function wf = get_waveform_obj(obj)
			wf = dacIIWaveform();
		end
		
		% setAll is called as part of the Experiment initialize instruments
		function setAll(obj,init_params)
            fs = fields(init_params);
            for i = 1:length(fs)
                initStr = sprintf('obj.%s = init_params.%s;',fs{i},fs{i});
                eval(initStr);
            end
			
			% TODO: Change this to read something from the DacII and 
			% Determine if it needs to be programmed
			bitFileVer = obj.readBitFileVersion();
			if ~isnumeric(bitFileVer) || bitFileVer ~= obj.expected_bit_file_ver
                obj.loadBitFile();
            end
            
			bit_file_programmed = 1;
        end
		
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function val = open(dac,id)
            if (dac.is_open)
                dac.close()
            end
            
            if exist('id')
                dac.device_id = id;
            end

            val = calllib('libdacii','DACII_Open' ,dac.device_id);
            if (val == 0)
                dac.log(sprintf('DACII USB Connection Opened'));
                dac.is_open = 1;
            elseif (val == 1)
                dac.log(sprintf('Could not open device %i.', dac.device_id))
                dac.log(sprintf('Device may be open by a different process'));
            elseif (val == 2)
                dac.log(sprintf('DACII Device Not Found'));
            else
                dac.log(sprintf('Unknown return from LIBDACII: %i', val));
            end
        end
        
        function val = openBySerialNum(dac,serialNum)
            if (dac.is_open)
                dac.close()
            end

            val = calllib('libdacii','DACII_OpenBySerialNum' ,serialNum);
            if (val >= 0)
                dac.log(sprintf('DACII USB Connection Opened'));
                dac.is_open = 1;
                dac.device_id = val;
            elseif (val == -1)
                dac.log(sprintf('Could not open device %i.', dac.device_id))
                dac.log(sprintf('Device may be open by a different process'));
            elseif (val == -2)
                dac.log(sprintf('DACII Device Not Found'));
            else
                dac.log(sprintf('Unknown return from LIBDACII: %i', val));
            end
        end
        
        function close(dac)
            val = calllib('libdacii','DACII_Close',dac.device_id);
            if (val == 0)
              dac.log(sprintf('DACII USB Connection Closed\n'));
            else
              dac.log(sprintf('Error closing DACII USB Connection: %i\n', val));
            end
            dac.is_open = 0;
        end
        
        function programFPGA(dac, data, bytecount,sel)
            if ~(dac.is_open)
                warning('DACII is not open');
                return
            end
            dac.log('Programming FPGA ');
            val = calllib('libdacii','DACII_ProgramFpga',dac.device_id,data, bytecount,sel);
            if (val < 0)
                errordlg(sprintf('DACII_ProgramFPGA returned an error code of: %i\n', val), 'Programming Error');
            end
            dac.log('Done');    
        end
        
        function setupPLL(dac)
            if ~(dac.is_open)
                warning('DACII is not open');
                return
            end
            dac.log('Setup PLL');
            val = calllib('libdacii','DACII_SetupPLL', dac.device_id);
        end
        
        function setupVCX0(dac)
            if ~(dac.is_open)
                dac.log('DACII is not open');
                return
            end
            dac.log('Setup VCX0');
            val = calllib('libdacii','DACII_SetupVCXO', dac.device_id);
        end
        
       
        function loadBitFile(dac,filename)
            
			if ~exist('filename','var')
				filename = [dac.bit_file_path dac.bit_file];
			end
		
            if ~(dac.is_open)
                warning('DACII is not open');
                return
            end
            dac.setupVCX0();
            dac.setupPLL();

            % assume we are programming both FPGA with the same bit file
            Sel = 3;
            
            dac.log(sprintf('Loading bit file: %s', filename));
            eval(['[DataFileID, FOpenMessage] = fopen(''', filename, ''', ''r'');']);
            if ~isempty(FOpenMessage)
                error('BitReverse:DataFile:Not Found', 'Input DataFile Not Found');
            end
                
            [filename, permission, machineformat, encoding] = fopen(DataFileID);
            %eval(['disp(''Machine Format = ', machineformat, ''');']);

            [DataVec, DataCount] = fread(DataFileID, inf, 'uint8=>uint8');
            dac.log(sprintf('Read %i bytes.', DataCount));
            
            dac.programFPGA(DataVec, DataCount,Sel);
        end

        function loadWaveform(dac,id,waveform,offset)
            if ~(dac.is_open)
                warning('DACII is not open');
                return
            end
            if isempty(waveform)
                return
            end
            dac.log(sprintf('Loading Waveform length: %i into DAC%i ', length(waveform),id));
            val = calllib('libdacii','DACII_LoadWaveform', dac.device_id,waveform,length(waveform),offset,id);
             if (val < 0)
                errordlg(sprintf('DACII_LoadWaveform returned an error code of: %i\n', val), 'Programming Error');
            end
            dac.log('Done');
        end
        
        function loadLinkList(dac,id,offsets,counts, ll_len)
            trigger = [];
            repeat = [];
            bank = 0;
            dac.loadLinkListELL(dac,id,offsets,counts, trigger, repeat, ll_len, bank)
        end
        
        function loadLinkListELL(obj,dac,id,offsets,counts, trigger, repeat, ll_len, bank)
            if ~(dac.is_open)
                warning('DACII is not open');
                return
            end
            dac.log(sprintf('Loading Link List length: %i into DAC%i ', ll_len,id));
            val = calllib('libdacii','DACII_LoadLinkList',dac.device_id, offsets,counts,trigger,repeat,ll_len,id,bank);
             if (val < 0)
                errordlg(sprintf('DACII_LoadLinkList returned an error code of: %i\n', val), 'Programming Error');
            end
            dac.log('Done');
        end
		        
        function triggerWaveform(dac,id,trigger_type)
            if ~(dac.is_open)
                warning('DACII is not open');
                return
            end
            dac.log(sprintf('Trigger Waveform %i Type: %i ', id, trigger_type));
            val = calllib('libdacii','DACII_TriggerDac',dac.device_id, id,trigger_type);
            dac.log('Done');
        end
        
        function pauseWaveform(dac,id)
            if ~(dac.is_open)
                warning('DACII is not open');
                return
            end
            dac.log(sprintf('Pause Waveform %i ', id));
            val = calllib('libdacii','DACII_PauseDac', dac.device_id, id);
            dac.log('Done');
        end
        
        function disableWaveform(dac,id)
            if ~(dac.is_open)
                warning('DACII is not open');
                return
            end
            dac.log(sprintf('Disable Waveform %i ', id));
            val = calllib('libdacii','DACII_DisableDac', dac.device_id,id);
            dac.log('Done');
        end
        
        function triggerFpga(dac,id,trigger_type)
            if ~(dac.is_open)
                warning('DACII is not open');
                return
            end
            dac.log(sprintf('Trigger Waveform %i Type: %i ', id, trigger_type));
            val = calllib('libdacii','DACII_TriggerFpga', dac.device_id,id,trigger_type);
            dac.log('Done');
        end
        
        function pauseFpga(dac,id)
            if ~(dac.is_open)
                warning('DACII is not open');
                return
            end
            dac.log(sprintf('Pause Waveform %i ', id));
            val = calllib('libdacii','DACII_PauseFpga', dac.device_id,id);
            dac.log('Done');
        end
        
        function disableFpga(dac,id)
            if ~(dac.is_open)
                warning('DACII is not open');
                return
            end
            dac.log(sprintf('Disable Waveform %i ', id));
            val = calllib('libdacii','DACII_DisableFpga', dac.device_id,id);
            dac.log('Done');
        end
        
        function setLinkListMode(dac,id, enable,dc)
            if ~(dac.is_open)
                warning('DACII is not open');
                return
            end
            dac.log(sprintf('Dac: %i Link List Enable: %i Mode: %i', id, enable,dc));
            val = calllib('libdacii','DACII_SetLinkListMode', dac.device_id,enable,dc,id);
            dac.log('Done');
        end
        
        function setFrequency(dac,id, freq)
            if ~(dac.is_open)
                warning('DACII is not open');
                return
            end
            dac.log(sprintf('Dac: %i Freq : %i', id, freq));
            val = calllib('libdacii','DACII_SetPllFreq', dac.device_id,id,freq);
            dac.log('Done');
        end
        
        function val = readBitFileVersion(dac)
            val = calllib('libdacii','DACII_ReadBitFileVersion', dac.device_id);
        end
        
   end
   
   methods(Static)
       mainwindow(varargin)
       fig = DacIIGui
   end
end 
