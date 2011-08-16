% --- Creates and returns a handle to the GUI figure.
function mainPanel = APSInsert(fig,position,drawMessagePanel)

% pass in object in case we are being loaded from class
persistent hsingleton;
if ishandle(hsingleton)
    mainFig = hsingleton;
    return;
end

leftAlign =  2;
rightAlign = 102;
buttonHeight = 1.45;

appdata = [];

if ~exist('drawMessagePanel','var') || isempty(drawMessagePanel)
    drawMessagePanel = true;
end

if ~drawMessagePanel
    heightAdjust = 4;
else
    heightAdjust = 0;
end

if ~exist('position','var') || isempty(position)
    position = [leftAlign 0 rightAlign+2*leftAlign 23-heightAdjust];
end

if ~exist('fig','var') || isempty(fig)
    fig = figure(...
        'Color', ones([1,3])*0.941176470588235,...
        'IntegerHandle','off',...
        'InvertHardcopy',get(0,'defaultfigureInvertHardcopy'),...
        'MenuBar','none',...
        'Name','Raytheon BBN Technologies APS',...
        'NumberTitle','off',...
        'PaperPosition',get(0,'defaultfigurePaperPosition'),...
        'CreateFcn', {@local_CreateFcn, blanks(0), appdata},...
        'CloseRequestFcn',@(hObject,eventdata)mainwindow('figure1_CloseRequestFcn',hObject,eventdata,guidata(hObject)),...
        'HandleVisibility','callback',...
        'UserData',[],...
        'Units','characters',...
        'Tag','figure1',...
        'Visible','on');
    
    % expand width of default figure
    pos = get(fig,'Position');
    pos(3) = 4*leftAlign+rightAlign;
    pos(4) = 26 - heightAdjust;
    set(fig,'Position',pos);
    
    position(2) = 2;
    
    buttons.tag = 'windowClose';
    buttons.position = [pos(3)-13-leftAlign .5-.125 13 buttonHeight];
    buttons.string = 'Close';
    buttons.enable = 'on';
    buttons.callback = 'figure1_CloseRequestFcn';
    %drawButton(fig, buttons);
    
