% --- Creates and returns a handle to the GUI figure.
function mainFig = DacIIGui

% pass in object in case we are being loaded from class
persistent hsingleton;
if ishandle(hsingleton)
    mainFig = hsingleton;
    figure(mainFig);
    return;
end

boxWidth = 138;
boxLeft = 3;
boxHeight = 6.55;
boxSpacing = boxHeight + 0.05;
row_one = 40;

% convert screen size to  characters to convert window Position to pixels
set(0,'Units','Pixels')
pixels = get(0,'ScreenSize'); 
set(0,'Units','characters');
characters = get(0,'ScreenSize');

c2p = pixels ./characters;
c2p(1:2) = c2p(3:4); % first 2 elements of c2p are zero, replicate 3:4

windowPositionChr = [78.6000   26.2308  144   43];
windowPosition = windowPositionChr .* c2p;
% center window
windowPosition(1:2) = (pixels(3:4)- windowPosition(3:4)) / 2;


appdata = [];

    function b = drawButton(parent,b)
        defaultSize = [13 1.7];
        if ~isfield(b,'callback')
            b.callback = sprintf('%s_Callback',b.tag);
        end
        switch length(b.position)
            case 3
                b.position(4) = defaultSize(2);
            case 2
                b.position(3:4) = defaultSize;
        end
        h13 = uicontrol(...
            'Parent',parent,...
            'Units','characters',...
            'Callback',@(hObject,eventdata)mainwindow(b.callback,hObject,eventdata,guidata(hObject)),...
            'Position',b.position,...
            'String',b.string,...
            'Tag',b.tag,...
            'Enable',b.enable,...
            'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );
    end

    function l = drawLabel(parent,l)
         h = uicontrol(...
                'Parent',parent,...
                'Units','characters',...
                'HorizontalAlignment','left',...
                'Position', l.position,...
                'String', l.string,...
                'Style','text',...
                'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );
    end


mainFig = figure(...
    'CloseRequestFcn',@(hObject,eventdata)mainwindow('figure1_CloseRequestFcn',hObject,eventdata,guidata(hObject)),...
    'Color', ones([1,3])*0.941176470588235,...
    'IntegerHandle','off',...
    'InvertHardcopy',get(0,'defaultfigureInvertHardcopy'),...
    'MenuBar','none',...
    'Name','DacII Control',...
    'NumberTitle','off',...
    'PaperPosition',get(0,'defaultfigurePaperPosition'),...
    'Position',windowPosition,...
    'Resize','off',...
    'CreateFcn', {@local_CreateFcn, blanks(0), appdata},...
    'HandleVisibility','callback',...
    'UserData',[],...
    'Units','characters',...
    'Tag','figure1',...
    'Visible','on');

appdata = [];
appdata.lastValidTag = 'text1';

%% Top Row %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

uicontrol(...
    'Parent',mainFig,...
    'Units','characters',...
    'FontWeight','bold',...
    'Position',[57.9 row_one 39.9 2],...
    'String',{  'DAC II Waveform Generation Board'; 'Command and Control GUI' },...
    'Style','text',...
    'Tag','text1',...
    'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

uicontrol(...
    'Parent',mainFig,...
    'Units','characters',...
    'Position',[3.8 row_one 10.4 1.1],...
    'String','Device',...
    'Style','text',...
    'Tag','text20',...
    'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

uicontrol(...
    'Parent',mainFig,...
    'Units','characters',...
    'BackgroundColor',[1 1 1],...
    'Callback',@(hObject,eventdata)mainwindow('pm_usb_ids_Callback',hObject,eventdata,guidata(hObject)),...
    'Position',[16 row_one 15 1.5],...
    'String','0',...
    'Style','popupmenu',...
    'Value',1,...
    'CreateFcn', {@local_CreateFcn, blanks(0), appdata} ,...
    'Tag','pm_usb_ids');
%% Open and Saved moved to button drawing


%%% Config Status Box %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

configPanel = uipanel(...
    'Parent',mainFig,...
    'Units','characters',...
    'Title','Configuration Status',...
    'Tag','uipanel1',...
    'Clipping','on',...
    'Position',[boxLeft 9.3+4*boxSpacing boxWidth 4],...
    'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );


labels = [];
labels(1).string = 'FPGA Programming Bit File:';
labels(1).position = [1.8 0.9 26.6 1.2];

labels(2).string = 'Version:';
labels(2).position = [81.8 1 10.4 1.2];

drawLabel(configPanel,labels(1));
drawLabel(configPanel,labels(2));

uicontrol(...
    'Parent',configPanel,...
    'Units','characters',...
    'BackgroundColor',[1 1 1],...
    'Callback',@(hObject,eventdata)mainwindow('txt_bit_file_name_Callback',hObject,eventdata,guidata(hObject)),...
    'Position',[29.8 0.7 38.2 1.6],...
    'String',blanks(0),...
    'Style','edit',...
    'CreateFcn',{@local_CreateFcn, blanks(0), appdata} ,...
    'Tag','txt_bit_file_name');

buttons = [];
buttons(1).tag = 'pb_open_bit_file';
buttons(1).position = [69.8 0.6 8.2];
buttons(1).string = '...';
buttons(1).enable = 'on';

buttons(2).tag = 'pb_load_bit_file';
buttons(2).position = [120 0.8];
buttons(2).string = 'Load';
buttons(2).enable = 'off';

drawButton(configPanel,buttons(1));
drawButton(configPanel,buttons(2));

uicontrol(...
    'Parent',configPanel,...
    'Units','characters',...
    'HorizontalAlignment','left',...
    'Position',[91.4 1 10.4 1.1],...
    'String',blanks(0),...
    'Style','text',...
    'Value',1,...
    'Tag','txt_bit_file_version',...
    'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function drawDacBox(dac, y)
        
        fpgas = [1 1 23 23];
        fpga = fpgas(dac+1);
        
        withdacs = [1 0 3 2];
        withdac = withdacs(dac + 1);
        
        row1Top = 3.5;
        row2Top = 1.5;
        cbTop = 1;
        
        newPanel = uipanel(...
            'Parent',mainFig,...
            'Units','characters',...
            'Title',sprintf('FPGA%02i / DAC%i ', fpga,dac),...
            'Clipping','on',...
            'Position',[boxLeft y boxWidth boxHeight],...
            'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );
        
        %% Draw Labels
        
        lblHeight = 1.15;
        
        labels = [];
        labels(1).string = 'Waveform mat File:';
        labels(1).position = [2.5 row1Top 26.2 lblHeight];
        
        labels(2).string = 'Scale Factor:';
        labels(2).position = [7.6 row2Top 14.2 lblHeight];
        
        labels(3).string = 'Trigger Type:';
        labels(3).position = [60 row1Top 14.2 lblHeight];
        
        labels(4).string = 'Sample Rate:';
        labels(4).position = [60 row2Top 14.12 lblHeight];
        
        labels(5).string = 'Offset:';
        labels(5).position = [33 row2Top 10.4 1.1];
        
        for i = 1:length(labels)
           drawLabel(newPanel,labels(i));
        end
        
        %% Draw Buttons
               
        buttons = [];
        buttons(1).tag = sprintf('pb_open_mat_file_%i',dac);
        buttons(1).position = [50 row1Top 8.2 ];
        buttons(1).string = '...';
        buttons(1).enable = 'on';
        buttons(1).callback = 'pb_open_mat_file_Callback';
        
        buttons(2).tag = sprintf('pb_load_wf_%i',dac);
        buttons(2).position = [92 row1Top ];
        buttons(2).string = 'Load';
        buttons(2).enable = 'off';
        buttons(2).callback = 'pb_load_wf_Callback';
        
        buttons(3).tag = sprintf('pb_trigger_wf_%i',dac);
        buttons(3).position = [106 row1Top ];
        buttons(3).string = 'Trigger';
        buttons(3).enable = 'off';
        buttons(3).callback = 'pb_trigger_wf_Callback';

        buttons(4).tag = sprintf('pb_plot_wf_%i',dac);
        buttons(4).position = [92 row2Top ];
        buttons(4).string = 'Plot';
        buttons(4).enable = 'off';
        buttons(4).callback = 'pb_plot_wf_Callback';
        
        buttons(5).tag = sprintf('pb_pause_wf_%i',dac);
        buttons(5).position = [106 row2Top ];
        buttons(5).string = 'Pause';
        buttons(5).enable = 'off';
        buttons(5).callback = 'pb_pause_wf_Callback'; 
        
        buttons(6).tag = sprintf('pb_disable_wf_%i',dac);
        buttons(6).position = [120 row2Top ];
        buttons(6).string = 'Disable';
        buttons(6).enable = 'off';
        buttons(6).callback = 'pb_disable_wf_Callback';
        
        for i = 1:length(buttons)
            drawButton(newPanel,buttons(i));
        end
        
        %% Text Boxes
        
        tb = [];
        tb(1).tag = sprintf('txt_wf_file_%i',dac);
        tb(1).position = [19 row1Top 30 1.6];
        tb(1).string = blanks(0);
        tb(1).callback = 'txt_wf_file_Callback';
        
        tb(2).tag = sprintf('txt_wf_scale_factor_%i',dac);
        tb(2).position = [19 row2Top 9.9 1.55];
        tb(2).string ='1.0';
        tb(2).callback = 'txt_wf_scale_factor_Callback';
        
        tb(3).tag = sprintf('txt_wf_offset_%i',dac);
        tb(3).position = [39 row2Top 9.9 1.55];
        tb(3).string ='0x0';
        tb(3).callback = 'txt_wf_offset_Callback';
        
        
        for i = 1:length(tb)
            if ~isfield(tb(i),'callback')
                tb(i).callback = sprintf('%s_Callback',tb(i).tag);
            end
            uicontrol(...
                'Parent',newPanel,...
                'Units','characters',...
                'BackgroundColor',[1 1 1],...
                'Callback',@(hObject,eventdata)mainwindow(tb(i).callback,hObject,eventdata,guidata(hObject)),...
                'Position', tb(i).position,...
                'String',tb(i).string,...
                'Style','edit',...
                'CreateFcn', {@local_CreateFcn, blanks(0), appdata} ,...
                'Tag', tb(i).tag);
        end
        
        %% check boxes
        
        cbWidth = 0.31;
        
        cb = [];
        cb(1).tag = sprintf('cb_ll_enable_%i',dac);
        cb(1).position = [19  cbWidth 21.6 cbTop];
        cb(1).string = 'Enable Link List ';
        cb(3).callback = 'cb_ll_enable_Callback';
        
        cb(2).tag = sprintf('cb_ll_dc_%i',dac);
        cb(2).position = [39 cbWidth 15 cbTop];
        cb(2).string = 'DC Mode';
        cb(3).callback = 'cb_ll_dc_Callback';
        
        cb(3).tag = sprintf('cb_simultaneous_%i',dac);
        cb(3).position = [92 cbWidth 18.6 cbTop];
        cb(3).string = sprintf('With DAC%i',withdac);
        cb(3).callback = 'cb_simultaneous_Callback';
        
        for i = 1:length(cb)
            if ~isfield(cb(i),'callback')
               cb(i).callback = sprintf('%s_Callback',cb(i).tag);
            end
            uicontrol(...
                'Parent',newPanel,...
                'Units','characters',...
                'Callback',@(hObject,eventdata)mainwindow(cb(i).callback,hObject,eventdata,guidata(hObject)),...
                'Enable','off',...
                'Position',cb(i).position,...
                'String',cb(i).string,...
                'Style','checkbox',...
                'Tag',cb(i).tag,...
                'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );
        end
        
        %% Drop Downs
        
        ddAdj = -.25;
           
        dd(1).tag = sprintf('pm_wf_trigger_%i',dac);
        dd(1).position = [72 (row1Top + ddAdj) 17 1.7];
        dd(1).string = {'Software'; 'Hardware' };
        
        dd(2).tag = sprintf('pm_wf_sample_rate_%i',dac);
        dd(2).position = [72 (row2Top + ddAdj) 17 1.7];
        dd(2).string = {'1.2 GHz'; '600 MHz'; '300 MHz'; '100 MHz'; '40 MHz' };
        dd(2).callback = 'pm_wf_sample_rate_Callback';

        for i = 1:length(dd)
            if ~isfield(dd(i),'callback')
                dd(i).callback = sprintf('%s_Callback',dd(i).tag);
            end
            uicontrol(...
                'Parent',newPanel,...
                'Units','characters',...
                'BackgroundColor',[1 1 1],...
                'Callback',@(hObject,eventdata)mainwindow(dd(i).callback,hObject,eventdata,guidata(hObject)),...
                'Position',dd(i).position,...
                'String',dd(i).string,...
                'Style','popupmenu',...
                'Value',1,...
                'CreateFcn', {@local_CreateFcn, blanks(0), appdata} ,...
                'Tag',dd(i).tag);
        end
    end

drawDacBox(0, 9.3 + 3*boxSpacing);
drawDacBox(1, 9.3 + 2*boxSpacing);
drawDacBox(2, 9.3 + 1*boxSpacing);
drawDacBox(3, 9.3)

%%% ??? All Buttons

all_top = 7;

buttons = [];
buttons(1).tag = 'pb_load_all';
buttons(1).position = [80 all_top];
buttons(1).string = 'Load All';
buttons(1).enable = 'off';

buttons(2).tag = 'pb_trigger_all';
buttons(2).position = [95.5 all_top];
buttons(2).string = 'Trigger All';
buttons(2).enable = 'off';

buttons(3).tag = 'pb_pause_all';
buttons(3).position = [109.5 all_top];
buttons(3).string = 'Pause All';
buttons(3).enable = 'off';

buttons(4).tag = 'pb_disable_all';
buttons(4).position = [123 all_top];
buttons(4).string = 'Disable All';
buttons(4).enable = 'off';


buttons(5).tag = 'pb_save_config';
buttons(5).position = [123 row_one];
buttons(5).string = 'Save';
buttons(5).enable = 'on';

buttons(6).tag = 'pb_open_config';
buttons(6).position = [109.5 row_one];
buttons(6).string = 'Open';
buttons(6).enable = 'on';


for i = 1:length(buttons)
    drawButton(mainFig,buttons(i));
end

%% Messages pannel

mesgPanel = uipanel(...
    'Parent',mainFig,...
    'Units','characters',...
    'Title','Messages',...
    'Tag','uipanel6',...
    'Clipping','on',...
    'Position',[boxLeft 0.7 boxWidth 6],...
    'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

for i = 1:4
    uicontrol(...
        'Parent',mesgPanel,...
        'Units','characters',...
        'HorizontalAlignment','left',...
        'Position',[ 1.5 (1.1*(i-1) + 0.1) 135 1.1],...
        'String',sprintf('%i',i),...
        'Style','text',...
        'Tag',sprintf('txt_msg_%i',i),...
        'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );
end

% Slider

    uicontrol(...
    'Parent',mesgPanel,...
    'Units','characters',...
    'BackgroundColor',[0.9 0.9 0.9],...
    'Callback',@(hObject,eventdata)mainwindow('sl_msg_Callback',hObject,eventdata,guidata(hObject)),...
    'CData',[],...
    'Position',[133 0.8 4.2 4],...
    'String',{  'Slider' },...
    'Style','slider',...
    'SliderStep',[1 1],...
    'Value',1,...
    'CreateFcn', {@local_CreateFcn, blanks(0), appdata} ,...
    'UserData',[],...
    'Tag','sl_msg');

hsingleton = mainFig;

end

% --- Set application data first then calling the CreateFcn.
function local_CreateFcn(hObject, eventdata, createfcn, appdata)

if ~isempty(appdata)
    names = fieldnames(appdata);
    for i=1:length(names)
        name = char(names(i));
        setappdata(hObject, name, getfield(appdata,name));
    end
end

if ~isempty(createfcn)
    if isa(createfcn,'function_handle')
        createfcn(hObject, eventdata);
    else
        eval(createfcn);
    end
end

end


