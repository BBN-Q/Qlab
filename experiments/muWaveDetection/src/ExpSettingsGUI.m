function ExpSettingsGUI()

%A simple launcher for the PulseParamGUI python program. 
progPath = fullfile(getpref('qlab', 'PyQLabDir'), 'ExpSettingsGUI.py');

%Check whether we are on windows to use pythonw instead of python
if ispc
    system(sprintf('pythonw "%s" --scripterFile "%s" &', progPath, getpref('qlab', 'CurScripterFile')));
%Otherwise just call regular python
else
    system(sprintf('python "%s" --scripterFile "%s" &', progPath, getpref('qlab', 'CurScripterFile')));
end

