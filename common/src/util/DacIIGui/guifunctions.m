%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Module Name : guifunctions
%
% Author/Date : B.C. Donovan / 21-Oct-08
%
% Description : additional connection logic between
%               CBL DAC II Command GUI and program state
%               Stores the state of the gui objects after changes and
%               passes variables to the dacii and waveform objects.
%
% Restrictions/Limitations :
%
% Requires:
%
%    waveform.m
%    dacii.m
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
% $Revision: 103 $
%
% $Log: guifunctions.m,v $
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

classdef guifunctions < handle
    %GUIFUNCTIONS GUI logic and state
    %   This object is to be created & called by the mainwindow.m callbacks.
    %   This object stores the waveform objects and the dacii interface object/
    
    properties
        
        bit_file_path;
        bit_file_name;
        bit_file_version;
        
        waveforms = [];
        
        bit_filter = '*.bit';
        bit_filter_desc = 'FPGA Bit File (*.bit)';
        
        wf_filter = '*.mat';
        wf_filter_desc = 'Waveform mat (*.mat)';
        
        message_manager;
        
        matching_dac = [1,0,3,2];
        
        pmval_to_sample_rate = [1200,600,300,100,40];
        
    end
    
    properties %(Access = 'private')
        ll_gui_enable = 'Off';
        
        bitFileVersion_8K = 5;
        bitFileVersion_link_list = 4;
    end
    
    properties (Transient=true)
        dac;
    end
    
    methods
        
        function gf = guifunctions(handles)
            % When creating the guifunctions object enumerate the dacii
            % device list. This will be stored in the dac object and used by
            % mainwindow.m to populate the Device popup menu.
            gf.message_manager = msgmanager(handles);
            
            
            % handle being inside and outside experiment framework
            
            loadedDacII = false;
            try
                gf.dac = dacII();
                loadedDacII = true;
            end
            
            if ~loadedDacII
                try
                    p = mfilename('fullpath');
                    loc = strfind(p,sprintf('src%sutil%sDacIIGui',filesep,filesep));
                    if ~isempty(loc)
                        p1 = p(1:loc+length('src/')-1);
                        p2 = p(1:loc+length('src/util/')-1);
                        addpath(p1,'-END')
                        addpath(p2,'-END')
                    end
                    
                    gf.dac = deviceDrivers.DacII();
                    loadedDacII = true;
                catch
                    
                    
                    error('Could not load dac object')
                end
            end
            
            gf.dac.message_manager = gf.message_manager;
            gf.dac.enumerate()
            gf.waveforms =  [dacIIWaveform(),dacIIWaveform(),dacIIWaveform(),dacIIWaveform()];
            message_manager = msgmanager(handles);
        end
        
        function open_dac(gui, id,versionHandle)
            % Open the dac device (index 0) based on GUI id (index 1)
            gui.dac.open(id-1);
            if (gui.dac.is_open)
                ver = gui.dac.readBitFileVersion();
                gui.bit_file_version = ver;
                set(versionHandle,'String', sprintf('%i', ver));
            end
        end
        
        function open_bit_file(gui,gui_handle)
            [file_name, file_path] = gui.load_file(gui.bit_filter,gui.bit_filter_desc);
            if (file_name == 0 & file_path == 0)
                % User selected cancel in dialog box ignore.
                return
            end
            gui.bit_file_name = file_name;
            gui.bit_file_path = file_path;
            set(gui_handle,'String',gui.bit_file_name)
        end
        
        function open_mat_file(gui,gui_handle,id)
            % Use a dialog box to select file and store filename
            % Based on waveform id
            
            [file_name, file_path] = gui.load_file(gui.wf_filter,gui.wf_filter_desc);
            if (file_name == 0 & file_path == 0)
                % User selected cancel in dialog box ignore.
                return
            end
            gui.waveforms(id+1).set_file(file_name,file_path);
            set(gui_handle,'String',file_name)
        end
        
        function set_wf_scale_factor(gui,id,hObject)
            wf = gui.waveforms(id+1);
            val = str2double(get(hObject,'String'));
            wf.set_scale_factor(val);
            if (wf.scale_factor ~= val)
                beep;
                gui.message_manager('Scale factor was out of range and has been put into range.');
            end
            set(hObject,'String', num2str(wf.scale_factor));
        end
        
        function set_wf_offset(gui,id,hObject)
            val = get(hObject,'String');
            ishex = ~isempty(findstr(val,'0x'));
            if (ishex)
                % remove leading '0x'
                val = val(3:length(val));
                val = hex2dec(val);
            else
                val = str2num(val);
            end
            wf = gui.waveforms(id+1);
            wf.set_offset(val);
            if (wf.offset ~= val)
                beep;
                gui.message_manager.disp('Offset was out of range and has been put into range.');
                
            end
            if (ishex)
                str = ['0x' dec2base(wf.offset,16)];
            else
                str = int2str(wf.offset);
            end
            set(hObject,'String', str);
        end
        
        function set_wf_trigger_type(gui,id,val)
            gui.waveforms(id+1).trigger_type = val;
        end
        
        function set_wf_sample_rate(gui,id,val)
            val = gui.pmval_to_sample_rate(val);
            if (id == 0 || id == 1)
                id1 = 0;
                id2 = 1;
            elseif (id == 2 || id == 3)
                id1 = 2;
                id2 = 3;
            else
                error('Bad DAC ID')
            end
            gui.waveforms(id1+1).sample_rate = val;
            gui.waveforms(id2+1).sample_rate = val;
        end
        
        function close(gui)
            gui.dac.close();
            gui.dac.unload_library();
        end
        
        function load_bit_file(gui,versionHandle)
            filename = [gui.bit_file_path gui.bit_file_name];
            if (~exist(filename, 'file'))
                gui.message_manager.disp(sprintf('[Error] File not found: %s\n', filename));
                errordlg(sprintf('Bit file: %s not found', filename), 'File not found', 'modal');
                return;
            end;
            set(versionHandle,'String', sprintf('Loading ...'));
            gui.dac.loadBitFile(filename);
            
            ver = gui.dac.readBitFileVersion();
            
            if (ver >= gui.bitFileVersion_8K)
                for i = 1:4
                    gui.waveforms(i).set_8k_mode()
                end
            end
            
            set(versionHandle,'String', sprintf('%i', ver));
            
        end
        
        function getBitFileVersion(gui,handle)
            ver = gui.dac.readBitFileVersion();
            set(handle,'String',num2str(ver));
        end
        
        function load(gui,filename)
            % Loads a guifunctions object from a .mat file
            % The file must have been created by the save function.
            % This function only loads the data
            load(filename)
            if exist('bfp')
                gui.bit_file_path = bfp;
            end
            if exist('bfn')
                gui.bit_file_name = bfn;
            end
            if exist('wf')
                gui.waveforms = wf;
            end
        end
        
        function save(gui,filename)
            % Saves a guifunctions object to a .mat file
            % Does not save the dacii object state
            bfp = gui.bit_file_path;
            save(filename, 'bfp')
            bfn = gui.bit_file_name;
            save(filename, 'bfn' ,'-append')
            wf = gui.waveforms;
            save(filename, 'wf' ,'-append')
        end
        
        function set_bit_file_controls(gui, handles)
            set(handles.txt_bit_file_name,'String',gui.bit_file_name)
            if (~isempty(gui.bit_file_name))
                set(handles.pb_load_bit_file, 'Enable', 'On');
            else
                set(handles.pb_load_bit_file, 'Enable', 'Off');
            end
        end
        
        function set_waveform_controls(gui,handles)
            for id = 0:3
                wf = gui.waveforms(id+1);
                txt = eval(sprintf('handles.txt_wf_file_%i', id));
                sf = eval(sprintf('handles.txt_wf_scale_factor_%i', id));
                tt = eval(sprintf('handles.pm_wf_trigger_%i', id));
                sr = eval(sprintf('handles.pm_wf_sample_rate_%i', id));
                srval = find(gui.pmval_to_sample_rate == wf.sample_rate);
                
                set(txt, 'String', wf.file_name);
                set(sf, 'String', wf.scale_factor);
                set(tt, 'Value', wf.trigger_type);
                set(sr, 'Value', srval);
                
                if (~isempty(wf.file_name))
                    % enable controls
                    gui.set_waveform_buttons_enable(handles,id,'On');
                    set( handles.pb_load_all, 'Enable', 'On');
                else
                    gui.set_waveform_buttons_enable(handles,id,'Off');
                end
                
                
            end
        end
        
        function set_waveform_buttons_enable(gui,handles,id,val)
            gui.set_ctrl_enable(handles,id,'pb_load_wf', val);
            gui.set_ctrl_enable(handles,id,'pb_plot_wf', val);
            set(handles.pb_load_all, 'Enable', val);
        end
        
        function load_waveform(gui,id, handles)
            % Load Waveform into FPGA by calling load_wave_form method of dacii
            % with correct waveform object
            wf = gui.waveforms(id+1);
            % clear current waveform data to
            % for the data to be reload from disk
            wf.data = [];
            vec = wf.get_vector();
            offset = wf.offset;
            if (offset + length(vec) > wf.max_offset)
                errdialog(sprintf('Vector of length: %i will not fit at offset: 0x%s',length(vec), dec2base(offset,16)), 'Error Loading Waveform');
                return;
            end
            gui.dac.loadWaveform(id,vec, offset)
            
            gui.set_ctrl_enable(handles,id,'pb_trigger_wf', 'On');
            
            set(handles.pb_trigger_all, 'Enable', 'On');
            
            gui.set_ctrl_enable(handles,id,'cb_simultaneous', 'On');
            
            if (gui.bit_file_version >= gui.bitFileVersion_link_list)
                [offsets, counts, ll_len] = wf.get_link_list();
                if (ll_len > 0)
                    gui.dac.loadLinkList(id,offsets,counts,ll_len);
                    
                    gui.ll_gui_enable = 'On';
                else
                    gui.ll_gui_enable = 'Off';
                    
                end
                
                % enable link list controls
                ll = eval(sprintf('handles.cb_ll_enable_%i', id));
                set(ll, 'Enable', gui.ll_gui_enable);
                
                ll = eval(sprintf('handles.cb_ll_dc_%i', id));
                set(ll, 'Enable', gui.ll_gui_enable);
            end
        end
        
        function trigger_waveform(gui,id, handles)
            
            wf = gui.waveforms(id+1);
            gui.dac.setFrequency(id,wf.sample_rate);
            
            if (gui.bit_file_version >= gui.bitFileVersion_link_list)
                % setup link list
                enable = eval(sprintf('handles.cb_ll_enable_%i', id));
                dc = eval(sprintf('handles.cb_ll_dc_%i', id));
                enable = get(enable, 'Value');
                dc = get(dc, 'Value');
                
                if (gui.waveforms(id+1).have_link_list)
                    gui.dac.setLinkListMode(id, enable,dc);
                end
            end
            
            cb = eval(sprintf('handles.cb_simultaneous_%i', id));
            trigger_both = get(cb, 'Value');
            
            if (~trigger_both)
                gui.dac.triggerWaveform(id,wf.trigger_type);
                handle_ids = [id];
            else
                gui.dac.triggerFpga(id,wf.trigger_type);
                id2 = gui.matching_dac(id+1);
                handle_ids = [id, id2];
            end
            
            for i = 1:length(handle_ids)
                id = handle_ids(i);
                
                gui.set_ctrl_enable(handles,id,'pb_trigger_wf', 'Off');
                gui.set_ctrl_enable(handles,id,'pb_pause_wf', 'On');
                gui.set_ctrl_enable(handles,id,'pb_disable_wf', 'On');
                
                gui.set_ctrl_enable(handles,id,'txt_wf_scale_factor', 'Off');
                gui.set_ctrl_enable(handles,id,'pm_wf_trigger', 'Off');
                gui.set_ctrl_enable(handles,id,'txt_wf_offset', 'Off');
                gui.set_ctrl_enable(handles,id,'pm_wf_sample_rate', 'Off');
                gui.set_ctrl_enable(handles,id,'pb_load_wf', 'Off');
                
                gui.set_ctrl_enable(handles,id,'cb_ll_enable','Off');
                gui.set_ctrl_enable(handles,id,'cb_ll_dc','Off');
                
            end
        end
        
        function set_ctrl_enable(gui,handles,id, ctrl, val)
            c = eval(sprintf('handles.%s_%i', ctrl, id));
            set(c, 'Enable', val);
        end
        
        function pause_waveform(gui,id, handles)
            
            cb = eval(sprintf('handles.cb_simultaneous_%i', id));
            pause_both = get(cb, 'Value');
            
            if (~pause_both)
                gui.dac.pauseWaveform(id);
                handle_ids = [id];
            else
                gui.dac.pauseFpga(id);
                id2 = gui.matching_dac(id+1);
                handle_ids = [id, id2];
            end
            
            for i = 1:length(handle_ids)
                id = handle_ids(i);
                gui.set_ctrl_enable(handles,id,'pb_trigger_wf', 'On');
                gui.set_ctrl_enable(handles,id,'pb_pause_wf', 'Off');
                gui.set_ctrl_enable(handles,id,'pb_disable_wf', 'On');
                
                
                gui.set_ctrl_enable(handles,id,'pm_wf_trigger', 'On');
                gui.set_ctrl_enable(handles,id,'pm_wf_sample_rate', 'On');
                
                gui.set_ctrl_enable(handles,id,'cb_ll_enable',  gui.ll_gui_enable);
                gui.set_ctrl_enable(handles,id,'cb_ll_dc',  gui.ll_gui_enable);
            end
            
        end
        
        function disable_waveform(gui,id, handles)
            
            cb = eval(sprintf('handles.cb_simultaneous_%i', id));
            pause_both = get(cb, 'Value');
            
            if (~pause_both)
                gui.dac.disableWaveform(id);
                handle_ids = [id];
            else
                gui.dac.disableFpga(id);
                id2 = gui.matching_dac(id+1);
                handle_ids = [id, id2];
            end
            
            for i = 1:length(handle_ids)
                id = handle_ids(i);
                gui.set_ctrl_enable(handles,id,'pb_trigger_wf', 'On');
                gui.set_ctrl_enable(handles,id,'pb_pause_wf', 'Off');
                gui.set_ctrl_enable(handles,id,'pb_disable_wf', 'Off');
                
                gui.set_ctrl_enable(handles,id,'txt_wf_scale_factor', 'On');
                gui.set_ctrl_enable(handles,id,'txt_wf_offset', 'On')
                gui.set_ctrl_enable(handles,id,'pm_wf_trigger', 'On');
                gui.set_ctrl_enable(handles,id,'pm_wf_sample_rate', 'On');
                gui.set_ctrl_enable(handles,id,'pb_load_wf', 'On');
                
                gui.set_ctrl_enable(handles,id,'cb_ll_enable', gui.ll_gui_enable);
                gui.set_ctrl_enable(handles,id,'cb_ll_dc',  gui.ll_gui_enable);
                
            end
            
        end
        
    end
    
    methods (Access = 'private')
        function [file_name, file_path] = load_file(gui,filter,filter_description)
            [file_name,file_path] = uigetfile({filter,filter_description;'*.*','All Files (*.*)'}, 'Open File');
        end
    end
end
