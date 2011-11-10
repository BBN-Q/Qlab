%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Module Name : guifunctions
%
% Author/Date : B.C. Donovan / 21-Oct-08
%
% Description : additional connection logic between
%               APS Command GUI and program state
%               Stores the state of the gui objects after changes and
%               passes variables to the aps and waveform objects.
%
% Restrictions/Limitations :
%
% Requires:
%
%    waveform.m
%    aps.m
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
% $Author: bdonovan $
% $Date: 2008/12/03 15:47:57 $
% $Locker:  $
% $Name:  $
% $Revision: 103 $
%
% Copyright (C) BBN Technologies Corp. 2008-2011
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef guifunctions < handle
    %GUIFUNCTIONS GUI logic and state
    %   This object is to be created & called by the mainwindow.m callbacks.
    %   This object stores the waveform objects and the aps interface object/
    
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
        
        last_file_path = '';
       
        handles = [];
    end
    
    properties %(Access = 'private')
        ll_gui_enable = {'Off','Off' ,'Off','Off'};
        ll_dc_enable = {'Off','Off' ,'Off','Off' };
        
        ll_ell = false;
        
        bitFileVersion_8K = 5;
        bitFileVersion_link_list = 4;
        bitFileVersion_ell = 16;
    end
    
    properties (Transient=true)
        dac;
    end
    
    methods
        
        function gf = guifunctions(handles)
            % When creating the guifunctions object enumerate the aps
            % device list. This will be stored in the dac object and used by
            % mainwindow.m to populate the Device popup menu.
            gf.message_manager = msgmanager(handles);
            
            gf.handles = handles;
            
            % handle being inside and outside experiment framework
            
            loadedAPS = false;
            try
                gf.dac = APS();
                loadedAPS = true;
            end
            
            if ~loadedAPS
                try
                    p = mfilename('fullpath');
                    loc = strfind(p,sprintf('src%sutil%sAPSGui',filesep,filesep));
                    if ~isempty(loc)
                        p1 = p(1:loc+length('src/')-1);
                        p2 = p(1:loc+length('src/util/')-1);
                        addpath(p1,'-END')
                        addpath(p2,'-END')
                    end
                    
                    gf.dac = deviceDrivers.APS();
                    loadedAPS = true;
                catch
                    
                    
                    error('Could not load dac object')
                end
            end
            
            gf.dac.message_manager = gf.message_manager;
            gf.dac.enumerate();
            gf.waveforms =  [APSWaveform(),APSWaveform(),APSWaveform(),APSWaveform()];
        end
        
        function open_dac(gui, id,versionHandle)
            % Open the dac device (index 0) based on GUI id (index 1)
            gui.dac.open(id-1, gui.dac.FORCE_OPEN);
            if (gui.dac.is_open)
                gui.message_manager.disp('Initializing.');
                try %wrap init it try block to make sure gui gets initialized
                    gui.dac.init();
                catch
                end
                gui.getBitFileVersion(versionHandle);
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
            if ((file_name == 0) & (file_path == 0))
                % User selected cancel in dialog box ignore.
                return
            end
            gui.waveforms(id+1).set_file(file_name,file_path);
            set(gui_handle,'String',file_name)
        end
        
        function set_aps_R16_mode(gui)
            gui.ll_ell = true; % enable enhanced link list mode
            for id = 0:3
                ll = sprintf('cb_ll_dc_%i', id);
                if isfield(gui.handles,ll)
                    set(gui.handles.(ll), 'String', 'One Shot');
                end
            end
        end
        
        function set_aps_R5_mode(gui)
            gui.ll_ell = false; % disable enhanced link list mode
            for id = 0:3
                ll = sprintf('cb_ll_dc_%i', id);
                set(gui.handles.(ll), 'String', 'DC Mode');
            end
        end
        
        function set_wf_scale_factor(gui,id,hObject)
            wf = gui.waveforms(id+1);
            val = str2double(get(hObject,'String'));
            wf.set_scale_factor(val);
            if (wf.scale_factor ~= val)
                beep;
                msg = sprintf('Scale factor %.2f was out of range and has been set to %.2f', ...
                               val, wf.scale_factor);
                gui.message_manager.disp(msg);
            end
            set(hObject,'String', num2str(wf.scale_factor));
        end
        
        function set_wf_offset(gui,id,hObject)
            val = get(hObject,'String');
            val = str2num(val);
            
            wf = gui.waveforms(id+1);
            wf.set_offset(val);
            % set zero register value for the channel to match the waveform
            % offset
            gui.dac.setOffset(id, wf.offset*wf.max_wf_amp_value);
            if (wf.offset ~= val)
                beep;
                gui.message_manager.disp('Offset was out of range and has been put into range.');
                
            end
            str = num2str(wf.offset);
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
                gui.dac.setFrequency(id1,val); % added BRJ
            elseif (id == 2 || id == 3)
                id1 = 2;
                id2 = 3;
                gui.dac.setFrequency(id1,val);
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
            
            gui.getBitFileVersion(versionHandle);
            gui.message_manager.disp('Initializing.');
            gui.dac.init();
            
        end
        
        function getBitFileVersion(gui,versionHandle)
            ver = gui.dac.readBitFileVersion();
            gui.bit_file_version = ver;
            set(versionHandle,'String', sprintf('%i', ver));
           
            if (ver >= gui.bitFileVersion_8K)
                for i = 1:4
                    gui.waveforms(i).set_8k_mode()
                end
            end
            
            if ver >= gui.bitFileVersion_ell
                gui.set_aps_R16_mode();
            else
                gui.set_aps_R5_mode();
            end
            
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
            % Does not save the aps object state
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
            if isfield(handles, 'pb_load_wf_0')
                % Set APS GUI Controls
                gui.set_ctrl_enable(handles,id,'pb_load_wf', val);
                gui.set_ctrl_enable(handles,id,'pb_plot_wf', val);
                set(handles.pb_load_all, 'Enable', val);
            end
        end
        
        function load_waveform(gui,id, handles)
            
            gui.set_ctrl_enable(handles,id,'pb_trigger_wf', 'Off');
            
            % Load Waveform into FPGA by calling load_wave_form method of aps
            % with correct waveform object
            wf = gui.waveforms(id+1);
            % clear current waveform data to
            % for the data to be reload from disk
            wf.data = [];
            vec = wf.get_vector();
            
            if isfield(handles,'pb_trigger_wf_0')
                % update APS Gui Controls
                gui.set_ctrl_enable(handles,id,'pb_trigger_wf', 'Off');
                set(handles.pb_trigger_all, 'Enable', 'Off');
            end
            
            if ~wf.ell
                gui.dac.loadWaveform(id,vec)
            else
                %% ell link lists use wf.data not wf.get_vector
                %% need to understand why
                gui.dac.clearLinkListELL(id);
                gui.dac.loadWaveform(id,vec);
            end
            
            % set frequency now
            % gui.dac.setFrequency(id,wf.sample_rate);
            gui.set_ctrl_enable(handles,id,'cb_simultaneous', 'On');
            
            if (gui.bit_file_version >= gui.bitFileVersion_link_list)
               
                gui.ll_gui_enable{id+1} = 'Off';
                gui.ll_dc_enable{id+1} = 'Off';
                
                if wf.ell
                    ell = wf.get_ell_link_list();
                    if isfield(ell,'bankA') && ell.bankA.length > 0
                        if (gui.bit_file_version < gui.bitFileVersion_ell)
                            errordlg('APS Bitfile does not support R16 version link list files');
                        else
                            
                            bankA = ell.bankA;
                            
                            gui.dac.loadLinkListELL(id,bankA.offset,bankA.count, ...
                                bankA.trigger, bankA.repeat, bankA.length, 0);
                            
                            if isfield(ell,'bankB')
                                bankB = ell.bankB;
                                gui.dac.loadLinkListELL(id,bankB.offset,bankB.count, ...
                                    bankB.trigger, bankB.repeat, bankB.length, 1);
                            end
                                
                            gui.dac.setLinkListRepeat(id,ell.repeatCount);
                            gui.ll_gui_enable{id+1} = 'On';
                            gui.ll_dc_enable{id+1} = 'On';
                        end
                    end
                end

                if isfield(handles,'pb_trigger_all')
                    % update APS Gui Controls
                    % enable Trigger Controls
                    gui.set_ctrl_enable(handles,id,'pb_trigger_wf', 'On');
                    set(handles.pb_trigger_all, 'Enable', 'On');
                    
                    % enable link list controls
                    ll = eval(sprintf('handles.cb_ll_enable_%i', id));
                    set(ll, 'Enable', gui.ll_gui_enable{id+1});
                    
                    ll = eval(sprintf('handles.cb_ll_dc_%i', id));
                    set(ll, 'Enable', gui.ll_gui_enable{id+1});
                end
            end
        end
        
        function trigger_all(gui,handles)
            for id = 0:3
                 wf = gui.waveforms(id+1);
                 %gui.dac.setFrequency(id,wf.sample_rate);
            
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
            
            end
            
            handle_ids = 0:3;
            
            % using triggerFPGA with the dac set to -1 will
            % cause the trigger to go to both FPGAs
            gui.dac.triggerFpga(-1,wf.trigger_type);
            
            gui.update_waveform_controls_trigger(handles,handle_ids)
        end
        
        function update_waveform_controls_trigger(gui,handles,handle_ids)
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
        
        function update_waveform_controls_pause(gui,handles,handle_ids)
            for i = 1:length(handle_ids)
                id = handle_ids(i);
                gui.set_ctrl_enable(handles,id,'pb_trigger_wf', 'On');
                gui.set_ctrl_enable(handles,id,'pb_pause_wf', 'Off');
                gui.set_ctrl_enable(handles,id,'pb_disable_wf', 'On');
                
                
                gui.set_ctrl_enable(handles,id,'pm_wf_trigger', 'On');
                gui.set_ctrl_enable(handles,id,'pm_wf_sample_rate', 'On');
                
                gui.set_ctrl_enable(handles,id,'cb_ll_enable',  gui.ll_gui_enable{id+1});
                gui.set_ctrl_enable(handles,id,'cb_ll_dc',  gui.ll_gui_enable{id+1});
            end
        end
        
        function update_waveform_controls_disable(gui,handles,handle_ids)
                % disable APSGuiControls
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
                
                gui.set_ctrl_enable(handles,id,'cb_ll_enable', gui.ll_gui_enable{id+1});
                gui.set_ctrl_enable(handles,id,'cb_ll_dc',  gui.ll_dc_enable{id+1});
                
            end
            
        end
        
        function set_waveform_link_list(gui,id,handles)
             if (gui.bit_file_version >= gui.bitFileVersion_link_list)
                % setup link list
                if (gui.waveforms(id+1).have_link_list)
                    enable = eval(sprintf('handles.cb_ll_enable_%i', id));
                    mode = eval(sprintf('handles.cb_ll_dc_%i', id));
                    
                    
                    enable = get(enable, 'Value');
                    mode = get(mode, 'Value');
                
                    gui.dac.setLinkListMode(id, enable, mode);
                end
            end
        end
        
        function trigger_waveform(gui,id, handles)
            
            wf = gui.waveforms(id+1);
            
            % set link bit for triggering waveform
            gui.set_waveform_link_list(id,handles)
            
            cb = eval(sprintf('handles.cb_simultaneous_%i', id));
            trigger_both = get(cb, 'Value');
            
            if (~trigger_both)
                gui.dac.triggerWaveform(id,wf.trigger_type);
                handle_ids = [id];
            else
                id2 = gui.matching_dac(id+1);
                % set link bit for matching waveform
                gui.set_waveform_link_list(id2,handles)
                gui.dac.triggerFpga(id,wf.trigger_type);
                handle_ids = [id, id2];
            end
            
            gui.update_waveform_controls_trigger(handles,handle_ids)
        end
        
        function set_ctrl_enable(gui,handles,id, ctrl, val)
            extended_str = sprintf('%s_%i', ctrl, id);
            if isfield(handles,extended_str)
                set(handles.(extended_str), 'Enable', val);
            end
        end
        
        function pause_all(gui, handles)
            % calling pause FPGA with dac set to -1 will
            % cause pause to go to all channels
            gui.dac.pauseFpga(-1);
            handle_ids = 0:3;
            gui.update_waveform_controls_pause(handles,handle_ids);
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
            
            gui.update_waveform_controls_pause(handles,handle_ids)
            
        end
        
        function disable_all(gui,handles)
           % calling disable FPGA with dac set to -1 will
           % cause disable to go to all channels
           gui.dac.disableFpga(-1);
           handle_ids = 0:3; 
           gui.update_waveform_controls_disable(handles,handle_ids);
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
            
            gui.update_waveform_controls_disable(handles,handle_ids);
            
        end
        
        function run(gui,handles)
            % run function for APS Insert control
            freq_selection = get(handles.pm_wf_sample_rate, 'Value');
            
            % set both FPGA outputs to same frequency
            gui.set_wf_sample_rate(0,freq_selection);
            gui.set_wf_sample_rate(2,freq_selection);
            gui.message_manager.disp(sprintf('Set frequnecy to: %i',  ...
                gui.pmval_to_sample_rate(freq_selection)));
            
            mode = get(handles.cb_ll_dc,'Value');
            if mode == 1
                mode = 0;  % set mode to 0 for continuous
                gui.message_manager.disp('Continous Mode');
            else
                mode = 1;  % set mode to 1 for one shot
                gui.message_manager.disp('One Shot Mode');
            end
            
            % trigger type is 1 -- software (interval) 2 -- hardware (external)
            trigger_type = get(handles.pm_wf_trigger,'Value');
            
            trigger = [false false false false];
            allTrigger = true;
            triggeredFPGA = [false false];
            
            for channel = 1:4
                cb_str = sprintf('rb_on_off_%i',channel-1);
                trigger(channel) = get(handles.(cb_str),'Value');
                if trigger(channel)
                    text_str = sprintf('txt_wf_file_%i',channel-1);
                    file_name = get(handles.(text_str),'String');
                    gui.waveforms(channel).file_name = file_name;
                    gui.load_waveform(channel-1,handles)

                    if gui.waveforms(channel).have_link_list
                        % waveform is a link list need to enable
                        gui.dac.setLinkListMode(channel - 1, true,mode)
                    end
                end
                allTrigger = allTrigger & trigger(channel);
            end
            
            if allTrigger
                gui.message_manager.disp('Trigger All');
                gui.dac.triggerFpga(-1,trigger_type); % -1 to trigger both FPGAs
                triggeredFPGA = [true true];
            elseif trigger(1) && trigger(2)
                    triggeredFPGA(1) = true;
                    gui.message_manager.disp('Trigger FPGA 0')
                    gui.dac.triggerFpga(gui.dac.FPGA0,trigger_type)
            elseif trigger(3) && trigger(4)
                triggeredFPGA(2) = true;
                gui.message_manager.disp('Trigger FPGA 1')
                gui.dac.triggerFpga(gui.dac.FPGA1,trigger_type)
            end
            
            for channel = 1:4
                if ~triggeredFPGA(ceil(channel / 2)) && trigger(channel)
                    gui.message_manager.disp(sprintf('Trigger Channel %i',(channel)))
                    gui.dac.triggerWaveform(channel-1,trigger_type)
                end
            end
           
            gui.message_manager.disp('Running')
            
        end
        
    end
    
    methods (Access = 'private')
        function [file_name, file_path] = load_file(gui,filter,filter_description)
            % currently ignoring filter_description
            % it does not appear that you can tell uigetfile both the path to
            % load from and the filter description to use
            % saving the last path is more usefull than using a filter
            % description

            [file_name,file_path] = uigetfile([gui.last_file_path filter], 'Open File');
            if file_path ~= 0
                gui.last_file_path = file_path;
            end
        end
    end
end