end

    function b = drawButton(parent,b)
        defaultSize = [13 1.7];
        if ~isfield(b,'callback')
            b.callback = sprintf('%s_Callback',b.tag);
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
        if ~isfield(l,'tag') || isempty(l.tag)
            l.tag = 'label';
        end
         h = uicontrol(...
                'Parent',parent,...
                'Units','characters',...
                'HorizontalAlignment','left',...
                'Position', l.position,...
                'String', l.string,...
                'Style','text',...
                'Tag',l.tag, ...
                'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );
    end

    function d = drawDropDown(parent, d)
        h = uicontrol('Parent',parent,...
            'Units','characters',...
            'BackgroundColor',[1 1 1],...
            'Callback',@(hObject,eventdata)mainwindow(d.callback,hObject,eventdata,guidata(hObject)),...
            'Position',d.position,...
            'String',d.string,...
            'Style','popupmenu',...
            'Value',1,...,
            'Tag',d.tag,...
            'CreateFcn', {@local_CreateFcn, blanks(0), appdata});
    end

    function e = drawEditText(parent,e)
        if ~isfield(e,'max')
            e.max = 1;
        end
        e = uicontrol('Parent',parent,...
            'Units','characters',...
            'BackgroundColor',[1 1 1],...
            'Callback',@(hObject,eventdata)mainwindow(e.callback,hObject,eventdata,guidata(hObject)),...
            'Position',e.position,...
            'String',e.string,...
            'Style','edit',...
            'CreateFcn', {@local_CreateFcn, blanks(0), appdata} ,...
            'Max',e.max, ...
            'HorizontalAlignment','left', ...
            'Tag',e.tag);
    end

mainPanel = uibuttongroup(...
    'Parent',fig,...
    'Units','characters',...
    'Title','APS',...
    'Tag','uipanel1',...
    'Clipping','on',...
    'Position',position,...
    'SelectedObject',[],...
    'SelectionChangeFcn',[],...
    'OldSelectedObject',[],...
    'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );


%%%%%%%%%%%%%%%%%%%%%% Main Panel Labels %%%%%%%%%%%%%%%%%%%%%%%%%%%%


labels = [];
labels(1).string = 'Device ID:';
labels(1).position = [leftAlign 20.25-heightAdjust 9 1];

labels(2).string = 'Channel Configuration';
labels(2).position = [leftAlign 11.5-heightAdjust 18.86 1];

if drawMessagePanel
    labels(3).string = 'Message Log';
    labels(3).position = [leftAlign 3.5 19.57 1];
end

for i = 1:length(labels)
    drawLabel(mainPanel,labels(i));
end

dropDown = [];
dropDown(1).tag = 'pm_usb_ids';
dropDown(1).callback = 'pm_usb_ids_Callback';
dropDown(1).string = {'Not Found'};
dropDown(1).position = [11.5 20.5-heightAdjust 14 1];

for i = 1:length(dropDown)
    drawDropDown(mainPanel,dropDown(i));
end



%%%%%  Device Config  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

configPanel = uibuttongroup(...
    'Parent',mainPanel,...
    'Units','characters',...
    'Title','Device Configuration',...
    'Tag','uipanel2',...
    'Clipping','on',...
    'Position',[leftAlign 13-heightAdjust rightAlign 7],...
    'SelectedObject',[],...
    'SelectionChangeFcn',[],...
    'OldSelectedObject',[],...
    'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

labels = [];
firstRow = 4.25;
secondRow = 2.5;
labels(1).string = 'FPGA Bit File:';
labels(1).position = [2 firstRow 14.43 1];

labels(2).string = 'Firmware version:';
labels(2).position = [63.5 firstRow 15.43 1];

labels(3).string = 'Unknown';
labels(3).position = [78.29 firstRow 8.714 1];
labels(3).tag = 'txt_bit_file_version';

labels(4).string = 'Trigger Type:';
labels(4).position = [2 secondRow 12.86 1];

labels(5).string  = 'Sample Rate:';
labels(5).position  = [34 secondRow 15.14 1];

labels(6).string  = 'Sequencer Mode:';
labels(6).position  = [67 secondRow 15.86 1];

for i = 1:length(labels)
    drawLabel(configPanel,labels(i));
end

dropDown = [];
dropDown(1).tag = 'pm_wf_trigger';
dropDown(1).callback = 'empty';
dropDown(1).string = { 'Internal'; 'External' };
dropDown(1).position = [15 secondRow+0.25 13 1];

dropDown(2).tag = 'pm_wf_sample_rate';
dropDown(2).callback = 'empty';
dropDown(2).string = { '1.2 GHz'; '600 MHz'; '300 MHz'; '100 MHz'; '40 MHz' };
dropDown(2).position = [49 secondRow+0.25 13 1];

dropDown(3).tag = 'cb_ll_dc';  % called dc for historical reasons this is actuall mode
dropDown(3).callback = 'empty';
dropDown(3).string = { 'Contiuous'; 'One Shot' };
dropDown(3).position = [87 secondRow+0.25 13 1];

for i = 1:length(dropDown)
    drawDropDown(configPanel,dropDown(i));
end



buttons = [];
buttons(1).tag = 'pb_open_bit_file';
buttons(1).position = [49 firstRow-.125 13 buttonHeight];
buttons(1).string = 'Choose';
buttons(1).enable = 'on';

buttons(2).tag = 'pb_load_bit_file';
buttons(2).position = [87 firstRow-.125 13 buttonHeight];
buttons(2).string = 'Program';
buttons(2).enable = 'on';

buttons(3).tag = 'pb_run';
buttons(3).position = [2 0.5 13 buttonHeight];
buttons(3).string = 'Run';
buttons(3).enable = 'on';

buttons(4).tag = 'pb_stop';
buttons(4).position = [15 0.5 13 buttonHeight];
buttons(4).string = 'Stop';
buttons(4).enable = 'off';

for i = 1:length(buttons)
    drawButton(configPanel,buttons(i));
end

bitFile.position = [15 firstRow-.125 33 1.35];
bitFile.tag = 'txt_bit_file_name';
bitFile.string = '';
bitFile.callback = '';

drawEditText(configPanel,bitFile);

%%% Config Status Box %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function drawChannelConfig(tab,channel)
        
        panel = uibuttongroup(...
            'Parent',tab,...
            'Units','normalized',...
            'Title','',...
            'Tag','uipanel2',...
            'Clipping','on',...
            'Position',[0 0 1 1],...
            'SelectedObject',[],...
            'SelectionChangeFcn',[],...
            'OldSelectedObject',[],...
            'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );
        
        labels = [];
        labels(1).string = 'Waveform/Sequence file:';
        labels(1).position = [leftAlign 3 21.43 0.7];
        
        labels(2).string = 'Scale factor:';
        labels(2).position = [leftAlign 1 11.86 0.7];

        labels(3).string = 'Offset:';
        labels(3).position = [25.86 1 7.43 0.7];
        
        for j = 1:length(labels)
            drawLabel(panel,labels(j));
        end
   
        edits = [];
        edits(1).position = [25 3-.375 61 1.35];
        edits(1).tag = sprintf('txt_wf_file_%i',channel-1);
        edits(1).string = '';
        edits(1).callback = 'txt_wf_file_Callback';
        
        edits(2).position = [13.5 1-.375 9.14 1.35];
        edits(2).tag = sprintf('txt_wf_scale_factor_%i',channel-1);
        edits(2).string = '1.00';
        edits(2).callback = 'txt_wf_scale_factor_Callback';
        
        edits(3).position = [33.57 1-.375 9.14 1.35];
        edits(3).tag = sprintf('txt_wf_offset_%i',channel-1);
        edits(3).string = '0.00';
        edits(3).callback = 'txt_wf_offset_Callback';
        
        for j = 1:length(edits)
           drawEditText(panel,edits(j)); 
        end
        
        button.tag = sprintf('pb_open_mat_file_%i',channel-1);
        button.position = [87 3-.375 13  buttonHeight];
        button.string = 'Choose';
        button.enable = 'On';
        button.callback = 'pb_open_mat_file_Callback';
        
        drawButton(tab,button);
        
        h30 = uicontrol(...
            'Parent',tab,...
            'Units','characters',...
            'Position',[87 1-.125 13 1.25],...
            'String',{  'On / Off' },...
            'Style','radiobutton',...
            'Value',0,...
            'Tag',sprintf('rb_on_off_%i',channel-1),...
            'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );
           %'Callback',@(hObject,eventdata)mainwindow('rb_on_off_callback',hObject,eventdata,guidata(hObject)),...
    end

%%%% Draw Tabs %%%%
% This is undocumented matlab and may change in the future
% taken from http://undocumentedmatlab.com/blog/tab-panels-uitab-and-relatives/
warning('off','MATLAB:uitabgroup:OldVersion');
tabGroup = uitabgroup(mainPanel, ...
    'Units','characters', ...
    'Position', [leftAlign 4.75-heightAdjust rightAlign 6.5]); 
tab1 = uitab(tabGroup,'title', 'Channel 1');
tab2 = uitab(tabGroup,'title', 'Channel 2');
tab3 = uitab(tabGroup,'title', 'Channel 3');
tab4 = uitab(tabGroup,'title', 'Channel 4');

drawChannelConfig(tab1,1);
drawChannelConfig(tab2,2);
drawChannelConfig(tab3,3);
drawChannelConfig(tab4,4);

edit.position = [leftAlign 0.5 rightAlign 3];
edit.tag = 'message_window';
edit.string = '';
edit.callback = '';
edit.max = 5;

if drawMessagePanel
    drawEditText(mainPanel,edit);
end
        
hsingleton = mainPanel;
mainwindow('mainwindow_OpeningFcn', mainPanel, [], guihandles(mainPanel));
end

% --- Set application data first then calling the CreateFcn.
function local_CreateFcn(hObject, eventdata, createfcn, appdata)

if ~isempty(appdata)
    names = fieldnames(appdata);
    for i=1:length(names)
        name = char(names(i));
        setappdata(hObject, name, appdata.(name));
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

