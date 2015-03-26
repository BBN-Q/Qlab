function ExpSettingsGUI()

%A simple launcher for the PulseParamGUI python program. 
progPath = fullfile(getpref('qlab', 'PyQLabDir'), 'ExpSettingsGUI.py');

%Check whether we are on windows to use pythonw instead of python
if ispc
    [status, result] = system(sprintf('pythonw "%s" --scripterFile "%s" &', progPath, getpref('qlab', 'CurScripterFile')));
%Otherwise just call regular python
else
    [status, result] = system(sprintf('python "%s" --scripterFile "%s" &', progPath, getpref('qlab', 'CurScripterFile')));
end

if status ~= 0
    error('Failed to launch ExpSettingsGUI with error: %s', result)
end