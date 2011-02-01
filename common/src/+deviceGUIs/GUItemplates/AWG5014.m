function varargout = AWG5014(varargin)
%AWG5014 M-file for AWG5014.fig
%      AWG5014, by itself, creates a new AWG5014 or raises the existing
%      singleton*.
%
%      H = AWG5014 returns the handle to a new AWG5014 or the handle to
%      the existing singleton*.
%
%      AWG5014('Property','Value',...) creates a new AWG5014 using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to AWG5014_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      AWG5014('CALLBACK') and AWG5014('CALLBACK',hObject,...) call the
%      local function named CALLBACK in AWG5014.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help AWG5014

% Last Modified by GUIDE v2.5 28-Oct-2010 14:23:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AWG5014_OpeningFcn, ...
                   'gui_OutputFcn',  @AWG5014_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
   gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before AWG5014 is made visible.
function AWG5014_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for AWG5014
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes AWG5014 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = AWG5014_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function ch1amp_Callback(hObject, eventdata, handles)
% hObject    handle to ch1amp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ch1amp as text
%        str2double(get(hObject,'String')) returns contents of ch1amp as a double


% --- Executes during object creation, after setting all properties.
function ch1amp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ch1amp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ch1off_Callback(hObject, eventdata, handles)
% hObject    handle to ch1off (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ch1off as text
%        str2double(get(hObject,'String')) returns contents of ch1off as a double


% --- Executes during object creation, after setting all properties.
function ch1off_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ch1off (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ch2amp_Callback(hObject, eventdata, handles)
% hObject    handle to ch2amp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ch2amp as text
%        str2double(get(hObject,'String')) returns contents of ch2amp as a double


% --- Executes during object creation, after setting all properties.
function ch2amp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ch2amp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ch2off_Callback(hObject, eventdata, handles)
% hObject    handle to ch2off (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ch2off as text
%        str2double(get(hObject,'String')) returns contents of ch2off as a double


% --- Executes during object creation, after setting all properties.
function ch2off_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ch2off (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ch3amp_Callback(hObject, eventdata, handles)
% hObject    handle to ch3amp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ch3amp as text
%        str2double(get(hObject,'String')) returns contents of ch3amp as a double


% --- Executes during object creation, after setting all properties.
function ch3amp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ch3amp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ch3off_Callback(hObject, eventdata, handles)
% hObject    handle to ch3off (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ch3off as text
%        str2double(get(hObject,'String')) returns contents of ch3off as a double


% --- Executes during object creation, after setting all properties.
function ch3off_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ch3off (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ch4amp_Callback(hObject, eventdata, handles)
% hObject    handle to ch4amp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ch4amp as text
%        str2double(get(hObject,'String')) returns contents of ch4amp as a double


% --- Executes during object creation, after setting all properties.
function ch4amp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ch4amp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ch4off_Callback(hObject, eventdata, handles)
% hObject    handle to ch4off (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ch4off as text
%        str2double(get(hObject,'String')) returns contents of ch4off as a double


% --- Executes during object creation, after setting all properties.
function ch4off_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ch4off (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ch1enable.
function ch1enable_Callback(hObject, eventdata, handles)
% hObject    handle to ch1enable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ch1enable


% --- Executes on button press in ch2enable.
function ch2enable_Callback(hObject, eventdata, handles)
% hObject    handle to ch2enable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ch2enable


% --- Executes on button press in ch3enable.
function ch3enable_Callback(hObject, eventdata, handles)
% hObject    handle to ch3enable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ch3enable


% --- Executes on button press in ch4enable.
function ch4enable_Callback(hObject, eventdata, handles)
% hObject    handle to ch4enable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ch4enable



function seqfile_Callback(hObject, eventdata, handles)
% hObject    handle to seqfile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of seqfile as text
%        str2double(get(hObject,'String')) returns contents of seqfile as a double


% --- Executes during object creation, after setting all properties.
function seqfile_CreateFcn(hObject, eventdata, handles)
% hObject    handle to seqfile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in enable.
function enable_Callback(hObject, eventdata, handles)
% hObject    handle to enable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of enable



function gpibAddress_Callback(hObject, eventdata, handles)
% hObject    handle to gpibAddress (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of gpibAddress as text
%        str2double(get(hObject,'String')) returns contents of gpibAddress as a double


% --- Executes during object creation, after setting all properties.
function gpibAddress_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gpibAddress (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function samplingRate_Callback(hObject, eventdata, handles)
% hObject    handle to samplingRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of samplingRate as text
%        str2double(get(hObject,'String')) returns contents of samplingRate as a double


% --- Executes during object creation, after setting all properties.
function samplingRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to samplingRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function triggerInterval_Callback(hObject, eventdata, handles)
% hObject    handle to triggerInterval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of triggerInterval as text
%        str2double(get(hObject,'String')) returns contents of triggerInterval as a double


% --- Executes during object creation, after setting all properties.
function triggerInterval_CreateFcn(hObject, eventdata, handles)
% hObject    handle to triggerInterval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in seqforce.
function seqforce_Callback(hObject, eventdata, handles)
% hObject    handle to seqforce (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of seqforce


% --- Executes on selection change in triggerSource.
function triggerSource_Callback(hObject, eventdata, handles)
% hObject    handle to triggerSource (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns triggerSource contents as cell array
%        contents{get(hObject,'Value')} returns selected item from triggerSource


% --- Executes during object creation, after setting all properties.
function triggerSource_CreateFcn(hObject, eventdata, handles)
% hObject    handle to triggerSource (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in scaleMode.
function scaleMode_Callback(hObject, eventdata, handles)
% hObject    handle to scaleMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns scaleMode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from scaleMode


% --- Executes during object creation, after setting all properties.
function scaleMode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scaleMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


